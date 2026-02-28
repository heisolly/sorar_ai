# User Profile Integration - Setup Guide

## Overview

The personalization data from the onboarding flow is now saved to Supabase and displayed throughout the dashboard.

## What Was Implemented

### 1. **UserProfileService** (`lib/services/user_profile_service.dart`)

A service to handle all user profile operations:

- `saveUserProfile()` - Saves all personalization data to Supabase
- `getUserProfile()` - Retrieves complete user profile
- `getUserName()` - Gets just the user's name
- `updateProfileField()` - Updates specific profile fields

### 2. **Database Schema** (`supabase_migration_user_profiles.sql`)

Created a `user_profiles` table with:

- **Fields**: name, gender, age, main_goals, challenges, anxiety_frequency, confidence_level, tried_coaching_before, communication_style
- **Security**: Row Level Security (RLS) policies ensure users can only access their own data
- **Performance**: Indexed on user_id for fast lookups

### 3. **PersonalizationFlow Updates**

- Now saves all user responses to Supabase after completion
- Data is saved before navigating to dashboard
- Error handling for failed saves

### 4. **HomeScreen Updates**

- Converted to StatefulWidget
- Fetches and displays user's actual name
- Shows personalized greeting: "Good Morning, [Name]"
- Loading state while fetching data

## Setup Instructions

### Step 1: Run Database Migration

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `supabase_migration_user_profiles.sql`
4. Click **Run** to create the table and policies

### Step 2: Test the Flow

1. Sign up as a new user
2. Complete the personalization flow
3. Check that your name appears on the home screen
4. Verify data in Supabase:
   - Go to **Table Editor** → `user_profiles`
   - You should see your profile data

## Data Structure

```dart
{
  "user_id": "uuid",
  "name": "John Doe",
  "gender": "Male",
  "age": 25,
  "main_goals": ["Better Dating Skills", "Building Confidence"],
  "challenges": ["Starting conversations", "Making eye contact"],
  "anxiety_frequency": "Sometimes",
  "confidence_level": "Moderate",
  "tried_coaching_before": "No, this is my first time",
  "communication_style": "Friendly and warm",
  "created_at": "2024-02-04T08:00:00Z",
  "updated_at": "2024-02-04T08:00:00Z"
}
```

## Next Steps

### Recommended Enhancements:

1. **Profile Settings Screen** - Allow users to edit their profile
2. **Personalized Recommendations** - Use goals/challenges to suggest training
3. **Progress Tracking** - Track improvement based on initial confidence level
4. **AI Coaching** - Use communication style to personalize AI responses
5. **Dashboard Widgets** - Display goals and challenges on dashboard

### Example Usage:

```dart
// Get full profile
final profileService = UserProfileService();
final profile = await profileService.getUserProfile();
print(profile?['main_goals']); // ["Better Dating Skills", ...]

// Update a field
await profileService.updateProfileField('confidence_level', 'High');
```

## Security Notes

- ✅ RLS policies ensure data privacy
- ✅ Users can only read/write their own profiles
- ✅ Authentication required for all operations
- ✅ Automatic user_id association

## Troubleshooting

**Profile not loading?**

- Check Supabase connection
- Verify migration was run successfully
- Check browser console for errors

**Name not showing?**

- Ensure user completed personalization flow
- Check that data was saved to `user_profiles` table
- Verify user is authenticated

**Permission errors?**

- Ensure RLS policies are enabled
- Check that user_id matches auth.uid()
