# Firebase Firestore Schema Specification

## Quran Application (quranglow) — Production Data Architecture

This document details the complete Firestore schema, collection hierarchies, document specifications, data types, query patterns, and ownership rules.

---

## 1. Global & Top-Level Collections

### `/users/{uid}`
* **Description**: Main user account document.
* **Access**: Authenticated owner only (`request.auth.uid == uid`).
* **Fields**:
  | Field | Type | Description |
  |---|---|---|
  | `uid` | `string` | Unique Firebase Auth UID |
  | `displayName` | `string?` | User's preferred display name |
  | `email` | `string?` | User's registered email |
  | `photoUrl` | `string?` | Optional avatar image URL |
  | `accountType` | `string` | `"user"` or `"admin"` |
  | `isAnonymous` | `boolean` | Indicates if user is using guest session |
  | `createdAt` | `timestamp` | Document creation time |
  | `updatedAt` | `timestamp` | Last update time |
  | `lastActiveAt` | `timestamp` | Last user interaction time |
  | `lastSyncAt` | `timestamp` | Last bidirectional synchronization time |
  | `schemaVersion` | `number` | Schema migration version (default: 1) |

---

### `/achievements/{achievementId}`
* **Description**: System-wide definitions of available badges and achievements.
* **Access**: Read-only for authenticated users; Server-writable only.
* **Fields**:
  | Field | Type | Description |
  |---|---|---|
  | `id` | `string` | Unique identifier (e.g. `first_reading`, `7_day_streak`) |
  | `title` | `string` | Localized title |
  | `description` | `string` | Criteria explanation |
  | `category` | `string` | `"reading"`, `"memorization"`, `"streak"`, `"khatmah"` |
  | `points` | `number` | Gamification score points |

---

## 2. User Subcollections (`/users/{uid}/...`)

### `/preferences`
Contains configuration documents:
1. `app`:
   - `language`: `string` (`"ar"`, `"en"`)
   - `theme`: `string` (`"light"`, `"dark"`, `"system"`)
   - `fontSize`: `number` (e.g. 18)
   - `quranFont`: `string` (`"uthmani"`, `"indopak"`)
   - `mushafEdition`: `string` (`"hafs"`, `"warsh"`)
   - `selectedTranslation`: `string`
   - `selectedTafsir`: `string`
   - `selectedReciter`: `string`
   - `audioSpeed`: `number` (0.5 to 2.0)
   - `repeatMode`: `string` (`"none"`, `"verse"`, `"surah"`)
   - `dailyGoal`: `map` (`{ pagesTarget: 4, minutesTarget: 20 }`)
   - `notificationsEnabled`: `boolean`
   - `dailyReminderTime`: `string` (`"20:00"`)
   - `memorizationReminderTime`: `string` (`"09:00"`)
   - `privacySettings`: `map`
   - `analyticsConsent`: `boolean`
2. `audio`:
   - `defaultReciter`: `string`
   - `speed`: `number`
   - `repeatCount`: `number`
   - `autoPlay`: `boolean`
   - `downloadQuality`: `string` (`"high"`, `"standard"`)
   - `lastPlayedReciter`: `string`
3. `notifications`:
   - `enabled`: `boolean`
   - `dailyReading`: `boolean`
   - `memorization`: `boolean`
   - `revision`: `boolean`
   - `khatmah`: `boolean`
   - `achievements`: `boolean`
   - `marketing`: `boolean`
   - `dailyReminderTime`: `string`
   - `timezone`: `string` (IANA name, e.g. `"Africa/Cairo"`)

---

### `/devices/{deviceId}`
* **Description**: Registered client devices for push notifications and sync tracking.
* **Fields**:
  - `deviceId`: `string`
  - `platform`: `string` (`"android"`, `"ios"`, `"web"`, `"windows"`)
  - `appVersion`: `string`
  - `osVersion`: `string?`
  - `deviceModel`: `string?`
  - `locale`: `string?`
  - `timezone`: `string?`
  - `fcmToken`: `string?`
  - `lastSeenAt`: `timestamp`
  - `updatedAt`: `timestamp`

---

### `/reading/progress`
* **Description**: Singleton document holding latest reading position across devices.
* **Debouncing**: Client writes debounced by 4-5 seconds to control Firestore cost.
* **Fields**:
  - `currentPage`: `number` (1 to 604)
  - `currentSurah`: `number` (1 to 114)
  - `currentAyah`: `number`
  - `currentJuz`: `number` (1 to 30)
  - `lastReadAt`: `timestamp`
  - `lastSessionId`: `string?`

---

### `/readingSessions/{sessionId}`
* **Description**: Aggregated sessions of completed reading activity.
* **Fields**:
  - `startedAt`: `string / timestamp`
  - `endedAt`: `string / timestamp`
  - `durationSeconds`: `number`
  - `startPage`: `number`
  - `endPage`: `number`
  - `startSurah`: `number`
  - `endSurah`: `number`
  - `pagesRead`: `number`
  - `versesRead`: `number`
  - `source`: `string` (`"mushaf"`, `"tafsir"`)
  - `deviceId`: `string`

---

