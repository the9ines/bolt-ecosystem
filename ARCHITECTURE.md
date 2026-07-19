# Bolt Ecosystem Architecture

## Core Shape

Bolt separates protocol authority, shared implementation, infrastructure, and
product shells.

| Layer | Owner | Notes |
|-------|-------|-------|
| Protocol spec | `bolt-protocol` | Wire format, security invariants, BTR schedule |
| Shared Rust core | `bolt-core-sdk` | Crypto primitives, BTR, transfer state machines, app runtime core |
| Native daemon | `bolt-daemon` | Native session orchestration, IPC, WS/WT endpoints |
| Rendezvous | `bolt-rendezvous` | Untrusted signaling relay |
| Browser apps | `localbolt-v3`, `localbolt` | Browser UI, browser transport adapters |
| Native app | `localbolt-app` | Thin SwiftUI shell over Rust bridge and daemon sidecar |

## Authority Rules

- Protocol and security behavior belongs in `bolt-protocol` and shared Rust core.
- Product shells must stay thin: UI, platform integration, packaging, and user
  workflow.
- Browser TypeScript may own browser APIs and UI glue, but it must not become a
  second protocol authority.
- Native shells use the Rust core and daemon path.
- Rendezvous is untrusted by design and must not see plaintext or keys.

## Native App Direction

The current native architecture is Rust core with platform-native wrappers.

- macOS: SwiftUI shell in `localbolt-app/native/macos`.
- Rust bridge: `localbolt-app/native/shared`.
- Runtime authority: `bolt-core-sdk/rust/bolt-app-core` and `bolt-daemon`.
- Future platforms should follow the same thin-wrapper pattern unless a new
  architecture decision explicitly changes that direction.

Retired cross-platform desktop shell stacks are not active product paths.

## Browser Direction

`localbolt-v3` is the hosted web app and public browser package workspace.
`localbolt` is the self-hosted web app. Browser code owns DOM integration,
browser transport APIs, file picker behavior, and web UX.

## EA1 Boundary

EA1 PAKE is design-complete for external cryptographer/formal-methods review.
It is not wire-frozen and is not implementation-authorized. Product code must
not expose verified-device behavior until that review, spec update, and
implementation gate are complete.
