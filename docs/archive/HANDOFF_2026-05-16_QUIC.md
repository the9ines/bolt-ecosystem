# Handoff — 2026-05-16 — App-to-App QUIC Migration

## Operator Context

- User needs to shut down machine and continue in a fresh session.
- Continue as PM/SRE lead. Follow governance, keep changes scoped, preserve working paths.
- User explicitly wants app-to-app to become QUIC, but does not want us to break currently working WS app-to-app behavior.
- Zero UI changes unless explicitly approved. The prior manual peer-code UI was rejected and reverted.
- LocalBolt is LAN-only. Do not make product copy imply internet-wide LocalBolt transfer/discovery.
- ByteBolt can be mentioned internally/governance only, not in public LocalBolt website copy until released.
- Tauri/egui are retired. Direction is Rust core plus thin native shells.

## Current Product/Architecture Truth

- Current production native app-to-app path: daemon WebSocket client mode.
- Target native app-to-app path: QUIC via quinn.
- QUIC must not become default until:
  - mutual cert-hash pinning is live,
  - no accept-any TLS path is reachable in production app-to-app QUIC,
  - QUIC streams run the same app session lifecycle as WS,
  - WS fallback remains intact.
- `bolt-core-sdk` should stay policy-neutral. LAN-only policy belongs in LocalBolt products.

## Repos In Play

Workspace root:

`/Users/oberfelder/Desktop/the9ines.com/bolt-ecosystem`

Relevant repos:

- `bolt-daemon` — QUIC implementation work.
- `bolt-ecosystem` — governance/roadmap updates.
- `localbolt-app` — native shell integration, already has QUIC metadata plumbing from prior work.
- `localbolt-v3` — web app; currently stable after manual UI rollback and em dash copy cleanup.

## What Was Just Done

### bolt-daemon

Commit created:

- `00e25ab feat(quic): add dynamic client cert pinning`

Files:

- `src/quic_transport.rs`
- `src/main.rs`

What changed:

- Added cloneable QUIC certificate material so the daemon certificate can be reused for client-auth presentation.
- Added `QuicClientCertPinSet`, a thread-safe dynamic allowlist of accepted client certificate hashes.
- Added a dynamic rustls `ClientCertVerifier` that requires client certs and fails closed unless the cert hash is allowlisted.
- Changed WsEndpoint QUIC startup so the metadata listener uses `bind_with_dynamic_client_cert_pins(...)` instead of the no-client-auth listener.
- Kept routing on WS. QUIC is still not default.

Validation already run and passed before commit:

- `cargo test --features transport-quic quic_transport -- --test-threads=1`
- `cargo test --features transport-quic -- --test-threads=1`
- `git diff --check` in `bolt-daemon`
- `git diff --check` in `bolt-ecosystem`

Known note:

- `cargo fmt` briefly touched unrelated files. That unrelated formatting churn was reversed before commit. The daemon working tree is clean after commit.

### bolt-ecosystem governance

Uncommitted governance update exists:

- `docs/ROADMAP.md`

It records:

- Q2C2 dynamic listener pin set implemented.
- WsEndpoint QUIC metadata listener now uses dynamic mutual-pin verifier.
- QUIC routing is still not wired.
- Remaining blocker is QUIC app session adapter.

Current root status:

- `bolt-ecosystem`: `M docs/ROADMAP.md`
- `bolt-daemon`: clean at `00e25ab`

This governance change still needs to be committed after review.

Suggested governance commit:

```bash
cd /Users/oberfelder/Desktop/the9ines.com/bolt-ecosystem
git add docs/ROADMAP.md
git commit -m "docs(roadmap): record quic dynamic pinning gate" \
  -m "Record Q2C2 progress for APP-TO-APP-QUIC-MIGRATION-1: daemon dynamic client-cert pin set exists, WsEndpoint QUIC metadata listener uses the mutual-pin verifier, and QUIC app session routing remains the next blocker." \
  -m "Files changed:" \
  -m "- docs/ROADMAP.md"
```

## Immediate Next Step

Do not flip QUIC default yet.

Next technical task:

`APP-TO-APP-QUIC-SESSION-ADAPTER-1`

Goal:

- Make accepted/dialed QUIC streams run the same application session lifecycle as the current WS path:
  - session-key exchange,
  - HELLO,
  - ProfileEnvelopeV1,
  - BTR,
  - file transfer send/receive,
  - IPC events,
  - disconnect handling.

Important implementation finding:

- `quic_transport.rs` currently gives a framed byte stream.
- `ws_endpoint.rs` owns most active session logic, but it is WebSocket-frame shaped.
- `wt_endpoint.rs` has a separate length-prefixed session loop for WebTransport.
- Best next design is likely to extract a transport-generic session/frame adapter from the WS/WT loops rather than copy/paste another full QUIC loop.

Do not do:

- Do not route `connect_remote.signal` to QUIC until the QUIC stream can run the app session lifecycle.
- Do not enable `transport-quic` by default yet.
- Do not remove WS fallback.
- Do not add UI.

## Suggested New-Session Opening Prompt

Continue from `/Users/oberfelder/Desktop/the9ines.com/bolt-ecosystem/HANDOFF_2026-05-16_QUIC.md`.

Mode:

- PM/SRE implementation
- keep working paths intact
- no UI changes
- no default QUIC flip until tests prove parity

First actions:

1. Verify repo status:
   - `git -C /Users/oberfelder/Desktop/the9ines.com/bolt-ecosystem/bolt-daemon status --short`
   - `git -C /Users/oberfelder/Desktop/the9ines.com/bolt-ecosystem status --short`
2. Review and commit the pending governance update in `bolt-ecosystem/docs/ROADMAP.md` if it still matches `00e25ab`.
3. Start `APP-TO-APP-QUIC-SESSION-ADAPTER-1`.
4. Inspect `ws_endpoint.rs`, `wt_endpoint.rs`, and `quic_transport.rs` to design the smallest session adapter that keeps WS and WT behavior stable.

## Last Known Clean/Dirty State

At handoff time:

- `bolt-daemon`: clean, HEAD `00e25ab`.
- `bolt-ecosystem`: dirty only in `docs/ROADMAP.md`.
- No commits pushed in this last step.

