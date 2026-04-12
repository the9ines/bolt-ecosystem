# ADR-001: Native App Architecture — Rust-First, Tauri Deprecated

**Status:** SUPERSEDED (2026-04-12). Desktop path updated: platform-native shells for all platforms.
**Original Status:** PROPOSED (2026-03-22)
**Supersedes:** Tauri v2 WebView architecture in localbolt-app
**Superseded by:** Platform-native shell architecture (macOS SwiftUI shell shipping v2.0.0 in localbolt-app)
**Builds on:** EGUI-NATIVE-1 (CLOSED), RUSTIFY-CORE-1 (CLOSED), bolt-ui crate (delivered)
**Defers to PM:** MOB-RUNTIME1 (mobile runtime)

> **Supersession Note (2026-04-12):** This ADR's core principle — Rust-first with shared `bolt-app-core` — remains valid. What changed: egui is no longer the forward desktop path. The macOS SwiftUI native shell (`localbolt-app/native/macos/`) shipped v2.0.0 with full transfer vertical, proving that platform-native shells are viable and preferred for desktop too. The forward architecture is now platform-native shells for ALL platforms (macOS: SwiftUI, Linux/Windows: TBD, iOS: SwiftUI, Android: Kotlin/Compose), with shared Rust core and daemon as protocol authority. `bolt-ui` (egui) is historical — it served as interim desktop replacement for Tauri but has been superseded. Option B's concern about "unsustainable engineering cost" of platform-native desktop was disproven by the macOS shell shipping successfully.

---

## Decision

Adopt a **Rust-first native app architecture** across all platforms:

| Platform | UI Layer | Rust Core | Status |
|----------|----------|-----------|--------|
| **Desktop (macOS)** | SwiftUI native shell (localbolt-app) | bolt-core via Rust FFI + bolt-daemon sidecar | **Shipping (v2.0.0)** |
| **Desktop (Linux/Windows)** | TBD native shell | bolt-core + bolt-daemon | Planned (egui historical, not default) |
| **iPhone/iPad** | SwiftUI thin shell | Rust core via FFI (UniFFI or C ABI) | Planned |
| **Android** | Kotlin/Compose thin shell | Rust core via JNI/FFI | Planned |
| **Browser** | React/TypeScript | bolt-core WASM + bolt-transport-web | Shipped (retained) |
| **Desktop (historical)** | ~~egui (bolt-ui)~~ | ~~bolt-core + bolt-daemon IPC~~ | Historical (EGUI-NATIVE-1). Superseded. |

**Tauri and egui are both retired for desktop.** The forward desktop path is platform-native shells. macOS shipped as SwiftUI shell (localbolt-app v2.0.0). Linux and Windows shells are TBD — egui is not the default for those platforms. The shared Rust core (`bolt-app-core`) and daemon remain the protocol authority across all platforms.

---

## Options Analyzed

### Option A: egui Desktop + SwiftUI/Kotlin Mobile + Rust Core (ORIGINALLY RECOMMENDED — SUPERSEDED)

> **Note (2026-04-12):** This option was originally recommended and implemented (EGUI-NATIVE-1). It has since been superseded: macOS desktop now uses a SwiftUI native shell (localbolt-app v2.0.0) instead of egui. The analysis below is retained for historical accuracy.

**Architecture:**
- Desktop: egui via eframe (bolt-ui, already built)
- iOS: SwiftUI thin shell → Rust core via FFI
- Android: Kotlin/Compose thin shell → Rust core via FFI
- Shared: bolt-core, bolt-daemon IPC, transfer SM, session logic — all Rust

**Strengths:**
- Desktop is already built and proven (EGUI-NATIVE-1 CLOSED)
- Mobile shells use platform-native UI frameworks — best UX quality on each platform
- Platform permissions, file pickers, share sheet, backgrounding handled natively
- Rust core is shared across ALL platforms (~80% code reuse)
- SwiftUI and Kotlin/Compose are the officially supported, long-lived UI frameworks
- Mobile app store compliance is straightforward with native shells
- Optionality preserved: if egui mobile matures, shells can thin further

**Weaknesses:**
- Three UI implementations to maintain (egui + SwiftUI + Kotlin)
- FFI boundary requires UniFFI or manual C ABI bindings
- Mobile shells require platform expertise (Swift, Kotlin)

**Verdict:** Best balance of product quality, engineering effort, and long-term maintainability. **Recommended.**

