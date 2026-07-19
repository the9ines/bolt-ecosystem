# Bolt Ecosystem Changelog

## Public Cleanup

- Public repository docs now describe the current app/protocol state directly.
- Internal governance, private audit trackers, AI-agent instructions, and
  private review evidence are kept outside the public GitHub tree.
- Retired desktop shell stacks were removed from active app trees.

## Current Security State

- LocalBolt transfers are encrypted.
- Current product UI must not claim verified-device identity.
- EA1 PAKE v7 is ready for external cryptographer/formal-methods review, but it
  is not wire-frozen, not specified in `PROTOCOL.md`, and not implemented.
