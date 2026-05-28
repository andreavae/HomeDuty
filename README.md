# HomeDuty

App Flutter per gestire faccende domestiche condivise, con backend Supabase.

## Stack
- Flutter
- Riverpod
- GoRouter
- Supabase (Auth + PostgreSQL)

## 1. Prerequisiti
- Flutter SDK installato e disponibile in PATH
- Account Supabase

## 2. Setup progetto
1. Recupera `SUPABASE_URL` e `SUPABASE_ANON_KEY` dal progetto Supabase
2. Esegui:
   - `flutter pub get`
   - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## 3. Setup database Supabase
1. Crea un nuovo progetto Supabase
2. Apri SQL Editor
3. Esegui il file `supabase/schema.sql`

## 4. Funzionalita implementate
- Login e registrazione via username univoco
- Username univoco lato database
- Household, membership e task condivisi
- Task CRUD con stato, ricorrenza e XP
- Completamento task con assegnazione XP automatica
- Leaderboard household
- Storico completamenti
- Profilo con XP, livello e statistiche
- Dark mode

## 5. Struttura architettura
- `lib/data`
- `lib/domain`
- `lib/presentation`
- `lib/core`

## Nota
In questo ambiente `flutter` non era disponibile da terminale. I file del progetto sono stati creati manualmente, ma per eseguire l'app devi installare Flutter localmente.
