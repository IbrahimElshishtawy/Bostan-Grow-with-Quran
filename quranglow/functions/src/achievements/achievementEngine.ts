import { db } from "../config/firebase";
import * as admin from "firebase-admin";
import { sendUserNotification } from "../notifications/notificationDispatcher";

const ACHIEVEMENTS_DEF: Record<string, { title: string; body: string; category: string }> = {
  first_reading: {
    title: "بداية الرحلة",
    body: "أتممت أول جلسة قراءة لك في بستان القرآن!",
    category: "reading",
  },
  "7_day_streak": {
    title: "مداومة أسبوعية",
    body: "ما شاء الله! حافظت على قراءة وردك لـ 7 أيام متتالية.",
    category: "streak",
  },
  "30_day_streak": {
    title: "مداومة شهرية",
    body: "إنجاز عظيم! حافظت على قراءة القرآن لـ 30 يوماً متتالياً.",
    category: "streak",
  },
  "100_pages": {
    title: "مئة صفحة من النور",
    body: "أتممت قراءة 100 صفحة من القرآن الكريم.",
    category: "reading",
  },
  first_memorization: {
    title: "حامل القرآن",
    body: "بدأت أول خطة لحفظ كتاب الله.",
    category: "memorization",
  },
  first_khatmah: {
    title: "ختمة مباركة",
    body: "مبارك إتمام أول ختمة للقرآن الكريم!",
    category: "khatmah",
  },
};

export async function unlockAchievement(
  userId: string,
  achievementId: string
): Promise<boolean> {
  const achRef = db
    .collection("users")
    .doc(userId)
    .collection("achievements")
    .doc(achievementId);

  const existing = await achRef.get();
  if (existing.exists) {
    return false; // Already unlocked
  }

  const def = ACHIEVEMENTS_DEF[achievementId] || {
    title: "إنجاز جديد",
    body: "تهانينا! لقد حققت إنجازاً جديداً.",
    category: "general",
  };

  const now = admin.firestore.FieldValue.serverTimestamp();

  await achRef.set({
    id: achievementId,
    title: def.title,
    body: def.body,
    category: def.category,
    unlockedAt: now,
  });

  // Send congratulatory push notification
  await sendUserNotification({
    userId,
    type: "achievement_unlocked",
    title: `🏆 إنجاز جديد: ${def.title}`,
    body: def.body,
    data: {
      achievementId,
    },
  });

  return true;
}

export async function checkReadingAchievements(
  userId: string,
  totalPagesRead: number
): Promise<void> {
  if (totalPagesRead >= 1) {
    await unlockAchievement(userId, "first_reading");
  }
  if (totalPagesRead >= 100) {
    await unlockAchievement(userId, "100_pages");
  }
}

export async function checkStreakAchievements(
  userId: string,
  currentStreak: number
): Promise<void> {
  if (currentStreak >= 7) {
    await unlockAchievement(userId, "7_day_streak");
  }
  if (currentStreak >= 30) {
    await unlockAchievement(userId, "30_day_streak");
  }
}
