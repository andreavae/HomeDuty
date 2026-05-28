# HomeDuty - Step-by-Step Guide

## 1. Install prerequisites
1. Install Flutter SDK and verify with `flutter doctor`.
2. Create a Supabase project.
3. Copy your project URL and anon key.

## 2. Initialize Supabase database
1. Open Supabase SQL Editor.
2. Run the content of `supabase/schema.sql`.
3. Verify these tables are created:
   - users
   - households
   - household_members
   - tasks
   - task_completions

## 3. Configure Flutter app
1. Run `flutter pub get`.
2. Start the app with dart-define:
   - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## 4. Quick functional test
1. Register user A with a unique username.
2. Create a household.
3. Register user B with a different username.
4. Have user B join using the household ID.
5. Create a task with XP, status, recurrence, and assignee.
6. Complete the task and verify XP increases.
7. Check leaderboard and completion history.
8. Switch light/dark theme from profile.

## 5. Implemented architecture
- Data layer: `lib/src/data`
- Domain layer: `lib/src/domain`
- Presentation layer: `lib/src/presentation`
- Core layer: `lib/src/core`

## 6. Notes
- Unique username is guaranteed by the `unique` constraint on `users.username`.
- Task completion with automatic XP is handled by SQL function `complete_task`.
- Real-time sync for tasks and household is provided by Supabase streams.
