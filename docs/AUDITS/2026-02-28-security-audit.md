# Security Audit — 2026-02-28

> **Status:** FROZEN — Immutable reference. Do not modify.
> **Audit Date:** 2026-02-28
> **Scope:** bolt-core-sdk (Rust + TS), bolt-daemon, bolt-transport-web
> **Source:** Read-only security audit by Principal Security Engineer
> **Registered:** AUDIT-GOV-12A

---

## Executive Summary

Second security audit of the Bolt ecosystem runtime code. Performed after
SA-LOW-SWEEP-1 resolved all remaining LOW findings from the 2026-02-26 audit
(SA13–SA18). This audit identified 11 new findings across lifecycle management,
memory safety, protocol enforcement, transport bounds, and governance gaps.

Key themes:
- **Lifecycle completeness**: Several disconnect/teardown paths leave handlers,
  guards, or timers in stale states (N1, N2, N3, N10).
- **Memory discipline**: Rust `KeyPair` derives `Clone`, allowing silent secret
  key duplication (N4).
- **Protocol enforcement gaps**: Envelope-v1 not enforced unilaterally (N5),
  daemon answerer lacks typed error on pre-HELLO failure (N6), and HelloState
  not structurally wired in answerer DC path (N7).
- **Transport bounds**: No per-capability string length limit (N8) and missing
  explicit length guard in TS `openBoxPayload` (N11).
- **Governance**: No cross-language golden vector test for TS seal → Rust open
  direction (N9).

**Relationship to prior audit:** N1 extends the SA13 surface. SA13 fixed DC
handler nulling (`onopen`, `onclose`, `onerror`, `onmessage`) but missed
`onbufferedamountlow` in the same disconnect block.

---

## Severity Distribution

| Severity | Count | IDs |
|----------|------:|-----|
| HIGH | 1 | N1 |
| MEDIUM | 6 | N2, N3, N4, N5, N6, N7 |
| LOW | 4 | N8, N9, N10, N11 |
| **Total** | **11** | |

---

## Findings

### N1 — HIGH — LIFECYCLE

**`onbufferedamountlow` not nulled in `disconnect()`**

The SA13 fix nulled `onopen`, `onclose`, `onerror`, and `onmessage` handlers
before calling `dc.close()`. However, `onbufferedamountlow` was missed in the
same block. If a backpressure-aware send is awaiting this callback at disconnect
time, the await may suspend permanently (leaked promise / hung transfer).

- **Component:** `WebRTCService.ts`
- **Related:** SA13 (DC handler null fix)
- **Risk:** Permanent suspension of backpressure-awaiting send path on disconnect.

---

### N2 — MEDIUM — LIFECYCLE

**`helloProcessing` never reset after success/error — reconnect blocked**

The `helloProcessing` synchronous guard (added by SA12 fix) is set before
the first `await` in `processHello()` but is only reset in `disconnect()`.
If `processHello()` completes successfully or throws without a full
disconnect cycle, subsequent reconnection attempts on the same instance
will be blocked by the stale guard.

- **Component:** `WebRTCService.ts`
- **Risk:** Reconnection failure after successful handshake or caught error.

---

### N3 — MEDIUM — LIFECYCLE

**`SignalingProvider.onSignal` return type allows void — listener may be unregisterable**

The SA6 fix requires `onSignal()` to return an unsubscribe function. However,
the `SignalingProvider` interface type signature allows `void` return. An
implementation returning `void` would compile but leave the listener
permanently registered, negating the SA6 fix.

- **Component:** `SignalingProvider` interface, `WebRTCService.ts`
- **Risk:** Listener leak if a SignalingProvider implementation returns void.

---

### N4 — MEDIUM — MEMORY

**`KeyPair` derives `Clone` — secret key silently duplicable**

The Rust `KeyPair` struct derives `Clone`. While the SA4 fix added `Drop`
with `write_volatile` zeroization, `clone()` creates a copy of the secret
key that extends its lifetime beyond the original's drop. Any call site
using `.clone()` silently duplicates secret material.

