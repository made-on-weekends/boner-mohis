# BRAND.md

> Identity layer: voice, naming, logo, positioning. Token values live in `DESIGN.md`.

## Positioning

Boner Mohis is the prepaid electricity balance forecaster for residential tenants who want clear, proactive credit depletion visibility to avoid running out of power, unlike official utility apps that lack forecasting, alerts, and offline simulation.

## Voice

The voice is **direct**, **technical**, and **calm**. Because power depletion is a stressful event, the application does not use sensationalist or alarmist language, but provides clear, grounded, mathematical predictions.

### Voice rules

**Do:**
- Lead with actionable metrics (e.g. "2.4 days remaining") and explain the consumption base second.
- Provide exact numbers or clear "--" indications when data is insufficient.
- Use friendly, precise phrasing for error messages (e.g., "Failed to sync with live API").

**Don't:**
- Don't use exclamation points or urgent formatting for warnings.
- Don't use marketing superlatives ("amazing", "revolutionary").
- Don't say "simply" or "just" when instructing the user.

### Voice examples

- ✅ "Forecast remaining: 1.5 days"
- ❌ "WARNING!!! Your balance is extremely low! Recharge now!!!"

## Brand-defining color choices

Brand colors reflect warmth and clarity. Color values live in `docs/DESIGN.md`:

- Primary brand color: `--accent` / Ember Orange (represents warning state, main logo fill, and primary buttons)
- Base body color: `--text-primary` / Warm Charcoal
- Background: `--bg-color` / Warm Paper

## Brand-defining typography choices

Typeface properties live in `docs/DESIGN.md`.

- Primary wordmark typeface: `Space Grotesk 500` (Google Fonts) — Latin hero wordmark "Boner Mohis".
- Secondary wordmark typeface: `Baloo Da 2` (Google Fonts) — Bangla localized wordmark "বনের মহিষ".
- Body typeface: `DM Sans` (Latin) / `Noto Sans Bengali` (Bangla).
- Mono typeface: `DM Mono` — mandatory for all numerals (balance, units, taka, timestamps) even on Bangla UI.

## Logo and marks

The locked brand logo is the **Spark-line** (§7.5):
- Concept: A minimal usage sparkline whose leading point is a glowing ember disc (`M14 56 L38 46 L62 52 L86 32`, stroke width 6, circle `r: 7` at `cx: 86, cy: 32`).
- Compact variant (toolbar/favicon): `M14 56 L50 44 L86 30`, stroke width 9, circle `r: 11` at `cx: 86, cy: 30`.
- Color: Light (`#181510` stroke, `#B25409` ember), Dark (`#EFEBE2` stroke, `#E88540` ember). State mechanic recolours the disc for OK (`#6FBF7C`), Low (`#E88540`), Critical (`#F0736A`).
- Banned: Battery icons, neon bolts, 3D houses.

## Naming

- Primary wordmark / hero: **Boner Mohis** (Latin)
- Secondary / localized wordmark: **বনের মহিষ** (Bangla)
- Subtitle: **Electricity forecaster** (also referred to as "Prepaid Electricity Meter Genius" in the extension header)
- Historic note: Named **Batti** from 2026-07-08 to 2026-07-09 before reverting back to the original name per user feedback.

## Domain vocabulary

Consistent vocabulary terms used across code and interface:
- **Balance**: Prepaid credit remaining (always in BDT/৳).
- **Yesterday Usage**: Consumption cost incurred on the previous calendar day.
- **Slab / Tier**: Progressive billing ranges defined by BPDB regulations.
- **Top Up / Recharge**: Adding credit to the meter balance.
