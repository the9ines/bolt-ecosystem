# Decision: EA1 PAKE v1 Protocol Profile — Proposal

> **Date:** 2026-07-15
> **Status:** **PROPOSED. NOT WIRE-FROZEN. NOT IMPLEMENTATION-AUTHORIZED.** A design record for
> review — it freezes nothing on the wire and authorizes no code. EA1 remains **OPEN**.
> **Scope repos:** `bolt-protocol` (spec revision), `bolt-core-sdk` (SDK), downstream products —
> all future, all gated.
> **Builds on:** `os/log/decisions/2026-07-15-ea1-adopt-pake-direction.md` (adopt a vetted PAKE;
> do not hand-roll pairing crypto). **Evidence:** `docs/evidence/EA1_REDTEAM.md`,
> `docs/evidence/PAKE_EVAL.md`, the EA1 row in `docs/AUDIT_TRACKER.md`, the inert spike crate
> `bolt-spake2-spike` (bolt-core-sdk commit `664df5a`, branch `spike/spake2-wasm`, unmerged).

## Context

The shipping pairing model is **compare-and-confirm**: both screens display a 24-bit SAS derived
from public keys; humans eyeball it and click "Mark Verified." The EA1 red-team's root defect is
that the SAS inputs (attacker-chosen X25519 identity keys) are uncommitted and public, so a two-leg
MITM at the untrusted rendezvous birthday-grinds ~2^15–2^16 throwaway identities **offline** until
both displayed SAS collide (~1 success/session; SAS length does not help — it is an offline
birthday search). Hand-rolled commit-reveal is also broken (it commits only the ephemeral; the
identity stays grindable). Two red-teams returned HAS-BLOCKERS.

This proposal captures the **type-a-secret PAKE** design that replaces the compare step: one device
shows a one-time code, the other's human types it, and the code *is* the SPAKE2 password. Security
comes from an automatic key-confirmation MAC (the shared key forms only if both sides used the same
secret), not from a short human compare. A MITM ignorant of the code is reduced to **one online
guess per session**, not an offline grind.

## Proposed profile: capability `bolt.pake-v1`

### Human-code UX

- **Who generates:** the **displaying peer** (the device being connected to) generates and shows
  the code.
- **Who types:** the **initiating peer's** human types it — **one-sided entry** (magic-wormhole
  model), not both-type. The other human only reads their own screen.
- **Code shape:** `ROUTING-SECRET`. `ROUTING` = public rendezvous mailbox id (the server sees only
  this). `SECRET` = the SPAKE2 password, **never sent to the server or on the wire in cleartext**.
  The split is mandatory: today's whole peer code is sent to rendezvous as routing, so the password
  portion must be carved off and kept off-server.
- **Alphabet:** the existing 31-char unambiguous set `ABCDEFGHJKMNPQRSTUVWXYZ23456789`
  (PROTOCOL.md §2).
- **Length/entropy:** `SECRET` ≈ 8 chars ≈ 40 bits (PAKE_EVAL's long code; MHF=none defensible at
  that entropy). `ROUTING` short (≈4 chars) — disambiguation only, no entropy budget.
- **Normalization (must be byte-identical Rust↔TS):** NFC → uppercase-fold → drop every char not in
  the alphabet (removes the `-` separator + spaces) → re-segment by fixed lengths. Password bytes =
  ASCII of the normalized `SECRET`. This normalization is itself a golden-vector item.

### Message sequence

Runs after the peer channel opens (post `CONNECTION_REQUEST`/`ACCEPTED` + transport connect), in
place of the plain identity-carrying HELLO as the root of trust. Two new pre-handshake message
types, accepted in the pre-`HANDSHAKE_COMPLETE` state alongside HELLO/ERROR (PROTOCOL.md §3, §15.5).

