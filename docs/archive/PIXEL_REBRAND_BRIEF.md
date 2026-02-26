> **ARCHIVED** — historical artifact, not active governance. Moved to docs/archive/ during DOC-GOV-1 (2026-02-26).

# LocalBolt Pixel Art Rebrand — Fiverr Artist Brief

## Project Overview

LocalBolt is an encrypted peer-to-peer file transfer tool. We're rebranding the entire visual identity to a **16-bit retro pixel art** aesthetic. The artist needs to deliver pixel art versions of our logo, app icons, UI icons, and an Open Graph image.

**Color scheme:** Dark background (#121212) with chartreuse/neon green (#A4E200) accent.

**Style:** 16-bit pixel art with a **limited color palette** (4-5 shades of green max). Detail and craftsmanship through dithering and smart shade placement, not lots of colors. Think SNES-era RPG UI icons or DOS VGA game interfaces — polished but restrained.

**Palette:**
- #A4E200 (neon green — primary)
- 2-3 darker/lighter shades of green for shading and highlights
- Depth comes from technique, not palette

---

## Deliverable 1: App Icon (Lightning Bolt)

The app icon is a **lightning bolt (zap)** shape. This is used as the app icon on every platform (macOS dock, Windows taskbar, phone home screen, etc.).

### Required Sizes (individual PNG files, RGBA, transparent background):

**Master:** 1024x1024 PNG + SVG version

**macOS:** icon.icns containing 512, 256, 128, 64, 32, 16 px

**Windows:** icon.ico containing 256, 48, 32, 16 px
Plus: Square310x310, Square284x284, Square150x150, Square142x142, Square107x107, Square89x89, Square71x71, Square44x44, Square30x30, StoreLogo 50x50

**Linux:** 512, 256, 128, 64, 32 px

**Android (Adaptive Icon):**
- ic_launcher_foreground: 48, 72, 96, 144, 192 px
- ic_launcher: 48, 72, 96, 144, 192 px
- ic_launcher_round: 48, 72, 96, 144, 192 px

**iOS:** 1024, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20 px

**Web:** apple-touch-icon (180), icon-512, icon-192, favicon.ico (32)

### Design Notes:
- Neon green (#A4E200) bolt on transparent background
- Recognizable even at 16x16 — simplify at small sizes
- The bolt is the ENTIRE icon — no text, no border, just the bolt shape

---

## Deliverable 2: UI Icons (29 icons)

All UI icons at **24x24 pixels**. Deliver as individual SVG files with pixel art rendered as rectangles/paths (not embedded PNGs). Icons should use `currentColor` for fill so we can theme them via CSS.

| # | Name | Depicts |
|---|------|---------|
| 1 | zap | Lightning bolt |
| 2 | shield | Security shield (outline) |
| 3 | shieldFilled | Security shield (filled/solid) |
| 4 | wifi | Wi-Fi signal waves |
| 5 | server | Server rack (two stacked boxes) |
| 6 | laptop | Laptop computer |
| 7 | lock | Padlock |
| 8 | globe | World/earth with grid |
| 9 | clock | Clock face with hands |
| 10 | arrowDown | Down arrow |
| 11 | share2 | Share/network (3 circles connected) |
| 12 | smartphone | Mobile phone |
| 13 | tablet | Tablet device |
| 14 | monitor | Desktop screen on stand |
| 15 | upload | Upload arrow from box |
| 16 | file | Document with folded corner |
| 17 | pause | Pause (two vertical bars) |
| 18 | play | Play (right triangle) |
| 19 | x | Close/cancel (X mark) |
| 20 | copy | Copy (two overlapping pages) |
| 21 | check | Checkmark |
| 22 | eye | Open eye (visible) |
| 23 | eyeOff | Eye with slash (hidden) |
| 24 | radio | Broadcast signal (concentric circles) |
| 25 | messageCircle | Chat/speech bubble |
| 26 | userX | Person with X (no account) |
| 27 | chevronRight | Right arrow > |
| 28 | chevronDown | Down arrow v |
| 29 | info | Circle with "i" |

### Icon Requirements:
- **Canvas:** 24x24 pixel grid
- **Style:** 16-bit technique, limited palette
- **Palette:** Neon green (#A4E200) + 2-3 shades for depth
- **Shading:** Dithering and pixel-level shade work for dimension
- **Format:** SVG (pixel art as `<rect>` or clean paths, not raster)
- **Consistency:** All icons should feel like one cohesive set
- **Anti-aliasing:** Artist's judgment — smooth where it helps

---

## Deliverable 3: Background Grid Pattern (Optional)

Subtle background texture tile:
- 32x32 SVG
- Very subtle (2% opacity white)
- Dot grid, scanline pattern, or classic pixel grid

---

## Deliverable 4: Logo Wordmark

The text "LocalBolt" rendered in pixel art style to match the icon. This is used in the app header and website.

- Horizontal layout: lightning bolt icon + "LocalBolt" text
- Neon green (#A4E200) on transparent background
- Deliver as SVG
- Should look good at ~24px tall (header size) and ~48px tall (hero size)

---

## Deliverable 5: Open Graph Image

Social sharing preview image (shows when someone shares a link to localbolt.site):

- **Size:** 1200x630 px
- **Content:** Lightning bolt logo centered, "LocalBolt" text below, dark background (#121212)
- **Style:** Match the 16-bit pixel art aesthetic
- **Format:** PNG

---

## File Delivery Format

```
delivery/
├── app-icon/
│   ├── master-1024x1024.png
│   ├── master.svg
│   ├── icon.icns          (macOS)
│   ├── icon.ico           (Windows)
│   ├── macos/             (all macOS sizes)
│   ├── windows/           (all Windows Store sizes)
│   ├── linux/             (512, 256, 128, 64, 32)
│   ├── android/
│   │   ├── mipmap-mdpi/
│   │   ├── mipmap-hdpi/
│   │   ├── mipmap-xhdpi/
│   │   ├── mipmap-xxhdpi/
│   │   └── mipmap-xxxhdpi/
│   ├── ios/               (all iOS sizes)
│   └── web/               (touch icon, PWA icons, favicon)
├── ui-icons/
│   ├── zap.svg
│   ├── shield.svg
│   ├── ... (all 29 icons)
│   └── info.svg
├── logo-wordmark.svg
├── og-image.png
└── grid-pattern.svg       (optional)
```

---

## Reference

- **Current app:** https://localbolt.site
- **GitHub:** https://github.com/the9ines/localbolt-app
- **Current color scheme:** #121212 (background), #A4E200 (accent/neon green)
- **Current icons:** Lucide icon set (stroke-based, 24x24) — see https://lucide.dev
- **Vibe:** 16-bit, SNES-era, DOS VGA, '90s computing nostalgia


---
---


# Implementation Plan — Pixel Art Rebrand

## Overview

After receiving assets from the artist, the rebrand touches three repos:
1. **localbolt-v3** (localbolt.site — marketing website + web app)
2. **localbolt** (lite/self-hosted version)
3. **localbolt-app** (Tauri native desktop app)

## Font: Fixedsys Excelsior

**License:** Public domain / free for commercial use
**Source:** https://github.com/kika/fixedsys (WOFF2 available)
**Key constraint:** Pixel fonts look best at exact multiples of their base size (8, 16, 24, 32px).

### Font Integration (all repos)

1. Download `FSEX302.woff2`
2. Add to each repo's font directory
3. Register via `@font-face` in CSS
4. Update Tailwind config:
   ```js
   fontFamily: {
     mono: ['Fixedsys Excelsior', 'monospace'],
     display: ['Fixedsys Excelsior', 'monospace'],
   }
   ```
5. Apply globally — all text uses the pixel font
6. Snap sizes to multiples of 8px for crispness

### Font Size Map
| Use | Current | Pixel |
|-----|---------|-------|
| Body text | 14-16px | 16px |
| Small/caption | 12px | 8px |
| H1/hero | 36-48px | 32px or 48px |
| H2/section | 24-30px | 24px or 32px |
| Button text | 14px | 16px |
| Icon labels | 12-14px | 16px |

## Icon Swap

### UI Icons (all repos share the same `icons.ts`)

Replace Lucide SVG paths with pixel art SVGs. Function signatures stay identical:

```typescript
// Before (Lucide)
zap: (cls = '') => svg(cls, '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/>'),

// After (pixel art)
zap: (cls = '') => svg(cls, '<path d="M13 2h2v2h-2v2h-2v2H9v2H7..."/>'),
```

The `svg()` helper and class system stay unchanged. Only inner SVG paths change.

### App Icons (native app only)

Drop-in replacement of files in `src-tauri/icons/`:
- Copy all platform icon files from the artist's delivery
- File names must match exactly (Tauri expects specific names)

### Web Assets (v3 + lite)

Replace in `public/`:
- `apple-touch-icon.png`
- `icon-192.png`, `icon-512.png` (v3 only, PWA)
- `og-image.png` (v3 only, social sharing)

### Logo Wordmark

Replace the inline SVG bolt + text in `header.ts` across all repos with the new pixel art logo wordmark.

## Repo-Specific Changes

### localbolt-v3 (website + web app)
| File | Change |
|------|--------|
| `packages/localbolt-web/src/ui/icons.ts` | Replace all SVG paths with pixel art |
| `packages/localbolt-web/src/sections/header.ts` | New logo wordmark |
| `packages/localbolt-web/src/index.css` | Add @font-face, update base sizes |
| `tailwind.config.ts` | Add Fixedsys to fontFamily |
| `packages/localbolt-web/public/` | Replace icon assets + og-image |
| All section files | Adjust text sizes to 8px multiples if needed |

### localbolt (lite/self-hosted)
| File | Change |
|------|--------|
| `web/src/ui/icons.ts` | Replace all SVG paths with pixel art |
| `web/src/sections/header.ts` | New logo wordmark |
| `web/src/index.css` | Add @font-face, update base sizes |
| `tailwind.config.ts` | Add Fixedsys to fontFamily |
| `web/public/` | Replace apple-touch-icon |

### localbolt-app (native desktop)
| File | Change |
|------|--------|
| `web/src/ui/icons.ts` | Replace all SVG paths with pixel art |
| `web/src/sections/header.ts` | New logo wordmark |
| `web/src/index.css` | Add @font-face, update base sizes |
| `web/tailwind.config.js` or similar | Add Fixedsys to fontFamily |
| `web/public/` | Replace web assets |
| `src-tauri/icons/` | Replace ALL platform icons |

## Execution Order

1. Receive assets from artist
2. **Font first** — integrate Fixedsys Excelsior across all 3 repos, verify sizing
3. **UI icons** — swap `icons.ts` paths in all 3 repos
4. **Logo** — swap header wordmark in all 3 repos
5. **App icons** — drop in platform icons for native app
6. **Web assets** — replace favicons, PWA icons, og-image
7. **QA pass** — verify every screen in all 3 apps
8. **Tag releases** — v3.0.32+, lite vX, app v1.0.1+

## Optional Enhancements (After Rebrand)

- **CRT scanline overlay** — subtle horizontal lines via CSS
- **Screen flicker on load** — CSS animation
- **Pixel cursor** — custom CSS cursor
- **Terminal boot sequence** — brief "loading" animation on app start
- **Sound effects** — retro beeps on transfer complete (native app only)
