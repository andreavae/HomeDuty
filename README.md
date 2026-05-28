# HomeDuty

Flutter app to manage shared household chores with a Supabase backend.

## Stack
- Flutter
- Riverpod
- GoRouter
- Supabase (Auth + PostgreSQL)

## 1. Prerequisites
- Flutter SDK installed and available in PATH
- Supabase account

## 2. Project setup
1. Get `SUPABASE_URL` and `SUPABASE_ANON_KEY` from your Supabase project.
2. Run:
   - `flutter pub get`
   - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## 3. Supabase database setup
1. Create a new Supabase project.
2. Open SQL Editor.
3. Run `supabase/schema.sql`.

## 4. Implemented features
- Login and registration with unique username
- Database-level unique username enforcement
- Shared household, membership, and tasks
- Task CRUD with status, recurrence, and XP
- Task completion with automatic XP assignment
- Household leaderboard
- Task completion history
- User profile with XP, level, and stats
- Dark mode

## 5. Architecture structure
- `lib/data`
- `lib/domain`
- `lib/presentation`
- `lib/core`
