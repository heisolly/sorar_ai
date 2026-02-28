# Troubleshooting: Email Showing Instead of Name

## Issue

The dashboard is showing the full email address instead of the user's name.

## Root Cause

This happens when:

1. **Database migration not run** - The `user_profiles` table doesn't exist yet
2. **User signed in before completing personalization** - No profile data was saved
3. **Something is returning the email as the name**

## Solution Steps

### Step 1: Run the Database Migration (REQUIRED)

1. Open your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **SQL Editor** (left sidebar)
4. Click **New Query**
5. Copy the entire contents of `supabase_migration_user_profiles.sql`
6. Paste into the editor
7. Click **Run** or press `Ctrl+Enter`
8. You should see "Success. No rows returned"

### Step 2: Verify Table Was Created

1. In Supabase, go to **Table Editor** (left sidebar)
2. Look for `user_profiles` in the list
3. If you see it, the migration worked!

### Step 3: Test With a New User

1. **Sign out** from the app
2. **Sign up** with a new account
3. Complete the **PersonalizationFlow** (enter your name, age, etc.)
4. Check the dashboard - it should now show your name!

### Step 4: For Existing Users

If you already have an account that shows the email:

1. Go to Supabase **Table Editor** → `user_profiles`
2. Click **Insert** → **Insert row**
3. Fill in:
   - `user_id`: Your user ID (get from **Authentication** → **Users**)
   - `name`: Your actual name (e.g., "Oluwayan")
   - Other fields as desired
4. Click **Save**
5. Restart the app

### Step 5: Check Debug Logs

When you run the app, check the console/logs for:

```
DEBUG: Profile data: null  (or actual data)
DEBUG: User metadata: {...}
DEBUG: User email: oluwayan...
DEBUG: Email name part: oluwayan
DEBUG: Clean name: Oluwayan Mi Micheal
```

This will tell you exactly what's happening.

## Expected Behavior After Fix

- **New users**: Name from PersonalizationFlow → Saved to database → Shows on dashboard
- **Email fallback**: "oluwayan.mi.micheal@lmu.edu.ng" → "Oluwayan Mi Micheal"

## Quick Fix (Temporary)

If you just want to test without the database:
The email parsing should convert "oluwayan.mi.micheal" to "Oluwayan Mi Micheal"

If it's still showing the full email, there might be an issue with how the name is being fetched. Check the debug logs!
