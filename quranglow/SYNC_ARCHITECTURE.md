# Synchronization Architecture

## Offline-First Local Data + Cloud Firebase Synchronization

---

## 1. Architectural Roles

```text
                    ┌──────────────────┐
                    │      Flutter     │
                    └────────┬─────────┘
                             │
                  ┌──────────┴──────────┐
                  │                     │
             Local Storage           Firebase
             (Hive/Device)              │
                  │             ┌───────┼────────┐
                  │             │       │        │
                  │          Firestore Analytics FCM
                  │             │
                  │         Cloud Functions
                  │
                  └──────────────┐
                                 │
                            Sync Engine
```

* **Local Storage (Offline First)**:
  - Immediate instant UI response without waiting for network.
  - Retains all offline reading states, cached surahs, offline bookmarks, memorization progress, and pending sync operations.
* **Firebase Cloud**:
  - Central source of truth for cross-device state.
  - Safe user identity persistence across device migrations.
  - Server-calculated aggregations (streaks, daily activity).

---

## 2. Sync Lifecycle

```text
User Action (e.g. Bookmark Ayah / Complete Page)
      ↓
Write to Local Storage immediately
      ↓
Update Flutter UI instantaneously
      ↓
Enqueue SyncOperation in Local Sync Queue
      ↓
Network Online?
  ├── Yes ──► Send to Firestore (Debounced/Batched) ──► Mark Synced & Remove from Queue
  └── No  ──► Retain in Offline Queue ──► Wait for connectivity ──► Retry with Exponential Backoff
```

---

## 3. Conflict Resolution Policies

| Entity | Resolution Strategy | Description |
|---|---|---|
| **Reading Position** | *Latest Timestamp Wins* | Highest valid `updatedAt` / `lastReadAt` determines current reading page. |
| **Bookmarks** | *Union & Last Modified* | If bookmarked on either device, it is preserved. Deletions propagate based on `updatedAt`. |
| **Notes** | *Conflict-Safe Merge* | Content with newer timestamp takes precedence. |
| **Daily Goals** | *Max Progress* | Progress counts (`pagesRead`, `versesRead`) are monotonically incremented and never lost. |
| **Khatmah Plans** | *Progress Maximum* | Highest `completedPages` wins to prevent user regression. |

---

## 4. Cost Control & Debounce Mechanism

Writing to Firestore on every single ayah scroll or page swipe leads to high costs and battery drain.
* Page reading position is debounced by 4-5 seconds.
* Reading sessions are committed only upon session completion or pause (> 60s).
* Audio playback positions are held locally and synced only upon verse or surah completion.
