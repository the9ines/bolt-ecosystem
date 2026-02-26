# Bolt Ecosystem — Product Requirements Document

**Version:** 1.0.0
**Date:** 2026-02-20
**Status:** Active

---

## 1. Vision

The Bolt ecosystem delivers encrypted device-to-device file transfer across a spectrum of deployment models:

- **Local**: Self-hosted, offline-capable, zero-dependency file transfer (LocalBolt)
- **Global**: Managed, internet-scale encrypted transfer via relay infrastructure (ByteBolt)

Both models share one protocol, one SDK, and one security guarantee. The ecosystem is structured so that the open-source local products fund development through the commercial global products, without restricting any open component.

---

## 2. Repository Responsibilities

### Protocol Layer (No Code)

| Repository | Responsibility | Contains |
|------------|---------------|----------|
| bolt-protocol | Normative specification | PROTOCOL.md, profile documents |

### Implementation Layer

| Repository | Responsibility | Contains |
|------------|---------------|----------|
| bolt-core-sdk | Reference SDK (Rust + TypeScript) | Envelope, handshake, state machine, SAS, conformance vectors |

### Infrastructure Layer

| Repository | Responsibility | Contains |
|------------|---------------|----------|
| bolt-rendezvous | Signaling/discovery server | Rust WebSocket server, IP-based room grouping |
| bolt-daemon | Background service for native apps | Identity persistence, session orchestration, IPC |
| bytebolt-relay | Managed global relay | Commercial relay infrastructure |

### Product Layer

| Repository | Responsibility | Deployment |
|------------|---------------|------------|
| localbolt | Self-hosted lite web app | User runs locally |
| localbolt-app | Native desktop app (Tauri v2) | User installs binary |
| localbolt-v3 | Hosted web app | localbolt.site (Netlify + Fly.io) |
| bytebolt-app | Commercial global app | App stores + direct download |

---

## 3. Open vs Commercial Boundary

### Open (MIT, Unrestricted)

- Bolt Protocol specification
- Bolt Core SDK (Rust + TypeScript)
- Bolt Rendezvous (self-hosted)
- Bolt Daemon
- LocalBolt (all three variants)

### Commercial (Private)

- ByteBolt App — subscription or usage-based pricing
- ByteBolt Relay — managed relay infrastructure

### Boundary Rules

1. No paywall may exist in the protocol layer.
2. No open repository may depend on a commercial repository.
3. Commercial products consume the same SDK as open products.
4. Revenue funds ecosystem development; open components remain unrestricted.
5. No telemetry, analytics, or tracking in open products without explicit opt-in.

---

## 4. Protocol vs SDK vs Infrastructure vs Product Separation

```
bolt-protocol (WHAT)
    ↓ defines
bolt-core-sdk (HOW)
    ↓ consumed by
bolt-rendezvous / bolt-daemon / bytebolt-relay (WHERE)
    ↓ composed into
localbolt / localbolt-app / localbolt-v3 / bytebolt-app (FOR WHOM)
```

### Separation Rules

1. **Protocol** defines message semantics, state machines, and security requirements. Contains no code.
2. **SDK** implements the protocol. Contains no transport-specific logic at Core level. Profile adapters handle transport binding.
3. **Infrastructure** provides network services (signaling, relay). Operates as untrusted. Cannot observe file contents or encryption keys.
4. **Products** compose SDK + infrastructure into user-facing applications. Products must not reimplement protocol logic.

---

## 5. Architectural Invariants

These require explicit approval to change:

1. Bolt Core remains transport-agnostic.
2. Encrypted envelope is mandatory for all protected messages.
3. HELLO is always encrypted inside an envelope.
4. Rendezvous and relay infrastructure is untrusted.
5. Relay is optional and commercial.
6. SDK remains open source (MIT).
7. Ephemeral keys are per-connection and discarded on disconnect.
8. Identity keys are persistent and TOFU-pinned.
9. No new top-level folders under workspace root without approval.
10. Subtree code (signal/) must not be modified locally — changes flow upstream.

---

## 6. Governance Model

### Tag Discipline

Tags are immutable. Once pushed, they are never moved or deleted.