### `/bookmarks/{bookmarkId}`
* **Fields**:
  - `id`: `string`
  - `type`: `string` (`"ayah"`, `"page"`, `"surah"`)
  - `surahId`: `number`
  - `ayahId`: `number`
  - `pageNumber`: `number`
  - `title`: `string?`
  - `note`: `string?`
  - `color`: `string?`
  - `createdAt`: `timestamp`
  - `updatedAt`: `timestamp`

---

### `/notes/{noteId}`
* **Description**: Private reflections and notes written by the user.
* **Privacy**: Strictly accessible ONLY by the owner. Never shared or exposed.
* **Fields**:
  - `id`: `string`
  - `surahId`: `number`
  - `ayahId`: `number`
  - `pageNumber`: `number`
  - `content`: `string`
  - `createdAt`: `timestamp`
  - `updatedAt`: `timestamp`

---

### `/memorization`
1. `data/plans/{planId}`:
   - `id`: `string`
   - `name`: `string`
   - `surahId`: `number`
   - `startAyah`: `number`
   - `endAyah`: `number`
   - `startDate`: `string`
   - `targetDate`: `string`
   - `dailyTarget`: `number`
   - `status`: `string` (`"active"`, `"completed"`, `"paused"`)
   - `progress`: `number` (0.0 to 1.0)
   - `createdAt`: `timestamp`
   - `updatedAt`: `timestamp`
2. `data/items/{itemId}`:
   - `surahId`: `number`
   - `ayahId`: `number`
   - `status`: `string` (`"new"`, `"learning"`, `"memorized"`, `"review"`)
   - `strength`: `number`
   - `lastReviewedAt`: `timestamp?`
   - `nextReviewAt`: `timestamp?`
   - `reviewCount`: `number`
   - `mistakeCount`: `number`
   - `updatedAt`: `timestamp`

---

### `/revisionSessions/{sessionId}`
* **Fields**:
  - `planId`: `string?`
  - `startedAt`: `timestamp`
  - `endedAt`: `timestamp`
  - `durationSeconds`: `number`
  - `versesReviewed`: `number`
  - `mistakes`: `number`
  - `score`: `number`
  - `completed`: `boolean`

---

### `/khatmah/{khatmahId}`
* **Fields**:
  - `id`: `string`
  - `name`: `string`
  - `type`: `string` (`"7_days"`, `"15_days"`, `"30_days"`, `"60_days"`, `"custom"`)
  - `startDate`: `string`
  - `targetDate`: `string`
  - `totalPages`: `number` (604)
  - `completedPages`: `number`
  - `progress`: `number`
  - `status`: `string` (`"active"`, `"completed"`, `"abandoned"`)
  - `createdAt`: `timestamp`
  - `updatedAt`: `timestamp`

---

### `/goals/daily`
* **Fields**:
  - `pagesTarget`: `number`
  - `minutesTarget`: `number`
  - `versesTarget`: `number`
  - `memorizationTarget`: `number`
  - `audioTarget`: `number`

---

### `/dailyActivity/{YYYY-MM-DD}`
* **Description**: Daily aggregates updated atomically via Cloud Functions or sync manager.
* **Fields**:
  - `date`: `string` (`"YYYY-MM-DD"`)
  - `pagesRead`: `number`
  - `versesRead`: `number`
  - `readingMinutes`: `number`
  - `listeningMinutes`: `number`
  - `memorizedVerses`: `number`
  - `revisionMinutes`: `number`
  - `completedDailyGoal`: `boolean`
  - `updatedAt`: `timestamp`

---

### `/statistics/streak`
* **Description**: Server-protected streak calculations.
* **Write Permission**: Server Admin SDK only.
* **Fields**:
  - `currentStreak`: `number`
  - `longestStreak`: `number`
  - `lastActiveDate`: `string` (`"YYYY-MM-DD"`)
  - `totalActiveDays`: `number`
  - `updatedAt`: `timestamp`

---

### `/achievements/{achievementId}`
* **Description**: Unlocked badges awarded to the user.
* **Write Permission**: Cloud Functions only.
* **Fields**:
  - `id`: `string`
  - `title`: `string`
  - `body`: `string`
  - `category`: `string`
  - `unlockedAt`: `timestamp`

---

### `/events/{eventId}`
* **Description**: Client-appended product events for server processing and aggregation.
* **Write Permission**: Append-only (create allowed, updates/deletions denied for clients).
* **Fields**:
  - `id`: `string`
  - `type`: `string`
  - `timestamp`: `string`
  - `metadata`: `map`

---

### `/notifications/{notificationId}`
* **Description**: User notification inbox and delivery history.
* **Write Permission**: Created by server; client may only update `readAt` and `openedAt`.
* **Fields**:
  - `id`: `string`
  - `type`: `string`
  - `title`: `string`
  - `body`: `string`
  - `data`: `map`
  - `createdAt`: `timestamp`
  - `sentAt`: `timestamp?`
  - `readAt`: `timestamp?`
  - `openedAt`: `timestamp?`
  - `status`: `string` (`"pending"`, `"sent"`, `"read"`, `"opened"`, `"failed"`)