```
Initiator (types code)                         Responder (shows code)
    ── PAIR_INIT ─────────────────────────────►
    ◄───────────────────────────── PAIR_INIT ──   (symmetric; both send, order-free)
  compute K_pake = SPAKE2.finish(peer.pake_msg)   (both sides)
  build transcript TT from BOTH PAIR_INITs; HKDF → K_conf_L/R, K_session
    ── PAIR_CONFIRM(MAC_role) ────────────────►
    ◄──────────────────── PAIR_CONFIRM(MAC_role) ─
  verify peer MAC (constant-time). Both verify ⇒ paired; else fail-closed.
    ── HELLO (caps/limits, now authenticated) ─►   (identity already bound in TT)
    ◄──────────────────────────────── HELLO ───
```

- **Roles:** symmetric SPAKE2 (`start_symmetric`) — no A/B assignment. Reflection/role-swap is
  handled at the transcript layer, not by role assignment.
- **`PAIR_INIT` fields** (each side sends one): `side_id` (16 B random), `pake_msg` (33 B SPAKE2
  outbound), `identity_key` (32 B X25519), `ephemeral_key` (32 B, echoes envelope header),
  `bolt_version`, `capabilities[]` (full advertisement), optional `channel_binding` (transport
  exporter / cert-hash — EA13 tie-in).
- **`PAIR_CONFIRM` fields:** `mac` (32 B).

### Transcript TT

The single value everything binds to; canonical, length-prefixed, capability list sorted for
encoding:

```
TT = SHA-256( "bolt-pake-v1" ‖ len‖routing_id
              ‖ sort_pair( enc(PAIR_INIT_self), enc(PAIR_INIT_peer) ) )
```

- **Downgrade resistance:** each side's **full advertised** `capabilities[]` + `bolt_version` are
  inside TT (not the intersection). Strip/edit a cap → TT differs → MAC fails. Plus a mandatory
  floor: a peer with a `pake-v1` pin, or configured "require PAKE," refuses fallback
  (`PAIR_REQUIRED`). Closes the downgrade blocker + EA16 + EA-D2.
- **Replay resistance:** TT includes fresh SPAKE2 messages, fresh 16 B `side_id`s, and fresh
  ephemeral keys; a replayed message won't match the live TT. Backed by one-time-code consumption
  (mailbox + code retired on first use, with lockout).
- **Role-swap / reflection:** symmetric mode alone is reflectable, so (a) reject inbound
  `side_id == own`; (b) derive role-labeled confirmation keys by sorting the two `side_id`s
  (smaller = L, larger = R); (c) both identity keys are in TT (kills UKS).

### SPAKE2 usage (grounded in spike `664df5a`)

```
let (state, msg) = Spake2::<Ed25519Group>::start_symmetric(
        &Password::new(secret_bytes),   // normalized SECRET, raw ASCII bytes
        &Identity::new(b"bolt-pake-v1"), // FIXED domain string, both sides identical
);
// exchange `msg` in PAIR_INIT
let k_pake: Vec<u8> = state.finish(&peer_pake_msg)?;  // 32 B = crate-internal SHA-256 digest
```

- **Library:** `spake2 = "=0.4.0"`, `Ed25519Group`, `start_symmetric`; lock `curve25519-dalek ≥
  4.1.3`. One canonical impl in bolt-core-sdk, compiled to WASM via `bolt-protocol-wasm`.
- **Password:** the normalized `SECRET` only (not routing, not the whole code).
- **Context/Identity param:** the crate's single symmetric `Identity` = fixed domain string
  `b"bolt-pake-v1"` (spike used `b"bolt-spike"`; freeze the label at design-freeze). It is not the
  device identity keys — those bind via TT.
- **Feeds HKDF:** the raw 32 B `k_pake` as IKM with `salt = TT`. Never use `k_pake` directly.
- **`Ed25519Group` ≠ Ed25519 identity:** the crate's group is the edwards25519 curve for the PAKE
  math; it does not reintroduce an Ed25519 signing identity. Identity keys stay **X25519** per the
  direction ADR.
- **Never hand-implement:** the SPAKE2 group math (M/N points, scalar mult, message/key
  derivation) — take it entirely from the crate; likewise HKDF/HMAC (use `hkdf 0.12`/`hmac`).
  Hand-authored surface is limited to code normalization, the canonical TT byte layout, and message
  framing — all golden-vector-tested.
