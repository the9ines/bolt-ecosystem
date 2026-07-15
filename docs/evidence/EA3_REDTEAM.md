# WebTransport Trust-Gate: Consolidated Reviewer-of-Record Report

Commits reviewed: 2ae6af7 (WT trust gate). Note: the cited 88ea948 (tracker entry) does not exist in this repo; only 2ae6af7 and 0d5cfba (item-2 fail-closed) are present. The code verdict is unaffected.

## Verdict: HAS-BLOCKERS

One blocker, and it is TEST/VERIFICATION quality, not a production defect. The shipped WT gate is production-correct and correctly placed, verified across roughly 30 independent holds-up checks with no bypass, no fail-open, and no policy divergence from the WS answerer. The blocker is that the WT test suite does not actually pin the enforcement invariant, so a future WT-specific regression could ship green. Item 4 may still proceed (see below) because it neither builds on nor is undermined by the WT test gap.

Classification legend: [TEST] test-quality, [PROD] production bug, [OBS] observability, [PRE] pre-existing/shared-core, [OFF] off-axis.

## Blocker

### B1. WT enforcement is not pinned by any test [TEST]
The two WT tests together do not prove that a peer which completes the HELLO handshake is blocked by policy before transfer.
- The None-config deny test (wt_endpoint.rs:665) asserts only `result.is_err()` and a vacuous `!saw_transfer` (no FileChunk is ever sent), discards the HELLO response, and never asserts the gate caused the denial. It catches gate REMOVAL today only incidentally, through the 5s `.expect()` timeout when the idle client makes run_read_loop spin (session_loop.rs:1462-1465), and it stays GREEN under any future pre-gate handshake drift (parse_hello_typed / build_hello_message change, a framing change, or moving the Step-7 HELLO response after the gate).
- The Allow test (wt_endpoint.rs:525, PairingPolicy::Allow) is a pure pass-through (session_loop.rs:120,138-142); deleting the gate call at wt_endpoint.rs:299-305 leaves it green, so it gives zero regression protection for the property item 3 exists to guarantee.
- No WT test uses PairingPolicy::Deny or Ask-unpinned. Concrete break: a refactor that passes SessionTrustRole::Offerer instead of Answerer at wt_endpoint.rs:299 would ALLOW an Ask-unpinned peer via the offerer None->Allow arm (ipc/trust.rs:307-313), a real bypass, and neither WT test would catch it (None still denies, Allow still allows). The shared enforce_session_trust unit tests do not cover a wrong-argument regression at the WT call site.

Required change (specify, do not write code):
1. Harden the deny test: read and validate the daemon HELLO response via parse_hello_typed exactly as the Allow test does at wt_endpoint.rs:594-596, proving execution reached Step 7 immediately before the gate; replace `assert!(result.is_err())` with unwrapping the Err and asserting its string contains both `PAIRING_DENIED` and the `WT_SESSION` tag (the exact message from session_loop.rs:110-113); and have the client send one encrypted FileChunk after the valid HELLO (mirror wt_endpoint.rs:606-626) so the no-transfer assertion proves the gate blocked a real attempt.
2. Add a positive policy-denial WT integration test with a VALID denying trust_config (PairingPolicy::Deny, and/or Ask with an empty TrustStore): drive the full session-key + HELLO handshake, attempt a FileChunk, and assert (a) the PAIRING_DENIED Err, (b) neither transfer.started nor transfer.complete, (c) ACTIVE_SESSION left None. This Allow-vs-Deny differential is what actually proves WT routes through the same enforcement as WS and fails if the gate is deleted or the call site passes the wrong role/args.

## High (real issues, but not blockers of item 3's authorization goal)