- **Component:** `crypto.rs`
- **Risk:** Secret key lifetime extension via implicit clone.

---

### N5 — MEDIUM — PROTOCOL

**Envelope-v1 not enforced unilaterally — downgrade possible**

When both peers support `bolt.envelope`, Profile Envelope v1 is used. However,
if a peer omits the capability, the session falls back to legacy plaintext
framing. There is no unilateral enforcement: a peer configured with identity
and envelope support will still accept a legacy-mode session from a peer that
does not advertise `bolt.envelope`.

- **Component:** `WebRTCService.ts` capability negotiation
- **Risk:** Downgrade to legacy plaintext framing when one peer omits capability.

---

### N6 — MEDIUM — PROTOCOL

**Daemon answerer pre-HELLO failure exits silently without typed error**

When the daemon is in the answerer role and encounters a failure before
sending its HELLO (e.g., envelope open failure, malformed inbound HELLO),
it exits the session without sending a typed error frame to the initiator.
The initiator sees a silent disconnection with no error code.

- **Component:** `web_hello.rs` (daemon answerer path)
- **Risk:** Silent failure without protocol-level error attribution.

---

### N7 — MEDIUM — PROTOCOL

**Answerer does not wire `HelloState` into DC HELLO path — exactly-once structural only**

The daemon's `HelloState` (added during H5) enforces exactly-once HELLO
semantics. However, the answerer's DataChannel HELLO processing path does
not use `HelloState` to gate HELLO acceptance. Exactly-once is enforced
only by structural flow (single-shot await), not by state machine guard.

- **Component:** `web_hello.rs` (daemon answerer DC path)
- **Risk:** Structural rather than state-machine enforcement of exactly-once HELLO.

---

### N8 — LOW — TRANSPORT

**No per-capability string length bound**

SA17 added `MAX_CAPABILITIES_COUNT` (32) to limit the number of capabilities
in a HELLO message. However, there is no per-capability string length bound.
A peer could send 32 capabilities each with arbitrarily long strings,
consuming unbounded memory during parsing.

- **Component:** `web_hello.rs` (daemon HELLO parsing)
- **Risk:** Memory amplification via oversized capability strings.

---

### N9 — LOW — GOVERNANCE

**No cross-language golden vector test (TS seal → Rust open)**

H3 golden vectors prove TS-sealed payloads can be opened by Rust (and vice
versa for SAS). However, there is no dedicated test that takes a TS-sealed
ciphertext and opens it with the Rust SDK in a single test harness. Cross-
language interop is inferred from matching vector outputs, not from a direct
seal→open round-trip test.

- **Component:** `bolt-core-sdk` test infrastructure
- **Risk:** Inferred rather than proven cross-language crypto interop.

---

### N10 — LOW — LIFECYCLE

**Completion `setTimeout` not cancellable by `disconnect()`**

A `setTimeout` used for transfer completion signaling is not tracked or
cleared during `disconnect()`. If `disconnect()` is called during the
timeout window, the callback fires on a stale/disconnected session.

- **Component:** `WebRTCService.ts`
- **Risk:** Stale callback execution after disconnect.

---

### N11 — LOW — TRANSPORT

**TS `openBoxPayload` missing explicit length guard before nonce slice**

The TS `openBoxPayload()` function slices the first 24 bytes as the nonce
without first verifying that the input is at least 24 bytes long. Short
inputs would produce a truncated nonce passed to NaCl `box.open`, which
would likely fail with an opaque crypto error rather than a clear
validation message.

- **Component:** `bolt-core` `openBoxPayload()`
- **Risk:** Opaque error on malformed short input instead of clear validation failure.

---

## Audit Metadata

- **Auditor role:** Principal Security Engineer (Claude Teams)
- **Audit type:** Read-only security review
- **Repos examined:** bolt-core-sdk (Rust + TS), bolt-daemon, bolt-transport-web
- **Prior audit:** 2026-02-26 (SA-series, 19 findings — all resolved)
- **Registration phase:** AUDIT-GOV-12A
- **Tracker location:** `docs/AUDIT_TRACKER.md`
