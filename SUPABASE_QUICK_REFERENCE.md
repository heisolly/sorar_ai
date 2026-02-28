# Supabase Quick Reference Guide for Sorar AI

## 🚀 Quick Start

### 1. Import the Service

```dart
import 'package:sorar_ai/services/supabase_service.dart';

final supabase = SupabaseService();
```

### 2. Check Authentication Status

```dart
// Check if user is logged in
if (supabase.currentUser != null) {
  print('User is logged in: ${supabase.currentUserId}');
}
```

## 🔐 Authentication Examples

### Sign Up

```dart
try {
  final response = await supabase.signUp(
    email: 'user@example.com',
    password: 'securePassword123',
    metadata: {
      'name': 'John Doe',
    },
  );
  print('User created: ${response.user?.id}');
} catch (e) {
  print('Sign up error: $e');
}
```

### Sign In

```dart
try {
  final response = await supabase.signIn(
    email: 'user@example.com',
    password: 'securePassword123',
  );
  print('Signed in: ${response.user?.id}');
} catch (e) {
  print('Sign in error: $e');
}
```

### Sign Out

```dart
await supabase.signOut();
```

## 👤 User Profile Examples

### Get User Profile

```dart
final profile = await supabase.getUserProfile();
if (profile != null) {
  print('Name: ${profile['name']}');
  print('Age: ${profile['age']}');
  print('Goals: ${profile['main_goals']}');
}
```

### Update User Profile

```dart
await supabase.upsertUserProfile({
  'name': 'Jane Doe',
  'age': 28,
  'gender': 'female',
  'main_goals': ['Build Confidence', 'Reduce Anxiety'],
  'challenges': ['Public Speaking', 'Social Situations'],
  'anxiety_frequency': 'sometimes',
  'confidence_level': 'moderate',
  'communication_style': 'direct',
});
```

### Get Full Profile (with settings and progress)

```dart
final fullProfile = await supabase.getFullUserProfile();
print('Profile: ${fullProfile?['profile']}');
print('Settings: ${fullProfile?['settings']}');
print('Progress: ${fullProfile?['progress']}');
print('Active Goals: ${fullProfile?['active_goals']}');
```

## ⚙️ Settings Examples

### Get User Settings

```dart
final settings = await supabase.getUserSettings();
print('Theme: ${settings?['theme']}');
print('Notifications: ${settings?['notifications_enabled']}');
```

### Update Settings

```dart
await supabase.updateUserSettings({
  'theme': ThemePreference.dark.value,
  'notifications_enabled': true,
  'email_notifications': false,
  'push_notifications': true,
  'language': 'en',
  'timezone': 'UTC',
});
```

## 📊 Progress Tracking Examples

### Get All Progress Metrics

```dart
final progress = await supabase.getUserProgress();
for (var metric in progress) {
  print('${metric['metric_type']}: ${metric['metric_value']}');
}
```

### Get Specific Metric

```dart
final sessions = await supabase.getProgressMetric(
  MetricType.sessionsCompleted,
);
print('Sessions completed: ${sessions?['metric_value']}');
```

### Update Progress Metric

```dart
await supabase.updateProgressMetric(
  metricType: MetricType.sessionsCompleted,
  value: 10,
  metadata: {
    'last_session': DateTime.now().toIso8601String(),
    'total_duration_minutes': 45,
  },
);
```

### Increment Progress

```dart
// Increment sessions completed by 1
await supabase.incrementProgressMetric(
  MetricType.sessionsCompleted,
);

// Increment by custom amount
await supabase.incrementProgressMetric(
  MetricType.streakDays,
  5,
);
```

## 🎯 Goals Examples

### Get User Goals

```dart
// Get all goals
final allGoals = await supabase.getUserGoals();

// Get only active goals
final activeGoals = await supabase.getUserGoals(
  status: GoalStatus.active,
);

// Get completed goals
final completedGoals = await supabase.getUserGoals(
  status: GoalStatus.completed,
);
```

