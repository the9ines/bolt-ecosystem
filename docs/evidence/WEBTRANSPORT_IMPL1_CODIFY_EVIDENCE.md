# WEBTRANSPORT-BROWSER-APP-IMPL-1 Codification Evidence

**Stream:** WEBTRANSPORT-BROWSER-APP-IMPL-1
**Date:** 2026-03-20
**Tag:** `ecosystem-v0.1.194-webtransport-impl1-codify`
**Type:** Governance (stream codification)

---

## Stream Definition

**Purpose:** Implement browser↔app WebTransport over HTTP/3. Implementation successor to WEBTRANSPORT-BROWSER-APP-1 governance (20 ACs, 5 PM decisions, all locked).

**What this is:** WebTransport over HTTP/3 between browser client and daemon endpoint. Requires a server/app endpoint. Not peer-to-peer.

**What this is not:** Raw QUIC in the browser. Replacement for browser↔browser WebRTC (G1 preserved). Universal browser solution (Safari/WebKit does not support WebTransport).

---

## Codification Checklist

| Item | Status |
|------|--------|
| Stream ID assigned | WEBTRANSPORT-BROWSER-APP-IMPL-1 |
| Phases defined (WTI1–WTI6) | 6 phases |
| ACs defined (AC-WTI-01–23) | 23 ACs |
| PM decisions identified (PM-WTI-01–02) | 2 decisions |
| Predecessor relationship documented | WEBTRANSPORT-BROWSER-APP-1 (governance), LOCALBOLT-PERF-1 (context), RUSTIFY-CORE-1 (foundation) |
| Browser support matrix explicit | Chrome/Edge 97+, Firefox 115+ primary. Safari N/A — fallback. |
| Non-goals documented (WTI-NG1–5) | 5 non-goals |
| Risk register (WTI-R1–5) | 5 risks |
| Tag naming rules added | daemon, SDK, governance formats |
| Forward backlog entry added | Item 23 |
| Stream summary row added | In stream summary table |
| Routing entry added | bolt-daemon + bolt-core-sdk + bolt-ecosystem |
| Governance constraints carried forward | PM-WT-01–05, WT-G1–G8, RB-L5 |

---

## Topology Distinction

| Path | Transport | This Stream? |
|------|-----------|-------------|
| browser↔browser | WebRTC DataChannel | NO — G1 preserved, unchanged |
| browser↔app | WebTransport over HTTP/3 (new), WS fallback, WebRTC fallback | YES |
| app↔app | QUIC/quinn (RC3 DONE) | NO — already operational |

LOCALBOLT-PERF-1 measured browser↔browser WebRTC at ~47 Mbps. That result is not comparable to this stream's browser↔app WT path — different topology, different transport. AC-WTI-19 and AC-WTI-21 explicitly scope measurement to the browser↔app path only.