- The spike confirms the crate supplies **no** key confirmation (`finish()` returns `Ok` on a wrong
  password; keys just differ) and binds only {password, Identity, both pake_msgs} internally — so
  external key confirmation and the TT binding are load-bearing.

### HKDF / key-confirmation plan

```
PRK       = HKDF-Extract(salt = TT, ikm = k_pake)
K_conf_L  = HKDF-Expand(PRK, "bolt-pake-v1 confirm L", 32)
K_conf_R  = HKDF-Expand(PRK, "bolt-pake-v1 confirm R", 32)
K_session = HKDF-Expand(PRK, "bolt-pake-v1 session",   32)
SAS_disp  = HKDF-Expand(PRK, "bolt-pake-v1 sas",       n)   // OPTIONAL display only, not the mechanism
```

- **Labels:** domain-separated, role-split L/R (role = owner of the smaller `side_id`).
- **MAC inputs:** `MAC_role = HMAC-SHA256(K_conf_role, TT)`. (Because K_conf is already HKDF'd with
  `salt = TT`, MACing a fixed per-role tag instead of TT is an equivalent simpler alternative — a
  cryptographer call.)
- **Who sends what:** each peer sends its own role's MAC in `PAIR_CONFIRM` and verifies the peer's
  under the other role's key. Both must verify before leaving `pairing`.
- **Failure behavior:** constant-time compare; on mismatch → terminal error `PAIR_CONFIRM_FAILED`,
  fail-closed (no pin, no transfer), consume the code + lockout. A mismatch is hostile (wrong code
  or active MITM), never a soft same-code retry loop.
- `SAS_disp` is an optional wormhole-style verifier; explicitly **not** the security mechanism.

### Identity and typed pins

- **Identity binding:** keep the **X25519** identity key (ADR-locked; the PAKE supplies the
  authentication a PoP signature would have). It is bound by being inside TT and thus under the
  confirmation MAC — the concrete fix for "identity not committed." No signing key introduced.
