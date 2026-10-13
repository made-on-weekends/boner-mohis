# COMPONENTS.md

> Reusable UI component inventory and Filament Design System guidelines.

## Component Conventions

- **Location**: `lib/ui/widgets/` for reusable widgets; `lib/ui/screens/` for full-page screens.
- **Styling**: `FilamentTheme` in `lib/ui/theme/filament_theme.dart` provides global color tokens, borders, and typography.
- **Typography**: Space Grotesk for headings, DM Sans for UI labels, and DM Mono for numbers and meter readings.

## Base & Primitive Components

| Widget | Purpose | File Location | Key Notes |
|---|---|---|---|
| `ChargeBar` | Visual filament meter indicating remaining slab capacity | `lib/ui/widgets/charge_bar.dart` | Recolors to alert state when near threshold |
| `StatCard` | Compact key-value indicator for metrics | `lib/ui/widgets/stat_card.dart` | Uses DM Mono for numerical values |
| `LowBalanceAlert` | Critical banner displayed on dashboard when balance is low | `lib/ui/widgets/low_balance_alert.dart` | Renders in ember or danger tones |
| `DonationCard` | Community support card linking to maintainer donation | `lib/ui/widgets/donation_card.dart` | Formats UTM campaign tracking |

---

## Composite Components

| Widget | Purpose | File Location | Key Notes |
|---|---|---|---|
| `AccountCard` | Main dashboard card showing account balance, meter ID, and status | `lib/ui/widgets/account_card.dart` | Tap navigates to `DetailScreen` |
| `UsageChart` | Interactive 30-day daily consumption chart | `lib/ui/widgets/usage_chart.dart` | Built with `fl_chart`, dual unit/cost toggle |
| `ForecastBreakdownSheet` | Modal bottom sheet explaining slab rate projections | `lib/ui/widgets/forecast_breakdown_sheet.dart` | Displays step-by-step tariff tier calculations |

---

## Extension Components (`extension-react/`)

- `App.jsx`: Primary popup container rendering the account switcher, live balance display, and consumption breakdown.
- `index.css`: Pure Vanilla CSS styled with custom properties from `theme.css`.

## Rules for New Components

1. **No Ad-Hoc Colors**: Never hardcode hex values in widgets. Always reference `FilamentColors.*` or CSS custom properties.
2. **Strict Numeral Font**: All numerical readouts (Taka, kWh, dates) must use `GoogleFonts.dmMono()`.
3. **Bangla Padding**: Ensure Bangla text widgets have adequate vertical padding (`lineHeight` ~ 1.35) to prevent clipped matras.
