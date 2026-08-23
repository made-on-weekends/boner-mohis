# ANDROID_DEVICE_TESTING.md

> Comprehensive guide for installing, testing, and debugging the Boner Mohis Android app on physical Android devices and emulators.

---

## 📋 Prerequisites

Before testing on an Android device or emulator, ensure you have:

1. **Built APK Artifacts**:
   - Debug APK: [`app-debug.apk`](file:///mnt/workbench/repos/live/boner-mohis/build/app/outputs/flutter-apk/app-debug.apk)
   - Release APK: [`app-release.apk`](file:///mnt/workbench/repos/live/boner-mohis/build/app/outputs/flutter-apk/app-release.apk)
   *(Generate using `flutter build apk --debug` or `flutter build apk --release`)*
2. **Android Command Line Tools (`adb`)** installed and available in system `PATH`.
3. **Android Device or Emulator**:
   - Physical device: Android OS 8.0+ (API 26+) with **USB Debugging** enabled in *Settings > Developer Options*.
   - Emulator: AVD running Android 10+ with Google Play Services.

---

## 🚀 1. Installation & Launch

### Option A: Install via ADB (Recommended)

Connect your device via USB (or start an AVD emulator) and verify it is detected:

```bash
adb devices
```

Install the generated APK onto your connected device:

```bash
# Install Debug build
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Or install Release build
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Option B: Run via Flutter CLI

To attach hot reload and stream real-time logs:

```bash
flutter run -d <device_id>
```

---

## ⚡ 2. Core Functional Test Scenarios

### Test Scenario 1: Account Setup & Initial API Sync
1. Launch **Boner Mohis** on your device.
2. Tap **Add Account**.
3. Select Distributor: `DESCO`.
4. Input valid DESCO credentials (Account No + Meter No).
5. Verify that:
   - Live balance is fetched and displayed in ৳ (BDT).
   - Remaining days estimation displays based on yesterday's usage.
   - Billing slab status (e.g. Lifeline vs First Step) updates accurately.

### Test Scenario 2: Offline & Network Resilience
1. Turn off Wi-Fi and Mobile Data on the device (Airplane Mode).
2. Launch the app or pull down to refresh.
3. Verify that:
   - App loads instantly from local SQLite DB (`boner_mohis.db`).
   - Graceful fallback banner/toast indicates offline status.
   - App does not crash or display raw unhandled exceptions.

### Test Scenario 3: Zero-Usage & Edge Cases
1. Set up an account where yesterday's recorded usage is `0.0 kWh`.
2. Verify:
   - Days remaining display shows `--` or `Infinity` gracefully rather than `NaN` or crashing.
   - Low-balance alerts do not throw division-by-zero exceptions.

---

## 🔔 3. Background WorkManager & Notification Testing

Boner Mohis uses `WorkManager` to run background checks every 24 hours (or retries hourly if offline).

### Granting Notification Permissions (Android 13+)
On Android 13 (API 33) or higher:
1. Open app for the first time.
2. Allow the system notification permission prompt for **Low Balance Alerts**.

### Force-Triggering Background WorkManager Task via ADB
Instead of waiting 24 hours to test background fetching and notifications, force execution via `adb`:

```bash
# Force run WorkManager scheduled tasks for Boner Mohis package
adb shell cmd jobscheduler run -f com.bonermohis.boner_mohis 1
```

Or monitor background WorkManager execution logs live:

```bash
adb logcat -s flutter WorkManager
```

---

## 💾 4. SQLite / Room Database Inspection

To inspect stored accounts and historical usage data stored locally on the device:

```bash
# Open interactive shell on the device
adb shell

# Navigate to app internal databases (requires debug build or root)
run-as com.bonermohis.boner_mohis
cd databases
sqlite3 boner_mohis.db "SELECT * FROM accounts;"
```

---

## 🤝 Support & Maintainer

If you find Boner Mohis useful for tracking prepaid electricity meters:
- ☕ **Support the maintainer** via [donation](https://asifiqbal.rocks/donation?utm_source=boner_mohis&utm_medium=github_readme&utm_campaign=readme&ref=boner-mohis-docs) to fund further open-source initiatives.
