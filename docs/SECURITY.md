# SECURITY.md

> Security rules and threat model. Cross-references `DATABASE.md` for access policies and `SCHEMA.md` for sensitive columns.

## Hard Rules

These rules are **absolute**. Violating any of them requires a `DECISIONS.md` entry that explicitly supersedes the rule, with security review.

1. **Never** log PII, account numbers, or meter serials — even at debug levels.
2. **Never** transmit stored account numbers or meter serials to any external server. All simulation and data operations must run strictly inside the local runtime environment.
3. **Never** use `innerHTML` or string concatenation to write user-controlled strings (e.g. account nicknames, account numbers) into the DOM. Always use `textContent` or robust DOM sanitization to prevent Cross-Site Scripting (XSS).
4. **Never** disable secure Sandboxing or CSP policies in the Chrome Extension manifest.
5. **Always** enforce input validation on account numbers and meter numbers to block injection attempts at the storage boundary.

## Secrets & PII Management

- **Local Storage:** Account and meter numbers are stored in plain text inside `chrome.storage.local` and SQLite. No high-security secrets (like bank PINs or passwords) should ever be requested or stored by this utility.
- **Third-Party Transmissions:** The application is designed to function 100% locally. No external domains may be contacted containing account identifier tokens.

## Sensitive Data Inventory

PII and sensitive credentials tracked locally in storage:

| Table / Key.field | Type of sensitivity | Encryption at rest | Notes |
| :--- | :--- | :--- | :--- |
| `accounts.accountNo` | PII (Account Number) | None | Handled locally in browser storage/SQLite. |
| `accounts.meterNo` | PII (Meter Serial Number) | None | Handled locally in browser storage/SQLite. |

## Input Validation

- **Client Input:** User input forms for nicknames, account numbers, and meter numbers must validate lengths, character sets, and formats before save operations are committed.
- **Output Sanitization:** In `popup.js` and Kotlin UI rendering:
  - Account nicknames must be rendered using `element.textContent` or native Compose Text components.
  - Inputs must be checked against regular expressions (e.g. alphanumeric only for nicknames, numeric only for account numbers).

## Threat Model — Top Concerns

1. **Cross-Site Scripting (XSS) in Popup:**
   - *Threat:* An attacker injects a malicious payload into an account nickname, executing script when the popup loads.
   - *Mitigation:* The extension never uses `innerHTML` for user-entered fields. It uses `document.createTextNode` or `element.textContent` exclusively.
2. **Database Theft via Phone Rooting/Browser Compromise:**
   - *Threat:* A compromised device exposes the local database.
   - *Mitigation:* We minimize the sensitivity of stored data. We never store credit cards, utility portal passwords, or personal identity numbers. The account number alone is insufficient to compromise the utility grid connection.