- **Typed pin (fixes EA5 + untyped-pin blocker):**
  ```
  PinRecord v2 { pin_format: 2, identity_key: [32]u8 (authoritative, KEY),
                 pake_profile: "bolt-pake-v1", verified_at, transcript_hash?, device_name }
  ```
  Keyed by `identity_key`, **not** the peer code (today's web store keys by code — the EA5 defect).
  `pin_format` makes v1/v2 byte-distinguishable so an honest upgrade does not fire KEY_MISMATCH.
  Migration is transactional (bump DB_VERSION), not lazy/fail-open.
- **Old SAS pins:** ignored for trust, not migrated to verified — continuing EA29 (the `verified`
  field is already dead). No mass reset; old records survive only as a weak seen-before hint with no
  verified status, upgraded organically on next pairing.
- **Reconnect:** `identity_key` must match the v2 pin (else `KEY_MISMATCH` hard-abort + explicit
  PAKE re-pair); the session authenticates that key via the envelope MAC (PROTO-HARDEN-01). Never
  persist `K_session`.

### Product states

Maps onto SESSION_CONTRACT's `verification_state` (today `unverified`/`verified`/`legacy`):

| State | Meaning | Transfer? |
|---|---|---|
| `unverified` | Connected; no PAKE this session, no matching v2 pin. | No (block-default) |
| `approved_for_session` (new) | Human authorized this session only (EA4/EA29 authorization, not verification); no pin persisted. | This session only |
| `verified_pake_v1` | PAKE confirmation succeeded this session, or reconnect with a matching v2 PAKE pin. Carries strength+version. (Canonical `Verified` enum may keep its name — rename deferred — but semantics are PAKE.) | Yes |
| `pake_failed` (new, hostile) | Confirmation MAC failed. Fail-closed, no pin, code consumed/locked. | No |
| `key_mismatch` (hostile) | Reconnect identity_key ≠ pin. Hard-abort + explicit PAKE re-pair. | No |
| `legacy` | Peer genuinely lacks PAKE and policy permits. Treated like `approved_for_session`, never `verified`; a require-PAKE peer refuses. | Policy-gated |

Also fix EA14: enforce the transfer gate on the **receive path** in the SDK, not UI-only.

### Test plan

Exceeds the PROTOCOL/HIGH floor (INTEROP + ≥1 ADVERSARIAL):

- **Native Rust ↔ WASM golden vectors** at the layers we control: code-normalization, TT
  encoding→hash, HKDF outputs, confirmation MAC — byte-identical across Rust and WASM. (The spike
  has deterministic native SPAKE2 vectors but ran no cross-language equality check and exports no
  wasm-bindgen surface — both net-new. Raw-pake_msg vectors need deterministic-RNG injection, so
  cross-lang equality may anchor at TT/HKDF/MAC.)
- **Wrong code** → different k_pake → both MACs mismatch → both abort `pake_failed`, no pin, code
  consumed.
- **Replay** → replayed PAIR_INIT/PAIR_CONFIRM into a fresh session → TT mismatch → reject.
- **MITM relay** → attacker ignorant of SECRET forced to one online guess; wrong guess → both
  honest peers abort, attacker learns nothing, one code consumed. (Replaces the grind test.)
- **Role swap / reflection** → bounce a peer's own PAIR_INIT / force equal roles → `side_id==own`
  reject or L/R key mismatch → MAC fails.
- **Downgrade** → strip `bolt.pake-v1` / edit version/caps → TT mismatch; require-PAKE peer with no
  advertisement → `PAIR_REQUIRED`.
- **Capability reordering** → honest reorder → success (canonical sort in TT); malicious add/drop →
  failure.
- **Old pins** → v1 verified ignored (PAKE required); v2 matching identity → reconnect continuity;
  v2 mismatch → KEY_MISMATCH; v1/v2 byte-distinguishable.
- **Formal model** (Tamarin/ProVerif) of the commit/transcript/confirm layout before wire freeze.

### Migration / rollout

- **Feature flag:** capability `bolt.pake-v1`, advertised in PAIR_INIT/HELLO, off by default.
- **Old-client compatibility:** non-advertising clients fall to legacy only if policy permits (LAN,
  user-approved, honest authorization-not-verification); a require-PAKE peer refuses. No silent
  auto-trust.
- **Staged default-on (all must hold):** (1) external cryptographer sign-off + formal model;
  (2) cross-impl golden vectors + error-code parity green in CI; (3) adversarial suite green as a
  conformance gate; (4) typed pin store shipped first; (5) bolt-protocol spec revision + major SDK
  bump through governance; (6) opt-in → default-on new pairings → hard-require config → deprecate,
  then remove, legacy accept. Never mass-reset pins.

## Unresolved until adversarial review

The following are explicitly **NOT settled** by this proposal and must be resolved by adversarial /
professional-cryptographer review before any wire freeze:

1. **Symmetric SPAKE2 reflection / UKS mitigation** — the `side_id` + L/R-label + full-transcript
   scheme is believed correct but is the subtle core; the crate's built-in `BadSide` check does not
   catch symmetric self-reflection. Ratify or replace (role-assigned SPAKE2 / SPAKE2+ / CPace).
2. **Reconnect policy** — TOFU-continuity to a PAKE-pinned identity vs. a fresh-code PAKE on every
   reconnect. Central UX↔security tradeoff; unresolved.
3. **Channel binding per transport** — which exporter/fingerprint to fold into TT for WebRTC
   DataChannel vs. direct WS/WT/QUIC (EA13). Unresolved.
4. **Constant-time / zeroization risk** — `spake2 0.4.0` is unaudited, self-describes as not
   constant-time, and does no secret zeroization. Acceptability at one-time-code entropy is an
   unresolved HIGH-severity sign-off.
5. **Whether to show any verifier** — `SAS_disp` at all. Surfacing it risks a human-compare
   regression; hiding it (wormhole style) is the alternative. Unresolved.
6. **Formal-model requirement** — a Tamarin or ProVerif model of the commit/transcript/confirm byte
   layout is required before the wire format is frozen. Not yet produced.

## Risks and assumptions

- `spake2 0.4.0` unaudited, not constant-time, no zeroization — HIGH risk needing an explicit filed
  sign-off. The "one online guess" property holds only if one-time-code consumption + lockout are
  enforced (ties to rendezvous rate-limiting, EA12).
- Not RFC 9382 (wormhole-style variant). No third-party PAKE interop assumed.
- Symmetric-mode reflection/UKS is the subtle core (see Unresolved #1).
- The displayed verifier is not the mechanism; the MAC must stay mandatory and fail-closed.
- Channel-binding assumes the key/exporter in TT is the one actually protecting the transport, or a
  rendezvous cert-swap (EA13) slips through.
- Golden-vector reachability: deterministic raw-SPAKE2 vectors need RNG injection the product path
  won't use; cross-language equality likely anchors at TT/HKDF/MAC. The spike's WASM round-trip was
  never executed (runner/crate version mismatch).
- ~40-bit SECRET with MHF=none, and byte-identical Rust/TS normalization; a normalization divergence
  silently breaks honest peers.

## Open questions (human / cryptographer)

Beyond the six Unresolved items: (a) is `HKDF(salt=H(TT))` over the raw key sufficient, or must the
verifier be secret-derived AND committed (the red-team's ZRTP correction); (b) code structure +
entropy split, MHF=none acceptability, lockout parameters; (c) confirm X25519-only identity (no PoP)
is acceptable now that the PAKE authenticates it; (d) SPAKE2 vs CPace (CFRG-selected) — an explicit
cryptographer accept/reject.

## Phase plan (implementation — not authorized here)

| Phase | Deliverable | Gate |
|---|---|---|
| 0 — Governance & cryptographer | Engage cryptographer; file the `spake2` risk sign-off; confirm X25519; freeze scope. No code. | Cryptographer engaged |
| 1 — Spec design-freeze | bolt-protocol revision: TT encoding, PAIR_INIT/PAIR_CONFIRM schemas, error codes, PinRecord v2, HKDF labels. To cryptographer + formal model before wire freeze. | Formal model + sign-off ⇒ wire frozen |
| 2 — Canonical codec + vectors | One normalization/TT/HKDF/MAC codec → WASM; cross-language golden vectors + error-code parity in CI. | Vectors green Rust+WASM |
| 3 — SPAKE2 wrapper + confirmation | Productize the spike behind `bolt.pake-v1` (off); PAIR_INIT/PAIR_CONFIRM, HKDF, MAC, fail-closed ordering; wrong-code/replay/role-swap tests. | Adversarial unit suite green |
| 4 — Typed pin store + migration | Rebuild pins: typed, identity-keyed, transactional, v1/v2 distinguishable; ignore old verified; no mass reset. Lands before any default-on. | Migration tests green |
| 5 — Channel binding + downgrade floor | Fold ephemeral/transport exporter into TT (EA13); mandatory cap floor + PAIR_REQUIRED (EA16); receive-path transfer gate (EA14). | Downgrade/binding tests green |
| 6 — Product UX | One-sided code generate/enter; automatic confirmation replaces Mark-Verified; approved_for_session vs verified_pake_v1; mismatch hostile; pin decoupled from transfer-unlock. | Block-default verified |
| 7 — Conformance CI gate | MITM/downgrade/cap-reorder/old-pin suite required; formal-model artifact attached. | Gate enforced in CI |
| 8 — Staged rollout | Opt-in → default-on new pairings → hard-require config → deprecate/remove legacy. Major SDK bump; CHANGELOGs. | Staged criteria met |

## Authorization boundary

- **No code is authorized by this ADR.** It is a proposal: nothing is wire-frozen, no implementation
  is authorized. Phase 0/1 begin only on explicit human authorization, gated on the external
  cryptographer and the adversarial review that resolves the six Unresolved items.
- **Old "verified" stays disabled until EA1 ships and passes its gates.** Products remain honest per
  EA29: no cryptographic "verified" claim, no persistent verified pin, no reconnect auto-trust. A
  `verified_pake_v1` state may exist only after the full EA1 workstream lands and the Phase 2/3/7
  gates (cross-impl vectors, adversarial suite, conformance CI) are green.

## Out of scope

No PAKE implementation, no spike merge, no spec change, no security code, no wire freeze, no SOC 2.
Design record only.