### Create Goal

```dart
final goal = await supabase.createGoal({
  'title': 'Complete 10 practice sessions',
  'description': 'Practice public speaking scenarios',
  'category': GoalCategory.confidence.value,
  'status': GoalStatus.active.value,
  'progress_percentage': 0,
  'target_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
});
print('Goal created: ${goal['id']}');
```

### Update Goal Progress

```dart
await supabase.updateGoal(goalId, {
  'progress_percentage': 50,
  'metadata': {
    'sessions_completed': 5,
    'last_updated': DateTime.now().toIso8601String(),
  },
});
```

### Complete Goal

```dart
await supabase.completeGoal(goalId);
```

### Delete Goal

```dart
await supabase.deleteGoal(goalId);
```

## 📝 Journal Examples

### Get Journal Entries

```dart
// Get all entries
final allEntries = await supabase.getJournalEntries();

// Get last 10 entries
final recentEntries = await supabase.getJournalEntries(limit: 10);
```

### Create Journal Entry

```dart
await supabase.createJournalEntry({
  'title': 'Today\'s Reflection',
  'content': 'I felt more confident during my presentation today.',
  'mood': Mood.confident.value,
  'tags': ['presentation', 'work', 'success'],
  'is_private': true,
});
```

### Update Journal Entry

```dart
await supabase.updateJournalEntry(entryId, {
  'content': 'Updated reflection...',
  'mood': Mood.happy.value,
});
```

### Delete Journal Entry

```dart
await supabase.deleteJournalEntry(entryId);
```

## 💬 Chat Examples

### Get Chat Sessions

```dart
// Get all sessions
final sessions = await supabase.getChatSessions();

// Get last 5 sessions
final recentSessions = await supabase.getChatSessions(limit: 5);
```

### Create Chat Session

```dart
final session = await supabase.createChatSession(
  scenarioId: 'job_interview',
  additionalData: {
    'difficulty': 'medium',
  },
);
print('Session created: ${session['id']}');
```

### Get Chat Messages

```dart
final messages = await supabase.getChatMessages(sessionId);
for (var msg in messages) {
  print('${msg['sender']}: ${msg['content']}');
}
```

### Add Chat Message

```dart
// Text message
await supabase.addChatMessage(
  sessionId: sessionId,
  sender: MessageSender.user.value,
  content: 'Hello, I need help with my interview preparation.',
);

// Voice message
await supabase.addChatMessage(
  sessionId: sessionId,
  sender: MessageSender.user.value,
  audioUrl: 'https://...',
);

// AI response with feedback
await supabase.addChatMessage(
  sessionId: sessionId,
  sender: MessageSender.ai.value,
  content: 'Great! Let\'s start with...',
  feedback: {
    'confidence_score': 8,
    'suggestions': ['Speak slower', 'Make eye contact'],
  },
);
```

### Update Chat Session

```dart
await supabase.updateChatSession(sessionId, {
  'status': 'completed',
  'score': 85,
});
```

## 📁 Storage Examples

### Upload Avatar

```dart
import 'dart:io';

final file = File('path/to/image.jpg');
final avatarUrl = await supabase.uploadAvatar(
  file,
  'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
);
print('Avatar URL: $avatarUrl');
```

### Upload Chat Attachment

```dart
final attachmentUrl = await supabase.uploadChatAttachment(
  file,
  'attachment_${DateTime.now().millisecondsSinceEpoch}.pdf',
);
```

### Upload Voice Recording

```dart
final recordingUrl = await supabase.uploadVoiceRecording(
  file,
  'recording_${DateTime.now().millisecondsSinceEpoch}.mp3',
);
```

### Delete File

```dart
await supabase.deleteFile(
  bucket: SupabaseConfig.avatarsBucket,
  path: '${supabase.currentUserId}/avatar.jpg',
);
```

## 🔴 Realtime Examples

### Subscribe to Chat Messages

