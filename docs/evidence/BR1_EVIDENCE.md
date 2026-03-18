# BR1 Evidence — Package + Artifact Delivery Audit

**Stream:** RUSTIFY-BROWSER-ROLLOUT-1
**Phase:** BR1 — Package + artifact delivery audit
**Date:** 2026-03-18
**Tag:** `ecosystem-v0.1.173-rustify-browser-rollout1-br1-audit`
**Type:** Engineering audit (read-only, specification phase)

---

## AC-by-AC Status

| AC | Criterion | Status |
|----|-----------|--------|
| AC-BR-01 | bolt-protocol-wasm delivery path defined | **PASS** — PM-BR-01 APPROVED: embed in @the9ines/bolt-transport-web `wasm/` directory, same pattern as existing policy WASM. |
| AC-BR-02 | Version bump plan documented | **PASS** — bolt-core 0.5.2→0.6.0 (new WASM exports), transport-web 0.6.8→0.7.0 (protocol WASM artifact + BTR factory). Ordered publish: bolt-core first, then transport-web. |
| AC-BR-03 | Build script for protocol WASM artifact exists and size-gated | **PASS (specification defined, implementation deferred to BR2).** Build/release path fully specified: `build-wasm-protocol.sh` script modeled on existing `build-wasm-policy.sh`, output to `ts/bolt-transport-web/wasm/`, 300 KiB gzipped gate per PM-RB-01. Script creation is BR2 engineering scope. |

---

## PM Decisions

| ID | Decision | Status |
|----|----------|--------|
| PM-BR-01 | WASM delivery path | **APPROVED (2026-03-18): Embedded in @the9ines/bolt-transport-web.** Protocol WASM artifact ships in the `wasm/` directory alongside existing policy WASM. Same proven pattern. No new npm package. |
| PM-BR-02 | Follow-on consumer timing | **APPROVED (2026-03-18): After localbolt-v3 burn-in.** localbolt and localbolt-app wired only after localbolt-v3 burn-in evidence collected. |

---

## Delivery Model

**Embedded in @the9ines/bolt-transport-web** (PM-BR-01 APPROVED).

Artifacts added to `ts/bolt-transport-web/wasm/`:
- `bolt_protocol_wasm_bg.wasm` (~228 KiB)
- `bolt_protocol_wasm.js` (~32 KiB, wasm-bindgen glue)
- `bolt_protocol_wasm.d.ts` (~10 KiB, TypeScript types)
- `bolt_protocol_wasm_bg.wasm.d.ts` (~3.7 KiB)

Package `files` field already includes `"wasm"` — no config change needed.

**Why this model:**
- Proven: existing policy WASM uses identical pattern
- Single install: consumers get WASM with `npm install @the9ines/bolt-transport-web`
- Relative imports: Vite resolves `import('./wasm/bolt_protocol_wasm.js')` naturally
- No new npm package to maintain

---

## Version Bump Plan

| Package | Current | Next | Reason |
|---------|---------|------|--------|
| @the9ines/bolt-core | 0.5.2 | **0.6.0** | New exports: initWasmCrypto, getWasmCrypto, createWasmBtrEngine, createWasmSendSession. crypto.ts/identity.ts/sas.ts WASM fallback logic. Minor bump (additive, non-breaking). |
| @the9ines/bolt-transport-web | 0.6.8 | **0.7.0** | Protocol WASM artifact in wasm/. createBtrAdapter factory. WasmBtrTransferAdapter. WASM init entry point. Minor bump (additive). |
| @the9ines/localbolt-core | 0.1.2 | No change | Not affected. |

**Publish order:**
1. bolt-core 0.6.0 → tag `sdk-v0.6.0` → auto-publish to GitHub Packages → manual dispatch to npmjs
2. transport-web 0.7.0 (peerDep: bolt-core ≥0.2.0, satisfied) → tag `transport-web-v0.7.0` → publish
3. localbolt-v3: update lockfile to bolt-core 0.6.0 + transport-web 0.7.0 → CI verify

---

## Build/Release Gap Summary

| Gap | Specification | Implementation (BR2) |
|-----|--------------|---------------------|
| Build script | `build-wasm-protocol.sh`: modeled on `build-wasm-policy.sh`. Uses rustup toolchain, wasm-pack, outputs to `ts/bolt-transport-web/wasm/`. Size gate: 300 KiB gzipped combined (WASM + JS). | BR2 creates the script. |
| Artifact placement | Copy from `rust/bolt-protocol-wasm/pkg/` to `ts/bolt-transport-web/wasm/`. Remove wasm-pack artifacts (.gitignore, package.json). | BR2 implements copy step in build script. |
| Dynamic import fix | Change `wasm-crypto.ts` init from bare `import("bolt-protocol-wasm")` to transport-web-relative import. Transport-web provides `initProtocolWasm()` that bolt-core's `initWasmCrypto()` calls. | BR2 implements the init path change. |
| Publish workflows | Existing workflows handle both packages. Version bump + tag triggers publish. | No workflow changes needed. |

---

## Consumer Impact Summary

| Consumer | Changes Needed | When |
|----------|---------------|------|
| **localbolt-v3** | Update package.json: bolt-core→0.6.0, transport-web→0.7.0. main.ts already wired (RB5). Verify WASM loads from published packages. | BR2 (publish) + BR4 (burn-in) |
| **localbolt** | Same version bump + add initWasmCrypto() to main.ts. | BR5 (after burn-in, PM-BR-02) |
| **localbolt-app** | Same version bump + add initWasmCrypto() to main.ts. | BR5 (after burn-in, PM-BR-02) |

---

## Verification

- No runtime files changed (audit/specification only)
- All three authoritative docs updated consistently
- No unrelated stream status drift
