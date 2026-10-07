import { db, messaging } from "../config/firebase";
import * as admin from "firebase-admin";

export interface SendNotificationOptions {
  userId: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendUserNotification(options: SendNotificationOptions): Promise<boolean> {
  const { userId, type, title, body, data } = options;

  // 1. Fetch user devices with valid FCM tokens
  const devicesSnap = await db
    .collection("users")
    .doc(userId)
    .collection("devices")
    .get();

  const tokens: string[] = [];
  devicesSnap.forEach((doc) => {
    const fcmToken = doc.data().fcmToken;
    if (fcmToken && typeof fcmToken === "string") {
      tokens.push(fcmToken);
    }
  });

  // 2. Record notification in history
  const notifRef = db
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .doc();

  const now = admin.firestore.FieldValue.serverTimestamp();

  await notifRef.set({
    id: notifRef.id,
    type,
    title,
    body,
    data: data || {},
    createdAt: now,
    sentAt: tokens.length > 0 ? now : null,
    readAt: null,
    openedAt: null,
    status: tokens.length > 0 ? "sent" : "pending",
  });

  if (tokens.length === 0) {
    return false;
  }

  // 3. Send multicast via FCM
  try {
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        type,
        notificationId: notifRef.id,
        ...(data || {}),
      },
    });

    return response.successCount > 0;
  } catch (error) {
    console.error("FCM send error:", error);
    await notifRef.update({ status: "failed" });
    return false;
  }
}
