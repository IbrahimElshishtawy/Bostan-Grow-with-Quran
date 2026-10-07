# Event Tracking Architecture & Privacy Guide

## Quran Application (quranglow)

---

## 1. Dual Event Routing System (Section 29)

```text
               User Activity
                    │
              EventService
                    │
      ┌─────────────┴─────────────┐
      ▼                           ▼
Firebase Analytics           Cloud Firestore
(High-Volume Product Telemetry)  (Meaningful User Milestones)
```

### High-Volume Product Telemetry (Firebase Analytics)
Used for tracking general usage metrics without incurring Firestore document write costs:
* `quran_opened`
* `reading_started`
* `reading_completed`
* `audio_started`
* `audio_completed`
* `search_used`
* `reciter_changed`
* `tafsir_opened`
* `notification_opened`

### Meaningful User Milestones (Cloud Firestore)
Appended to `/users/{uid}/events/{eventId}` and processed by Cloud Functions to maintain streaks and unlock achievements:
* `page_read`
* `reading_session_completed`
* `audio_completed`
* `bookmark_created`
* `memorization_started`
* `memorization_completed`
* `revision_completed`
* `khatmah_created`
* `khatmah_completed`
* `goal_completed`

---

## 2. Privacy & PII Guardrails (Section 28)

The following parameters are **STRICTLY PROHIBITED** from ever reaching Firebase Analytics:
* Private Quran notes & reflection texts
* Specific note IDs containing user content
* Passwords or authentication credentials
* User email addresses
* Device-specific hardware serial numbers
* Sensitive search queries

---

## 3. Idempotency & Duplicate Prevention (Section 32)

Every milestone event written to Firestore is assigned a deterministic or millisecond-timestamped `eventId`:
```json
{
  "id": "ev_1728312000000_12345",
  "type": "reading_session_completed",
  "timestamp": "2026-10-07T12:00:00.000Z",
  "metadata": {
    "pagesRead": 4,
    "versesRead": 20,
    "durationMinutes": 15
  }
}
```
Cloud Functions verify execution state and use atomic increments (`FieldValue.increment()`) to guarantee that retrying an event delivery will not result in duplicate daily activity counts or duplicate streak increments.