### Option B: SwiftUI macOS + Separate Native Shells + Rust Core

**Architecture:**
- macOS: SwiftUI
- Windows: WinUI or WPF
- Linux: GTK4
- iOS: SwiftUI
- Android: Kotlin/Compose
- Shared: Rust core via FFI

**Strengths:**
- Pixel-perfect platform-native UX on every platform
- Best OS integration (menu bar, notifications, system dialogs)
- SwiftUI on macOS + iOS shares significant code

**Weaknesses:**
- **Four separate UI implementations** (SwiftUI, WinUI, GTK, Kotlin) — massive maintenance burden
- Throws away the working egui desktop (EGUI-NATIVE-1 wasted)
- No path to UI unification
- Requires 4 platform specialists instead of 1 Rust developer
- Windows and Linux shells are particularly expensive for the team size

**Verdict:** Best UX quality but **unsustainable engineering cost**. Rejected for a small team.

### Option C: egui Everywhere Including Mobile

**Architecture:**
- Desktop: egui (bolt-ui)
- iOS: egui via eframe (Winit + Metal backend)
- Android: egui via eframe (Winit + OpenGL/Vulkan backend)
- Shared: Rust core + Rust UI = single codebase

**Strengths:**
- Single codebase for all platforms
- Maximum code reuse
- One language, one toolchain
- If it works, lowest total engineering cost

**Weaknesses:**
- egui mobile is **experimental** — Winit mobile backends are unstable
- No native platform integration (file pickers, share sheet, permissions, backgrounding)
- Touch UX with egui is poor — designed for mouse/keyboard
- App store compliance uncertain (custom rendering, no native accessibility)
- EGUI-WASM-1 already failed in browser (1.3 MiB, 26% reuse) — signals egui portability limits
- PM-EN-05 (mobile egui) is PENDING, not approved

**Verdict:** Appealing in theory but **premature for mobile**. egui mobile is not production-ready. If it matures, Option A's thin shells can be replaced incrementally. Rejected as primary strategy; preserved as future option.

### Option D: egui Everywhere Including Website

**Architecture:**
- All platforms including browser via egui + WASM

**Strengths:**
- True single-codebase nirvana

**Weaknesses:**
- **Already rejected.** EGUI-WASM-1 PoC measured 1,296 KiB gzipped (2.6× over 500 KiB kill threshold), 26% presentation reuse, 20× bundle regression vs current 65 KiB app. Stream ABANDONED (2026-03-17).
- Browser egui fundamentally doesn't fit: canvas rendering breaks accessibility, SEO, browser dev tools, and standard web patterns.

**Verdict:** Dead. Evidence-based kill from EGUI-WASM-1. Not reconsidered.

---

## Rust-Core Boundary

### Shared Rust (all platforms)

| Layer | Crate | Contents |
|-------|-------|----------|
| Protocol | bolt-core | Crypto, encoding, session, capabilities, SAS, identity |
| Transfer | bolt-transfer-core | Transfer state machine, chunk processing, hash verification |
| Ratchet | bolt-btr | Bolt Transfer Ratchet (per-transfer DH + chain encryption) |
| App logic | bolt-app-core (NEW) | Connection state machine, peer discovery model, transfer orchestration, app-level events. Shared view-model layer. |
| Daemon IPC | bolt-daemon (existing) | IPC client, daemon lifecycle, trust management |
| Desktop UI | bolt-ui (existing) | egui screens, theme, eframe app shell |

**bolt-app-core** is the key new crate. It extracts the app-level state machine and orchestration logic that currently lives in localbolt-app's Tauri commands and IPC bridge into a shared, transport-agnostic Rust layer. This is the boundary that mobile shells call via FFI.

### Platform-Native Shells (NOT shared)

| Concern | Why Native |
|---------|-----------|
| Platform permissions (camera, files, network) | OS-specific APIs, app store requirements |
| App lifecycle (backgrounding, suspend, resume) | Fundamentally different per OS |
| File picker / share sheet | Platform UI components, not renderable by egui |
| Push notifications | APNs (iOS), FCM (Android), platform-specific |
| System tray / menu bar | macOS: NSStatusItem, Windows: system tray, Linux: varies |
| Deep links / URL schemes | Platform registration + handling |

### FFI Boundary