### H1. ACTIVE_SESSION single process-global race [PROD, PRE, not an auth bypass]
Single `Mutex<Option<ActiveSessionHandle>>` (session_loop.rs:182-183) with last-writer-wins registration and no existing-session check (:1318-1328) and an unconditional teardown-clear (:1406-1411). BREAK A (misdelivery/confidentiality, under allow policy or a second already-pinned peer under ask): attacker session B overwrites the global so a native `send secret.pdf` streams to B instead of trusted session A. BREAK B (teardown DoS): session A closing nulls the global while B is live, killing B's outbound send. This predates item 3 (a597e82 registered WT, 8248390 folded it onto the shared loop, both before 2ae6af7), and item 3 STRICTLY SHRINKS it because a denied peer never reaches registration. Not an authorization bypass of the new gate.
Required change: file a standalone concurrency finding in docs/AUDIT_TRACKER.md, separate from the trust-gate track. Make registration reject-or-atomic-replace and teardown a compare-and-clear (null only if the current handle is mine), or replace the single global with a per-session outbound registry keyed by remote identity so send_file_to_browser routes to an explicit target. No later trust-gate item may rely on the one-active-session invariant until it is enforced.

### H2. Session-test serialization masks H1 and inflates concurrency evidence [TEST]
SESSION_GLOBALS_LOCK is held for the whole body of every session test (wt_endpoint.rs:526,666; session_loop.rs:1914..2732), so no test ever runs two sessions against the shared ACTIVE_SESSION. The commit message's green (WT 6/6, native-full 5/5, WS 5/5 "parallel") means distinct cases serialized on the lock, not two sessions sharing one global, and is fully consistent with H1 being live in production. What is masked is concurrency/availability, not authorization; the item-3 deny test itself passes for the right reason.
Required change: add a concurrency test that drives two sessions through run_session_with_outbound WITHOUT holding the lock and asserts the intended isolation (or the documented single-session rejection once H1 is fixed). Keep the lock for auth/lifecycle tests. Stop citing "parallel N/N under the lock" as concurrency-safety evidence in commit messages or DONE-VERIFIED claims.

## Medium

### M1. WT omits session.connected + session.sas IPC that WS and QUIC emit [OBS, PRE, not an auth bypass]
WT goes SessionContext::new (wt_endpoint.rs:307) to compute_sas (:311) to `eprintln!("[SAS]")` (:317) to run_session_with_outbound (:321) with no emit_ipc between. WS emits session.connected (session_loop.rs:1186) and session.sas (:1194); QUIC emits the same at :860/:868. The SAS is computed on WT but only written to stderr, so a WT peer's SAS never reaches the UI and a human cannot compare it out-of-band to detect a rendezvous MITM; a WT transfer also surfaces no session.connected. Device verification is outside item-3's authorization scope, and 2ae6af7 added the gate only.
Required change: track as a SEPARATE parity item; do not fold into item 3 and do not silently close as done. After the WT gate passes (right after wt_endpoint.rs:317) emit session.connected {remote_peer_id, negotiated_capabilities} and session.sas {sas, remote_identity_pk_b64} exactly as WS at session_loop.rs:1184-1201 and QUIC at :859-875.

## Low

### L1. --no-wt kill-switch is dead code [OFF, not a trust bypass]
args.no_wt is parsed (main.rs:192) and stored (:235) and documented as a kill-switch (:86-88) but the WT spawn block (main.rs:799-824) never reads it; grep confirms zero consumers in the spawn path. The listener comes up regardless, yet it stays gated by the same session_trust_config, so no ungated transfer results; only the operator's "WT off" expectation is violated.
Required change: gate main.rs:800 on `!args.no_wt` around the `if let Some(ref cert) = wt_cert` block and fold it into wt_enabled at main.rs:496 so capabilities do not advertise WT either, or delete the flag if retired. Not a prerequisite for item 4.

### L2. Respond-then-gate ordering leaks the daemon identity pubkey pre-auth [PRE, WS-parity holds]
WT sends the HELLO response (wt_endpoint.rs:287, carrying identity.public_key) before the gate (:299), same as WS (send :1151, gate :1160). QUIC gates first (:828 before :838). A scanner harvests the daemon long-term identity pubkey before being denied by the Ask no-pin gate.
Required change: none for item 3 (WT matches the WS answerer exactly, which is the stated bar). If pre-auth disclosure is later deemed undesirable, move the gate ahead of the HELLO-response send on BOTH WS and WT to match QUIC (session_loop.rs:828-838). Pre-existing.

