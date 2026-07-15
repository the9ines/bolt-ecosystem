# LocalBolt Trust-Gate Spine (EA2+EA3+EA4): Consolidated Red-Team Review

**Verdict: HAS-BLOCKERS.** The design's reading of the *current* code is accurate (I re-verified every load-bearing fact in-tree), but the *proposed* spine cannot be built as written and, even if built, would be net-negative on security until two upstream problems are fixed. Five blocker-class issues stand: two are deep security-model defects (unauthenticated identity, grindable SAS), two are constructive prerequisites (the approval handle will not compile; the approval wait starves the reactor), and one is a live ungated transport (WebTransport) that fix #5 cannot actually close.

Seven red-teamers produced 34 raw findings. Deduplicated below to 18, ranked by true severity.

## Blockers (resolve before writing code)

| ID | Sev | Consolidated flaw | Merges |
|----|-----|-------------------|--------|
| **F1** | BLOCKER | **Identity is never authenticated.** The HELLO `identityPublicKey` is a plaintext field sealed only with the ephemeral session key (`web_hello.rs:111-134`); the identity secret key is never signed/sealed/opened, and identity keys are X25519 (`identity.rs`) which cannot sign. Anyone who knows a victim's *public* identity key (shown in the very prompt this design adds; emitted in cleartext over IPC at `session_loop.rs:604`) can present it, and on the pinned path get Allow with no prompt and no SAS. Pinning makes the victim strictly *less* safe. | pinned-fast-path-spoofable; "pin is authenticated" premise |
| **F2** | BLOCKER | **EA1 before EA4.** The SAS is a 24-bit plain-SHA256 code with no commitment (`sas.rs:56-77`), offline-grindable (~2^24) so an active MITM at the untrusted rendezvous forces both peers to see a matching "verified" code inside the 30s window. The design then launders that into a permanent, prompt-skipping "verified" pin. Confirmed by the project's own tracker: EA1 is OPEN (`AUDIT_TRACKER.md:649`), EA-D2 flags the persistence. | grindable-SAS; grinded-pin-persistence |
| **F3** | BLOCKER | **Approval handle will not compile.** `IpcServer` owns `decision_rx: std::sync::mpsc::Receiver` (`server.rs:156`), which is !Sync, so `Arc<IpcServer>` is !Send and cannot cross `tokio::spawn` at `session_loop.rs:922`, `main.rs:572`, `wt_endpoint.rs:142`. The "or a trait object" hedge does not escape it. | 4 duplicate compile-blocker findings |
| **F4** | BLOCKER | **Blocking `await_decision` starves the reactor.** It is a synchronous `thread::sleep(50ms)` poll to 30s (`server.rs:208-239`) called inline from async handlers, not `spawn_blocking`. N >= num_cpus unauthenticated inbounds park every worker for 30s; on a 1-vCPU VPS a single inbound freezes the daemon. Renewable, no auth. Also bypasses the `is_ui_connected()` no-UI fast-path, so headless still blocks 30s. | 4 duplicate DoS findings |
| **F5** | BLOCKER | **WebTransport is a live, ungated 0.0.0.0 inbound transport and fix #5 cannot gate it.** `WtEndpointConfig` has no trust field (`wt_endpoint.rs:43-52`), `run_wt_endpoint` is never passed a `SessionTrustConfig`, and the handler calls no gate today. Fix #1 threads only the IpcServer capability, not the config the gate needs. A literal implementation no-ops via `None => Ok`. | ungated-WT; inert-WT-gate; unsound-gate-propagation |

## High

