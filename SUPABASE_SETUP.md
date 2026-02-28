# Supabase Setup for Sorar AI

## Project Information

- **Project Name**: Sorar
- **Project ID**: `epofftojgzzywrqndptp`
- **Project URL**: `https://epofftojgzzywrqndptp.supabase.co`
- **Region**: `eu-central-2`
- **Status**: ACTIVE_HEALTHY

## API Keys

### Publishable Key (Recommended)

```
sb_publishable_F24uzDfNsNZai6VVnGIJ-Q_-wGXy3jS
```

### Legacy Anon Key (JWT-based)

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwb2ZmdG9qZ3p6eXdycW5kcHRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2MjM2OTAsImV4cCI6MjA4NTE5OTY5MH0.7QFIc_u4UmKbZNlYGmujJUZSUw3C4occGO6ojl9jGzc
```

## Database Schema

### Tables Created

#### 1. **user_profiles**

Stores user profile information from onboarding.

**Columns:**

- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users, Unique)
- `name` (TEXT)
- `gender` (TEXT, nullable)
- `age` (INTEGER, nullable)
- `main_goals` (TEXT[], nullable)
- `challenges` (TEXT[], nullable)
- `anxiety_frequency` (TEXT, nullable)
- `confidence_level` (TEXT, nullable)
- `tried_coaching_before` (TEXT, nullable)
- `communication_style` (TEXT, nullable)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

**RLS Policies:**

- Users can view, insert, and update their own profiles

#### 2. **user_settings**

Stores user app preferences and settings.

**Columns:**

- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users, Unique)
- `theme` (TEXT: 'light', 'dark', 'system')
- `notifications_enabled` (BOOLEAN)
- `email_notifications` (BOOLEAN)
- `push_notifications` (BOOLEAN)
- `language` (TEXT)
- `timezone` (TEXT)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

**RLS Policies:**

- Users can view, insert, and update their own settings

#### 3. **user_progress**

Tracks user achievements and progress metrics.

**Columns:**

- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users)
- `metric_type` (TEXT) - e.g., 'sessions_completed', 'goals_achieved', 'streak_days'
- `metric_value` (NUMERIC)
- `metadata` (JSONB)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)
- **Unique constraint**: (user_id, metric_type)

**RLS Policies:**

- Users can view, insert, and update their own progress

#### 4. **user_goals**

Stores user-defined goals and tracks their progress.

**Columns:**

- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users)
- `title` (TEXT)
- `description` (TEXT, nullable)
- `category` (TEXT, nullable) - e.g., 'confidence', 'anxiety', 'communication'
- `target_date` (DATE, nullable)
- `status` (TEXT: 'active', 'completed', 'paused', 'cancelled')
- `progress_percentage` (INTEGER, 0-100)
- `metadata` (JSONB)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)
- `completed_at` (TIMESTAMPTZ, nullable)

**RLS Policies:**

- Users can view, insert, update, and delete their own goals

#### 5. **journal_entries**

Stores user journal entries and reflections.

**Columns:**

- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users)
- `title` (TEXT, nullable)
- `content` (TEXT)
- `mood` (TEXT, nullable) - e.g., 'happy', 'sad', 'anxious', 'confident'
- `tags` (TEXT[])
- `is_private` (BOOLEAN)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

**RLS Policies:**

- Users can view, insert, update, and delete their own journal entries

#### 6. **chat_sessions**

Stores AI coaching chat sessions.

**Columns:**

- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users)
- `scenario_id` (TEXT, nullable)
- `status` (TEXT, nullable)
- `score` (NUMERIC, nullable)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

**RLS Policies:**

- Users can view, insert, and update their own chat sessions

#### 7. **chat_messages**

Stores individual messages within chat sessions.

**Columns:**

- `id` (UUID, Primary Key)
- `session_id` (UUID, Foreign Key to chat_sessions)
- `sender` (TEXT, nullable) - 'user' or 'ai'
- `content` (TEXT, nullable)
- `audio_url` (TEXT, nullable)
- `feedback` (JSONB, nullable)
- `created_at` (TIMESTAMPTZ)

**RLS Policies:**

- Users can view and insert messages for their own sessions

#### 8. **waitlist** (existing)

Stores waitlist signups.

#### 9. **site_visits** (existing)

Tracks site visits for analytics.

### Views

#### 1. **chat_sessions_with_counts**

Provides chat sessions with message counts and last message timestamp.

#### 2. **user_statistics**

Aggregates user statistics including:

- Total chat sessions
- Total messages
- Completed goals
- Active goals
- Journal entries count
- Last chat session timestamp

## Storage Buckets

### 1. **app_storage**

- **Public**: Yes
- **Size Limit**: None
- **Allowed Types**: All
- **Use**: General app storage

### 2. **avatars**

- **Public**: Yes
- **Size Limit**: 5 MB
- **Allowed Types**: image/jpeg, image/png, image/webp, image/gif
- **Use**: User profile pictures
- **Policies**: Users can upload/update/delete their own avatars (stored in `{user_id}/` folder)

### 3. **chat_attachments**

- **Public**: No
- **Size Limit**: 10 MB
- **Allowed Types**: image/jpeg, image/png, image/webp, image/gif, application/pdf, text/plain
- **Use**: Files shared in chat sessions
- **Policies**: Users can only access their own attachments (stored in `{user_id}/` folder)

### 4. **voice_recordings**

- **Public**: No
- **Size Limit**: 50 MB
- **Allowed Types**: audio/mpeg, audio/mp4, audio/wav, audio/webm, audio/ogg
- **Use**: Voice messages and recordings
- **Policies**: Users can only access their own recordings (stored in `{user_id}/` folder)

## Database Functions

### 1. **handle_updated_at()**

Automatically updates the `updated_at` timestamp on row updates.

- Applied to: user_profiles, user_settings, user_progress, user_goals, journal_entries, chat_sessions, chat_messages

### 2. **handle_new_user()**

Automatically creates user profile and settings when a new user signs up.

- Triggered on: auth.users INSERT

### 3. **get_user_full_profile(user_uuid UUID)**

Returns a complete user profile including:

- Profile data
- Settings
- Progress metrics
- Active goals

**Usage:**

```sql
SELECT * FROM get_user_full_profile(auth.uid());
```

## Realtime

The following tables have realtime enabled:

- `chat_messages`
- `chat_sessions`
- `user_progress`
- `user_goals`
- `user_profiles`

## Extensions Enabled

- `pgcrypto` - Cryptographic functions
- `uuid-ossp` - UUID generation
- `pg_stat_statements` - Query performance monitoring

## Security Notes

### Current Warnings (Non-Critical)

1. **Leaked Password Protection**: Currently disabled. Consider enabling in Auth settings for enhanced security.

2. **Permissive RLS Policies**: The `waitlist` and `site_visits` tables allow unrestricted INSERT access for anonymous users. This is intentional for signup/tracking purposes.

3. **Security Definer Views**: The views `chat_sessions_with_counts` and `user_statistics` use SECURITY DEFINER. This is acceptable for read-only aggregation views.

4. **Function Search Path**: Some functions have mutable search paths. This is a low-priority warning.

### All Tables Have RLS Enabled ✅

All public tables now have Row Level Security (RLS) enabled with appropriate policies.

## Flutter/Dart Integration

### Add Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

### Initialize Supabase

In your `main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://epofftojgzzywrqndptp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwb2ZmdG9qZ3p6eXdycW5kcHRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2MjM2OTAsImV4cCI6MjA4NTE5OTY5MH0.7QFIc_u4UmKbZNlYGmujJUZSUw3C4occGO6ojl9jGzc',
  );

  runApp(MyApp());
}

