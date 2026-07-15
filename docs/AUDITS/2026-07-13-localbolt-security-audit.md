# LocalBolt Ecosystem: Final Security Audit Report

Scope: bolt-core-sdk, bolt-daemon, bolt-rendezvous, bolt-cli, bolt-protocol, localbolt-v3 (browser app), localbolt-app (native macOS app), and localbolt (self-host tooling). Twenty specialist auditors covered 20 review surfaces; every finding was adversarially re-verified by independent skeptics. Rejected findings that did not survive verification are not listed here (40 total).

Severity tally after de-duplication: 0 Critical, 6 High, 8 Medium, 7 Low, 2 Info, plus 9 items flagged for human review.

---

## Executive Summary

There is no critical finding, no memory-corruption, no server-side key or plaintext exposure, and no weak-RNG or nonce-reuse defect. The cryptographic core is well built. The exposure is concentrated in the pairing and transport-authorization layer that is supposed to deliver the product's headline promise: MITM-resistant end-to-end pairing even against a malicious rendezvous. That promise does not currently hold.

Six High findings converge on it:

1. The SAS is 24 bits with no key commitment, so an active MITM at the rendezvous grinds a colliding SAS in under a second and both users see a matching "verified" code. Present identically in the Rust core, the WASM build, and the browser TypeScript.
2. A remote-controlled `legacy:true` HELLO flag makes the native daemon skip identity binding, the pairing policy, and the SAS, and the transfer policy explicitly allows transfers to those no-SAS sessions.
3. The WebTransport handler, the preferred browser transport, never calls the trust gate at all.
4. The shipped macOS app launches the daemon with `--pairing-policy allow` on a `0.0.0.0` listener, so any LAN host silently auto-pairs and drops a file into `~/Downloads`.
5. Browser TOFU pins on an ephemeral, rendezvous-controlled peer code instead of the identity key, so key-continuity never forms.
6. The public rendezvous can be taken offline by a single unauthenticated host.

The shared root cause behind (2), (3), and (4) is that trust enforcement is a per-caller responsibility that individual transports skip, rather than a property of the shared session loop `run_session_with_outbound`. Five fixes retire most of the risk: centralize the trust gate; add a ZRTP-style commitment plus a longer SAS; stop shipping `--pairing-policy allow` on a routable interface; key TOFU on the identity key; move key material out of world-writable `/tmp`. Everything below High is availability, defense-in-depth, or local/dev-only.

---

## Findings by Severity

### HIGH

