# Android Device & APK Testing Guide

> Comprehensive procedures for building, installing, testing, and debugging the Boner Mohis Android APK on physical Android devices and emulators.

---

## 📋 Prerequisites

Before testing on an Android device or emulator, ensure you have:

1. **Flutter SDK & Android CLI Tools**:
   - Flutter 3.x (`flutter --version`)
   - Android SDK Platform-Tools (`adb` available in system `PATH`)
2. **Target Device or Emulator**:
   - **Physical Device**: Android OS 8.0+ (API 26+) with **USB Debugging** enabled in *Settings > Developer Options*.
   - **Emulator (AVD)**: Running Android 10+ (API 29+) with Google Play Services enabled.
3. **Application Identifier**: `com.adommo.bonermohis`

---

## 🔨 1. Building the APK

Run the appropriate Flutter build command from the repository root:

```bash
# Build Debug APK (enables run-as debugging in adb shell)
flutter build apk --debug

# Build Release APK (optimized standalone APK)
flutter build apk --release

# Build split per-ABI APKs (smaller file sizes for arm64-v8a / armeabi-v7a)
flutter build apk --release --split-per-abi
```

Generated APK artifacts will be placed in:
- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`

---

## 🚀 2. Installation & Launch via ADB

### Connect Device
Connect your device via USB or start an emulator, then verify ADB detects it:

```bash
adb devices
```

### Install APK

```bash
# Install / reinstall Debug build
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Or install / reinstall Release build
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Launch & Stream Logs

```bash
# Launch application on device
adb shell am start -n com.adommo.bonermohis/.MainActivity

# Stream Flutter application logs in real-time
adb logcat -s flutter
```

Alternatively, attach Flutter tools directly:

```bash
flutter run -d <device_id> --release
```

---

## 🧪 3. Core Functional Test Scenarios

### Test Scenario 1: Account Setup & Live API Sync
1. Open **Boner Mohis** on the device.
2. Tap the `+` button or "Add Account".
3. Enter Account Nickname, 8-digit DESCO Account Number, and 11–12 digit Meter Number.
4. Tap **Save & Verify**.
5. **Expected Results**:
   - Live balance appears in ৳ (BDT) using `DM Mono` Latin numerals.
   - Current BERC tariff slab (e.g., Step 1, Step 2) and remaining units display accurately.
   - Last updated timestamp matches current local time.

### Test Scenario 2: TLS Intermediate Certificate Handshake Verification
DESCO prepaid servers omit the intermediate CA certificate. Standard Android devices fail if the app does not pin the intermediate CA.
1. Connect device to a public or mobile Wi-Fi network.
2. Trigger account balance refresh.
3. **Expected Results**:
   - Handshake succeeds without `HandshakeException` or `CERTIFICATE_VERIFY_FAILED`.
   - Data loads normally via the scoped DigiCert Global G2 CA certificate.

### Test Scenario 3: Offline & Network Resilience (Airplane Mode)
1. Enable **Airplane Mode** on the device (disable Wi-Fi and Mobile Data).
2. Launch the app or swipe down to refresh on the dashboard.
3. **Expected Results**:
   - App launches instantly without a blank or frozen screen.
   - Previous cached readings, account details, and daily consumption graphs display from local SQLite DB.
   - A subtle offline notice appears indicating the cached sync time.
   - No unhandled exception dialog or app crash occurs.

### Test Scenario 4: Zero-Usage & Division-by-Zero Edge Cases
1. Add an account with a new meter where yesterday's recorded consumption is `0.0 kWh`.
2. **Expected Results**:
   - Estimated days remaining shows `--` rather than `NaN` or `Infinity`.
   - Forecast breakdown sheet handles zero-usage run rate without throwing runtime errors.

---

## 🔔 4. Background WorkManager & Notification Testing

Boner Mohis schedules an hourly background check via `WorkManager` to sync meter balances at 1:00 AM local time and issue emergency low-balance alerts (throttled to at most once per 12 hours).

### Notification Permissions (Android 13+)
On Android 13 (API 33) or higher:
1. Launch the app after fresh install.
2. Confirm the system prompt: Allow notifications for **Low Balance Alerts**.

### Force-Triggering WorkManager Tasks via ADB
Rather than waiting for the periodic timer, manually trigger the scheduled background sync job:

```bash
# Force-run WorkManager scheduled job for Boner Mohis
adb shell cmd jobscheduler run -f com.adommo.bonermohis 1
```

Monitor background sync execution and notification dispatch:

```bash
adb logcat -s flutter WorkManager
```

---

## 🗄️ 5. SQLite Database Inspection via ADB

To inspect local cached accounts and usage records stored on-device (requires debug APK build):

```bash
# Open interactive shell on device
adb shell

# Enter application sandboxed directory
run-as com.adommo.bonermohis

# Inspect SQLite database tables
cd databases
sqlite3 boner_mohis.db "SELECT id, nickname, account_no, meter_no, balance, current_slab FROM accounts;"
sqlite3 boner_mohis.db "SELECT account_id, date, kwh, cost FROM daily_usage_history ORDER BY date DESC LIMIT 5;"
```

---

## 🧹 6. Clean Uninstallation

To completely clear all cached SQLite data, SharedPreferences, and background alarms:

```bash
adb uninstall com.adommo.bonermohis
```

---

## ⭐ Support & Maintainer

If Boner Mohis is useful to you:
- ☕ **Support Our Work** — [Donate](https://asifiqbal.rocks/donation?utm_source=boner_mohis&utm_medium=github_readme&utm_campaign=readme&ref=boner-mohis-readme) to help us maintain and grow our open-source projects.
