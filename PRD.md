# Bolt Ecosystem Product Requirements

## Vision

Bolt powers encrypted file transfer between devices. LocalBolt is the open local
product line; ByteBolt is the commercial/global product line.

The ecosystem should stay understandable:

- one protocol,
- shared Rust authority for protocol-critical logic,
- thin product shells,
- clear public security claims.

## Products

| Product | Status | Notes |
|---------|--------|-------|
| LocalBolt web | Active | Hosted browser app at `localbolt.app` |
| LocalBolt self-hosted | Active | Browser app users can run locally |
| LocalBolt native macOS | Active | SwiftUI + Rust native bridge + daemon sidecar |
| ByteBolt | Commercial direction | Global relay/product surfaces |

## Requirements

1. Preserve encrypted transfer as the core user value.
2. Keep protocol-critical behavior in shared protocol/core repos.
3. Keep native apps on Rust core with native wrappers.
4. Keep public docs honest about what is implemented.
5. Keep EA1 PAKE locked until external review and wire-freeze are complete.

## Non-Goals

- No product-facing verified-device claim until EA1 is implemented and reviewed.
- No dead desktop shell stacks in active product trees.
- No internal governance or AI-agent operating docs in public app repositories.

## Community Help Wanted

Community testing is useful now for app behavior, build issues, documentation,
and SDK ergonomics. Cryptographer/formal-methods help is wanted for EA1 before
any verified-pairing implementation begins.
