import { firestore } from "firebase-functions/v1";
import { db } from "../config/firebase";
import * as admin from "firebase-admin";
import { calculateAndUpdateStreak } from "../streaks/streakEngine";
import {
  checkReadingAchievements,
  checkStreakAchievements,
  unlockAchievement,
} from "../achievements/achievementEngine";

export const onUserEventCreated = firestore
  .document("users/{userId}/events/{eventId}")
  .onCreate(async (snapshot, context) => {
    const userId = context.params.userId;
    const event = snapshot.data();

    if (!event || !event.type) return;

    const eventType = event.type;
    const timestampStr = event.timestamp || new Date().toISOString();
    const dateStr = timestampStr.substring(0, 10); // YYYY-MM-DD
    const metadata = event.metadata || {};

    const userRef = db.collection("users").doc(userId);
    const activityRef = userRef.collection("dailyActivity").doc(dateStr);
    const now = admin.firestore.FieldValue.serverTimestamp();

    // 1. Update last active timestamp
    await userRef.set(
      {
        lastActiveAt: now,
        lastSyncAt: now,
      },
      { merge: true }
    );

    // 2. Process based on event type
    switch (eventType) {
      case "page_read":
      case "reading_session_completed": {
        const pages = Number(metadata.pagesRead || metadata.pages || 1);
        const verses = Number(metadata.versesRead || metadata.verses || 0);
        const minutes = Number(metadata.durationMinutes || metadata.minutes || 1);

        await activityRef.set(
          {
            date: dateStr,
            pagesRead: admin.firestore.FieldValue.increment(pages),
            versesRead: admin.firestore.FieldValue.increment(verses),
            readingMinutes: admin.firestore.FieldValue.increment(minutes),
            updatedAt: now,
          },
          { merge: true }
        );

        // Update streak
        const { currentStreak, streakUpdated } = await calculateAndUpdateStreak(userId, dateStr);
        if (streakUpdated) {
          await checkStreakAchievements(userId, currentStreak);
        }

        // Check total reading milestones
        const actSnap = await activityRef.get();
        const actData = actSnap.data();
        if (actData) {
          await checkReadingAchievements(userId, actData.pagesRead || pages);
        }
        break;
      }

      case "audio_completed": {
        const minutes = Number(metadata.durationMinutes || metadata.durationSeconds ? Math.round(metadata.durationSeconds / 60) : 5);
        await activityRef.set(
          {
            date: dateStr,
            listeningMinutes: admin.firestore.FieldValue.increment(minutes),
            updatedAt: now,
          },
          { merge: true }
        );
        break;
      }

      case "memorization_started":
      case "memorization_completed": {
        const verses = Number(metadata.versesCount || metadata.verses || 1);
        await activityRef.set(
          {
            date: dateStr,
            memorizedVerses: admin.firestore.FieldValue.increment(verses),
            updatedAt: now,
          },
          { merge: true }
        );
        await unlockAchievement(userId, "first_memorization");
        break;
      }

      case "revision_completed": {
        const minutes = Number(metadata.durationMinutes || 5);
        await activityRef.set(
          {
            date: dateStr,
            revisionMinutes: admin.firestore.FieldValue.increment(minutes),
            updatedAt: now,
          },
          { merge: true }
        );
        break;
      }

      case "khatmah_completed": {
        await unlockAchievement(userId, "first_khatmah");
        break;
      }

      case "goal_completed": {
        await activityRef.set(
          {
            date: dateStr,
            completedDailyGoal: true,
            updatedAt: now,
          },
          { merge: true }
        );
        break;
      }

      default:
        break;
    }
  });
