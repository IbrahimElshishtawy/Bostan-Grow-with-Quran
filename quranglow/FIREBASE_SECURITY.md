# Firebase Security Architecture & Rules Guide

## Quran Application (quranglow)

This document outlines the security architecture, role models, validation invariants, threat models, and security test matrices implemented in `firestore.rules`.

---

## 1. Core Principles

1. **Default Deny All**: Every collection and document path is blocked by default unless explicitly allowed.
2. **User Isolation**: A user can only access documents under `/users/{request.auth.uid}`. Cross-user reading or writing is unconditionally blocked.
3. **Privilege Separation**:
   - **User Writable**: Bookmarks, Notes, Plans, Reading position, App Preferences, Device tokens.
   - **Append-Only**: User Events (`/users/{uid}/events/{eventId}`). Once created, clients cannot modify or tamper with past logs.
   - **Server-Protected**: Achievements (`/users/{uid}/achievements/{id}`), Streak Statistics (`/users/{uid}/statistics/streak`), Global Badges (`/achievements/{id}`). Only Firebase Cloud Functions (Admin SDK) can award achievements or compute streaks.
   - **Status-Only Updates**: Notifications (`/users/{uid}/notifications/{id}`). Clients cannot forge notification content or fake send times; they may only modify `readAt` and `openedAt`.
4. **App Check Verification**: Replay attacks and automated bot traffic are mitigated through Play Integrity (Android) and DeviceCheck (iOS).

---

## 2. Security Test Matrix

| Access Vector | Target Resource | Permission | Rationale |
|---|---|---|---|
| User A | User A profile & preferences | **ALLOWED** | User owns the document |
| User A | User B profile & preferences | **DENIED** | Strict UID matching rule |
| User A | User A notes | **ALLOWED** | Private personal reflections |
| User A | User B notes | **DENIED** | Notes are strictly private |
| Client | Own `/statistics/streak` | **DENIED (Write)** | Prevents streak manipulation |
| Client | Own `/achievements/{id}` | **DENIED (Write)** | Prevents badge forgery |
| Server Functions | `/statistics/streak` | **ALLOWED** | Trusted Admin SDK execution |
| Server Functions | `/achievements/{id}` | **ALLOWED** | Trusted Admin SDK execution |
| Client | `/events/{id}` (Create) | **ALLOWED** | Validated event structure |
| Client | `/events/{id}` (Update/Delete) | **DENIED** | Immutable audit trail |
| Client | `/notifications/{id}` (Create) | **DENIED** | Only server sends notifications |
| Client | `/notifications/{id}` (Update) | **CONDITIONAL** | Only `readAt` / `openedAt` / `status` allowed |

---

## 3. Account Deletion & GDPR Compliance

When an account is deleted via `deleteUserAccount` (Cloud Functions):
- The user's authentication record is removed from Firebase Authentication.
- All associated subcollections (`preferences`, `devices`, `reading`, `readingSessions`, `listening`, `listeningSessions`, `bookmarks`, `notes`, `memorization`, `revisionSessions`, `khatmah`, `goals`, `dailyActivity`, `statistics`, `achievements`, `events`, `notifications`) are permanently purged.
- No residual personal content remains on the cloud.
