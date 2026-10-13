# PRODUCT.md

> What we're building, for whom, and what is explicitly NOT in scope.
> This is the canonical scope document. Agents must check here before adding features.

## Product

Boner Mohis (বনের মহিষ) is a local-first, privacy-respecting prepaid electricity balance and consumption tracker for DESCO consumers in Bangladesh.

## Target user

Residential and small-business electricity consumers in Dhaka under DESCO prepaid metering who want transparent balance tracking, daily consumption breakdowns, and advance warnings before their electricity cuts out.

## Anti-persona

- Postpaid consumers with monthly billing cycles.
- Consumers outside DESCO service areas (DPDC, BREB, NESCO, WZPDCL).
- Users looking for automated bill payment or money transfer integrations.

## Core value

Immediate, accurate visibility into prepaid balance, daily unit consumption, and tariff-slab progression without requiring third-party cloud servers, user accounts, or financial credential sharing.

## In scope (current phase)

- **Account Management**: Add, view, edit nickname, and remove multiple DESCO prepaid accounts (Account No and Meter No).
- **Balance & Slab Monitoring**: Fetch live balance and monthly cumulative units from DESCO APIs; compute current tariff slab and estimated remaining days.
- **Consumption Analytics**: Daily consumption charts and monthly breakdown history stored locally.
- **Proactive Alerts**: Background balance sync and local notification dispatch when balance falls below user-configured emergency thresholds.
- **Cross-Platform Access**: Native Android mobile application (Flutter) and companion browser extension (React 19 / Manifest V3).
- **TLS Certificate Pinning**: Scoped trust of DigiCert Global G2 intermediate CA on Android to overcome incomplete server certificate chains.

## Explicitly out of scope

- **Online Recharge & Payments**: No integration with bKash, Nagad, Rocket, or credit card gateways — reason: User financial liability and credential security risk.
- **Other Electricity Distributors**: No support for DPDC, BREB, or NESCO in current architecture — reason: Incompatible API formats, authentication schemes, and meter infrastructures.
- **Centralized Cloud Accounts**: No centralized login, sync server, or telemetry — reason: Preserves complete consumer privacy.

## Phase plan (optional)

- **Phase 1 (Current)**: Local-first Android app and Chrome extension with DESCO balance, daily consumption, and local SQLite cache.
- **Phase 2 (Future)**: Support for exporting consumption history to CSV; optional home-screen widgets for Android.

## Non-goals

- Not an official government or DESCO utility application.
- Not a smart-home appliance control or remote power switch tool.
- Not a replacement for official payment portals.

## Success criteria

- Zero TLS handshake failures on supported Android devices when connecting to DESCO servers.
- Accurate slab calculations matching actual monthly billing receipts within 1% margin.
- 100% offline readability of previously fetched readings and statistics.
