# Bolt Ecosystem

Bolt is the protocol and app ecosystem behind LocalBolt: encrypted device-to-device
file transfer for browser and native clients.

This repository is the public ecosystem map. The implementation lives in sibling
repositories:

| Repository | Role |
|------------|------|
| `bolt-protocol` | Protocol specification |
| `bolt-core-sdk` | Shared Rust SDK, WASM bindings, transfer core, BTR |
| `bolt-daemon` | Native-side daemon for session and transport orchestration |
| `bolt-rendezvous` | Untrusted signaling/rendezvous server |
| `localbolt-v3` | Hosted web app at `localbolt.app` |
| `localbolt` | Self-hosted web app |
| `localbolt-app` | macOS native app: SwiftUI + Rust native bridge + daemon sidecar |
| `bytebolt-*` | Commercial/global product and relay surfaces |

## Current Security Posture

- Transfers are encrypted.
- The app no longer presents user-approved sessions as verified-device identity.
- EA1 PAKE is a reviewable protocol proposal, not an implemented feature.
- EA1 is not wire-frozen, not implementation-authorized, and not product-facing.
- Do not treat the current app as MITM-proof verified pairing.

## What Is Current

- Native direction: Rust core with thin platform-native wrappers.
- macOS native shell: SwiftUI over `native/shared` Rust C-ABI bridge.
- Browser direction: TypeScript UI and browser adapters over shared protocol/SDK
  surfaces where available.
- Retired desktop shell stacks have been removed from active app trees.

## Public Docs

- [Architecture](ARCHITECTURE.md)
- [Product Requirements](PRD.md)
- [Roadmap](ROADMAP.md)
- [Docs Index](docs/README.md)
