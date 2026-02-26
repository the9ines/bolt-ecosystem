# Product Build

Build systems and integration across product repositories.

---

## Per-Repo Runtime Constraints

| Repo | Bundles Rendezvous | Bundles Daemon | Offline Capable |
|------|--------------------|----------------|-----------------|
| localbolt | Yes (subtree) | No (initially) | Yes |
| localbolt-app | Yes (subtree) | Yes | Yes |
| localbolt-v3 | No | No | No |
| bytebolt-app | No (uses relay) | Yes | No |

- localbolt-v3 MUST NOT bundle servers, daemons, or native binaries.
- localbolt-v3 connects to hosted bolt-rendezvous endpoint only.

---

## Offline and Online Requirement

localbolt and localbolt-app MUST support:
- **Offline mode**: local rendezvous server on LAN, no internet required.
- **Online mode**: optional remote rendezvous for broader discovery.

The application MUST function without internet connectivity when peers are on the same network.

---

## Protocol Integration Rule

- Products MUST depend on bolt-core-sdk for all protocol logic.
- Products MUST NOT copy, fork, or reimplement:
  - Envelope encryption/decryption
  - HELLO handshake
  - SAS computation
  - State machine transitions
  - Message serialization at Core level
- Profile-level encoding (e.g. json-envelope-v1 serialization) lives in SDK profile adapters, not in product code.

---

## Subtree Update Procedure (bolt-rendezvous)

When upstream bolt-rendezvous has changes to pull into a product repo:

1. Ensure product repo working tree is clean.
2. `git subtree pull --prefix=signal <bolt-rendezvous-remote> main --squash`
3. Resolve any conflicts (should be rare if subtree rule is followed).
4. Run full build and test suite.
5. Commit with message: `chore: update bolt-rendezvous subtree to <upstream-tag>`
6. Tag per repo convention.

- MUST NOT modify files under the subtree prefix directly.
- If a fix is needed, make it upstream first, then pull.

---

## Chunk Size Guidance

- Default chunk size (16384 bytes) is defined in Bolt Core constants.
- Platform-specific overrides (mobile 8KB, Steam Deck 32KB) belong in:
  - Profile specification (normative)
  - Application configuration (runtime)
- Chunk size MUST NOT be hardcoded in Core SDK internals.
- Applications MAY negotiate chunk size via capabilities.

---

## Build Checklist

Before any product release:

- [ ] bolt-core-sdk dependency version pinned and declared.
- [ ] Subtree vendored code matches upstream tag.
- [ ] Offline mode tested (local rendezvous, no internet).
- [ ] Online mode tested (hosted rendezvous).
- [ ] No protocol logic duplicated outside SDK.
- [ ] CI passes: lint, test, build.
- [ ] No secrets in build artifacts.
