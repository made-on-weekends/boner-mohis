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

- Heading typeface: `Space Grotesk` (Google Fonts) — carries a geometric, modern utility feel.
- Body typeface: `DM Sans` (Google Fonts) — clean, highly readable sans-serif.
- Mono typeface: `DM Mono` (Google Fonts) — used for currency and tabular logs.

## Logo and marks

The logo is a custom bolt design:
- File / Code: Inline SVG defined in `App.jsx` (line 337) and `MainActivity.kt`.
- Color: Filled with `var(--accent)` (Ember Orange).

## Naming

- Product name: **Boner Mohis**
- Subtitle: **Electricity forecaster** (also referred to as "Prepaid Electricity Meter Genius" in the extension header)
- Historic note: Named **Batti** from 2026-07-08 to 2026-07-09 before reverting back to the original name per user feedback.

## Domain vocabulary

Consistent vocabulary terms used across code and interface:
- **Balance**: Prepaid credit remaining (always in BDT/৳).
- **Yesterday Usage**: Consumption cost incurred on the previous calendar day.
- **Slab / Tier**: Progressive billing ranges defined by BPDB regulations.
- **Top Up / Recharge**: Adding credit to the meter balance.
