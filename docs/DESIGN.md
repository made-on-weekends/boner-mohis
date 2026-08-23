---
version: 2.1.0
name: Filament Style System — Boner Mohis
description: Warm paper themed layout with ember orange accents, 12px base radius, Space Grotesk/DM Sans typography, and charge indicators.
colors:
  primary: "#B25409"
  secondary: "#535046"
  bg: "#F9F6F0"
  fg: "#181510"
  muted: "#756F61"
  success: "#2E7D3A"
  warning: "#B25409"
  danger: "#C22A21"
typography:
  body:
    fontFamily: "'DM Sans', sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.6
  heading:
    fontFamily: "'Space Grotesk', sans-serif"
    fontSize: "24px"
    fontWeight: 500
    lineHeight: 1.2
rounded:
  sm: "8px"
  md: "12px"
  lg: "16px"
spacing:
  1: "4px"
  2: "8px"
  3: "12px"
  4: "16px"
  6: "24px"
  8: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.sm}"
  button-primary-hover:
    backgroundColor: "{colors.warning}"
    textColor: "#FFFFFF"
  card-default:
    backgroundColor: "{colors.bg}"
    textColor: "{colors.fg}"
    rounded: "{rounded.md}"
  badge-success:
    backgroundColor: "{colors.success}"
    textColor: "#FFFFFF"
  badge-secondary:
    backgroundColor: "{colors.bg}"
    textColor: "{colors.secondary}"
  badge-muted:
    backgroundColor: "{colors.bg}"
    textColor: "{colors.muted}"
  badge-danger:
    backgroundColor: "{colors.danger}"
    textColor: "#FFFFFF"
---

# DESIGN.md — বনের মহিষ / Boner Mohis

**Brand:** Boner Mohis (Latin wordmark) · Bangla secondary: বনের মহিষ  
**Product:** Prepaid electricity meter tracker for **DESCO prepaid** users — balance, usage, low-balance warnings. Android app + Chrome extension.  
**Owner:** Adommo LLC (product line) · **Market:** Bangladesh  
**System name (internal only, never shown):** Filament  
**Version:** 2.1.0 · **Updated:** 2026-08-21

> **Changelog 2.1.0 (fresh restart — supersedes all prior locks):**
> 1. Logo locked: **Spark-line** mark + Latin **Boner Mohis** wordmark (Space Grotesk 500, outlined). New §7.5.
> 2. Wordmark hero is now **Latin** per founder decision; Bangla wordmark demoted to localized/secondary. §1, §4 updated.
> 3. Dark-mode semantic table completed — five missing tokens added, all WCAG-verified. §3.
> 4. §4.3 corrected: the name has **no conjuncts**; the real risk is matra/vowel-sign placement and the ষ glyph.
> 5. Light focus-ring contrast corrected 3.42 → **3.23** (still ≥3 UI threshold).

---

## 1. Overview

Know your DESCO prepaid balance, see usage patterns, and get warned days before the balance runs out.

**Essence:** Never surprised by an empty meter.  
**Tagline:** বাতি জ্বলতে থাকুক — *keep the lights on.*  
**Name:** বনের মহিষ / Boner Mohis — the wild buffalo. Unbothered, unhurried, impossible to catch off guard.

### Name lockup rule (v2.1)

| Surface | Form |
|---|---|
| Primary wordmark / logo, store listings, marketing | **Boner Mohis** — Latin, Space Grotesk 500 (the locked hero) |
| Bangla surfaces / localized headings | **বনের মহিষ** — Baloo Da 2, secondary/localized wordmark |
| App UI copy | Bangla-first per §9 (the logo is Latin; the interface is Bangla) |
| Domain / package / handles | `bonermohis.com` |
| Spoken | Bangla pronunciation always |

### Data source — DESCO prepaid; design supports both states

DESCO prepaid has no confirmed public balance API, and Play Store restricts SMS-reading permissions — so the product is **manual-entry-first**, with an optional linked/portal-derived sync as a second-class enhancement. Both states appear in every balance surface:
- `as of 9:12pm · synced`
- `as of 9:12pm · manual entry`

The design must **never imply official DESCO affiliation** (see §10, §12).

---

## 2. Design principles

