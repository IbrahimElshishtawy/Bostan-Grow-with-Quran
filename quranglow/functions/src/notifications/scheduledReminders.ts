import { pubsub } from "firebase-functions/v1";
import { db } from "../config/firebase";
import { sendUserNotification } from "./notificationDispatcher";

/**
 * Scheduled daily Quran reminder
 * Evaluates active users whose notification preferences are enabled
 */
export const scheduledDailyReminder = pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const notifPrefSnap = await db
        .collection("users")
        .doc(userId)
        .collection("preferences")
        .doc("notifications")
        .get();

      if (!notifPrefSnap.exists) continue;
      const pref = notifPrefSnap.data();
      if (!pref || !pref.enabled || !pref.dailyReading) continue;

      // Check if user already read today
      const today = new Date().toISOString().substring(0, 10);
      const actSnap = await db
        .collection("users")
        .doc(userId)
        .collection("dailyActivity")
        .doc(today)
        .get();

      if (!actSnap.exists || (actSnap.data()?.pagesRead || 0) === 0) {
        // User hasn't read today yet, send gentle encouragement
        await sendUserNotification({
          userId,
          type: "daily_reminder",
          title: "وردك القرآني اليومي 📖",
          body: "لا تنسَ نصيبك من كتاب الله اليوم، دقيقة واحدة تصنع فرقاً في يومك.",
        });
      }
    }
  });
