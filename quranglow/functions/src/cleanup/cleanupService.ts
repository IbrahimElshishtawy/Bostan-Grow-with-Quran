import { pubsub, https } from "firebase-functions/v1";
import { db, auth } from "../config/firebase";

/**
 * Scheduled cleanup of temporary events (> 30 days) and inactive devices (> 90 days)
 * Runs daily at midnight UTC
 */
export const scheduledDataCleanup = pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const thirtyDaysAgoIso = thirtyDaysAgo.toISOString();

    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    // Clean up old events across users
    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;

      // 1. Delete events older than 30 days
      const oldEvents = await db
        .collection("users")
        .doc(userId)
        .collection("events")
        .where("timestamp", "<", thirtyDaysAgoIso)
        .limit(100)
        .get();

      if (!oldEvents.empty) {
        const batch = db.batch();
        oldEvents.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
      }

      // 2. Delete devices not seen in 90 days
      const oldDevices = await db
        .collection("users")
        .doc(userId)
        .collection("devices")
        .where("lastSeenAt", "<", ninetyDaysAgo)
        .limit(50)
        .get();

      if (!oldDevices.empty) {
        const batch = db.batch();
        oldDevices.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
      }
    }
  });

/**
 * Account Deletion (GDPR / Privacy compliant)
 * Deletes all personal data, subcollections, and Auth user
 */
export const deleteUserAccount = https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new https.HttpsError("unauthenticated", "User must be authenticated to delete account.");
  }

  const userId = context.auth.uid;
  const userRef = db.collection("users").doc(userId);

  // Subcollections to wipe
  const subcollections = [
    "preferences",
    "devices",
    "reading",
    "readingSessions",
    "listening",
    "listeningSessions",
    "bookmarks",
    "notes",
    "memorization/plans",
    "memorization/items",
    "revisionSessions",
    "khatmah",
    "goals",
    "dailyActivity",
    "statistics",
    "achievements",
    "events",
    "notifications",
    "downloads/audio",
  ];

  for (const sub of subcollections) {
    const snap = await userRef.collection(sub).get();
    if (!snap.empty) {
      const batch = db.batch();
      snap.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  }

  // Delete main user document
  await userRef.delete();

  // Delete Firebase Auth user
  try {
    await auth.deleteUser(userId);
  } catch (err) {
    console.error(`Error deleting auth user ${userId}:`, err);
  }

  return { success: true };
});
