import { db } from "../config/firebase";
import * as admin from "firebase-admin";

/**
 * Update user streak when an activity is recorded for a specific date (YYYY-MM-DD)
 */
export async function calculateAndUpdateStreak(
  userId: string,
  activityDate: string
): Promise<{ currentStreak: number; streakUpdated: boolean }> {
  const streakRef = db.collection("users").doc(userId).collection("statistics").doc("streak");

  return db.runTransaction(async (transaction) => {
    const streakDoc = await transaction.get(streakRef);
    const data = streakDoc.data() || {
      currentStreak: 0,
      longestStreak: 0,
      lastActiveDate: "",
      totalActiveDays: 0,
    };

    const lastDate = data.lastActiveDate;

    if (lastDate === activityDate) {
      // Already recorded for this date
      return { currentStreak: data.currentStreak, streakUpdated: false };
    }

    let newCurrentStreak = data.currentStreak;
    let newLongestStreak = data.longestStreak;
    const newTotalDays = (data.totalActiveDays || 0) + 1;

    if (!lastDate) {
      newCurrentStreak = 1;
    } else {
      const prev = new Date(`${lastDate}T00:00:00Z`).getTime();
      const curr = new Date(`${activityDate}T00:00:00Z`).getTime();
      const diffDays = Math.round((curr - prev) / (1000 * 60 * 60 * 24));

      if (diffDays === 1) {
        // Consecutive day
        newCurrentStreak += 1;
      } else if (diffDays > 1) {
        // Streak broken
        newCurrentStreak = 1;
      } else {
        // Activity from the past, streak count does not advance
        return { currentStreak: data.currentStreak, streakUpdated: false };
      }
    }

    if (newCurrentStreak > newLongestStreak) {
      newLongestStreak = newCurrentStreak;
    }

    transaction.set(
      streakRef,
      {
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        lastActiveDate: activityDate,
        totalActiveDays: newTotalDays,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { currentStreak: newCurrentStreak, streakUpdated: true };
  });
}
