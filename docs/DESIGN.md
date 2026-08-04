---
version: alpha
name: Filament Style System
description: Warm paper themed layout with ember orange accents, 1px/1.5px borders, Space Grotesk/DM Sans typography, and charge indicators.
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
    backgroundColor: "#8A4108"
---

# DESIGN.md

> Self-contained design-system source of truth. Conforms to the [design.md spec](https://github.com/google-labs-code/design.md/blob/main/docs/spec.md): YAML frontmatter holds machine-readable tokens; the body holds human rationale. This doc owns the values; `BRAND.md` owns identity.

## Overview

The Filament Style System provides a clean, premium, warm aesthetic ("Warm Paper") designed to feel calm and utility-focused. It avoids neons, dynamic Material 3 colors, and heavy gradients, preferring clean card outlines, 1px/1.5px borders, and custom 1.5px stroke icons.

## Colors

The system uses a warm, low-contrast palette for light and dark modes with a prominent Ember Orange primary accent.

| Token       | Hex / value | Usage          |
|-------------|-------------|----------------|
| `primary`   | `#B25409`   | Ember Orange primary accent and warning color |
| `secondary` | `#535046`   | Secondary body text, currency symbols |
| `bg`        | `#F9F6F0`   | Warm Paper background (Light Mode) |
| `fg`        | `#181510`   | Primary high-contrast text |
| `muted`     | `#756F61`   | Sub-labels and decorative indicators |
| `success`   | `#2E7D3A`   | Safe billing tiers / good balance states |
| `warning`   | `#B25409`   | Medium warning threshold / low balance |
| `danger`    | `#C22A21`   | Critical warnings / high slab consumption |

## Typography

Typography establishes clear visual hierarchy using high-character display faces paired with highly readable body and tabular typefaces.

- Font families:
  - Display: `Space Grotesk` (Medium/500) for large header displays, balances, and cards.
  - Body: `DM Sans` (Regular/400 and Medium/500) for content, captions, and buttons.
  - Mono: `DM Mono` (Medium/500) for currency symbols and tabular data listings.
- Font weights in use: 400 (Regular), 500 (Medium), 700 (Bold)
- Type scale:

| Token       | Size | Line height | Usage          |
|-------------|------|-------------|----------------|
| `text-xs`   | 11px | 1.2         | Badges, captions, helper text |
| `text-sm`   | 12px | 1.3         | Labels, details table text |
| `text-base` | 15px | 1.6         | Standard body text, inputs |
| `text-lg`   | 18px | 1.4         | Subheaders, small display fields |
| `heading-2` | 24px | 1.2         | Component / view titles |
| `heading-1` | 44px | 1.0         | Balance and large meter displays |

## Layout

- Spacing scale:
  - `4px` (gap between badge/nickname, input icons)
  - `8px` (stat-card padding, gap between stats grid elements)
  - `12px` (inner padding of sub-items, small gap spacing)
  - `16px` (main inner padding of cards, grid row gaps)
  - `24px` (outer layout padding, page gutters)
  - `32px` (empty state hero spacing)
- Container max-width: 100% (Chrome extension popup runs fluidly)
- Grid: 2-column or 4-column item grids depending on viewport size.

## Elevation & Depth

To match the clean, card-outline styling, the system relies on flat borders instead of soft drop shadows:
- Borders: `1px solid var(--border-color)` (`#E2DCCF` in Light Mode, `#38342C` in Dark Mode)
- Card accent border: Left edge highlighted with `3px solid var(--accent)`
- Hover elevation: Slight translation up `translateY(-1px)` and subtle shadow glow `box-shadow: 0 6px 20px rgba(178, 84, 9, 0.14)`

## Shapes

Standard rounded borders:
- `lg` (`16px`): Primary container cards and view panels.
- `md` (`12px`): Inner tooltips, interactive grids, and utility modules.
- `sm` (`8px`): Form inputs, badges, and action buttons.

## Components

- **Buttons:** Primary buttons use Ember Orange bg with white text and `8px` border radius. Secondary buttons use transparent/card-bg with a border and dark text.
- **ChargeBar:** Represents monthly consumption partitioned into 6 distinct segments. Each segment's fill color reveals a portion of the green (0 kWh) to red (600 kWh) gradient.
- **Empty States:** A full container card featuring a large alert icon, description text, and a prompt button to add the first meter account.
- **Alerts:** Bordered banners matching the warning/danger state color with inline SVG warning icons.

## Do's and Don'ts

**Do:**
- Always use tokens, never raw hex/px values in components.
- Pair color choices with sufficient contrast (WCAG AA minimum).
- Make sure to use the correct type scale when showing numerical values.

**Don't:**
- Don't use neons, background gradients, or dynamic Material 3 coloring.
- Don't use drop shadows unless they represent interactive element hover states.

<!-- Sections below are project extensions beyond the design.md spec; the spec preserves unknown sections without error. -->

## Dark mode

Implemented via CSS system preference media queries (`@media (prefers-color-scheme: dark)`). The style system swaps the core variables to a Warm-Dark theme:
- `--bg-color`: `#1C1914`
- `--card-bg`: `#25221C`
- `--border-color`: `#38342C`
- `--text-primary`: `#F0ECE3`
- `--text-secondary`: `#B2AEA2`
- `--text-muted`: `#8E897D`

### State text variants (dark mode)

`success`/`warning`/`danger`/`accent` are tuned for light backgrounds and drop below the 4.5:1 WCAG AA minimum when used as text, icon fill, or chart marks directly on `--card-bg`/`--bg-color` in dark mode. Use these lightened variants for **text, icons, chart lines/dots, and legend swatches** on dark surfaces; keep the base tones for borders and alpha-tinted backgrounds, which stay legible as-is.

| Token | Light (base) | Dark (text variant) | Usage |
|---|---|---|---|
| `--state-ok-text` | `#2E7D3A` | `#6FCB7F` | Success/good-balance text, chart kWh line & dots, legend |
| `--state-low-text` | `#B25409` | `#E8954D` | Warning/low-balance text |
| `--state-critical-text` | `#C22A21` | `#E8746A` | Danger/critical text, delete icon, error banners |
| `--accent-text` | `#B25409` | `#E8954D` | Ember accent used as text (forecast values, chart cost line) |

Flutter equivalents live in `FilamentColors.successText(isDark)`, `emberText(isDark)`, `dangerText(isDark)` (`lib/ui/theme/filament_theme.dart`).