1. **Glanceable first.** Days remaining and the charge bar read across a room.
2. **Calm, never alarmist.** The product reduces meter anxiety.
3. **Numbers are sacred.** Balance, units, taka in mono, generously sized, always with a freshness timestamp *and its source*.
4. **Ember means attention, calmly.** The accent doubles as the low-balance state.
5. **Warm domestic light.** Never cold black glass; dark mode is first-class.

---

## 3. Color

Ember on warm soot neutrals. **All pairings WCAG 2.1 AA verified computationally.**

### Neutral — soot
| Token | Hex |
|---|---|
| soot-50 | `#F9F6F0` |
| soot-100 | `#F1EDE4` |
| soot-200 | `#E2DCCF` |
| soot-300 | `#C9C2B1` |
| soot-400 | `#9E9787` |
| soot-500 | `#756F61` |
| soot-600 | `#535046` |
| soot-700 | `#38352E` |
| soot-800 | `#232019` |
| soot-900 | `#181510` |
| soot-950 | `#131210` *(dark sunken fill)* |

### Signal — ember
| Token | Hex |
|---|---|
| ember-300 | `#F5A96B` |
| ember-400 | `#E88540` |
| ember-500 | `#D96A14` |
| ember-600 | `#B25409` |
| ember-700 | `#8A4108` |

### Semantic — light (on bg `#F9F6F0`)
| Role | Hex | Contrast |
|---|---|---|
| background | `#F9F6F0` | — |
| surface | `#FFFFFF` | — |
| surface-sunken | `#F1EDE4` | — |
| text | `#181510` | 16.50:1 |
| text-secondary | `#535046` | 7.18:1 |
| text-muted | `#756F61` | 4.60:1 |
| border | `#E2DCCF` | — |
| border-strong (inputs) | `#9E9787` | 3.12:1 |
| accent / low tier | `#B25409` | 4.88:1 |
| accent-hover | `#8A4108` | — |
| focus ring | `#D96A14` | **3.23:1** (UI threshold ≥3) |
| text-on-accent | `#FFFFFF` | 5.04:1 on accent |
| ok tier | `#2E7D3A` | 4.74:1 |
| critical tier | `#C22A21` | 5.34:1 |

### Semantic — dark, first-class (on bg `#181510`) — **completed v2.1**
| Role | Hex | Contrast | Note |
|---|---|---|---|
| background | `#181510` | — | warm dark, never black glass |
| surface | `#232019` | — | |
| surface-sunken | `#131210` | — | subtle inset fill |
| text | `#EFEBE2` | 15.30:1 | |
| text-secondary | `#C9C2B1` | 10.26:1 | |
| text-muted | `#9E9787` | 6.27:1 | |
| border | `#38352E` | — | hairlines only |
| border-strong (inputs) | `#9E9787` | 6.27 / 5.60:1 | use as input outline |
| accent / low tier | `#E88540` | 6.81:1 | |
| accent-hover | `#F5A96B` | — | fill; pairs with `#181510` label (9.34:1) |
| focus ring | `#D96A14` | 5.22 / 4.66:1 | verified on bg + surface |
| **text-on-accent** | `#181510` | **6.81:1** | critical. White on ember-400 is 2.67:1 and fails; labels on a dark-mode ember fill MUST be soot-900 |
| ok tier | `#6FBF7C` | 8.17:1 | |
| critical tier | `#F0736A` | 6.38:1 | |

### Rules
- **No separate warning colour.** Ember *is* the warning. Tiers: **ok green · low ember · critical red.**
- Accent appears on primary actions, links, and the low-balance state.
- No gradients. Never pure white or pure black backgrounds. No neon.

---

## 4. Typography — bilingual

| Role | Family | Usage |
|---|---|---|
| **Latin wordmark / logo** | **Space Grotesk** (Medium 500) | The hero wordmark "Boner Mohis" — outlined in the logo files |
| Latin display / balance figure | **Space Grotesk** (Medium) | Hero balance number, Latin headings |
| Latin body / UI | **DM Sans** | Latin interface text |
| **Bangla display / secondary wordmark** | **Baloo Da 2** | বনের মহিষ (localized), Bangla headings |
| **Bangla body / UI** | **Noto Sans Bengali** | All Bangla interface text |
| Mono | **DM Mono** | Units, taka, timestamps, logs |

