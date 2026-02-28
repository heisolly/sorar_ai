import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class UserProfileService {
  final _supabase = Supabase.instance.client;

  // Simple in-memory cache
  static Map<String, dynamic>? _cachedProfile;
  static String? _cachedUserId;

  // Save user profile data (legacy/specific fields)
  Future<void> saveUserProfile({
    required String userName,
    required String gender,
    required int age,
    required List<String> mainGoals,
    required List<String> challenges,
    required String anxietyFrequency,
    required String confidenceLevel,
    required String triedCoachingBefore,
    required String communicationStyle,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final profileData = {
      'user_id': userId,
      'name': userName,
      'gender': gender,
      'age': age,
      'main_goals': mainGoals,
      'challenges': challenges,
      'anxiety_frequency': anxietyFrequency,
      'confidence_level': confidenceLevel,
      'tried_coaching_before': triedCoachingBefore,
      'communication_style': communicationStyle,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Upsert (insert or update) the profile
    await _supabase
        .from('user_profiles')
        .upsert(profileData, onConflict: 'user_id');

    // Update cache
    _cachedProfile = profileData;
    _cachedUserId = userId;
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _cachedProfile = null;
      _cachedUserId = null;
      return null;
    }

    // Return cached if valid
    if (_cachedProfile != null && _cachedUserId == userId) {
      debugPrint('DEBUG: Returning cached profile for user: $userId');
      return _cachedProfile;
    }

    debugPrint('DEBUG: Fetching profile from DB for user: $userId');
    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    _cachedProfile = response;
    _cachedUserId = userId;

    return response;
  }

  // Get user name
  Future<String> getUserName() async {
    try {
      // First, try to get from user_profiles table
      final profile = await getUserProfile();

      if (profile != null &&
          profile['name'] != null &&
          profile['name'].toString().isNotEmpty) {
        final profileName = profile['name'].toString();
        // Don't return if it's an email address
        if (!profileName.contains('@')) {
          final firstName = profileName.split(' ').first;
          return firstName;
        }
      }

      // Fallback to auth metadata (from sign up)
      final user = _supabase.auth.currentUser;

      if (user?.userMetadata?['full_name'] != null) {
        final metadataName = user!.userMetadata!['full_name'].toString();
        // Don't return if it's an email address
        if (!metadataName.contains('@')) {
          final firstName = metadataName.split(' ').first;
          return firstName;
        }
      }

      // Last fallback: extract name from email
      if (user?.email != null) {
        final email = user!.email!;
        final emailName = email.split('@').first;

        // Remove dots, underscores, and numbers, then capitalize each word
        final cleanNameParts = emailName
            .replaceAll(RegExp(r'[._\d]'), ' ')
            .trim()
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map(
              (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .toList();

        // Return only the first name
        final firstName = cleanNameParts.isNotEmpty
            ? cleanNameParts.first
            : 'User';
        return firstName;
      }

      return 'User';
    } catch (e) {
      debugPrint('DEBUG: Error in getUserName: $e');
      return 'User';
    }
  }

  // Update specific profile field (Legacy support)
  Future<void> updateProfileField(String field, dynamic value) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('user_profiles')
        .update({field: value, 'updated_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId);

    // Invalidate cache
    _cachedProfile = null;
  }

  // Update full user profile with arbitrary fields
  Future<void> updateFullUserProfile(Map<String, dynamic> data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Filter out protected fields if necessary, or just merge
    final profileData = {
      ...data,
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Using upsert ensures we create a profile if it doesn't exist
    await _supabase
        .from('user_profiles')
        .upsert(profileData, onConflict: 'user_id');

    // Update cache
    _cachedProfile = profileData;
    _cachedUserId = userId;
  }

  // Clear cache manually
  void clearCache() {
    _cachedProfile = null;
    _cachedUserId = null;
  }
}