```dart
late RealtimeChannel messageChannel;

void setupChatListener(String sessionId) {
  messageChannel = supabase.subscribeToChatMessages(
    sessionId: sessionId,
    onMessage: (message) {
      print('New message: ${message['content']}');
      // Update UI with new message
    },
  );
}

// Don't forget to unsubscribe when done
@override
void dispose() {
  supabase.unsubscribe(messageChannel);
  super.dispose();
}
```

### Subscribe to Progress Updates

```dart
late RealtimeChannel progressChannel;

void setupProgressListener() {
  progressChannel = supabase.subscribeToUserProgress(
    onUpdate: (progress) {
      print('Progress updated: ${progress['metric_type']} = ${progress['metric_value']}');
      // Update UI with new progress
    },
  );
}
```

### Subscribe to Goals Updates

```dart
late RealtimeChannel goalsChannel;

void setupGoalsListener() {
  goalsChannel = supabase.subscribeToUserGoals(
    onUpdate: (goal) {
      print('Goal updated: ${goal['title']}');
      // Update UI with goal changes
    },
  );
}
```

## 📈 Statistics Examples

### Get User Statistics

```dart
final stats = await supabase.getUserStatistics();
print('Total chat sessions: ${stats?['total_chat_sessions']}');
print('Total messages: ${stats?['total_messages']}');
print('Completed goals: ${stats?['completed_goals']}');
print('Active goals: ${stats?['active_goals']}');
print('Journal entries: ${stats?['journal_entries_count']}');
```

## 🛠️ Common Patterns

### Complete Onboarding Flow

```dart
Future<void> completeOnboarding({
  required String name,
  required int age,
  required String gender,
  required List<String> goals,
  required List<String> challenges,
}) async {
  // Update profile
  await supabase.upsertUserProfile({
    'name': name,
    'age': age,
    'gender': gender,
    'main_goals': goals,
    'challenges': challenges,
  });

  // Initialize progress metrics
  await supabase.updateProgressMetric(
    metricType: MetricType.sessionsCompleted,
    value: 0,
  );

  // Create first goal
  await supabase.createGoal({
    'title': 'Complete first coaching session',
    'category': GoalCategory.confidence.value,
    'status': GoalStatus.active.value,
    'progress_percentage': 0,
  });
}
```

### Complete Chat Session Flow

```dart
Future<void> startChatSession(String scenarioId) async {
  // Create session
  final session = await supabase.createChatSession(
    scenarioId: scenarioId,
  );

  // Add initial message
  await supabase.addChatMessage(
    sessionId: session['id'],
    sender: MessageSender.user.value,
    content: 'I\'m ready to start!',
  );

  // Subscribe to new messages
  final channel = supabase.subscribeToChatMessages(
    sessionId: session['id'],
    onMessage: (message) {
      // Handle new messages
    },
  );

  // When session ends
  await supabase.updateChatSession(session['id'], {
    'status': 'completed',
    'score': 85,
  });

  // Increment progress
  await supabase.incrementProgressMetric(
    MetricType.sessionsCompleted,
  );

  // Unsubscribe
  await supabase.unsubscribe(channel);
}
```

## ⚠️ Error Handling

Always wrap Supabase calls in try-catch blocks:

```dart
try {
  final profile = await supabase.getUserProfile();
  // Use profile
} on PostgrestException catch (e) {
  print('Database error: ${e.message}');
} on AuthException catch (e) {
  print('Auth error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## 🔍 Debugging

Enable debug mode in main.dart:

```dart
await Supabase.initialize(
  url: SupabaseConfig.projectUrl,
  anonKey: SupabaseConfig.anonKey,
  debug: true, // Enable debug logging
);
```

## 📚 Additional Resources

- **Full Setup Documentation**: See `SUPABASE_SETUP.md`
- **Supabase Dashboard**: https://supabase.com/dashboard/project/epofftojgzzywrqndptp
- **Supabase Docs**: https://supabase.com/docs
- **Flutter Supabase Docs**: https://supabase.com/docs/reference/dart/introduction