All SIL OFL, bundled in-app. **Type scale:** 13 / 15 / 17 / 21 / 26 / 32 / 44 px. Radius **12px**.

### Bilingual rules (locked)
1. **Latin numerals always** for balance, units, taka, timestamps — DM Mono, even inside Bangla UI.
2. **Bangla needs its own leading** — ~+0.15 line-height over the Latin equivalent.
3. **Glyph check before lock:** বনের মহিষ contains **no conjuncts**. Real rendering risks are matra / vowel-sign placement and the ষ glyph.
4. Mixed-script data lines always use the Latin numeral form.

---

## 5. Space, shape, elevation

| Property | Value |
|---|---|
| Spacing grid | 8px — 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 |
| Corner radius | **12px** base · 8px small · 999px pill |
| Border width | 1px |
| Shadow | `0 2px 8px rgba(24,21,16,0.08)` — home balance card only |
| Content max-width | 480px app · 1040px marketing |
| Breakpoints | 640 / 900 / 1200 px |
| Touch target min | **48px** |
| Density | Roomy throughout |

---

## 6. Component library specification

Foundations, primitives, composites, navigation/shell, domain components, states.
The freshness row — timestamp + `synced`/`manual entry` in mono — appears under every balance figure.

---

## 7. Signature element — the charge bar (in-app UI)

A segmented horizontal level indicator: filled segments solid, the active segment glowing ember, remaining segments hollow outlines. **Permitted uses:** the balance display, state indicators, the loading motif.

**Never style it to resemble a phone battery icon** — banned.  
**Note (v2.1):** the in-app charge bar is distinct from the brand **spark-line mark** (§7.5); they share the ember accent but are different objects.

---

## 7.5 Logo — LOCKED (v2.1) · "Spark-line"

**Mark:** a spark-**line** — a minimal usage sparkline whose leading point is a solid **ember disc**. It reads as *usage trend + your live balance, glowing*: the graph is the mark, the ember is the signal. No battery, no bolt, no house.

**Geometry (100 viewBox):**
- Full (≥48px): polyline `M14 56 L38 46 L62 52 L86 32`, stroke-width 6, round caps; ember `circle cx86 cy32 r7`.
- Compact (≤32px, favicon/toolbar): `M14 56 L50 44 L86 30`, stroke-width 9; ember `r11`.

**Wordmark:** "Boner Mohis" in **Space Grotesk 500, outlined to vector paths** (no live text in any logo file).

**Colour:**
- Light: stroke soot-900 `#181510`, ember ember-600 `#B25409`.
- Dark: stroke `#EFEBE2`, ember ember-400 `#E88540`.
- Mono fallback: stroke + ember both `currentColor`.

**State mechanic:** the ember disc *is* the state signal. Recolour it **ok `#6FBF7C` · low ember · critical `#F0736A`** (dark) / `#2E7D3A · ember · #C22A21` (light) for the extension toolbar icon — one glyph, three states.

---

## 8. Iconography

Lucide-style rounded 1.5px stroke. Domain glyphs: meter, bolt (recharge), bell, home/shop, sync. **Banned:** neon bolts, 3D houses, smart-home renders, **battery icons**.

---

## 9. Voice & tone

Bangla-first UI, domestic-warm, brief. Sentence case. No exclamation marks.

**Notification grammar (locked):**
`[Meter name]: ~[N] days left ([units] units). Recharge when convenient.`  
Critical tier drops "when convenient" and adds nothing panicked.

---

## 10. Content conventions

Bangla UI copy with Latin numerals. Realistic data only. **No invented accuracy claims, no fake user counts, no implied affiliation with DESCO or any utility.** No lorem ipsum.

---

## 11. Accessibility

- All pairings meet WCAG 2.1 AA (§3, computationally verified).
- Focus always visible: 2px `#D96A14` ring, 2px offset — verified in **both** modes.
- Touch targets ≥48px.
- State tiers pair colour with a text label — never colour alone.

---

## 12. Compliance notes

- **Play Store SMS policy:** manual-entry-first; functions fully without SMS permissions.
- **Credential handling:** any linked sync states plainly what is stored and where.
- **No ads, ever.**
- **No implied DESCO affiliation** anywhere in mark, copy, or store listing.
