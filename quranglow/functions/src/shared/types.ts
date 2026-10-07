export interface UserProfileData {
  uid: string;
  displayName: string | null;
  email: string | null;
  photoUrl: string | null;
  accountType: string;
  isAnonymous: boolean;
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  lastActiveAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  lastSyncAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  schemaVersion: number;
}

export interface UserEventPayload {
  type: string;
  timestamp: string;
  sessionId?: string;
  deviceId?: string;
  appVersion?: string;
  platform?: string;
  metadata?: Record<string, any>;
}

export interface StreakData {
  currentStreak: number;
  longestStreak: number;
  lastActiveDate: string; // YYYY-MM-DD
  totalActiveDays: number;
}

export interface DailyActivityData {
  date: string; // YYYY-MM-DD
  pagesRead: number;
  versesRead: number;
  readingMinutes: number;
  listeningMinutes: number;
  memorizedVerses: number;
  revisionMinutes: number;
  completedDailyGoal: boolean;
  updatedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
}

export interface AchievementItem {
  id: string;
  title: string;
  description: string;
  unlockedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  category: string;
}
