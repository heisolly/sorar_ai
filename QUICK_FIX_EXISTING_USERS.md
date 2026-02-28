# Quick Fix for Existing Users

## Problem

You signed in before the database migration was run, so your name wasn't saved.

## Solution Options

### Option 1: Sign Up Again (Recommended)

1. Sign out from the app
2. Use a different email to sign up
3. Complete the personalization flow with your real name
4. Your name will be saved and displayed correctly

### Option 2: Manually Add Your Profile (Advanced)

1. Go to Supabase Dashboard → SQL Editor
2. Run this query (replace with your actual data):

```sql
-- First, find your user_id
SELECT id, email FROM auth.users WHERE email = 'your.email@example.com';

-- Then insert your profile (use the id from above)
INSERT INTO user_profiles (user_id, name, gender, age, main_goals, challenges, anxiety_frequency, confidence_level, tried_coaching_before, communication_style)
VALUES (
  'YOUR_USER_ID_HERE',  -- Replace with your actual user ID
  'Your Name',          -- Your actual name
  'Male',               -- or 'Female', 'Other'
  25,                   -- Your age
  ARRAY['Better Dating Skills', 'Building Confidence'],  -- Your goals
  ARRAY['Starting conversations'],  -- Your challenges
  'Sometimes',          -- Anxiety frequency
  'Moderate',           -- Confidence level
  'No, this is my first time',  -- Coaching experience
  'Friendly and warm'   -- Communication style
);
```

3. Restart the app
4. Your name should now appear!

### Option 3: Wait for the Fix (Easiest)

The app now extracts your name from your email automatically:

- `oluwayan.mi.micheal@lmu.edu.ng` → `"Oluwayan Mi Micheal"`

Just restart the app and it should work!

## Verification

After applying any fix, you should see:

- Dashboard: "Good Morning, Your Name" (not your email)
- Debug logs showing: "DEBUG: Returning name from profile: Your Name"
