/// Supabase Configuration for Parot
///
/// This file contains all Supabase-related configuration constants.
/// DO NOT commit this file to version control with real credentials.
/// Consider using environment variables or flutter_dotenv for production.
library;

class SupabaseConfig {
  // Project Information
  static const String projectId = 'epofftojgzzywrqndptp';
  static const String projectUrl = 'https://epofftojgzzywrqndptp.supabase.co';
  static const String region = 'eu-central-2';

  // API Keys
  // Use the publishable key for better security and independent rotation
  static const String publishableKey =
      'sb_publishable_F24uzDfNsNZai6VVnGIJ-Q_-wGXy3jS';

  // Legacy anon key (JWT-based) - kept for compatibility
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwb2ZmdG9qZ3p6eXdycW5kcHRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2MjM2OTAsImV4cCI6MjA4NTE5OTY5MH0.7QFIc_u4UmKbZNlYGmujJUZSUw3C4occGO6ojl9jGzc';

  // Storage Buckets
  static const String appStorageBucket = 'app_storage';
  static const String avatarsBucket = 'avatars';
  static const String chatAttachmentsBucket = 'chat_attachments';
  static const String voiceRecordingsBucket = 'voice_recordings';

  // Storage Limits (in bytes)
  static const int avatarSizeLimit = 5242880; // 5 MB
  static const int chatAttachmentSizeLimit = 10485760; // 10 MB
  static const int voiceRecordingSizeLimit = 52428800; // 50 MB

  // Table Names
  static const String userProfilesTable = 'user_profiles';
  static const String userSettingsTable = 'user_settings';
  static const String userProgressTable = 'user_progress';
  static const String userGoalsTable = 'user_goals';
  static const String journalEntriesTable = 'journal_entries';
  static const String chatSessionsTable = 'chat_sessions';
  static const String chatMessagesTable = 'chat_messages';
  static const String waitlistTable = 'waitlist';
  static const String siteVisitsTable = 'site_visits';

  // Views
  static const String chatSessionsWithCountsView = 'chat_sessions_with_counts';
  static const String userStatisticsView = 'user_statistics';

  // Database Functions
  static const String getUserFullProfileFunction = 'get_user_full_profile';

  // Realtime Channels
  static const String chatMessagesChannel = 'chat_messages_channel';
  static const String userProgressChannel = 'user_progress_channel';
  static const String userGoalsChannel = 'user_goals_channel';

  // Helper method to get storage URL for a file
  static String getStorageUrl(String bucket, String path) {
    return '$projectUrl/storage/v1/object/public/$bucket/$path';
  }

  // Helper method to get user-specific storage path
  static String getUserStoragePath(String userId, String fileName) {
    return '$userId/$fileName';
  }
}

/// Enum for user goal status
enum GoalStatus {
  active,
  completed,
  paused,
  cancelled;

  String get value => name;

  static GoalStatus fromString(String value) {
    return GoalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalStatus.active,
    );
  }
}

/// Enum for theme preferences
enum ThemePreference {
  light,
  dark,
  system;

  String get value => name;

  static ThemePreference fromString(String value) {
    return ThemePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemePreference.system,
    );
  }
}

/// Enum for message sender
enum MessageSender {
  user,
  ai;

  String get value => name;

  static MessageSender fromString(String value) {
    return MessageSender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageSender.user,
    );
  }
}

/// Enum for mood tracking
enum Mood {
  happy,
  sad,
  anxious,
  confident,
  neutral,
  excited,
  stressed;

  String get value => name;

  static Mood fromString(String value) {
    return Mood.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Mood.neutral,
    );
  }
}

/// Enum for progress metric types
enum MetricType {
  sessionsCompleted('sessions_completed'),
  goalsAchieved('goals_achieved'),
  streakDays('streak_days'),
  totalMessages('total_messages'),
  confidenceScore('confidence_score'),
  anxietyReduction('anxiety_reduction');

  final String value;
  const MetricType(this.value);

  static MetricType fromString(String value) {
    return MetricType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MetricType.sessionsCompleted,
    );
  }
}

/// Enum for goal categories
enum GoalCategory {
  confidence,
  anxiety,
  communication,
  leadership,
  relationships,
  career,
  personal;

  String get value => name;

  static GoalCategory fromString(String value) {
    return GoalCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalCategory.personal,
    );
  }
}
