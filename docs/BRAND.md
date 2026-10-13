# BRAND.md

> Identity layer: voice, naming, logo, positioning. Token values live in `DESIGN.md`.

## Positioning

Boner Mohis (বনের মহিষ) is the local-first utility tracker for DESCO prepaid electricity consumers in Bangladesh who want clear, uncompromised visibility into their balance and slab costs without trusting third-party servers.

## Voice

Calm, utilitarian, authentic, reliable, and unadorned.

### Voice rules

**Do:**
- Speak in plain, clear language in both Bangla and English.
- Use Latin numerals (`DM Mono`) for all financial, unit, and date data lines.
- State facts directly: current balance, units remaining, slab tier, and last updated time.
- Provide practical guidance when balance is low.

**Don't:**
- Don't use marketing fluff or artificial urgency ("Recharge immediately or you will be disconnected!").
- Don't use battery icons, neon lightning bolts, or 3D cartoon house renders.
- Don't use exclamation marks in product notices.

### Voice by context

- **Mobile App**: Terse, neutral, informative. Data-dense cards with clear visual hierarchy.
- **Browser Extension**: Minimalist glanceable status. The toolbar ember conveys health state at a glance.
- **Error States**: Clear, technical explanation without assigning blame (e.g., "DESCO server did not respond. Showing cached balance from 2 hours ago.").

## Brand-defining color choices

Values live in `docs/DESIGN.md` — semantic names are documented here:

- **Ember (Primary Accent)**: `--color-accent` (`#AE5105` light / `#E88540` dark). Represents the warm, glowing filament.
- **Warm Paper (Background)**: `--color-background` (`#F9F6F0`). High-legibility unbleached paper ground.
- **Soot (Dark Background & Ink)**: `--color-dark-background` (`#181510`). Deep charcoal ground for dark mode.
- **Status Signal Ember**:
  - `ok`: Green (`#2C7B38` light / `#6FBF7C` dark)
  - `low`: Ember Orange (`#AE5105` light / `#E88540` dark)
  - `critical`: Red (`#C22A21` light / `#F0736A` dark)

## Brand-defining typography choices

- **Display & Headings**: Space Grotesk (Latin) / Hind Siliguri (Bangla)
- **Body UI**: DM Sans (Latin)
- **Data & Numerals**: DM Mono (Latin numerals always for balances, units, timestamps, and account numbers)

### Bilingual Typography Rules

1. **Latin numerals always**: Balance, units, taka, timestamps, and mixed-script data lines strictly use the Latin numeral form in DM Mono — even inside otherwise Bangla UI.
2. **Bangla leading adjustment**: Bangla text requires roughly **+0.15** line-height over the Latin equivalent to avoid collisions between matra and vowel markers.

## Logo and marks

- **The Locked Mark**: Represents the horned buffalo silhouette fused with an electrical filament.
- **Toolbar Ember State**: A single glyph drawing whose inner disc changes color depending on account health (`ok`, `low`, `critical`). Never introduce a secondary glyph.
- **Two-Scale Mark**: Full mark at ≥48px (`stroke: 6, ember r7`); compact cut at ≤32px (`stroke: 9, ember r11`).
- **No Banned Iconography**: Never substitute the mark with a generic battery gauge or lightning bolt.

## Naming

- **Product Name**: Boner Mohis (বনের মহিষ)
- **Publisher / Organization**: made-on-weekends
- **Distributor Reference**: DESCO (Dhaka Electric Supply Company Limited)

## Domain vocabulary

- Use **Account No** (হিসাব নম্বর) and **Meter No** (মিটার নম্বর).
- Use **Balance** (ব্যালেন্স) with the Taka currency sign (`৳`).
- Use **Slab** (ট্যারিফ ধাপ) to refer to BERC progressive residential tariff brackets.
- Use **kWh** or **Unit** (ইউনিট) for electricity volume.
