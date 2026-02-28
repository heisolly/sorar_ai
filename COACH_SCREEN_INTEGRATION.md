# CoachScreen Supabase Integration

## ✅ What Was Added

The `coach_screen.dart` has been successfully integrated with Supabase to save all chat data and track user progress.

## 🔧 Changes Made

### 1. **Imports Added**

```dart
import '../services/supabase_service.dart';
import '../config/supabase_config.dart';
```

### 2. **New State Variables**

```dart
final _supabase = SupabaseService();
String? _sessionId;
String _userName = 'there';
bool _isLoading = true;
```

### 3. **Session Initialization**

When the screen loads, it now:

- ✅ Fetches the user's profile from Supabase
- ✅ Personalizes the welcome message with the user's name
- ✅ Creates a new chat session in the database
- ✅ Stores the session ID for message tracking

### 4. **Message Persistence**

Every message (user and AI) is now:

- ✅ Saved to the `chat_messages` table
- ✅ Linked to the current session
- ✅ Tagged with the correct sender (user or ai)

### 5. **Session Completion**

When the user leaves the screen:

- ✅ Session status is updated to 'completed'
- ✅ A score is assigned (currently hardcoded to 85)
- ✅ User's progress metric `sessions_completed` is incremented

## 📊 Database Flow

```
User Opens Coach Screen
        ↓
1. Load user profile (get name)
        ↓
2. Create chat_session record
        ↓
3. Display personalized welcome message
        ↓
4. Save welcome message to chat_messages
        ↓
User sends message
        ↓
5. Save user message to chat_messages
        ↓
6. AI responds
        ↓
7. Save AI message to chat_messages
        ↓
User leaves screen
        ↓
8. Update session status to 'completed'
        ↓
9. Increment sessions_completed metric
```

## 🎯 Features Enabled

### Personalization

- Welcome message now uses the user's actual name from their profile
- Falls back to "there" if profile not found

### Data Persistence

- All chat conversations are saved
- Session metadata includes:
  - `scenario_id`: 'social_practice'
  - `difficulty`: 'beginner'
  - `scenario_type`: 'coffee_shop'

### Progress Tracking

- Automatically increments `sessions_completed` metric
- Session score recorded (can be enhanced with actual scoring logic)

### Error Handling

- Graceful fallback if Supabase is unavailable
- Debug messages for troubleshooting
- App continues to work even if database operations fail

## 🔍 What Gets Saved

### Chat Session Record

```json
{
  "id": "uuid",
  "user_id": "user-uuid",
  "scenario_id": "social_practice",
  "status": "completed",
  "score": 85,
  "difficulty": "beginner",
  "scenario_type": "coffee_shop",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Chat Message Records

```json
{
  "id": "uuid",
  "session_id": "session-uuid",
  "sender": "user" | "ai",
  "content": "message text",
  "created_at": "timestamp"
}
```

### Progress Update

```json
{
  "user_id": "user-uuid",
  "metric_type": "sessions_completed",
  "metric_value": 5, // incremented by 1
  "updated_at": "timestamp"
}
```

## 🚀 Future Enhancements

You can easily extend this to:

1. **Load Previous Sessions**

   ```dart
   final sessions = await _supabase.getChatSessions(limit: 10);
   ```

2. **Resume a Session**

   ```dart
   final messages = await _supabase.getChatMessages(sessionId);
   ```

3. **Real-time Updates**

   ```dart
   _supabase.subscribeToChatMessages(
     sessionId: _sessionId!,
     onMessage: (message) {
       // Add message to UI in real-time
     },
   );
   ```

4. **Calculate Dynamic Scores**
   - Analyze conversation quality
   - Track response times
   - Measure confidence indicators

5. **Add Voice Messages**

   ```dart
   final audioUrl = await _supabase.uploadVoiceRecording(
     audioFile,
     'recording_${DateTime.now().millisecondsSinceEpoch}.mp3',
   );

   await _supabase.addChatMessage(
     sessionId: _sessionId!,
     sender: MessageSender.user.value,
     audioUrl: audioUrl,
   );
   ```

## 📈 Analytics Available

With this integration, you can now query:

- Total sessions per user
- Average session duration
- Most common scenarios
- User progress over time
- Conversation patterns

## 🔐 Security

- ✅ All data is protected by Row Level Security (RLS)
- ✅ Users can only access their own sessions and messages
- ✅ Session IDs are UUIDs (not guessable)

## 🎉 Summary

The CoachScreen is now fully integrated with Supabase! Every coaching session is:

- ✅ Tracked in the database
- ✅ Personalized with user data
- ✅ Contributing to progress metrics
- ✅ Available for future analytics

All chat history is preserved and can be used for:

- User progress reports
- AI model training
- Conversation analysis
- Feature improvements

---

**Integration Status**: ✅ Complete  
**File**: `lib/screens/coach_screen.dart`  
**Lines Added**: ~90 lines of Supabase integration code
