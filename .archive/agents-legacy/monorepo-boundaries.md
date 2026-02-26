# Monorepo Boundaries

Prevent repository creep and duplication.

---

## What Lives Where

| Content | Repository | Notes |
|---------|-----------|-------|
| Bolt Core specification | bolt-protocol | PROTOCOL.md, profile docs, no code |
| Bolt Core SDK (Rust) | bolt-core-sdk | Reference implementation |
| Bolt Core SDK (TypeScript) | bolt-core-sdk | Same repo, separate package |
| Conformance test vectors | bolt-core-sdk | Shared between Rust and TS |
| Rendezvous server (Rust) | bolt-rendezvous | Canonical implementation |
| Rendezvous (vendored) | localbolt, localbolt-app | Via git subtree only |
| Daemon (Rust) | bolt-daemon | Canonical implementation |
| Relay infrastructure | bytebolt-relay | Commercial |
| Web lite app | localbolt | Open source |
| Native multi-platform app | localbolt-app | Open source |
| Web app (Netlify) | localbolt-v3 | Open source |
| Commercial global app | bytebolt-app | Commercial |
| Protocol spec (temp) | bolt-core-sdk | Until bolt-protocol separated |

---

## Subtree Policy

- bolt-rendezvous is vendored into product repos via `git subtree`.
- Subtree prefix: `signal/` (in localbolt and localbolt-app).
- Vendored code MUST NOT be modified in the product repo.
- All fixes and features MUST be made upstream in bolt-rendezvous.
- Pull upstream: `git subtree pull --prefix=signal <remote> main --squash`

---

## No Code Copying Rule

- MUST NOT copy source files between repositories.
- MUST NOT duplicate protocol logic across repos.
- Use one of:
  - **Dependency**: add bolt-core-sdk as a package dependency.
  - **Subtree**: vendor bolt-rendezvous via git subtree.
- If logic is needed in two places, it belongs in a shared dependency (SDK or rendezvous).

---

## No New Repos Rule

- MUST NOT create new repositories without explicit instruction.
- The repository landscape is defined in CLAUDE.md section 2.
- Planned but not yet created repos are documented; do not pre-create them.

Currently existing repos:
- bolt-core-sdk (contains spec temporarily)
- localbolt
- localbolt-app
- localbolt-v3

Planned repos (do not create without instruction):
- bolt-protocol
- bolt-rendezvous
- bolt-daemon
- bytebolt-app
- bytebolt-relay

---

## Canonical Repo Names and Allowed Contents

| Repo | Allowed | Forbidden |
|------|---------|-----------|
| bolt-protocol | Markdown specs only | Code, configs, CI |
| bolt-core-sdk | SDK code, tests, spec (temp) | Product UI, transport impl |
| bolt-rendezvous | Rendezvous server code | Protocol logic, UI |
| bolt-daemon | Daemon code, IPC API | Protocol logic, UI |
| localbolt | Web app, vendored signal | SDK internals, spec |
| localbolt-app | Tauri app, vendored signal+daemon | SDK internals, spec |
| localbolt-v3 | Web app (TS only) | Servers, daemons, native code |
| bytebolt-app | Commercial app | Open-source protocol changes |
| bytebolt-relay | Relay infra | Protocol changes, free features |

---

## Boundary Violation Checklist

- [ ] No source files copied between repos.
- [ ] No protocol logic outside bolt-core-sdk.
- [ ] No vendored code modified locally.
- [ ] No new repos created without instruction.
- [ ] No rendezvous logic in Core SDK.
- [ ] No daemon logic in web-only repos (localbolt-v3).
- [ ] No commercial logic in open repos.
