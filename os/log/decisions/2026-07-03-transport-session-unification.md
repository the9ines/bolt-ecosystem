# Decision: Transport Session Unification (frame-trait)

> **Date:** 2026-07-03
> **Status:** Decided. Execution pending — each phase requires its own phase prompt.
> **Scope repo:** bolt-daemon
> **Supersedes:** the "extract a transport-generic session/frame adapter" note in
> the retired QUIC handoff (now `docs/archive/HANDOFF_2026-05-16_QUIC.md`).

## Context

The daemon runs one Bolt session protocol over three transports (WS, WebTransport,
QUIC). Today each transport re-owns the full session lifecycle:

- **Three message loops:** `run_session_with_outbound` (WS), `run_quic_session_with_outbound`
  (QUIC), and `run_message_loop` in `wt_endpoint.rs` (WT). Near-duplicates.
- **Three handshakes:** the session-key exchange + HELLO + SAS + IPC emit is
  re-implemented inline for each transport (`[WS_HELLO]`, `[QUIC_HELLO]`, WT's).
- **Root cause:** `run_session_with_outbound` *is* generic — but over
  `tungstenite::Message`, a WebSocket library type. QUIC and WT don't speak that
  type, so instead of adapting they each got a full copy of the loop.

This duplication has a live cost: `ws_endpoint.rs` is ~3,188 lines (6x the §13
"<500" guideline), the three copies drift, and on 2026-07-03 the WT receive path
was found missing BTR decryption and the `transfer.*` IPC events that WS and QUIC
already had — work that only existed because WT's loop was a separate copy.

`ACTIVE_SESSION` (`Mutex<Option<ActiveSessionHandle>>`, ~25 uses) is registered
separately inside each of the three loops and races under parallel test runs.

## Decision

**Unify the three transports onto a transport-neutral frame trait. Do not drop a
transport. Do not build a session registry.**

1. Define a small frame abstraction — a `Sink` + `Stream` of text/binary frames
   (`Vec<u8>`), independent of any transport library.
2. Re-base the single session loop on that trait. Each transport supplies a thin
   adapter (its stream ↔ frames) instead of a copy of the loop.
3. Keep `ACTIVE_SESSION` single-valued (single active peer session is LocalBolt's
   domain model), but centralize its registration into the one loop and make it
   injectable so tests don't fight over process-global state.

### Why (vision alignment)

Bolt's premise is "one protocol, any transport, any platform" — and the future
includes a ByteBolt relay-assisted path, which from the core's view is *just another
transport*. A system built on that premise cannot carry N copies of its session
brain. The frame trait is the socket every transport (WS, WT, QUIC, relay-next)
plugs into. This is not cleanup; it is the substrate the platform requires.

Multi-session/concurrent transfers are **explicitly out of scope** today
(FORWARD_BACKLOG "Multiple concurrent transfers — out of scope"; PM-FB-01 open), so
a session registry would be speculative. Keep single-session; leave the seam clean
so a registry is a localized change if/when a concurrent-session product needs it.

## Hard guardrails (apply to every phase)

- **Behavior-preserving refactor.** No protocol semantics, no wire-format, no
  cryptographic changes (ARCH-01..03; `os/rules/phase-discipline.md` §1–3). The bytes
  each transport puts on the wire must be identical before and after — the frame
  trait is an internal seam only.
- **Oracle:** the existing suite is the safety net — `cargo test --features
  native-full -- --test-threads=1` (378 passing as of daemon `a45b76b`), including the
  interop, golden-vector, and `btr_over_ws` / `wti5_btr_over_wt` / `rc3_btr_over_quic`
  tests. Plus `cargo fmt --check` and `cargo clippy` clean. Every phase must keep them
  green.
- **Phase-gated.** Each phase needs its own phase prompt, its own local tag, a journal
  line, and a clean tree. No push (No-Push Policy). No stealth merges.

## Phases

Ordered low-risk-first. Each is independently shippable and independently reversible.

- **Phase 1 — frame trait + converge WS and QUIC.** Define the frame trait; make the
  session loop generic over it; adapt WS (near-trivial — `Message` already wraps
  text/binary) and QUIC onto it; delete `run_quic_session_with_outbound`. Both already
  live in `ws_endpoint.rs`, so this proves the abstraction on two transports with the
  least risk. **Gate:** full suite green; WS and QUIC run one loop; wire bytes unchanged.

- **Phase 2 — fold in WebTransport.** Adapt WT's stream to the frame trait; delete
  `wt_endpoint.rs`'s `run_message_loop`. WT becomes a thin adapter and *inherits* BTR +
  the `transfer.*` IPC events instead of copying them (directly retiring the 2026-07-03
  drift). **Gate:** WT tests green (`wti5_btr_over_wt`, etc.); browser↔app-over-WT still
  works (the App↔Browser manual path).

- **Phase 3 (opportunistic) — unify the handshake.** Collapse the triplicated
  session-key/HELLO/SAS/IPC-emit into one function parameterized by a transport tag for
  logging. Optional; do only if the diff stays small and reviewable. **Gate:** suite
  green; one handshake path.

- **Phase 4 — centralize + de-race ACTIVE_SESSION.** With all sessions running through
  one loop, register `ACTIVE_SESSION` in exactly that one place; make it injectable so
  the QUIC-IPC parallel-test race disappears; document "single active session" as an
  explicit invariant. **No registry.** **Gate:** the previously-racy IPC test passes
  under parallel runs; suite green.

## Explicitly out of scope

- **ByteBolt** (relay + app) — shelved for later per PM (2026-07-03). This workstream
  only makes the core *ready* for a relay transport; it builds nothing ByteBolt.
- Any session registry / concurrent-session work — deferred until a product needs it.
- Legacy WebRTC quarantine finish (`ice_filter.rs`) and CI-coverage reconciliation —
  separate findings, separate workstreams.
