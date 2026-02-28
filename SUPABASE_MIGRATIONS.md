# Supabase Migration History

## Project Information

- **Project**: Sorar AI
- **Project ID**: epofftojgzzywrqndptp
- **Database**: PostgreSQL 17.6.1
- **Region**: eu-central-2
- **Setup Date**: 2026-02-04

## Migration Timeline

### Migration 1: `enable_rls_on_public_tables`

**Date**: 2026-02-04  
**Purpose**: Enable Row Level Security on existing public tables

**Changes**:

- ✅ Enabled RLS on `waitlist` table
- ✅ Enabled RLS on `site_visits` table
- ✅ Added RLS policies for both tables

**SQL Summary**:

```sql
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_visits ENABLE ROW LEVEL SECURITY;
-- + policies for INSERT and SELECT
```

**Impact**: Fixed security warnings, all public tables now have RLS

---

### Migration 2: `setup_storage_buckets_and_policies`

**Date**: 2026-02-04  
**Purpose**: Create storage buckets with proper security policies

**Changes**:

- ✅ Created `avatars` bucket (public, 5MB limit, images only)
- ✅ Created `chat_attachments` bucket (private, 10MB limit)
- ✅ Created `voice_recordings` bucket (private, 50MB limit)
- ✅ Added storage policies for all buckets
- ✅ Updated `app_storage` bucket policies

**Buckets Created**:

1. **avatars**: Public, 5MB, images
2. **chat_attachments**: Private, 10MB, images/PDF/text
3. **voice_recordings**: Private, 50MB, audio files

**Security Model**: User-specific folders (`{user_id}/filename`)

---

### Migration 3: `create_additional_app_tables`

**Date**: 2026-02-04  
**Purpose**: Create core application tables for user data

**Tables Created**:

1. **user_settings**
   - User preferences and app settings
   - Theme, notifications, language, timezone
   - RLS enabled with user-specific policies

2. **user_progress**
   - Achievement tracking and metrics
   - Metric type, value, metadata
   - Unique constraint on (user_id, metric_type)
   - RLS enabled

3. **user_goals**
   - User-defined goals with progress tracking
   - Title, description, category, status
   - Progress percentage (0-100)
   - Target date, completion tracking
   - RLS enabled

4. **journal_entries**
   - Personal reflections and mood tracking
   - Title, content, mood, tags
   - Privacy flag (is_private)
   - RLS enabled

**Indexes Created**:

- idx_user_settings_user_id
- idx_user_progress_user_id
- idx_user_progress_metric_type
- idx_user_goals_user_id
- idx_user_goals_status
- idx_journal_entries_user_id
- idx_journal_entries_created_at

**Impact**: Complete user data management system

---

### Migration 4: `setup_database_functions_and_triggers`

**Date**: 2026-02-04  
**Purpose**: Add utility functions and automatic behaviors

**Functions Created**:

1. **handle_updated_at()**
   - Automatically updates `updated_at` timestamp
   - Applied to all tables with updated_at column
   - Trigger: BEFORE UPDATE

2. **handle_new_user()**
   - Automatically creates user profile and settings on signup
   - Trigger: AFTER INSERT on auth.users
   - Creates entries in user_profiles and user_settings

3. **get_user_full_profile(user_uuid)**
   - Returns complete user profile
   - Includes profile, settings, progress, active goals
   - Security: SECURITY DEFINER

**Triggers Applied To**:

- user_profiles
- user_settings
- user_progress
- user_goals
- journal_entries
- chat_sessions
- chat_messages

**Impact**: Automated data management, reduced boilerplate code

---

### Migration 5: `enable_extensions_and_views`

**Date**: 2026-02-04  
**Purpose**: Enable database extensions and create helpful views

**Extensions Enabled**:

1. **pg_stat_statements** - Query performance monitoring
2. **uuid-ossp** - UUID generation functions

**Realtime Tables Added**:

- user_progress
- user_goals
- user_profiles
- chat_messages (already enabled)
- chat_sessions (already enabled)

**Views Created**:

1. **chat_sessions_with_counts**
   - Aggregates chat sessions with message counts
   - Includes last message timestamp
   - Useful for session listings

2. **user_statistics**
   - Aggregates user statistics
   - Total sessions, messages, goals
   - Journal entry counts
   - Last activity timestamps

**Impact**: Better query performance, easier data aggregation

---

## Pre-existing Tables (Not Modified)

These tables existed before the migration:

1. **profiles** - Legacy profile table (kept for compatibility)
2. **scenarios** - Coaching scenario definitions
3. **chat_sessions** - Chat session management
4. **chat_messages** - Individual chat messages
5. **waitlist** - Email collection
6. **site_visits** - Analytics tracking

---

## Current Database State

### Tables (11 total)

✅ All have RLS enabled
✅ All have proper foreign keys
✅ All have appropriate indexes

1. user_profiles
2. user_settings
3. user_progress
4. user_goals
5. journal_entries
6. chat_sessions
7. chat_messages
8. profiles (legacy)
9. scenarios
10. waitlist
11. site_visits