// Get Supabase client anywhere in your app
final supabase = Supabase.instance.client;
```

### Example Usage

#### Create User Profile

```dart
final userId = supabase.auth.currentUser!.id;

await supabase.from('user_profiles').insert({
  'user_id': userId,
  'name': 'John Doe',
  'age': 25,
  'gender': 'male',
  'main_goals': ['Build Confidence', 'Reduce Anxiety'],
  'challenges': ['Public Speaking', 'Social Situations'],
});
```

#### Fetch User Profile

```dart
final profile = await supabase
    .from('user_profiles')
    .select()
    .eq('user_id', supabase.auth.currentUser!.id)
    .single();
```

#### Upload Avatar

```dart
final file = File('path/to/image.jpg');
final userId = supabase.auth.currentUser!.id;
final fileName = 'avatar.jpg';

await supabase.storage
    .from('avatars')
    .upload('$userId/$fileName', file);

// Get public URL
final avatarUrl = supabase.storage
    .from('avatars')
    .getPublicUrl('$userId/$fileName');
```

#### Subscribe to Realtime Updates

```dart
final subscription = supabase
    .from('chat_messages')
    .stream(primaryKey: ['id'])
    .eq('session_id', sessionId)
    .listen((data) {
      // Handle new messages
      print('New message: $data');
    });

// Don't forget to cancel when done
subscription.cancel();
```

#### Create Chat Session

```dart
final session = await supabase.from('chat_sessions').insert({
  'user_id': supabase.auth.currentUser!.id,
  'scenario_id': 'job_interview',
  'status': 'active',
}).select().single();

// Add message to session
await supabase.from('chat_messages').insert({
  'session_id': session['id'],
  'sender': 'user',
  'content': 'Hello, I need help with my interview preparation.',
});
```

#### Track User Progress

```dart
await supabase.from('user_progress').upsert({
  'user_id': supabase.auth.currentUser!.id,
  'metric_type': 'sessions_completed',
  'metric_value': 5,
  'metadata': {'last_session': DateTime.now().toIso8601String()},
});
```

#### Create Goal

```dart
await supabase.from('user_goals').insert({
  'user_id': supabase.auth.currentUser!.id,
  'title': 'Complete 10 practice sessions',
  'description': 'Practice public speaking scenarios',
  'category': 'confidence',
  'status': 'active',
  'progress_percentage': 0,
  'target_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
});
```

#### Add Journal Entry

```dart
await supabase.from('journal_entries').insert({
  'user_id': supabase.auth.currentUser!.id,
  'title': 'Today\'s Reflection',
  'content': 'I felt more confident during my presentation today.',
  'mood': 'confident',
  'tags': ['presentation', 'work', 'success'],
  'is_private': true,
});
```

## Next Steps

1. **Enable Leaked Password Protection** in Supabase Dashboard → Authentication → Password Protection
2. **Set up Email Templates** in Supabase Dashboard → Authentication → Email Templates
3. **Configure OAuth Providers** if needed (Google, Apple, etc.)
4. **Set up Database Backups** in Supabase Dashboard → Database → Backups
5. **Monitor Usage** in Supabase Dashboard → Reports

## Migrations Applied

1. `enable_rls_on_public_tables` - Enabled RLS on waitlist and site_visits tables
2. `setup_storage_buckets_and_policies` - Created storage buckets with proper policies
3. `create_additional_app_tables` - Created user_settings, user_progress, user_goals, journal_entries
4. `setup_database_functions_and_triggers` - Created utility functions and triggers
5. `enable_extensions_and_views` - Enabled extensions and created helpful views

## Support

For issues or questions:

- Supabase Documentation: https://supabase.com/docs
- Supabase Dashboard: https://supabase.com/dashboard/project/epofftojgzzywrqndptp