Mobile shells call into Rust via:
- **iOS:** UniFFI-generated Swift bindings (recommended) or raw C ABI via `cbindgen`
- **Android:** UniFFI-generated Kotlin bindings (recommended) or JNI via `jni` crate

UniFFI is the recommended approach: it generates idiomatic Swift/Kotlin bindings from Rust interface definitions, handles memory management, and is maintained by Mozilla (battle-tested in Firefox).

---

## Migration Plan

> **Note (2026-04-12):** This migration plan was written when egui was the desktop target. Phase 0 (bolt-app-core extraction) completed and remains valid — the shared core is used by all shells. Phases 1 and 4 (egui desktop packaging, Tauri removal) are superseded — the macOS forward path is now the SwiftUI native shell in localbolt-app. Phases 2 and 3 (iOS/Android native shells) remain valid and planned.

### Phase 0: Extract bolt-app-core (DONE)

Extract shared app logic from localbolt-app's Tauri backend into a new `bolt-app-core` crate:
- Connection state machine (connect, pair, transfer, disconnect)
- Peer discovery model
- Transfer orchestration (send/receive/progress/cancel)
- App-level event types
- Daemon IPC client abstraction

This crate becomes the shared foundation that all platform shells (SwiftUI, Kotlin, future native shells) depend on.

**Milestone:** bolt-ui refactored to use bolt-app-core instead of direct daemon IPC.

### Phase 1: Desktop Packaging (SUPERSEDED)

> **Superseded (2026-04-12):** Originally planned as egui packaging to replace Tauri. The actual desktop path became the SwiftUI native shell in localbolt-app (shipping v2.0.0 as DMG). egui packaging (NATIVE-DESKTOP-PKG-1) completed historically but the egui shell itself is now superseded.

### Phase 2: iOS Shell

Create SwiftUI thin shell for iPhone/iPad:
- New repo: `localbolt-ios` (or subdirectory of localbolt-app)
- SwiftUI views calling bolt-app-core via UniFFI
- Native: file picker, share sheet, backgrounding, push notifications
- Xcode project + Swift Package Manager for Rust dependency

**Milestone:** App Store-submittable iOS app with peer discovery + file transfer.

### Phase 3: Android Shell

Create Kotlin/Compose thin shell for Android:
- New repo: `localbolt-android` (or subdirectory of localbolt-app)
- Compose UI calling bolt-app-core via UniFFI/JNI
- Native: file picker, share intent, background service, FCM
- Gradle project + Rust cross-compilation via `cargo-ndk`

**Milestone:** Play Store-submittable Android app.

### Phase 4: Tauri Deprecation (COMPLETE)

Tauri is retired across all platforms. PM-EN-03 rollback window is CLOSED.

### Future Option: egui Mobile (DEFERRED — NOT DEFAULT)

> **Note (2026-04-12):** egui mobile (EGUI-MOBILE-1) was a deferred proposal. Given that the desktop path has moved to platform-native shells, egui mobile is no longer the default mobile strategy. Platform-native shells (SwiftUI for iOS, Kotlin/Compose for Android) are the forward direction. egui may be revisited only if explicitly reopened by governance.

This is NOT a commitment — it preserves optionality.

---

## Repo Strategy

**Recommendation:** Evolve `localbolt-app` + create new mobile repos.

| Repo | Role | Action |
|------|------|--------|
| **localbolt-app** | Desktop app | Evolve: replace Tauri with egui packaging. Keep repo name. |
| **localbolt-ios** | iOS app | **New repo.** SwiftUI + UniFFI + bolt-app-core. |
| **localbolt-android** | Android app | **New repo.** Kotlin/Compose + UniFFI + bolt-app-core. |
| **bolt-core-sdk** | Shared Rust crates | Add `bolt-app-core` to workspace. bolt-ui already here. |
| **bolt-daemon** | Daemon binary | Unchanged. Mobile apps embed daemon or use IPC. |

**Why separate mobile repos:**
- Xcode and Gradle project structures don't mix well with Cargo workspaces
- App store signing, provisioning, and CI are platform-specific
- Mobile repos have different release cadences than desktop
- Clean separation of platform concerns

**Why NOT a monorepo:**
- Existing multi-repo structure is deliberate (ARCHITECTURE.md)
- Mobile repos need platform-specific CI (Xcode Cloud, GitHub Actions with Android SDK)
- Rust core is shared via path/git dependencies, not monorepo coupling

---

## Proposed Execution Streams

