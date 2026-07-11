# COMPONENTS.md

> Reusable UI component rules and inventory.

## Component conventions

- **Chrome Extension (React):**
  - Location: `extension-react/src/` (e.g. `App.jsx` contains co-located sub-components like `ChargeBar` and `UsageChart`).
  - Styling: CSS class naming rules in `index.css`.
- **Android App (Jetpack Compose):**
  - Location: `android/app/src/main/java/com/example/bonermohis/ui/` (e.g. `DashboardScreen.kt`).

## Prop API rules

**Do:**
- Type every prop/parameter clearly (using Kotlin types or JS doc tags).
- Provide sensible defaults for optional parameters.
- Affirmative names for booleans (e.g. `loading` instead of `notDone`).

**Don't:**
- Don't pass deep object trees. Keep component inputs focused.
- Don't accept 8+ parameters. Break components down if they become too complex.

## Composite components

These represent the custom UI components created for the balance forecaster dashboard:

| Component Name | Platform | Purpose | Notes |
| :--- | :--- | :--- | :--- |
| `ChargeBar` | React / Compose | Displays a progressive 6-segment charge indicator of monthly usage. | Computes filling widths and applies a green-to-red gradient background. |
| `UsageChart` | React / Compose | Renders visual trend graphs showing historic consumption over time. | Draws custom canvas charts of past daily usage metrics. |
| `AccountCard` | React / Compose | Renders the dashboard card summary for a registered meter account. | Displays active balance, billing tier details, and days remaining forecasts. |
| `LowBalanceAlert` | React / Compose | Highlighted banner warning indicating credit is projected to expire soon. | Displays estimated remaining units and countdown days in Ember Orange. |

## When to create a new component

- **Do** extract a component when a layout pattern is used on both the dashboard overview and detailed view, or across both the Chrome extension and Android App platforms.
- **Don't** create a component if it's only a single-use wrapper around a standard text field or primitive button.