| ID | Sev | Consolidated flaw |
|----|-----|-------------------|
| **F6** | HIGH | **Single-consumer `decision_rx` mis-routes concurrent prompts.** It discards any decision whose `request_id` does not match the caller. Two overlapping prompts: the wrong waiter dequeues and drops the real approval, the approved peer times out and is denied. Griefable by opening a decoy session. A naive `Arc<Mutex<Receiver>>` "fix" converts this to 30s head-of-line blocking of *all* pairing. |
| **F7** | HIGH | **SAS is never enforced in the daemon.** `compute_sas` is only logged/emitted; `enforce_session_trust` takes no SAS input and at every call site the SAS is not computed until *after* the gate. The only approval helper builds an empty identity + empty sas payload. Even if shown, on-screen SAS authenticates nothing without forced out-of-band comparison. (Meaningful only post-F2.) |
| **F8** | HIGH | **Offerer/initiator path has no gate and no pin.** `Offerer => stage_a=None => Allow` on first contact with any identity (`trust.rs:307-313`); the `connect_remote` signal is populated from untrusted signaling; QUIC cert-pin authenticates a transport cert, not the bolt identity. A MITM on the outbound dial is auto-trusted with zero UI. Design changes 1-6 do not touch this, and it is the common send-initiator UX. |
| **F9** | HIGH | **EA2 legacy removal is asymmetric.** The offerer honors a `legacy:true` HELLO *response* (`session_loop.rs:530-547`): sets identity `[0u8;32]`, empty SAS, no gate, enters the loop. A MITM drops QUIC to force the WS fallback then answers legacy. Fix #4 is answerer-centric. Reject legacy by deletion on BOTH branches, block the QUIC->WS legacy landing, and remove `VerificationState::Legacy` from `is_transfer_allowed`. |
| **F10** | HIGH | **Removing `legacy` from `is_transfer_allowed` closes nothing on the daemon.** That function has zero daemon callers (browser-only); the receive path writes files with no verification check. `enforce_session_trust` at HELLO is the sole daemon gate. Listing this edit as a daemon closure is false assurance. |
| **F11** | HIGH | **The shipped UI can only emit `allow_once`/`deny_once`** (`BoltBridge.swift:758`), so change #2's `AllowAlways -> pin` branch is dead: no TOFU pin is ever created, the answerer re-prompts every reconnect (approval fatigue), the offerer stays pinless. |
| **F12** | HIGH | **No connection/concurrency/rate/per-IP cap on any accept path.** All three loops spawn a handler per accept; channels are unbounded; a fresh random identity per HELLO makes every session a new prompt (coalescing cannot help). One host opens thousands of connections, each a modal sheet held 30s. The real prompt is buried; FDs/tasks/memory pile up. |

## Medium / Low

| ID | Sev | Consolidated flaw |
|----|-----|-------------------|
| **F13** | MED | `enforce_session_trust` fails OPEN on `trust_config=None` (`session_loop.rs:102-104`); "identity-configured" must not be conflated with `trust_config.is_some()` (the daemon *always* has an identity). Invert to fail-closed in native mode; assert every enabled transport got `Some`. |
| **F14** | MED | The "single mandatory gate" is a per-call-site convention, not a chokepoint. `run_session_with_outbound` (the shared transfer entry) is ungated; the WS legacy path reaches it ungated today. Move enforcement into that function. Sequence after F3. |
| **F15** | MED | Pin poisoning / persistent DoS with no in-band recovery: `set()` never overwrites (`trust.rs:206-214`) and a pinned identity is never re-prompted, so a planted DenyAlways (or an un-overridable AllowAlways) needs manual `trust.json` editing. Fixing F1 removes plant-for-others; add an authenticated revoke/re-pair path. |
| **F16** | MED | Accept is unconditionally enabled: SAS comparison is optional (consent theater). Post-EA1, gate Accept behind an affirmative SAS-match. Pre-EA1, remove the verification framing. |
| **F17** | MED | The 30s `DECISION_TIMEOUT` multiplies with the missing caps and a single human-serialized UI. Shorten unattended holds, release slots on deny/abort, cap outstanding prompts. Bundle with F12. |
| **F18** | LOW | `TrustStore::load` returns an empty store on corrupt/unreadable file, silently forgetting DenyAlways pins (fail-open for deny), worsened by the `/tmp` data_dir. Distinguish absent vs corrupt; fail closed on corrupt; land EA8. |

## Why HAS-BLOCKERS and not NEEDS-REVISION

Two independent classes force it. First, **you cannot write the spine**: the approval handle does not compile (F3) and the approval wait is a reactor-starving DoS primitive (F4), so the decision channel must be redesigned before any of changes #1/#2/#3/#5 exist as code. Second, **even a correct wiring authenticates nothing**: the identity is never proven (F1) and the SAS is grindable (F2), so a "verified" pin persists an attacker's identity, which is worse than today's one-shot auto-accept. F5 means a shipped transport is wide open right now and the proposed fix is inert.

## Verification note

I read the cited code directly. Every current-state premise checks out: the std `mpsc::Receiver` and 30s poll-loop (`server.rs`), the discard-on-mismatch, `set()` no-overwrite, the plaintext session-sealed HELLO identity (`web_hello.rs`), X25519 identity keys (`identity.rs`), the 24-bit SAS (`sas.rs`), `WtEndpointConfig` with no trust field, the client legacy branch (`session_loop.rs:535`), Swift emitting only `allow_once`/`deny_once`, and `--pairing-policy allow` on `0.0.0.0` with a `/tmp` data_dir. The tracker itself has EA1 OPEN and EA4 DESIGN-LOCKED to exactly this plan, which is why the sequencing verdict is firm.