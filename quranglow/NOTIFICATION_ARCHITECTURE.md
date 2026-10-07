# Notification Architecture Specification

## Quran Application (quranglow) — Firebase Cloud Messaging & Reminders

---

## 1. Notification Types & Priority

| Category | Channel ID | Trigger | Description |
|---|---|---|---|
| **Daily Reading Reminder** | `daily_reading` | Scheduled Function | Gentle encouragement to read the daily Quran portion if not yet completed. |
| **Memorization Reminder** | `memorization` | Scheduled / Local | Reminder to practice the active memorization plan. |
| **Revision Reminder** | `revision` | Scheduled / Local | Prompt to review verses based on spaced-repetition intervals. |
| **Khatmah Milestone** | `khatmah` | User Milestone | Alerts on target date pacing and Khatmah completion. |
| **Achievement Unlocked** | `achievements` | Cloud Functions | Congratulatory alert when a user earns a milestone badge or streak. |

---

## 2. Token Registration & Device Lifecycle

1. Upon app initialization, `MessagingService.initialize()` requests user notification authorization.
2. The retrieved FCM Registration Token is registered under `/users/{uid}/devices/{deviceId}`:
   ```json
   {
     "deviceId": "device_123",
     "platform": "android",
     "appVersion": "1.0.0",
     "fcmToken": "cXYZ...",
     "lastSeenAt": "SERVER_TIMESTAMP"
   }
   ```
3. When `onTokenRefresh` triggers, the device document is updated in Firestore automatically.
4. If a device has been inactive for > 90 days, the scheduled cleanup job purges the device document.

---

## 3. Notification History & Inbox

Notifications dispatched by the server are recorded under `/users/{uid}/notifications/{notificationId}`:
* **Fields**:
  - `id`: Unique Notification Document ID
  - `type`: Category identifier (`daily_reminder`, `achievement_unlocked`, etc.)
  - `title`: Alert title
  - `body`: Message body
  - `data`: Extra deep-link navigation parameters
  - `createdAt`: Dispatched timestamp
  - `readAt`: Timestamp when user views in inbox
  - `openedAt`: Timestamp when user clicks the system tray banner
  - `status`: `"pending"`, `"sent"`, `"read"`, `"opened"`, `"failed"`
* **Client Security**: Clients may only update `readAt`, `openedAt`, and `status`. Clients cannot fake notification dispatch records.
