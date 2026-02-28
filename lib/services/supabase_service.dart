import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Supabase Service
///
/// Provides a centralized service for all Supabase operations.
/// This includes authentication, database queries, storage, and realtime subscriptions.
class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // Get current user ID
  String? get currentUserId => currentUser?.id;

  // ==================== Authentication ====================

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Delete current user account
  /// WARNING: This will delete the user and all their data via RLS or triggers
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    // In Supabase, deleting a user from the client side is tricky.
    // Usually, we call a database function or use the Admin API (which we shouldn't expose).
    // However, for this implementation, we will assume there is an edge function or
    // we use the RPC to delete personal data and then sign out.
    // For a real production app, you'd use a service role in an edge function.

    // As a placeholder for client-side deletion (which triggers RLS cleanup if configured):
    await client.rpc('delete_user_data');
    await client.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Update user metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    return await client.auth.updateUser(UserAttributes(data: metadata));
  }

  // ==================== User Profile ====================

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    final id = userId ?? currentUserId;
    if (id == null) return null;

    final response = await client
        .from(SupabaseConfig.userProfilesTable)
        .select()
        .eq('user_id', id)
        .maybeSingle();

    return response;
  }

  /// Create or update user profile
  Future<Map<String, dynamic>> upsertUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    if (!profileData.containsKey('user_id')) {
      profileData['user_id'] = currentUserId;
    }

    final response = await client
        .from(SupabaseConfig.userProfilesTable)
        .upsert(profileData, onConflict: 'user_id')
        .select()
        .single();

    return response;
  }

  /// Get full user profile (using database function)
  Future<Map<String, dynamic>?> getFullUserProfile([String? userId]) async {
    final id = userId ?? currentUserId;
    if (id == null) return null;

    final response = await client.rpc(
      SupabaseConfig.getUserFullProfileFunction,
      params: {'user_uuid': id},
    );

    return response;
  }

  // ==================== User Settings ====================

  /// Get user settings
  Future<Map<String, dynamic>?> getUserSettings([String? userId]) async {
    final id = userId ?? currentUserId;
    if (id == null) return null;

    final response = await client
        .from(SupabaseConfig.userSettingsTable)
        .select()
        .eq('user_id', id)
        .maybeSingle();

    return response;
  }

  /// Update user settings
  Future<Map<String, dynamic>> updateUserSettings(
    Map<String, dynamic> settings,
  ) async {
    if (!settings.containsKey('user_id')) {
      settings['user_id'] = currentUserId;
    }

    final response = await client
        .from(SupabaseConfig.userSettingsTable)
        .upsert(settings, onConflict: 'user_id')
        .select()
        .single();

    return response;
  }

  // ==================== User Progress ====================

  /// Get user progress metrics
  Future<List<Map<String, dynamic>>> getUserProgress([String? userId]) async {
    final id = userId ?? currentUserId;
    if (id == null) return [];

    final response = await client
        .from(SupabaseConfig.userProgressTable)
        .select()
        .eq('user_id', id);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get specific progress metric
  Future<Map<String, dynamic>?> getProgressMetric(
    MetricType metricType, [
    String? userId,
  ]) async {
    final id = userId ?? currentUserId;
    if (id == null) return null;

    final response = await client
        .from(SupabaseConfig.userProgressTable)
        .select()
        .eq('user_id', id)
        .eq('metric_type', metricType.value)
        .maybeSingle();

    return response;
  }

  /// Update progress metric
  Future<Map<String, dynamic>> updateProgressMetric({
    required MetricType metricType,
    required num value,
    Map<String, dynamic>? metadata,
  }) async {
    final data = {
      'user_id': currentUserId,
      'metric_type': metricType.value,
      'metric_value': value,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await client
        .from(SupabaseConfig.userProgressTable)
        .upsert(data, onConflict: 'user_id, metric_type')
        .select()
        .single();

    return response;
  }

  /// Increment progress metric
  Future<void> incrementProgressMetric(
    MetricType metricType, [
    num incrementBy = 1,
  ]) async {
    final current = await getProgressMetric(metricType);
    final currentValue = current?['metric_value'] ?? 0;

    await updateProgressMetric(
      metricType: metricType,
      value: currentValue + incrementBy,
    );
  }

  // ==================== User Goals ====================

  /// Get user goals
  Future<List<Map<String, dynamic>>> getUserGoals({
    GoalStatus? status,
    String? userId,
  }) async {
    final id = userId ?? currentUserId;
    if (id == null) return [];

    var query = client
        .from(SupabaseConfig.userGoalsTable)
        .select()
        .eq('user_id', id);

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create goal
  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    if (!goalData.containsKey('user_id')) {
      goalData['user_id'] = currentUserId;
    }

    final response = await client
        .from(SupabaseConfig.userGoalsTable)
        .insert(goalData)
        .select()
        .single();

    return response;
  }

  /// Update goal
  Future<Map<String, dynamic>> updateGoal(
    String goalId,
    Map<String, dynamic> updates,
  ) async {
    final response = await client
        .from(SupabaseConfig.userGoalsTable)
        .update(updates)
        .eq('id', goalId)
        .select()
        .single();

    return response;
  }

  /// Complete goal
  Future<Map<String, dynamic>> completeGoal(String goalId) async {
    return await updateGoal(goalId, {
      'status': GoalStatus.completed.value,
      'progress_percentage': 100,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Delete goal
  Future<void> deleteGoal(String goalId) async {
    await client.from(SupabaseConfig.userGoalsTable).delete().eq('id', goalId);
  }

  // ==================== Journal Entries ====================

  /// Get journal entries
  Future<List<Map<String, dynamic>>> getJournalEntries({
    int? limit,
    String? userId,
  }) async {
    final id = userId ?? currentUserId;
    if (id == null) return [];

    var query = client
        .from(SupabaseConfig.journalEntriesTable)
        .select()
        .eq('user_id', id)
        .order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create journal entry
  Future<Map<String, dynamic>> createJournalEntry(
    Map<String, dynamic> entryData,
  ) async {
    if (!entryData.containsKey('user_id')) {
      entryData['user_id'] = currentUserId;
    }

    final response = await client
        .from(SupabaseConfig.journalEntriesTable)
        .insert(entryData)
        .select()
        .single();

    return response;
  }

  /// Update journal entry
  Future<Map<String, dynamic>> updateJournalEntry(
    String entryId,
    Map<String, dynamic> updates,
  ) async {
    final response = await client
        .from(SupabaseConfig.journalEntriesTable)
        .update(updates)
        .eq('id', entryId)
        .select()
        .single();

    return response;
  }

  /// Delete journal entry
  Future<void> deleteJournalEntry(String entryId) async {
    await client
        .from(SupabaseConfig.journalEntriesTable)
        .delete()
        .eq('id', entryId);
  }

  // ==================== Chat Sessions ====================

  /// Get chat sessions
  Future<List<Map<String, dynamic>>> getChatSessions({
    int? limit,
    String? userId,
  }) async {
    final id = userId ?? currentUserId;
    if (id == null) return [];

    var query = client
        .from(SupabaseConfig.chatSessionsTable)
        .select()
        .eq('user_id', id)
        .order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create chat session
  Future<Map<String, dynamic>> createChatSession({
    String? scenarioId,
    Map<String, dynamic>? additionalData,
  }) async {
    final data = {
      'user_id': currentUserId,
      'scenario_id': scenarioId,
      'status': 'active',
      ...?additionalData,
    };

    final response = await client
        .from(SupabaseConfig.chatSessionsTable)
        .insert(data)
        .select()
        .single();

    return response;
  }

  /// Update chat session
  Future<Map<String, dynamic>> updateChatSession(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    final response = await client
        .from(SupabaseConfig.chatSessionsTable)
        .update(updates)
        .eq('id', sessionId)
        .select()
        .single();

    return response;
  }

  /// Delete chat session and its messages
  Future<void> deleteChatSession(String sessionId) async {
    try {
      // First delete all messages associated with this session with a timeout
      await client
          .from(SupabaseConfig.chatMessagesTable)
          .delete()
          .eq('session_id', sessionId)
          .timeout(const Duration(seconds: 10));

      // Then delete the session itself
      await client
          .from(SupabaseConfig.chatSessionsTable)
          .delete()
          .eq('id', sessionId)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Error in deleteChatSession: $e");
      rethrow;
    }
  }

  /// Get chat messages for a session
  Future<List<Map<String, dynamic>>> getChatMessages(String sessionId) async {
    final response = await client
        .from(SupabaseConfig.chatMessagesTable)
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Add chat message
  Future<Map<String, dynamic>> addChatMessage({
    required String sessionId,
    required String sender,
    String? content,
    String? audioUrl,
    Map<String, dynamic>? feedback,
  }) async {
    final data = {
      'session_id': sessionId,
      'sender': sender,
      if (content != null) 'content': content,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (feedback != null) 'feedback': feedback,
    };

    final response = await client
        .from(SupabaseConfig.chatMessagesTable)
        .insert(data)
        .select()
        .single();

    return response;
  }

  // ==================== Statistics ====================

  /// Get user statistics
  Future<Map<String, dynamic>?> getUserStatistics([String? userId]) async {
    final id = userId ?? currentUserId;
    if (id == null) return null;

    final response = await client
        .from(SupabaseConfig.userStatisticsView)
        .select()
        .eq('user_id', id)
        .maybeSingle();

    return response;
  }

  // ==================== Storage ====================

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file,
  }) async {
    await client.storage.from(bucket).upload(path, file);
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Upload avatar
  Future<String> uploadAvatar(dynamic file, String fileName) async {
    final path = SupabaseConfig.getUserStoragePath(currentUserId!, fileName);
    return await uploadFile(
      bucket: SupabaseConfig.avatarsBucket,
      path: path,
      file: file,
    );
  }

  /// Upload chat attachment
  Future<String> uploadChatAttachment(dynamic file, String fileName) async {
    final path = SupabaseConfig.getUserStoragePath(currentUserId!, fileName);
    return await uploadFile(
      bucket: SupabaseConfig.chatAttachmentsBucket,
      path: path,
      file: file,
    );
  }

  /// Upload voice recording
  Future<String> uploadVoiceRecording(dynamic file, String fileName) async {
    final path = SupabaseConfig.getUserStoragePath(currentUserId!, fileName);
    return await uploadFile(
      bucket: SupabaseConfig.voiceRecordingsBucket,
      path: path,
      file: file,
    );
  }

  /// Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await client.storage.from(bucket).remove([path]);
  }

  // ==================== Realtime ====================

  /// Subscribe to chat messages
  RealtimeChannel subscribeToChatMessages({
    required String sessionId,
    required void Function(Map<String, dynamic>) onMessage,
  }) {
    return client
        .channel(SupabaseConfig.chatMessagesChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.chatMessagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to user progress updates
  RealtimeChannel subscribeToUserProgress({
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    return client
        .channel(SupabaseConfig.userProgressChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.userProgressTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to chat sessions updates
  RealtimeChannel subscribeToChatSessions({
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    return client
        .channel('public:chat_sessions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.chatSessionsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to user goals updates
  RealtimeChannel subscribeToUserGoals({
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    return client
        .channel(SupabaseConfig.userGoalsChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.userGoalsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
