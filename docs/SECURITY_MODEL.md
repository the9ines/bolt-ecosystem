# Bolt Ecosystem — Security Model

> **Status:** Current — describes the model the implementations are held to.
> Wire semantics are normative in `bolt-protocol/PROTOCOL.md`; enforcement
> posture (fail-closed rules, error codes) is normative in
> `PROTOCOL_ENFORCEMENT.md`. Enforcement is verified by per-repo test suites
> and CI, not by audit matrices maintained in this public tree.

## 1. Trust Boundaries

| Component | Trust Level | Rationale |
|-----------|------------|-----------|
| Browser endpoint | Trusted local agent | Holds identity keys (origin-scoped storage), performs crypto. Full session authority when no daemon is present. |
| Native shell (`localbolt-app`) | Trusted local UI | Thin platform-native wrapper. Does not hold crypto keys directly; delegates to the Rust core and daemon. |
| Daemon (`bolt-daemon`) | Trusted local authority | Highest-privilege local component. Owns identity, session crypto, and the transfer engine. Compromise is full endpoint compromise. |
| Local IPC | Trusted local channel | Owner-only socket/pipe permissions. Protected by OS user isolation; equivalent trust to the daemon process boundary. |
| Local filesystem | Trusted local storage | Identity keys and trust store are owner-only files. Protected by OS file permissions. |
| Rendezvous server | Untrusted relay | Routes encrypted signals only. Cannot read protected contents. Sees IP addresses, peer codes, and connection metadata. |
| Network transport (WS / WebTransport / QUIC) | Untrusted channel | All protected data is envelope-encrypted. A man-in-the-middle sees ciphertext only. |
| Remote peer | Authenticated after HELLO | Untrusted until mutual HELLO and SAS verification. Trusted for the scope of that session only. User-approved sessions are not verified-device identity. |

```
┌────────────────────────────────────────────────┐
│                 Local Device                   │
│  ┌────────────┐   IPC    ┌──────────────────┐  │
│  │ native     │◄────────►│   bolt-daemon    │  │
│  │ shell      │          │  identity keys   │  │
│  └────────────┘          │  session crypto  │  │
│  ┌────────────┐ direct WS│  transfer engine │  │
│  │ browser    │◄────────►└────────┬─────────┘  │
│  │ endpoint   │                   │            │
│  └─────┬──────┘                   │            │
└────────┼──────────────────────────┼────────────┘
         │        signaling         │
         └────────────┬─────────────┘
              ┌───────▼────────┐
              │   rendezvous   │
              │ untrusted relay│
              └────────────────┘
```

## 2. Attacker Model

| Class | Capabilities | What the design denies them |
|-------|-------------|----------------------------|
| Passive network observer | Sees encrypted frames, timing, sizes, IPs, peer codes. | Plaintext, message forgery. |
| Active network meddler (MitM) | Drops, delays, replays, mutates traffic; injects malformed frames. | Forging valid envelopes without key material; surviving SAS verification when users compare codes. |
| Compromised rendezvous | Injects/modifies signals, logs metadata, denies service. | Reading envelope contents, forging HELLO, breaking SAS, reaching file contents. |
| Malicious remote peer | Sends malformed messages, downgrade pressure, hostile filenames/sizes, duplicate HELLOs. | Bypassing envelope encryption, impersonating a verified peer (SAS mismatch), reading local keys. |
| Local process, different OS user | Observes network traffic. | IPC access and key files (owner-only permissions). |
| Local process, same OS user | Full IPC and key-file access. | Nothing — same-user compromise is equivalent to daemon compromise. IPC has no authentication beyond filesystem permissions. |
| Compromised endpoint device | Everything on that device. | Other peers' endpoints; sessions are isolated per peer. |
| Stale/legacy client | Advertises fewer capabilities, pressures weaker modes. | Forcing a peer to accept a capability it doesn't support; negotiation is intersection-based and must be truthful. |
| Abusive automation | Floods connections/signals at the rendezvous. | File contents — transfer still requires HELLO and SAS verification. |

## 3. Assets

- **Identity keypair (Ed25519):** persistent; daemon data dir (owner-only file) or browser origin-scoped storage. Loss means a new identity.
- **Ephemeral session keys (X25519):** memory only, per connection, discarded on disconnect. Must never persist.
- **BTR ratchet state and derived keys:** memory only, transfer-scoped, cleared with the transfer context. Reuse across transfers is forbidden.
- **TOFU pin store:** persistent; low confidentiality, high integrity (tampering enables pin bypass).
- **File contents:** envelope-encrypted in transit; written to the user's download location at rest. Bolt does not provide at-rest encryption.
- **Logs/diagnostics:** must never contain secret key material.

## 4. Security Invariants

The normative wire rules and error registry live in `bolt-protocol/PROTOCOL.md`;
fail-closed enforcement posture lives in `PROTOCOL_ENFORCEMENT.md`. The core
invariants:

1. HELLO is encrypted; it never crosses the wire in plaintext.
2. Before mutual HELLO completion, only HELLO/ERROR/PING/PONG are accepted.
3. TOFU key mismatch fails closed: error, then disconnect.
4. Every envelope uses a fresh CSPRNG nonce; MACs are verified before any plaintext is processed.
5. Ephemeral keys are per-connection and discarded on disconnect.
6. Capability advertisement is truthful; unnegotiated capabilities are never acted on; negotiation is intersection-based.
7. Transfer chunks are individually encrypted; duplicate or out-of-range chunks are rejected.
8. All protocol violations fail closed — no log-and-continue, no downgrade, no re-negotiation within a session.
9. IPC messages are size-bounded and malformed input disconnects the client.

## 5. Bolt Transfer Ratchet (BTR)

BTR (`bolt.transfer-ratchet-v1`) adds per-transfer ratchet context and
per-chunk key evolution on top of the authenticated session. It does not
replace session authentication.

- Endpoints advertise BTR only if they fully implement it (truthful advertisement, no silent downgrade).
- Ratchet state is scoped and bound to one transfer in one authenticated session; cross-transfer or cross-session reuse is forbidden.
- Malformed, out-of-order, or unverifiable BTR payloads fail closed.
- Ratchet material is retained no longer than the active transfer requires.
- When BTR is not negotiated, transfers still run under authenticated static session-key encryption, and the negotiated outcome is observable — absence of BTR is never misrepresented as BTR protection.

## 6. Compromise Blast Radius

| Compromised | Exposes | Contained by |
|-------------|---------|--------------|
| Browser endpoint | That origin's sessions, its identity key and pin store. | Origin sandbox; other devices and the daemon's identity are unaffected. |
| Daemon | All sessions mediated by that daemon; persistent identity; local files of that user. | OS process/user isolation; remote peers and other devices are unaffected. |
| Rendezvous | Signaling metadata (who, when, IPs, peer codes); service denial. | End-to-end encryption is independent of rendezvous integrity; no plaintext exposure. |
| Native shell | Local UI and IPC command surface. | Keys stay in the daemon; daemon-side validation of IPC commands. |

## 7. Device Verification Boundary

Session approval plus SAS comparison is the current peer-verification
mechanism. The EA1 PAKE proposal for verified-device pairing is design-complete
for external review only: not wire-frozen, not implementation-authorized, not
product-facing. Product surfaces must not present user-approved sessions as
verified-device identity.