### L3. A _once trust-store entry passes the Ask gate [PRE, out of threat model]
The Ask branch keys on `store.get(identity).is_some()` not the pin variant (session_loop.rs:126-132), so a _once entry yields stage_a_decision=None, enforce_stage_b treats _once as no-pin (ipc/trust.rs:253-268), and the None arm returns Allow (:307-313). The modeled attacker cannot trigger it: TrustStore::set never writes _once variants (ipc/trust.rs:206-220), so it fires only if trust.json is hand-seeded, corrupted-yet-valid, or restored from a bad backup. Shared with WS/QUIC.
Required change: shared-core fix, own tracker item, not an item-3 blocker: make the existing-pin `_ =>` arm for _once return StageBResult::Deny; and/or match a concrete AllowAlways pin in the Ask branch rather than is_some(); and/or have TrustStore::load drop any non-{AllowAlways,DenyAlways} peer entries.

### L4. Trust-store double-read TOCTOU on revocation [PRE, tiny window]
enforce_session_trust loads the store at session_loop.rs:126, then enforce_stage_b re-loads it at ipc/trust.rs:250; a pin revoked between the two reads lets read-2 see no pin and default to Allow (:307-313). Extremely tight window, standard in-flight authorization, predates item 3, not WT-specific, no cross-session double-spend.
Required change: low priority, not required for item 3. If tightened: pass the already-loaded store into enforce_stage_b (single read), or re-verify the pin under the None branch in the answerer role instead of defaulting to Allow.

### L5. Redundant Arc<Option<SessionTrustConfig>> in run_wt_endpoint [OFF, diff-hygiene]
wt_endpoint.rs:141 wraps the config in Arc, then :156 deep-clones the inner Option per session, so the Arc's shared ownership is discarded at use. Behavior is correct.
Required change: optional cleanup only. Clone config.trust_config per session directly, or keep the Arc but pass a borrow if handle_incoming_session takes Option<&SessionTrustConfig>. No functional change.

## Item 4 gate

May proceed. Item 4 (legacy WS bypass closure, the EA2 legacy-HELLO downgrade path) operates on the WS answerer and the shared enforce_session_trust, both directly unit-tested (session_loop.rs:1817/1893/2275) and unaffected by the WT test gap; wt_endpoint has no legacy branch. The production WT gate is correct and is a faithful port of the same WS call, so item 4 neither builds on a broken WT gate nor is undermined by B1. Carry-forward conditions: add the WT enforcement tests (B1) in parallel and stop treating WT enforcement as verified until they exist; item 4 must not rely on the single-active-session ACTIVE_SESSION invariant (H1); do not cite "parallel N/N under the lock" as concurrency evidence (H2).

## What holds up (production authorization is sound)

The gate is the same enforce_session_trust(Answerer, "WT_SESSION") call as WS, placed after remote-identity decode and before SessionContext::new (wt_endpoint.rs:299-321), with `?` propagating every deny (missing config, Deny, Ask-unpinned, StageB Deny). Production always supplies Some(trust_config) (main.rs:807/812, the same object cloned to WS/QUIC); the only None constructions are startup/shutdown tests. Fail-closed is real and correct-direction (None denies, never allows). Feature coupling is compile-enforced (no ungated WT binary can be built; default build has no WT). The gated identity is the authenticated, decrypted-HELLO identity, not spoofable. run_wt_endpoint has one inbound path (no datagram/alternate-stream handler) and no independent transfer machinery. Item 3 strictly reduces the pre-existing ACTIVE_SESSION concurrency surface. Corrupt/missing trust files fail closed; there is no mutex/poison fail-open inside the gate and no legacy/downgrade branch on WT.

## Scope caveats

Identity authenticity (a signature binding identity_public_key to the session keys) is intentionally out of item-3 scope and identical to WS/QUIC; not assessed. H1, H2, M1, L2, L3, L4 are pre-existing and shared with WS/QUIC or off-axis; none were introduced by 2ae6af7. The tracker commit 88ea948 could not be cross-checked (absent from this repo).