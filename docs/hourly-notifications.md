# Hourly Local Notifications Specification & Architecture

This document describes the local hourly notification system implemented in **Boner Mohis**.

## Architecture Overview

The application generates local notifications natively on the Android device without relying on Firebase Cloud Messaging (FCM) or any remote push services.

```text
+------------------------+      +-------------------------------+      +----------------------------+
|  NotificationService   | ---> | Android WorkManager           | ---> | Local Notification Display |
|  (Dart Service API)    |      | (PeriodicTask ~1 hour)        |      | (flutter_local_notif)      |
+------------------------+      +-------------------------------+      +----------------------------+
            |                                  |
            v                                  v
+------------------------+      +-------------------------------+
|  SharedPreferences     |      | App Closed / Screen Locked /  |
|  (User Enable/Disable) |      | Background Isolate Dispatcher |
+------------------------+      +-------------------------------+
```

## Packages Used

- **`flutter_local_notifications` (`^17.2.2`)**: Handles creation of Android Notification Channels (`hourly_reminders`) and immediate display of local notification banners.
- **`workmanager` (`^0.9.0+3`)**: Manages Android WorkManager background execution and scheduling.
- **`shared_preferences` (`^2.2.3`)**: Persists user enabled/disabled preferences.

## Why WorkManager Was Selected

Android background execution guidelines recommend WorkManager for deferred periodic tasks that do not require exact-second execution. WorkManager ensures battery efficiency, respects Android Doze mode and App Standby, and persists periodic tasks across system reboots via Android's JobScheduler / AlarmManager under the hood. Exact alarm APIs (`SCHEDULE_EXACT_ALARM`) were avoided as per requirements because exact clock-second delivery is unnecessary for hourly reminders and requires high-risk special permissions on Android 12+.

## Android Permissions

The following permissions are configured in `android/app/src/main/AndroidManifest.xml`:

1. `android.permission.POST_NOTIFICATIONS`:
   - Required for Android 13+ (API level 33+) to display notification banners.
   - Handled dynamically at runtime via `NotificationService.requestPermission()`.
2. `android.permission.RECEIVE_BOOT_COMPLETED`:
   - Allows WorkManager to automatically restore scheduled background jobs after device reboot.

## Notification Channel Configuration (Android 8+)

- **Channel ID**: `hourly_reminders`
- **Channel Name**: `Hourly Reminders`
- **Channel Description**: `Periodic hourly local reminder notifications`
- **Importance**: `Importance.high` (ensures visual heads-up banner display when active)
- **Sound**: Enabled
- **Icon**: `@mipmap/ic_launcher`

## Scheduling Lifecycle

### How Scheduling Starts
When the user opens the application (or enables notifications in settings):
1. `NotificationService.initialize()` initializes the plugin and creates notification channels.
2. `NotificationService.scheduleHourlyNotifications()` registers a periodic task:
   - **Task Name**: `com.bonermohis.hourly_notification`
   - **Frequency**: `Duration(hours: 1)`
   - **Existing Work Policy**: `ExistingPeriodicWorkPolicy.update` (prevents duplicate schedules; strictly idempotent).

### How Scheduling Stops
When the user disables notifications in settings:
1. `NotificationService.setHourlyNotificationsEnabled(false)` saves `false` to `SharedPreferences`.
2. `NotificationService.cancelHourlyNotifications()` calls WorkManager's `cancelByUniqueName('com.bonermohis.hourly_notification')`.

## App Lifecycle & Background Behavior

The hourly notification operates in all standard app lifecycle states:

- **Foreground**: Yes.
- **Background**: Yes.
- **App Swiped Away / Closed**: Yes. WorkManager spawns a background Flutter isolate executing `@pragma('vm:entry-point')` entry point `hourlyNotificationDispatcher()`.
- **Screen Locked / Device Idle**: Yes. Displayed as soon as Android WorkManager runs the deferred task.
- **Device Rebooted**: Yes. Automatically rescheduled by WorkManager using `RECEIVE_BOOT_COMPLETED`.

## Android OS Limitations

### Force-Stop Limitation
If a user manually executes `Settings -> Apps -> Boner Mohis -> Force Stop`, Android explicitly halts all app execution and suppresses WorkManager tasks until the user manually launches the application again. This is a deliberate Android security and power-management boundary that applications must not circumvent.

### Doze Mode & Battery Optimization
Android defers periodic WorkManager execution during deep sleep (Doze Mode) to preserve battery life. Notifications scheduled for "every 1 hour" will fire approximately every hour, depending on when Android wakes up the device maintenance window.

## Developer & Testing Workflow (Without Waiting 1 Hour)

To verify notification rendering instantly during development and manual QA:

1. **In App UI**:
   - Open the **Notification Settings** dialog from the Dashboard screen app bar.
   - Tap **"Trigger Test Notification"**.
   - This invokes `NotificationService.showHourlyNotification()`, displaying the notification immediately.
2. **Via Flutter Code**:
   ```dart
   final service = NotificationService();
   await service.showHourlyNotification();
   ```

## Relevant Source Files

- `lib/background/notification_config.dart` — Centralized notification strings & constants.
- `lib/background/notification_service.dart` — Core notification service, WorkManager background isolate handler, and SharedPreferences toggle.
- `lib/background/notification_setup.dart` — Application startup notification initialization.
- `lib/providers/providers.dart` — Riverpod providers for `NotificationService` and `hourlyNotificationsEnabledProvider`.
- `lib/ui/screens/dashboard_screen.dart` — UI toggle and test trigger UI dialog.
- `test/notification_service_test.dart` — Unit tests for service and configuration.

---
- ☕ **Support the maintainer** via [donation](https://asifiqbal.rocks/donation?utm_source=boner_mohis&utm_medium=github_readme&utm_campaign=readme&ref=boner-mohis-readme) to fund further open-source initiatives.