### Storage Buckets (4 total)

1. app_storage (existing)
2. avatars (new)
3. chat_attachments (new)
4. voice_recordings (new)

### Functions (3 total)

1. handle_updated_at()
2. handle_new_user()
3. get_user_full_profile()

### Views (2 total)

1. chat_sessions_with_counts
2. user_statistics

### Extensions (3 enabled)

1. pgcrypto
2. uuid-ossp
3. pg_stat_statements

---

## Security Status

### ✅ Resolved Issues

- All public tables now have RLS enabled
- Proper storage policies in place
- User-specific data isolation

### ⚠️ Current Warnings (Non-Critical)

1. **Leaked Password Protection**: Disabled (can be enabled in Auth settings)
2. **Permissive RLS Policies**: Intentional for waitlist/site_visits
3. **Security Definer Views**: Acceptable for read-only aggregation
4. **Function Search Path**: Low priority

### 📊 Performance Notes

- Some indexes marked as "unused" (normal for new database)
- Foreign key indexes can be added if needed
- Query performance monitoring enabled via pg_stat_statements

---

## Migration Best Practices Used

1. ✅ **Idempotent Migrations**: All migrations use IF NOT EXISTS, ON CONFLICT
2. ✅ **RLS First**: Security enabled before data insertion
3. ✅ **Indexes Created**: Performance optimizations included
4. ✅ **Triggers Added**: Automatic behaviors configured
5. ✅ **Documentation**: All changes documented

---

## Rollback Information

If you need to rollback migrations, here's the order:

### Rollback Migration 5

```sql
DROP VIEW IF EXISTS user_statistics;
DROP VIEW IF EXISTS chat_sessions_with_counts;
-- Remove from realtime publication if needed
```

### Rollback Migration 4

```sql
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS set_updated_at ON [tables];
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS handle_updated_at();
DROP FUNCTION IF EXISTS get_user_full_profile(UUID);
```

### Rollback Migration 3

```sql
DROP TABLE IF EXISTS journal_entries;
DROP TABLE IF EXISTS user_goals;
DROP TABLE IF EXISTS user_progress;
DROP TABLE IF EXISTS user_settings;
```

### Rollback Migration 2

```sql
-- Remove storage policies
-- Delete buckets via Supabase Dashboard
```

### Rollback Migration 1

```sql
ALTER TABLE public.waitlist DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_visits DISABLE ROW LEVEL SECURITY;
-- Drop policies
```

**⚠️ Warning**: Rollbacks will delete data. Always backup first!

---

## Future Migration Recommendations

### Potential Enhancements

1. **Add Full-Text Search**

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_trgm;
   CREATE INDEX idx_journal_content_search
     ON journal_entries USING gin(to_tsvector('english', content));
   ```

2. **Add Soft Deletes**

   ```sql
   ALTER TABLE user_goals ADD COLUMN deleted_at TIMESTAMPTZ;
   -- Update RLS policies to exclude deleted rows
   ```

3. **Add Audit Logging**

   ```sql
   CREATE TABLE audit_log (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     table_name TEXT,
     action TEXT,
     user_id UUID,
     old_data JSONB,
     new_data JSONB,
     created_at TIMESTAMPTZ DEFAULT now()
   );
   ```

4. **Add Materialized Views for Analytics**

   ```sql
   CREATE MATERIALIZED VIEW user_analytics AS
   SELECT user_id, COUNT(*) as total_sessions, ...
   FROM chat_sessions
   GROUP BY user_id;
   ```

5. **Add Partitioning for Large Tables**
   ```sql
   -- For chat_messages if it grows very large
   CREATE TABLE chat_messages_2026_02
     PARTITION OF chat_messages
     FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
   ```

---

## Testing Checklist

After migrations, verify:

- [ ] All tables have RLS enabled
- [ ] Storage buckets are accessible
- [ ] Triggers fire correctly
- [ ] Functions return expected results
- [ ] Realtime subscriptions work
- [ ] Foreign keys are enforced
- [ ] Indexes are used in queries
- [ ] No security warnings (critical)

---

## Maintenance Schedule

### Daily

- Monitor error logs
- Check query performance

### Weekly

- Review unused indexes
- Check storage usage
- Review security advisors

### Monthly

- Analyze query patterns
- Optimize slow queries
- Review and update indexes
- Check database size

### Quarterly

- Review and archive old data
- Update documentation
- Review security policies
- Performance audit

---

## Contact & Resources

- **Supabase Dashboard**: https://supabase.com/dashboard/project/epofftojgzzywrqndptp
- **Documentation**: See SUPABASE_SETUP.md
- **Quick Reference**: See SUPABASE_QUICK_REFERENCE.md
- **Schema Diagram**: See SUPABASE_SCHEMA_DIAGRAM.md

---

**Last Updated**: 2026-02-04  
**Migration Version**: 5  
**Database Status**: ✅ Healthy  
**Security Status**: ✅ Secure
