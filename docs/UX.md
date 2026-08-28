# UX.md

> User flows and behavior rules. The "what happens when" doc.
> Visual rules in `docs/DESIGN.md`. Component-level rules in `docs/COMPONENTS.md`.

## Core flows

### 1. Account Setup
- **Trigger**: Click the "+" button in the header (if accounts exist) or click the "Add first account" button on the empty dashboard state.
- **Interactions**:
  - Modal overlay appears containing the account form.
  - User fills in Nickname, Account Number, and Meter Number (DESCO).
  - Submit checks input validations (Account Number and Meter Number must contain digits only).
  - On success, the modal closes, the account is created, and live sync is immediately initiated.

### 2. Dashboard Navigation
- **Interactions**:
  - The dashboard displays summary cards for all registered accounts.
  - Tap/click any account card to slide/navigate into the **Detail View**.
  - Tap/click the Back Arrow (`<`) in the header of the Detail View to return to the Dashboard.

### 3. Live Synchronisation (DESCO)
- **Interactions**:
  - Upon entering the Detail View for a DESCO account, the application automatically triggers `syncAccount` to fetch live balance and historical consumption from the official DESCO prepaid API.
  - Clicking the rotating "Sync Live" button triggers a manual update.
  - The sync button rotates/spins during the operation. If it fails, an inline error banner displays the message at the top of the card.

## Always / Never (behavior rules)

**Always:**
- Always confirm destructive operations (like deleting an account) with a confirmation dialog.
- Always display a "--" indicator for remaining days if yesterday's consumption is 0 or negative.
- Always display low-balance warning elements (`LOW_BALANCE` alert banner and highlighted orange stat cards) if remaining days is $\le 2.0$ days.

**Never:**
- Never perform a single-tap delete. Always intercept the deletion request with a confirmation dialog.
- Never crash on API sync failures. Handle errors gracefully and display them inside a localized, dismissible error banner in the UI.

## Irreversible action policy

- **Deleting an Account**:
  - Clicking the Trash button triggers a browser `confirm()` dialog.
  - Message: `"Are you sure you want to delete this account?"`
  - On confirm, the account and all associated usage history are removed from database storage, and the user is redirected to the dashboard.

## Empty states

- If no accounts are saved in the storage database, the dashboard displays a centered empty state panel showing a warning icon, a `"No accounts added yet"` text caption, and an `"Add first account"` button.

## Loading thresholds

- **Sync state**: Spinning sync icon is displayed continuously while an active network fetch is running in the background.

## Notifications

- **Chrome Extension**: All warnings (e.g. low balance alerts) are displayed visually within the popup dashboard.
- **Android Companion App**: Emits a native Android push notification once daily if a WorkManager background check determines that an account's balance will deplete in $\le 2$ days.