#### H1. 24-bit SAS with no key commitment is offline-grindable (pairing MITM resistance broken)
- Component: bolt-core (Rust/WASM), bolt-core-browser, localbolt-browser HandshakeManager, bolt-protocol spec.
- Locations: `bolt-core-sdk/rust/bolt-core/src/sas.rs:77` (constants.rs:26,35); `localbolt-v3/packages/bolt-core-browser/src/sas.ts:77` (constants.ts:20,29); `localbolt-v3/packages/localbolt-browser/src/services/webrtc/HandshakeManager.ts:203-215`; `bolt-protocol/PROTOCOL.md:247` (v2 deferral at 249,255); daemon SAS at `bolt-daemon/src/session_loop.rs:570-575`.
- Exploit scenario: An active MITM at the untrusted rendezvous (#2) or on-path (#3) terminates two session legs. Ephemeral keys are exchanged with no prior commitment and the SAS is the first 6 hex chars (24 bits) of SHA-256 over the sorted identity and ephemeral keys. The attacker grinds its own late-committed keys (pure SHA-256, sub-second) so the SAS shown to A equals the SAS shown to B. Both users compare the identical 6-char code, mark verified, and the attacker reads and rewrites every file while both endpoints show a green verified state.
- Recommended fix: Add a ZRTP-style commit-reveal (each side commits H(ephemeral) before learning the peer's key), raise the SAS to at least ~30 bits, and bind a full transcript (version, capabilities, encoding, both key pairs) into the SAS/KDF. Coordinate across PROTOCOL.md and both implementations. Until then, do not represent SAS comparison as reliable active-MITM detection.
- Status: Confirmed (merged 4 findings; both skeptics High on all three implementations).

#### H2. Attacker-controlled `legacy` HELLO flag strips identity/SAS/trust on native WS, and the transfer policy blesses no-SAS legacy sessions
- Component: bolt-daemon WS session bring-up + bolt-app-core session contract.
- Locations: `bolt-daemon/src/session_loop.rs:1053-1111` (WS server legacy branch, no enforce_session_trust, no SAS); `session_loop.rs:530-547` (WS client legacy branch); `session_loop.rs:599` (session.sas suppressed by `if !sas.is_empty()`); `bolt-core-sdk/rust/bolt-app-core/src/contracts/session_contract.rs:90-96` (is_transfer_allowed Legacy => true, mirrored in BoltBridge.swift:583-588); downgrade routing `connect_signal.rs:44-52` + `bolt-daemon/src/main.rs:698-744`.
- Exploit scenario: A malicious rendezvous omits QUIC metadata (or an on-path attacker drops the QUIC handshake) to force the WS fallback, then answers the honest peer's HELLO with `legacy:true`. Both WS paths skip enforce_session_trust, zero the remote identity, and set an empty SAS that is never surfaced, while still entering the file-transfer loop encrypted to the attacker's ephemeral key. The transfer policy allows Legacy, so files flow. A user who set pairing policy Deny still gets a live legacy session, with no SAS to compare.
- Recommended fix: Do not let the remote peer select unauthenticated legacy mode when the local side has an identity. Treat a legacy HELLO response to an identity-configured dial as a downgrade error (fail closed), run enforce_session_trust for legacy, never suppress the SAS, and remove legacy from the transfer-allow set (or gate it behind explicit per-session user consent).
- Status: Confirmed (merged 3 findings; matches the project's own SA10 fix, ported to the TS SDK but not the Rust daemon).

#### H3. WebTransport session handler (preferred browser transport) never calls the identity trust gate
- Component: bolt-daemon WebTransport endpoint.
- Locations: `bolt-daemon/src/wt_endpoint.rs:172-305` (handle_incoming_session), `:296` (run_session_with_outbound), `:43-52` (WtEndpointConfig has no trust_config field), `:279` (remote_identity_pk decoded but unused for authz); contrast `session_loop.rs:1150` (WS server), `:562` (WS client), `:698` (QUIC client), `:818` (QUIC server); `main.rs:793` (0.0.0.0 bind).
- Exploit scenario: Under the default policy Ask (standalone daemon, Linux CLI, Steam Deck), an unknown identity is denied over WS/QUIC but admitted over WT because the WT handler brings the session up and enters the transfer loop with the remote identity in hand yet never passes it to enforce_session_trust. A malicious LAN peer opens a wtransport client (server-side TLS only, so no pinned cert is needed), completes key/HELLO exchange with fresh keys, and drives file transfer. An in-repo test already proves an unpaired WT client writes bytes to the save path.
- Recommended fix: Add trust_config to WtEndpointConfig, thread it through into handle_incoming_session, and call enforce_session_trust immediately after decoding the remote identity and before constructing SessionContext. Emit session.connected/session.sas over IPC for WT. Best fix: make run_session_with_outbound require a proof-of-trust argument so no transport can reach the loop ungated.
- Status: Confirmed, severity contested (High for default-Ask daemons; on the flagship app it overlaps H4 because the app already runs allow-all).

#### H4. Native app spawns the daemon with `--pairing-policy allow` on `0.0.0.0`, so any LAN host silently writes files into `~/Downloads`
- Component: localbolt-app native bridge (sidecar daemon spawn).
- Locations: `localbolt-app/native/shared/src/daemon.rs:75` (0.0.0.0:{port}), `:91` (--pairing-policy allow); `bolt-daemon/src/ipc/trust.rs:347-349` and `session_loop.rs:108-110` (Allow => AllowOnce, headless); `session_loop.rs:1611-1657` (auto-save to $HOME/Downloads before the app is notified); `BoltBridge.swift:87`.
- Exploit scenario: With LocalBolt open, a LAN attacker (#1) scans ports 9100-9999 (or reads the wsUrl advertised via the shared rendezvous room), opens a raw Bolt session bypassing the Accept/SAS flow, and pushes a file named e.g. `LocalBolt-Update.dmg`. The daemon auto-pairs with no prompt and writes it to `~/Downloads` (basename-sanitized, bounded to Downloads) before the UI is consulted. The victim later opens it believing they downloaded it. Repeated pushes are a disk-fill DoS, and the attacker becomes ACTIVE_SESSION so the victim's next outbound send can be misdirected.
- Recommended fix: Stop spawning with `--pairing-policy allow`; use `ask` and drive accept/deny from the Swift UI over the existing pairing.decision IPC so the daemon fails closed until approval. Bind the WS listener to the specific interface rather than 0.0.0.0, and tie inbound acceptance to a token issued when the user taps Accept (as the QUIC cert-hash allowlist already does).
- Status: Confirmed (merged 2 findings; both native-dist skeptics High).

#### H5. TOFU pin store keyed on the ephemeral, rendezvous-controlled peer code instead of the identity key
- Component: localbolt-browser TOFU pin store.
- Locations: `localbolt-v3/packages/localbolt-browser/src/services/webrtc/pin-verify.ts:24-38`; `HandshakeManager.ts:178-182,244-252`; `pin-store.ts:150-167`; `WebRTCService.ts:240` (remotePeerCode = signal.from); `peer-connection.ts:721-728` (peer code regenerated per session); `PROTOCOL.md:102` (spec mandates keying on identity key).
- Exploit scenario: PROTOCOL.md requires pinning by the 32-byte identity key; the implementation keys on the peer code, a random token regenerated every session and delivered by the untrusted rendezvous. Because the key changes each session while the identity persists, `verified` never persists, every legitimate reconnect looks like first contact, and KEY_MISMATCH only fires on a same-code/different-identity coincidence. An attacker presenting a fresh identity under a fresh code yields the identical unverified prompt a real reconnect yields, so the continuity signal is meaningless and the resulting alarm fatigue erodes the SAS check.
- Recommended fix: Key the pin store on the remote identity public key (raw 32 bytes) per spec, storing the peer code and friendly name only as non-authoritative metadata. This restores continuity, makes KEY_MISMATCH reachable for a reused identity with a changed key, and lets `verified` persist.
- Status: Confirmed, severity contested (High: defeats a documented control and induces fatigue; Medium dissent: SAS still functions and harm is fatigue-mediated).

#### H6. Rendezvous connection-slot exhaustion: trivial single-host DoS of the public discovery service
- Component: bolt-rendezvous.
- Locations: `bolt-rendezvous/src/server.rs:191` (peek, no timeout), `:331-416` (registration loop, no timeout); `lib.rs:157` (slot acquired before handler), `:38` (DEFAULT_MAX_WS_CONNECTIONS=256), `:166-168` (TCP RST when full).
- Exploit scenario: One unprivileged host opens 256 bare TCP connections and sends zero bytes. Each acquires a global slot then blocks forever at the un-timed peek; no idle timeout applies before registration. The 256-slot pool is consumed by one attacker and every legitimate client is rejected with a RST, killing discovery for the whole deployment. No handshake, TLS, registration, or bandwidth is needed, and with no per-IP cap, raising the global limit does not help.
- Recommended fix: Wrap peek and the registration next() in a short bounded deadline (5-10s), releasing the slot on expiry. Add a per-IP concurrent-connection cap so one source cannot consume the whole pool.
- Status: Confirmed, severity contested (High for the internet-facing Fly.io deployment; Medium for LAN-only self-hosted/bundled instances).

### MEDIUM

#### M1. Receive-side unbounded memory accumulation (declared-size-only guard) enables daemon OOM
- Component: bolt-daemon run_read_loop.
- Locations: `bolt-daemon/src/session_loop.rs:1532-1540` (guard checks declared file_size only), `:1575` (rx.chunks.insert, no chunk_index or byte bound), `:1611-1614` (completion only at len>=total_chunks; Vec::with_capacity(file_size) amplification); `ws_validation.rs:27` (MAX_TRANSFER_SIZE=2.5GB, strict `>`).
- Exploit scenario: A peer that reached the loop (via the allow policy, the legacy branch, or a paired session) sends chunks sharing one transfer_id with file_size=1000 (passes the check), total_chunks=u32::MAX, and distinct chunk_index values. Completion never triggers, nothing is freed, and memory grows until OOM. A single-message variant (file_size=2.5GB, total_chunks=1) forces an immediate large Vec::with_capacity. No user interaction is required.
- Recommended fix: Enforce MAX_TRANSFER_SIZE against the running sum of buffered bytes and abort on exceed; reject chunk_index >= total_chunks; cap total_chunks and concurrent active_receives; do not pre-allocate the declared size; set an explicit tungstenite max_message_size; ideally stream to a temp file.
- Status: Confirmed (merged 2 findings; availability-only, LAN-scoped, restartable).

#### M2. Daemon data-dir (identity key + TOFU store) in predictable, world-writable `/tmp` per-PID path
- Component: localbolt-app native bridge + bolt-daemon identity_store.
- Locations: `localbolt-app/native/shared/src/daemon.rs:72-73` (/tmp/bolt-native-{pid}), `:77-82` (discarded create_dir_all/set_permissions results); `bolt-daemon/src/identity_store.rs:141-153` (mode-only, symlink-following dir check), `:172-183` (mode-only file check), `:269-271` (fs::write then chmod window); `main.rs:432-448,417-420`; secure alternative at `bolt-app-core/src/platform.rs:36-70`.
- Exploit scenario: Confirmed impact: the path is per-PID and removed on exit, so the daemon presents a NEW identity every launch and both pin databases start empty; persistent TOFU pins, pin-skip, and the M7 identity-mismatch alarm are inert in production, and every reconnect looks like first contact (verification fatigue). Contested facet: a local attacker can pre-plant the predictable directory; ownership-blind validation, symlink-following, and the world-readable temp-file window enable a local DoS and, per one skeptic, key substitution/exfiltration (the other showed cross-uid mode checks block the strong key-theft path).
- Recommended fix: Use default_data_dir() (per-user, 0700) for the identity key and trust store; keep only ephemeral session scratch per-PID. Harden identity_store: reject symlinked parents, verify st_uid == geteuid(), create the key with O_EXCL at 0600, and stop discarding create/chmod results.
- Status: Confirmed (merged 2 findings; identity-rotation impact unanimous Medium, local key-substitution facet contested Low/High).

#### M3. Interior-NUL peer metadata aborts the native app via `CString::new().unwrap()` (zero-interaction remote DoS)
- Component: localbolt-app native bridge (signaling FFI + crate panic safety).
- Locations: `localbolt-app/native/shared/src/signaling.rs:214-216`; `bolt-app-core/src/signaling_client.rs:62-65,388-395` (unsanitized peer strings); `BoltBridge.swift:410-427` (500ms poll); `lib.rs:13` (documented no-panic invariant), 16 lock().unwrap() sites, zero catch_unwind.
- Exploit scenario: A malicious rendezvous (#2), or a LAN peer whose device_name is relayed (device_name is length-checked but not control-char-filtered), injects a peer entry with a NUL in device_name. The 500ms poll calls bolt_signaling_get_peer, CString::new().unwrap() panics, the unwind crosses the extern C boundary, and the app aborts. Re-injection sustains a crash loop with no user interaction.
- Recommended fix: Never unwrap CString::new on external data at an FFI boundary; map failures to null or strip NULs (mirror the existing wt_url handling). As defense-in-depth, wrap every extern C body in catch_unwind returning the error sentinel, and reject NUL/control chars in the signaling client.
- Status: Confirmed (merged the concrete panic with the systemic FFI panic-safety note; availability-only).

#### M4. Bundled QUIC/WebTransport stack ships quinn-proto 0.11.14 (RUSTSEC-2026-0185)
- Component: bolt-daemon transport dependency.
- Locations: `bolt-daemon/Cargo.lock:978`; `bolt-daemon/Cargo.toml:58,61`; `bolt-daemon/src/wt_endpoint.rs:116-125` (WT ServerConfig, no client-cert auth).
- Exploit scenario: quinn-proto <0.11.15 has an unbounded out-of-order stream reassembly buffer. The WT listener requires no client certificate, so any host that completes the QUIC/TLS handshake (LAN peer, malicious rendezvous, or local process) can send STREAM frames with large offset gaps it never fills, before any Bolt/NaCl/SAS auth. The buffer grows unbounded and the daemon is OOM-killed. The path is shipped (macOS native-full, Steam Deck transport-webtransport).
- Recommended fix: cargo update -p quinn-proto to >=0.11.15 and re-commit Cargo.lock. Additionally cap per-connection/stream receive windows and max concurrent streams via quinn TransportConfig, and rate-limit inbound accepts.
- Status: Confirmed (availability-only, E2E crypto unaffected).

#### M5. Vendored signal-server subtrees are 8 security releases stale
- Component: localbolt + localbolt-app vendored signal/ subtree.
- Locations: `localbolt/signal/src/lib.rs:71` (unbounded accept), `server.rs:177-185` (leftmost X-Forwarded-For trusted), `server.rs:248` (registration no timeout); `localbolt-app/signal/src/*` (same code, no pin/guard); `localbolt/scripts/verify_signal_subtree.sh:8` (guard blind to staleness); upstream fixes at `bolt-rendezvous/src/lib.rs:38,108-170` and `server.rs:212-218,274-281`.
- Exploit scenario: Both vendored copies are pinned to rendezvous-v0.2.6 and predate the connection cap (AC-22), MAX_ROOMS/MAX_PEERS_PER_ROOM, IDLE_TIMEOUT, DP-5 session guard, and trusted-proxy XFF gating. An unauthenticated client opens unbounded connections and registers unbounded peers into one IP-keyed room to exhaust FDs/memory, and can spoof X-Forwarded-For to enter a stranger's or the shared room. The CI drift guard reports PASS because it hashes only against the stale pin.
- Recommended fix: git subtree pull both copies to >= rendezvous-v0.2.14. Add a pin + verify guard to localbolt-app, and add a staleness check that fails/warns when the pin is N releases behind canonical.
- Status: Confirmed (merged 3 findings; peak impact is the connection-exhaustion DoS).

#### M6. Rendezvous unbounded per-peer relay channel enables server memory-exhaustion against a slow reader
- Component: bolt-rendezvous relay path.
- Locations: `bolt-rendezvous/src/server.rs:308` (unbounded_channel), `:509-525` (Signal relay), `:311-324` (write_task); `room.rs:16` (UnboundedSender); MAX_MESSAGE_BYTES=1MiB (server.rs:43), RATE_LIMIT_PER_SECOND=50 (server.rs:52).
- Exploit scenario: An attacker registers a slow reader (WS handshake completed, never reads its socket, stalling its write_task) and a sender, then relays ~1 MiB Signal messages at 50/s. The undrained unbounded queue accumulates ~50 MiB/s; a 256-512 MB host OOMs in 5-10s. One attacker (even self-signaling on a single connection) suffices.
- Recommended fix: Use a bounded channel with drop/close on overflow, or a per-peer total-queued-bytes cap. Apply a much smaller size limit to signal payloads than the 1 MiB frame cap.
- Status: Confirmed (availability-only, public discovery service).

#### M7. Browser direct WT/WS transports perform no TOFU pinning; cert-hash pin is rendezvous-supplied
- Component: localbolt-browser ws-transport.
- Locations: `WsDataTransport.ts:233,127-131` (no pinStore); `WtDataTransport.ts:240-244,287-297` (serverCertificateHashes from signal); `HandshakeManager.ts:176` (TOFU gated on pinStore); `peer-connection.ts:276,310` (certHash from signal.data).
- Exploit scenario: The direct browser<->desktop transports reuse HandshakeManager but are never given a pinStore, so TOFU is dead code, KeyMismatchError never fires, and markPeerVerified is non-persistent. The WT cert-hash pin arrives through the untrusted rendezvous, so a malicious rendezvous routes the browser to its own MITM server and supplies a matching hash. With no identity-continuity backstop, the only remaining defense is the 24-bit SAS (H1).
- Recommended fix: Thread the same IndexedDBPinStore into the WsDataTransport/WtDataTransport HandshakeContext, make markPeerVerified persist, and treat the rendezvous-supplied certHash strictly as defense-in-depth behind verified identity pinning.
- Status: Confirmed (defense-authentication gap; compounds H1 for a full silent MITM).

#### M8. Transfer-authorization gate (unverified -> blocked) is UI-visibility-only on the sender and absent on the receive path
- Component: localbolt-browser transfer gating.
- Locations: `TransferManager.ts:698,742` (onReceiveFile regardless of state); `transfer-policy.ts:5-20`; `sections/transfer.ts:44-47` (only enforcement hides the upload widget); `WebRTCService.ts:708-725`; `peer-connection.ts:211-220` (auto-download).
- Exploit scenario: The policy says unverified transfers are blocked, but the only enforcement hides the sender's upload widget. There is no gate in sendFile/TransferManager and none on the receive path. A malicious sender (#4) who completed the connection-approval handshake uses a modified client that ignores the hidden widget; the victim decrypts, reassembles, and auto-downloads the file with no per-file prompt and no verification.
- Recommended fix: Enforce isTransferAllowed at the protocol layer on both sides (reject inbound file-offer/file-chunk when state is unverified), gate sendFile rather than element.hidden, and consider a per-file receive prompt.
- Status: Confirmed (bypass requires the victim to first accept the connection; LAN-scoped; payload staged not executed).

### LOW

#### L1. Reachable panic in `parse_transfer_id_bytes`: non-ASCII 32-byte transferId slices inside a UTF-8 char boundary
- Component: bolt-daemon ws_validation (BTR transfer-id parsing).
- Locations: `bolt-daemon/src/ws_validation.rs:110-120` (guards byte length only, slices at `:116`); reached via `ws_btr.rs:107,131`; transfer_id is a serde String at `dc_messages.rs:59-75`.
- Exploit scenario: An authenticated peer sends one BTR-tagged file-chunk whose inner transferId is a 32-byte string containing a multibyte char at an even offset (e.g. `"a"+é+29×"a"`). The str-range slice panics. Under the shipped build (panic=unwind, per-connection tokio task), the unwind terminates only the attacker's own session, so this is a self-DoS. If the daemon is ever built panic=abort, the same single frame crashes the whole process.
- Recommended fix: Validate ASCII-hex before slicing (or slice `as_bytes()`), add an adversarial unit test with a non-ASCII 32-byte input, and keep panic=unwind explicit.
- Status: Confirmed (merged 2 findings).

#### L2. Capability/BTR negotiation has no mandatory-capability floor and the spec'd BTR anti-downgrade control is dead code
- Component: bolt-core session + bolt-btr negotiate.
- Locations: `bolt-core-sdk/rust/bolt-core/src/session.rs:185-191` (pure intersection, no floor); `bolt-btr/src/negotiate.rs:34-50` (BtrMode/Reject with zero live callers); daemon decides BTR with a bare `has_capability` at `session_loop.rs:1286`, `ws_btr.rs:225,242`; envelope path fails closed (envelope.rs:236,271,316-327) which bounds impact.
- Exploit scenario: A malicious counterparty omits `bolt.transfer-ratchet-v1` from its HELLO; the intersection drops it and the send/receive paths silently fall back to per-chunk static NaCl box with no Reject, no log token, no disconnect, and no user-enforceable require-BTR policy. Impact is a forward-secrecy-granularity reduction on an otherwise-encrypted channel (the envelope capability itself fails closed, so no plaintext exposure).
- Recommended fix: Add a required/floor concept to negotiate_capabilities so a session aborts when a mandated capability is missing; either wire the daemon's BTR gating through negotiate_btr so the Reject path is reachable, or delete the dead control; add a fail-closed require-BTR option.
- Status: Confirmed (merged 2 findings).

#### L3. IPC read paths allow unbounded / post-hoc-bounded allocation from a hostile local endpoint
- Component: bolt-app-core / bolt-ui IPC clients + bolt-daemon IPC server.
- Locations: client readers with no bound at `bolt-app-core/src/ipc_bridge_core.rs:157` (and 92,115), `ipc_client.rs:89,121`, `bolt-ui/src/ipc.rs:60,86`; daemon `bolt-daemon/src/ipc/server.rs:50-65` (read_until then post-hoc size check).
- Exploit scenario: A hostile or spoofed local endpoint streams bytes with no newline. The client readers (std read_line) grow a String without limit until OOM; the daemon's read_line_bounded calls read_until first and checks the 1 MiB cap only afterward, so the cap does not bound allocation. Reachable only across the local IPC surface (same-user, or a socket-squat per the local threat model).
- Recommended fix: Share one bounded reader (`reader.take(MAX_LINE_BYTES+1).read_until(...)`) on every client and server read path and treat oversize as a protocol violation.
- Status: Confirmed (merged 2 findings; defense-in-depth against an actor the model already treats as high-privilege).

#### L4. Single-client IPC server wedges permanently on an idle connected client
- Component: bolt-daemon IPC server.
- Locations: `bolt-daemon/src/ipc/server.rs:462-464` (post-handshake read has no timeout), `:265` (handle_client blocks the accept loop), `:516` (writer is_finished never fires); docs promise "new client kicks old client" (mod.rs:5, server.rs:4).
- Exploit scenario: A same-user process (or a hung, not crashed, real UI) completes the version handshake and then never sends or closes. The reader blocks forever, accept() is never called again, and because pairing approval requires a live UI, every incoming pairing/transfer request is denied for the daemon's lifetime. Fails closed (availability only), but the documented no-dead-UI-blocking guarantee is not met.
- Recommended fix: Implement the documented kick (run accept concurrently and signal the current handler to terminate on a new connection), or apply an idle/keepalive deadline to the post-handshake reader.
- Status: Confirmed.

#### L5. Shared-public-IP (CGNAT) room collision leaks presence, internal LAN WT URL, and cert hash to strangers on the hosted service
- Component: bolt-rendezvous room broadcast.
- Locations: `bolt-rendezvous/src/room.rs:148-155` (PeerJoined broadcast), `server.rs:297-301` (public IP used verbatim as room key); PeerData carries device_name, peer_code, wt_url (internal LAN IP:port), wt_cert_hash.
- Exploit scenario: On the hosted deployment, unrelated users behind one carrier/corporate NAT share a room. On join, add_peer broadcasts the newcomer's full PeerData (native peers include the macOS computer name and an internal LAN wt_url) to every stranger in that room, with no pairing or consent gate. Reconnaissance-only (the RFC1918 wt_url is not routable by a stranger, and the WT endpoint is still cert-pinned + NaCl + SAS), so no data or crypto break, but a real presence/topology leak.
- Recommended fix: Treat non-RFC1918 shared IPs as untrusted for auto-discovery: do not broadcast wt_url/wt_cert_hash to peers that merely share a public IP, gate presence behind pairing on the public deployment, and minimize device_name exposure to unpaired peers.
- Status: Confirmed.

#### L6. Vite dev-server wasm middleware path traversal (dev-only)
- Component: localbolt-web build/dev server.
- Locations: `localbolt-v3/packages/localbolt-web/vite.config.ts:16-45`, `:30` (path.join on raw url), `:49` (host `::`).
- Exploit scenario: The dev middleware serves any `.wasm`-suffixed request by joining the raw URL onto the workspace root with no containment check, and the dev server binds all interfaces. A same-LAN attacker using a non-normalizing HTTP client requests `/../../..<path>.wasm` and reads any `.wasm`-suffixed file from the developer's machine. Not present in the Netlify production artifact.
- Recommended fix: Resolve the candidate path and verify it stays within the workspace root before streaming, and/or bind the dev server to 127.0.0.1.
- Status: Confirmed (dev-only, extension-limited).

#### L7. `start.sh` self-hosts via the Vite dev server on `0.0.0.0` instead of a static build
- Component: localbolt self-host web serving.
- Locations: `localbolt/start.sh:98` (`vite --host --port 8080`), `start.bat:60`; unused `build`/`preview` scripts in `web/package.json:9-10`.
- Exploit scenario: The launcher runs the Vite dev server (module graph, /@fs routes, HMR WebSocket) bound to all interfaces as the serving layer for a LAN file-sharing appliance. No current CVE against the installed Vite, but the dev-server surface is unnecessary exposure and inherits any future server.fs bypass class.
- Recommended fix: `vite build` and serve `dist/` with a minimal static server (at least `vite preview`); bind to the intended interface.
- Status: Confirmed (hardening).

### INFO

#### I1. ReplayGuard `seen` set grows unbounded for the session and is redundant with the ORDER-BTR monotonic check
- Component: bolt-btr replay.rs.
- Locations: `bolt-core-sdk/rust/bolt-btr/src/replay.rs:17,53-100,104-106`.
- Note: `seen` accumulates a triple per accepted chunk and is cleared only on disconnect, but the preceding ORDER-BTR check plus strictly-monotonic generation make the triple globally unique, so seen.insert can never return false. It is redundant, unbounded dead weight dominated by the full-file receive buffer in the same loop. Drop it or prune on end_transfer.
- Status: Confirmed (info; code-hygiene).

#### I2. `start.sh` rustup installer "checksum verification" is never compared, and the toolchain is unpinned
- Component: localbolt self-host setup script.
- Locations: `localbolt/start.sh:16-33` (downloads, prints a SHA-256 that is never compared, then executes), `:14` (unpinned brew install).
- Note: The printed hash implies a verification that does not happen (security theater), but the effective posture equals the official rustup TLS bootstrap (curl flags preserve `--proto '=https' --tlsv1.2`, download-then-exec avoids truncation), so no real control was removed. Delete the misleading comment or actually pin and compare a hash, and pin the toolchain via rust-toolchain.toml.
- Status: Confirmed (info; code-honesty/hardening).

---

## Needs Human Review (Disputed)

These items are real code observations whose exploitability or severity split the verifiers. They are not counted in the confirmed tally. Nine items (consolidating ten source adjudications).

1. Transient secret copies not zeroized (X25519 keygen buffer + HKDF PRK). `crypto.rs:48-56`, `key_schedule.rs:26,49,67`, `ratchet.rs:74`. Real best-effort-zeroization gaps in the RustCrypto stack, but unreachable in the threat model (needs a separate memory-disclosure primitive: core dump, swap, cold-boot). Info. Worth a Zeroizing wrapper where cheap.
2. bolt-ui identity key + TOFU store in `/tmp/bolt-ui-{pid}`. `bolt-ui/src/app.rs:106`. Contested Medium vs not-real: the mechanics are real, but one verifier holds bolt-ui is retired (ADR-001) and the key is per-session (never durably pinned). Resolve by confirming what actually ships.
3. SAS is OPTIONAL (SHOULD) on first contact; the daemon auto-pairs by device name with an empty SAS. `PROTOCOL.md:90`, `trust.rs:244-315,371-378`. Contested Medium vs not-real: real that SAS is skippable (classic TOFU first-use gap), disputed whether it "falsifies" the deliberately-hedged "probabilistically detectable" spec claim. Consider making first-contact SAS mandatory in the UI flow; complements H1.
4. TOCTOU between `UnixListener::bind` and chmod 0600. `bolt-daemon/src/ipc/transport.rs:75-82`. Real non-atomic permissioning, but unreachable under the default umask 022 (socket is 0755, not connectable). Low hardening: set umask(0o077) before bind or bind under a 0700 directory.
5. CSP `frame-ancestors` inert in a `<meta>` tag. `localbolt-v3/packages/localbolt-web/index.html:7`. Spec-accurate but unreachable: X-Frame-Options: DENY already blocks framing. Info: emit the CSP as an HTTP header so frame-ancestors is enforced, or drop the inert directive.
6. Code signing omits `--options runtime`. `build-app.sh:136`, `RELEASE.md:67-70`. The security-injection framing was refuted (same-uid gains nothing; the app is unsandboxed already), but the documented notarization flow cannot succeed without the hardened runtime. Low: add `--options runtime` and `--timestamp` so notarization passes and Library Validation applies as defense-in-depth.
7. Over-provisioned entitlements: sandbox disabled while sandbox-only file keys remain, and the UI carries `network.server`. `LocalBolt.entitlements:5`. Real least-privilege hygiene, unreachable (all keys inert with the sandbox off). Info: split per-binary entitlements; remove inert keys.
8. No automated dependency monitoring (dependabot/cargo-audit) on the core Rust repos. `bolt-daemon/Cargo.toml:1`. Real process gap, not a vuln itself; lengthens time-to-notice. Info: add cargo-audit/cargo-deny to core CI and extend dependabot to the Rust core.
9. npm audit findings are dev/build tooling only. `localbolt-v3/package.json:1`. Assurance item: verified that vite/vitest/esbuild/ws/undici et al. are devDependencies not present in any shipped bundle, so no end-user runtime exposure. Info: `npm audit fix` for developer-workstation hygiene.

---

## What Was Checked And Found Solid

- Crypto primitives (bolt-core-sdk): fresh OsRng/CSPRNG nonces per NaCl box and per BTR envelope plus single-use message keys (no nonce/keystream reuse), OsRng/getrandom on native and wasm with no seeded/mock RNG, domain-separated HKDF-SHA256 with correct salts, constant-time Poly1305 tags, fail-closed length guards before slicing, KeyPair/chain/message-key zeroization, no weak/hardcoded production keys. High confidence.
- Ratchet & forward secrecy: per-chunk keys bind transfer_id/generation/chain_index, reorder/replay/cross-context injection fail closed, symmetric-chain forward secrecy with zeroization, ReplayGuard rejects wrong generation/transfer/index, test-only ratchet bypass feature-gated out of production. High confidence.
- Identity/SAS construction: binds the actual session keys at correct offsets, unbiased CSPRNG peer codes, X25519-only identity (no key confusion), zeroize-on-drop. The 24-bit length is the gap, not the construction.
- Session state machine: sealed-box HELLO confidentiality/integrity for non-legacy sessions, downgrade-attempt rejection, bounded capability arrays, envelope encode/decode with no plaintext fallback, exhaustively-tested transition tables.
- Untrusted message parsing (daemon): Result-based fail-closed parsers with bounded JSON recursion, length-prefix caps before allocation on QUIC/WT/WS, filename sanitization plus Downloads containment, per-connection tokio task isolation.
- Transport auth: real SHA-256 cert-hash pinning with signature verification delegated to rustls/ring (no accept-all verifier), mutual pinning fail-closed with adversarial tests, ephemeral short-lived WT certs, bounded frames.
- IPC trust boundary: 1 MiB ingress cap with disconnect, fail-closed pairing on every non-approval path, mandatory version handshake, atomic 0600 trust-store writes with re-validation, sound two-stage TOFU, constant-time public-key compare, Windows DACL/remote-client rejection, no keys or plaintext over IPC.
- Key material at rest: CSPRNG keygen, no-Clone + zeroize-on-drop, no secret in logs, exact 0600 enforcement with fail-closed corrupt-key handling, atomic key write, secure per-user data dir already implemented.
- Rendezvous isolation: normal-signal cross-room relay blocked and regression-tested, DP-5 reconnect race guarded, 1 MiB caps at protocol and app layers, strict peer-code/target validation, room/peer table bounds, RAII connection accounting, fail-closed rate limiter, genuine content-blindness.
- Browser crypto & parity: CSPRNG only, fresh 192-bit random nonce per message, validated fail-closed base64, no plaintext reachable via envelope/transport downgrade, TOFU fail-closed on the WebRTC path, SAS construction parity, no secret-dependent timing branches, clean crypto deps.
- Web XSS/DOM/CSP: consistent escapeHTML at every untrusted sink, whitelist-validated device types, safe download/blob handling, no service worker, no postMessage/open-redirect sinks, tight CSP (no unsafe-inline/eval), strong headers (XFO DENY, nosniff, HSTS preload, COOP), no committed secrets.
- Signaling/WebRTC: LAN-only ICE (no STUN/TURN, host-only candidates, same-network re-check), fail-closed HELLO timeout, anti-downgrade enforcement, thorough stale-callback/reentrancy hardening.
- Native FFI: consistent C-string ownership/free, bounds-checked peer access, null/non-UTF8-safe inbound handling, validated QUIC cert-hash input, Mutex/Atomic-guarded state, bounded queues, UAF-safe stop ordering, test-only parity code not shipped.
- Native distribution: retired Tauri code not built/shipped, statically-linked FFI bridge (no dylib hijack), no-shell daemon spawn, received-file traversal defense, 0600/0700 key-permission fail-close, SHA-pinned CI actions + CodeQL.
- Self-host/Docker: non-root containers with --locked builds, per-connection rate limiting, strong input caps, no hardcoded secrets, overridable bind config, start.bat does not auto-exec remote code.
- Supply chain: E2E crypto crate stack cargo-audit clean, no wildcard versions, git dep pinned to a commit hash, trivial build.rs scripts, no Actions script-injection or unsafe secret handling, rustls-webpki and quick-xml advisory paths unreachable.
- Protocol design: nonce hygiene, identity keys never in cleartext and never used for bulk encryption, MAC-before-processing, per-chunk replay dedup, TOFU key-change handling, BTR domain separation and memory-only lifecycle, canonical error taxonomy.

---

## Coverage Gaps And Recommended Follow-up

1. Static review only. No fuzzing, no dynamic testing, and no live exploit PoCs beyond the reviewers' standalone reproductions of the transferId panic and the SAS math. Fuzz the envelope/dc_message/HELLO parsers and the BTR chunk path, and build a real two-leg MITM + SAS-grinding PoC against a live pairing.
2. Dependency advisories are a point-in-time snapshot from committed lockfiles; the exact RUSTSEC/npm IDs were not re-fetched live and sit near/after the knowledge cutoff. Run fresh cargo-audit and npm-audit in CI; the absence of automated monitoring on the core repos means this set will drift.
3. The commitment-less 24-bit SAS is the headline crypto-design gap and requires a protocol change. Get external cryptographer sign-off on the v2 commit-reveal + longer SAS + transcript binding before re-asserting MITM resistance.
4. Trust enforcement is a per-caller responsibility (WT omits it, legacy skips it, the shared loop performs no check). Audit every transport entry point against a single mandatory gate and consider making run_session_with_outbound require a proof-of-trust argument.
5. Product-inventory ambiguity (bolt-ui/egui and Tauri retired vs shippable) created contested findings. A definitive shipping inventory would close or escalate several disputed items.
6. No end-to-end review of auto-update, notarization/Gatekeeper acceptance, or the full code-signing chain beyond the hardened-runtime flag. Run a dedicated release-integrity pass.
7. Rendezvous availability was flagged but not load-tested against the live Fly.io service and its proxy.
8. Same-user local access is treated as accepted compromise; if the product targets shared/multi-user hosts, the local IPC, socket-TOCTOU, and /tmp findings escalate.
9. No full git-history secret scan (only the current tree was checked). Cheap insurance across this many repos.
10. Any iOS/mobile or additional-OS variants, and the Windows named-pipe path beyond the DACL/FIRST_PIPE_INSTANCE notes, were not deeply exercised.

---

## Security Strengths

- Cryptographic primitive hygiene is strong and consistent across Rust, WASM, and TypeScript: fresh CSPRNG nonces, XSalsa20-Poly1305 with constant-time tags, domain-separated HKDF-SHA256, per-chunk single-use keys, no weak/hardcoded keys, fail-closed length checks before every slice.
- The BTR forward-secrecy design is genuinely good: per-transfer DH ratchet plus one-way symmetric chain, memory-only keys with explicit zeroization at defined cleanup points, and no session resume.
- Parsing is fail-closed throughout the daemon: typed HELLO parsing rejects downgrade/oversize/bad-version, envelope encode/decode has no plaintext fallback, received filenames are sanitized and contained to Downloads, and length prefixes are bounded before allocation.
- Transport authentication is real: cert-hash pinning delegates the actual TLS signature check to rustls/ring (no accept-all verifier ships), WT certs are ephemeral, and mutual pinning verifiers fail closed with adversarial tests in the tree.
- Trust-store integrity is well engineered: atomic write + fsync + 0600 re-validation, constant-time identity compare, TOFU never overwrites an existing pin, pairing fails closed on every non-approval path.
- The rendezvous is genuinely zero-knowledge of content: only opaque signaling metadata transits, room isolation on the normal path is enforced and regression-tested, and connection accounting is sound RAII.
- The web app has a clean XSS/DOM posture: consistent output escaping, no service worker, no cross-origin postMessage or open-redirect sinks, a tight CSP, and strong response headers.
- Memory-safety discipline is high: no unsafe in scope, panic=unwind + per-connection task isolation contains panics, and secret KeyPair has no Clone and zeroizes on Drop.
- The team runs a real security-engineering process: PROTOCOL.md, ARCHITECTURE.md, and AUDIT_TRACKER track many of these exact issues, several findings map to acknowledged v2 items, CI uses SHA-pinned Actions plus CodeQL, and Docker images are non-root with --locked builds and no embedded secrets. That self-awareness makes remediation tractable.