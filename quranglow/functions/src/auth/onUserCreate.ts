import { auth } from "firebase-functions/v1";
import { db } from "../config/firebase";
import * as admin from "firebase-admin";

export const onUserCreated = auth.user().onCreate(async (user) => {
  const userRef = db.collection("users").doc(user.uid);
  const now = admin.firestore.FieldValue.serverTimestamp();

  const batch = db.batch();

  // 1. User document
  batch.set(
    userRef,
    {
      uid: user.uid,
      displayName: user.displayName || null,
      email: user.email || null,
      photoUrl: user.photoURL || null,
      accountType: "user",
      isAnonymous: user.providerData.length === 0,
      createdAt: now,
      updatedAt: now,
      lastActiveAt: now,
      lastSyncAt: now,
      schemaVersion: 1,
    },
    { merge: true }
  );

  // 2. Default app preferences
  batch.set(
    userRef.collection("preferences").doc("app"),
    {
      language: "ar",
      theme: "system",
      fontSize: 18,
      quranFont: "uthmani",
      mushafEdition: "hafs",
      selectedTranslation: "en.sahih",
      selectedTafsir: "ar.muyassar",
      selectedReciter: "mishari_alafasy",
      audioSpeed: 1.0,
      repeatMode: "none",
      dailyGoal: { pagesTarget: 4, minutesTarget: 20 },
      notificationsEnabled: true,
      dailyReminderTime: "20:00",
      memorizationReminderTime: "09:00",
      privacySettings: { analyticsConsent: true },
      updatedAt: now,
    },
    { merge: true }
  );

  // 3. Default audio preferences
  batch.set(
    userRef.collection("preferences").doc("audio"),
    {
      defaultReciter: "mishari_alafasy",
      speed: 1.0,
      repeatCount: 1,
      autoPlay: true,
      downloadQuality: "high",
      lastPlayedReciter: "mishari_alafasy",
      updatedAt: now,
    },
    { merge: true }
  );

  // 4. Default notification preferences
  batch.set(
    userRef.collection("preferences").doc("notifications"),
    {
      enabled: true,
      dailyReading: true,
      memorization: true,
      revision: true,
      khatmah: true,
      achievements: true,
      marketing: false,
      dailyReminderTime: "20:00",
      timezone: "Africa/Cairo",
      updatedAt: now,
    },
    { merge: true }
  );

  // 5. Initial streak statistics
  batch.set(
    userRef.collection("statistics").doc("streak"),
    {
      currentStreak: 0,
      longestStreak: 0,
      lastActiveDate: "",
      totalActiveDays: 0,
      updatedAt: now,
    },
    { merge: true }
  );

  await batch.commit();
});
