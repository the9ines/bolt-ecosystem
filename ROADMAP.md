# Bolt Ecosystem Roadmap

## Now

- Keep public repos focused on app, protocol, SDK, daemon, and deployment code.
- Keep LocalBolt security wording honest: encrypted transfer, no implemented
  verified-device claim.
- Prepare EA1 PAKE v7 for external cryptographer/formal-methods review.

## Next

- Clean and verify public docs across child repos.
- Keep native macOS stable on SwiftUI + Rust bridge + daemon sidecar.
- Continue SDK and daemon hardening without adding new trust claims.

## Later

- External review result drives EA1 wire-freeze decisions.
- Future Linux, Windows, iOS, and Android native shells should use thin native
  wrappers over shared Rust authority.
- ByteBolt/global relay work stays separate from LocalBolt local-first claims.