### NATIVE-APP-CORE-1: Shared App Logic Extraction

**Scope:** Extract `bolt-app-core` crate from localbolt-app Tauri backend. Shared connection SM, peer discovery, transfer orchestration, event types. Refactor bolt-ui to use it.

**Phases:**
- NAC1: Audit current Tauri backend, define crate boundary
- NAC2: Create bolt-app-core crate, extract logic
- NAC3: Refactor bolt-ui to use bolt-app-core
- NAC4: Validation + closure

**Outcome:** Shared Rust app-logic crate ready for desktop, iOS, and Android consumers.

### NATIVE-DESKTOP-PKG-1: Desktop egui Packaging

**Scope:** Replace Tauri build with egui-only packaging in localbolt-app. Platform installers (DMG, MSI, AppImage). Close Tauri dependency.

**Phases:**
- NDP1: Packaging scaffold (cargo-bundle or equivalent)
- NDP2: Platform installer generation + smoke test
- NDP3: Tauri removal + rollback window closure (requires PM-EN-03 sign-off)

**Outcome:** localbolt-app ships as native egui binary. No WebView.

### NATIVE-IOS-1: iOS App

**Scope:** SwiftUI thin shell + UniFFI bindings + bolt-app-core integration. Create localbolt-ios repo.

**Phases:**
- NI1: UniFFI scaffold + bolt-app-core Swift bindings
- NI2: SwiftUI launcher + peer discovery screen
- NI3: Transfer screen + file picker + share sheet
- NI4: App Store packaging + TestFlight

**Outcome:** Submittable iOS app.

### NATIVE-ANDROID-1: Android App

**Scope:** Kotlin/Compose thin shell + UniFFI/JNI bindings + bolt-app-core integration. Create localbolt-android repo.

**Phases:**
- NA1: UniFFI scaffold + bolt-app-core Kotlin bindings
- NA2: Compose launcher + peer discovery screen
- NA3: Transfer screen + file picker + share intent
- NA4: Play Store packaging + internal testing

**Outcome:** Submittable Android app.

---

## Execution Order

```
NATIVE-APP-CORE-1  ←── must come first (shared foundation)
    ↓
NATIVE-DESKTOP-PKG-1  ←── can start after NAC3 (bolt-ui refactored)
    ↓
NATIVE-IOS-1  ←── can start after NAC2 (bolt-app-core exists)
    ↓
NATIVE-ANDROID-1  ←── can start after NAC2, parallel with iOS
```

NATIVE-IOS-1 and NATIVE-ANDROID-1 can run in parallel once bolt-app-core is extracted.

---

## Major Risks and Tradeoffs

| Risk | Severity | Mitigation |
|------|----------|------------|
| UniFFI complexity / learning curve | MEDIUM | Mozilla-maintained, well-documented. Firefox uses it. Start with minimal surface area. |
| egui desktop UX limitations (no native dialogs) | LOW | bolt-ui already shipped and working (EN3). Platform dialogs via `rfd` crate. |
| Mobile Rust cross-compilation | MEDIUM | cargo-ndk (Android) and cargo-lipo (iOS) are mature. CI templates exist. |
| Three UI codebases to maintain | HIGH | Mitigated by thin shells — 80%+ logic in shared Rust. Shells are ~500-1000 lines each. |
| Tauri deprecation risk (rollback needed) | LOW | PM-EN-03 condition-gated. Dual-path maintained until explicit PM closure. |
| App store rejection (custom rendering on desktop) | NONE | Only mobile uses native UI frameworks. Desktop has no app store gate. |

---

## Relationship to Existing Decisions

| Decision | Relationship |
|----------|-------------|
| PM-EN-01 (egui for desktop) | **Confirmed and extended.** egui remains desktop UI. |
| PM-EN-03 (rollback window) | **Unchanged.** Tauri retained until PM closes window. |
| PM-EN-05 (mobile egui) | **Deferred.** This ADR uses native mobile shells. If PM-EN-05 later approves egui mobile, shells can thin. |
| EGUI-WASM-1 (browser egui) | **Dead.** Browser retains React/TS. Not revisited. |
| PLAT-CORE1 | **Superseded.** bolt-app-core fulfills the shared-core vision. |
| MOB-RUNTIME1 | **Partially addressed.** This ADR defines mobile runtime architecture. MOB-RUNTIME1 stream may still codify platform-specific details. |