| Repository | Format | Example |
|------------|--------|---------|
| bolt-protocol | `vX.Y.Z-spec` | `v1.0.0-spec` |
| bolt-core-sdk | `sdk-vX.Y.Z` | `sdk-v1.0.0` |
| bolt-rendezvous | `rendezvous-vX.Y.Z` | `rendezvous-v1.0.0` |
| bolt-daemon | `daemon-vX.Y.Z` | `daemon-v1.0.0` |
| localbolt | `localbolt-vX.Y.Z` | `localbolt-v2.1.0` |
| localbolt-app | `localbolt-app-vX.Y.Z` | `localbolt-app-v1.0.0` |
| localbolt-v3 | `v3.0.<N>-<slug>` | `v3.0.38-faq-sync` |
| bytebolt-app | `bytebolt-vX.Y.Z` | `bytebolt-v1.0.0` |
| bytebolt-relay | `relay-vX.Y.Z` | `relay-v1.0.0` |

### Spec Discipline

- Protocol changes require spec update in bolt-protocol before SDK implementation.
- Profile changes require corresponding profile document update.
- Breaking changes require major version increment across spec, SDK, and dependent products.

### Commit Discipline

- Every commit is tagged.
- Working tree must be clean at session end.
- Secrets are never committed.
- History is never rewritten on shared branches.

---

## 7. Dependency Graph

```
bolt-protocol (spec, no code)
    │
    ▼
bolt-core-sdk (Rust + TypeScript)
    │
    ├──► bolt-rendezvous (standalone)
    │        │
    │        ├──► localbolt (subtree at signal/)
    │        └──► localbolt-app (subtree at signal/)
    │
    ├──► bolt-daemon (standalone)
    │        │
    │        ├──► localbolt-app (bundled)
    │        └──► bytebolt-app (bundled)
    │
    ├──► localbolt (web, self-hosted)
    ├──► localbolt-app (native, Tauri v2)
    ├──► localbolt-v3 (web, hosted)
    └──► bytebolt-app (native, commercial)

bytebolt-relay (standalone commercial)
    │
    └──► bytebolt-app (client connection)
```

### Bundling Matrix

| Product | bolt-rendezvous | bolt-daemon | bytebolt-relay |
|---------|:-:|:-:|:-:|
| localbolt | Subtree | No | No |
| localbolt-app | Subtree | Planned | No |
| localbolt-v3 | Hosted endpoint | No | No |
| bytebolt-app | No | Bundled | Client |

---

## 8. Monetization Model

### Revenue Sources

1. **ByteBolt App** — Subscription or usage-based pricing for global encrypted file transfer.
2. **ByteBolt Relay** — Managed relay infrastructure fees.
3. **Enterprise Support** — Optional paid support and consulting for self-hosted deployments.

### Cost Structure

1. Fly.io hosting for cloud rendezvous (localbolt-signal.fly.dev).
2. Netlify hosting for localbolt.site.
3. GitHub organization and CI compute.
4. Apple/Google developer accounts for app store distribution.

### Monetization Rules

1. Open products generate adoption and trust.
2. Commercial products capture value from users who need global reach.
3. No feature in an open product may be gated behind payment.
4. Relay pricing must be transparent and published.

---

## 9. Security Model

All products share the same security guarantees via bolt-core-sdk:

- **Encryption**: NaCl box (X25519 + XSalsa20-Poly1305)
- **Nonce**: 24-byte CSPRNG per envelope, no reuse
- **Authentication**: Poly1305 MAC per message
- **Identity**: TOFU pinning with SAS verification
- **Forward secrecy**: Ephemeral session keys, discarded on disconnect
- **Infrastructure trust**: Rendezvous and relay are untrusted — they forward opaque ciphertext

Security is implemented once in the SDK and consumed by all products. Products must not reimplement crypto.

---

## 10. Current State (as of 2026-02-20)

| Repository | Version | Maturity | Deployed |
|------------|---------|----------|:---:|
| bolt-protocol | v0.1.0-spec | Draft | N/A |
| bolt-core-sdk | sdk-v0.0.1 | Spec + README only | No |
| bolt-rendezvous | rendezvous-v0.0.1 | Seeded from localbolt | No (via subtree) |
| bolt-daemon | daemon-v0.0.1 | README stub only | No |
| localbolt | v1.0.0 | Production | Self-hosted |
| localbolt-app | v1.0.0 | Production | GitHub releases |
| localbolt-v3 | v3.0.38 | Production (web) | localbolt.site |
| bytebolt-app | bytebolt-v0.0.1 | README stub only | No |
| bytebolt-relay | relay-v0.0.1 | README stub only | No |
