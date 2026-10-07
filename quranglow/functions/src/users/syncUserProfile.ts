import { https } from "firebase-functions/v1";
import { db } from "../config/firebase";
import * as admin from "firebase-admin";

/**
 * Callable function to securely sync user profile attributes
 */
export const syncUserProfile = https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const userId = context.auth.uid;
  const { displayName, photoUrl, language, theme } = data;

  const userRef = db.collection("users").doc(userId);
  const now = admin.firestore.FieldValue.serverTimestamp();

  const updates: Record<string, any> = {
    updatedAt: now,
    lastSyncAt: now,
  };

  if (typeof displayName === "string") updates.displayName = displayName;
  if (typeof photoUrl === "string") updates.photoUrl = photoUrl;

  await userRef.set(updates, { merge: true });

  if (language || theme) {
    const prefUpdates: Record<string, any> = { updatedAt: now };
    if (language) prefUpdates.language = language;
    if (theme) prefUpdates.theme = theme;

    await userRef.collection("preferences").doc("app").set(prefUpdates, { merge: true });
  }

  return { success: true, timestamp: new Date().toISOString() };
});
