# FestCompanion 🎶

> **All you need in one place for your summer festivals.**
> A cross-platform, **multi-festival** companion app — pick your event, navigate its line-up, rate sets together with your group, find each other on the grounds, and stay safe. First deployed live on-site for **Extrema Outdoor 2026** (Houthalen-Helchteren, Belgium).

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.11-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white">
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-FCM%20%7C%20Auth%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black">
  <img alt="Flask" src="https://img.shields.io/badge/Backend-Flask-000000?logo=flask&logoColor=white">
  <img alt="BigQuery" src="https://img.shields.io/badge/Data-BigQuery-4285F4?logo=googlecloud&logoColor=white">
  <img alt="Platforms" src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-3DDC84">
</p>

---

## Table of Contents
- [Overview](#overview)
- [Screenshots](#screenshots)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Engineering Highlights](#engineering-highlights)
- [Backend API](#backend-api)
- [Getting Started](#getting-started)
- [Roadmap](#roadmap)
- [Author](#author)

---

## Overview

FestCompanion is a **full-stack mobile product**: a Flutter front-end backed by a Python/Flask REST API on Google Cloud. It was designed for a real-world constraint — a crowded, multi-stage electronic music festival where mobile signal is patchy, friends get separated, and everyone wants to plan which DJ sets to catch.

The app turns a static festival line-up into a **shared, collaborative experience**: each member of a group can mark and rate sets, see what the rest of the group is into, locate one another by **stage**, and trigger safety / hype alerts that push to everyone's phone in real time.

It is **multi-festival**: on launch you pick a festival from a selection screen, and the whole app (line-up, days, stages, weather, team, countdown) is scoped to it. Accounts are **shared across festivals**; your favorites, ratings and live position are recorded per festival.

This repository contains the **Flutter client**. The companion REST API lives in the [`extremalineup-api`](../../ExtremaLineUp/extremalineup-api) repository (also documented).

| | |
|---|---|
| **Type** | Cross-platform mobile app (Android + iOS) + REST backend |
| **Scope** | Multi-festival (festival picked at launch) |
| **Users** | Private groups of festival-goers (real on-site usage) |
| **Distribution** | Built & signed via Codemagic CI/CD |

---

## Screenshots

> _Add screenshots / a short screen-recording here — this is the first thing an interviewer looks at._
> Suggested shots: Festival selection, Home (countdown + weather), Line-up with team favorites, Timetable grid, Team / stages, Event wheel (SOS/lost/hype).

| Festivals | Home | Line-up | Timetable | Team |
|:---:|:---:|:---:|:---:|:---:|
| _screenshot_ | _screenshot_ | _screenshot_ | _screenshot_ | _screenshot_ |

---

## Key Features

### 🎪 Multi-festival
- A **festival selection screen** at launch (driven by `GET /api/festivals`); the choice is persisted and propagated to every request as a `festival_id`.
- Festival name, city, dates and **days are dynamic** — derived from the selected event, not hard-coded.
- Switch festivals at any time from the drawer.

### 🎧 Line-up & Timetable
- Full festival line-up across **stages** and the event's days.
- Timetable rendered as a **time-scaled grid** (custom-painted vertical time lines, per-stage rows), with times shifted to the festival's local timezone.
- Filter modes: **all DJs**, **my favorites**, or **the whole team's favorites**.

### ⭐ Shared favorites & ratings
- One tap to favorite a set; favorites sync across the group.
- **10-point rating** per set, with aggregated views of who-liked-what.
- Fully **offline-tolerant**: optimistic local updates with background sync to the server.

### 🏷️ Collaborative DJ tags
- Any user can add free-text **tags** (no spaces, auto-prefixed with `#`) to a set; everyone sees them, each chip carrying its author's avatar — like the notes.
- Tap your own tag to remove it (with confirmation).
- The **Search** tab lets you find DJs by name (also stage, day or tag) and/or pick any existing tag to browse every DJ that matches — text and tag filters combine.

### 📈 Trending (best-rated DJs)
- A **"Trending"** screen ranks the festival's DJs by a **Bayesian average** of the group's ratings, so a set with many good ratings outranks one with a single perfect score.
- Computed entirely client-side from already-cached ratings — no extra endpoint or query.

### 📍 Find your friends (geolocation)
- The festival grounds are split into named **stages** defined by GPS bounding boxes; each stage also carries a **rally point** the group can navigate to in one tap.
- **Foreground-only** location: a member's position refreshes when they open the app (or tap a "lost" alert) — no background tracking, so permissions stay simple and the battery is spared.
- See where every group member currently is — no need to text "where r u??".

### 🚨 Real-time group alerts (push)
Three one-tap event types broadcast to everyone via Firebase Cloud Messaging:
- **SOS** — high-priority emergency alert (dedicated Android channel, long vibration).
- **Lost** — "I'm lost", which also refreshes everyone's stage so the group can converge on a rally point.
- **Hype** — "it's going off over here, come through!"

### 🔴 Live & at-a-glance home
- A **"Live"** landing (auto-selected during the event) showing **what's playing now** and **what's next** on each stage, with live progress bars.
- Live **weather forecast** for the festival days (pulled from WeatherAPI, cached server-side, only fetched once the forecast window opens).
- **Countdown timer** to the first set (derived from the festival's own timetable).
- Quick access to your current location / stage.

### 📨 Journal & scheduled notifications
- A server-driven **Journal** (a single timeline with a per-theme filter) records every notification the festival sends.
- **Scheduled "fun" pushes** built server-side from the group's own data: a daily Trending spotlight, plus playful daily awards (biggest drinker, most "lost", top hydrator, FOMO champion…), all gender-aware.
- **Countdown pushes** (J-30 → J-1) that ramp up as the event approaches — testable live well before the weekend.
- **Line-up change pushes**: when the line-up re-syncs, added/cancelled/rescheduled sets are pushed and logged under a *Programmation* filter; tapping one opens the Journal and force-refreshes the cached timetable.
- **Onboarding nudges**: a tent-location reminder before the first set and a graduated location-sharing sequence on day 0.

### ⏰ Local reminders (offline, no server)
- A **set reminder** ~10 min before each of your favorited sets — tapping it jumps to the Live tab.
- A **hydration reminder** every 2 h through each festival day, with day-themed copy (escalating from serious to silly) — tapping it jumps to Events to log a drink.
- Scheduled at the festival's **wall-clock time** via its IANA timezone, so they fire correctly whatever timezone the phone is in; rescheduled whenever favorites change.

### 🏕️ Tent / camp location
- Save your **tent location** per festival (Mon compte) and navigate back to it — the 4 a.m. you, compass broken, will be grateful.

### 👤 Profiles & team
- Per-user profile photos (Firebase Storage), phone number, and location sharing toggle.
- Team view listing every member present on the festival with avatar, current stage, and quick actions.

---

## System Architecture

```
┌──────────────────────────────┐         ┌─────────────────────────────┐
│        Flutter App            │         │     Flask REST API          │
│   (Android / iOS client)      │         │   (extremalineup-api)       │
│                               │  HTTPS  │   hosted on Render          │
│  ┌────────────────────────┐   │ ──────► │  /api/festivals             │
│  │ Pages / Widgets (UI)   │   │  JSON   │  /timetable  /api/events    │
│  ├────────────────────────┤   │ ◄────── │  /api/user-favorites        │
│  │ AppDataManager         │   │ (festi- │  /api/stages  /api/geoloc   │
│  │ (singleton state)      │   │  val_id)│                             │
│  ├────────────────────────┤   │         └─────────────┬───────────────┘
│  │ Services               │   │                       │
│  │  • ApiService (HTTP)   │   │                       ▼
│  │  • LocalStorage (cache)│   │            ┌──────────────────────────┐
│  │  • FcmService (push)   │   │            │   Google BigQuery          │
│  │  • NotificationSched.  │   │            │ festivals · festival_users │
│  └────────────────────────┘   │            │ timetable · users ·        │
│                               │            │ favorites · stages ·       │
└──────────────┬────────────────┘            │ geoloc · events · weather  │
               │                              └──────────────────────────┘
               │ Firebase SDK                             ▲
               ▼                                          │ Admin SDK
   ┌───────────────────────────┐         ┌────────────────┴───────────┐
   │  Firebase                 │         │  External services           │
   │  • Cloud Messaging (FCM)  │ ◄────── │  • WeatherAPI (forecast)     │
   │  • Auth · Storage         │         │                              │
   └───────────────────────────┘         └──────────────────────────────┘
```

**Data flow at a glance**
1. On launch the user picks a festival; its `festival_id` is persisted and injected into every API call.
2. The Flutter client talks to the Flask API over HTTPS (JSON).
3. Flask is a thin, stateless layer over **BigQuery**, which is the single source of truth.
4. **Push notifications** are sent server-side via the Firebase Admin SDK to the `all_users` topic; every device subscribes on launch.
5. The client keeps a **local cache** (SharedPreferences, namespaced per festival) so core screens still work with no connectivity.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile** | Flutter 3.11 · Dart 3.11 |
| **State** | Singleton `AppDataManager` + service layer (no heavyweight state lib — deliberately lean) |
| **Networking** | `http`, JSON serialization via model `fromJson`/`toJson` |
| **Local cache** | `shared_preferences` (per-festival namespacing) |
| **Push** | `firebase_messaging` (remote) + `flutter_local_notifications` + `timezone` (scheduled local reminders) |
| **Auth & media** | `firebase_auth`, `firebase_storage`, `image_picker`, `cached_network_image` |
| **Location** | `geolocator` (foreground fixes only) |
| **Config** | `flutter_dotenv` |
| **Backend** | Python · Flask · Flask-CORS · Gunicorn |
| **Data** | Google BigQuery (`google-cloud-bigquery`, pandas) |
| **Cloud / infra** | Render (API hosting) · Firebase · Codemagic (mobile CI/CD) |
| **3rd-party APIs** | WeatherAPI |

---

## Project Structure

```
lib/
├── main.dart                 # App bootstrap: Firebase, FCM, restore selected festival
├── models/                   # Plain data models (festival, timetable, dj, stage, event, user, favorite, weather)
├── services/                 # App logic & I/O
│   ├── app_data_manager.dart #   ⭐ central singleton state store (+ selected festival)
│   ├── api_service.dart      #   REST client (injects festival_id)
│   ├── local_storage_service.dart
│   ├── fcm_service.dart      #   remote push (FCM) wiring & deep-link routing
│   ├── notification_scheduler.dart #  local set/hydration reminders (timezone-aware)
│   ├── auth_service.dart · profile_service.dart · weather_service.dart
├── pages/                    # Screens (festival selection, home, lineup, timetable, stages, events, profile, team, login…)
├── widgets/                  # Reusable UI, grouped by feature (home/ lineup/ timetable/ ratings/ team/ stages/…)
├── helpers/                  # Pure helpers (formatting, url launching, location math)
└── extensions/               # BuildContext extensions
```

The UI is **decomposed by feature** (e.g. `widgets/timetable/`, `widgets/ratings/`) which keeps screens thin and widgets reusable — a deliberate choice to keep the codebase navigable as features grew.

---

## Engineering Highlights

A few problems worth calling out — these are the kinds of things that came up building a real app against real cloud services:

- **Multi-festival, single source of truth.** A `festivals` metadata table plus a `festival_id` on every data table replaced the constants that used to be hard-coded (city, dates, timezone, festival days). The client carries the selected `festival_id` through one place — a static on `ApiService`, set at selection — so call sites stayed clean while every request became festival-scoped.

- **Shared accounts, per-festival presence.** Accounts are global, but where a user *is* depends on the festival, so live GPS + current stage live in a `festival_users` join table rather than on the user row.

- **Reliable favorite persistence (`MERGE`/UPSERT).** Toggling a favorite or saving a rating originally used `UPDATE`, which silently no-ops when the row doesn't exist yet. Switched the backend to BigQuery `MERGE` statements so the first interaction inserts and subsequent ones update — favorites stopped "disappearing".

- **BigQuery streaming buffer vs. DML.** Newly *streamed* rows can't be `DELETE`d/`UPDATE`d for ~90 minutes. The "delete my last event" feature kept failing because of this. Fixed by switching event inserts from streaming inserts to **batch load jobs**, which are immediately available to DML.

- **Foreground-only geolocation (a deliberate scope cut).** An earlier design tracked location in the background via a WorkManager isolate, which forced `LocationPermission.always`, drained battery, and was unreliable for small/overlapping stage zones. It was dropped in favour of refreshing a member's position only when the app is **open** — or when they tap a "lost" alert (the push handler fires a one-shot fix). Simpler permissions ("while in use"), no battery cost, and good enough for a group converging on a rally point.

- **Bayesian ranking on tiny samples.** With ~15 users and only a handful of ratings per set, a plain average lets a single 10/10 top the chart. The "Trending" screen uses a Bayesian average — `(C·m + Σ) / (C + n)` with a tuned confidence constant `C` — to pull thinly-rated sets toward the global mean. It runs client-side over already-cached ratings, so it costs no extra round-trip.

- **Offline-first, optimistic UI.** Favorites/ratings update local state immediately and cache to disk (cache keys namespaced per festival to avoid cross-event bleed), then sync to the server; on a flaky festival network the UI never blocks, and the app falls back to a cached timetable/stages when the API is unreachable.

- **Push that works app-closed.** Devices subscribe to the `all_users` FCM topic on launch (before login, retried each start), and a top-level background handler is registered before `runApp()` so SOS/lost/hype alerts arrive even when the app isn't running.

- **Avoiding favorite-toggle bugs in bulk sync.** The toggle endpoint *inverts* server state, so a naive "sync all" loop would flip everything. Background sync only pushes **ratings**, never re-toggles favorites.

---

## Backend API

The Flask service exposes a small, focused REST surface. Every data endpoint is scoped by `festival_id` (query param on `GET`, body field on writes). Full source & setup in [`extremalineup-api`](../../ExtremaLineUp/extremalineup-api).

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/api/festivals` · `/api/festivals/<id>` | List festivals / one festival's metadata |
| `GET` | `/timetable?festival_id=` | Full line-up (times adjusted to the festival TZ) |
| `GET` | `/users?festival_id=` · `/users/check` | Users on a festival / resolve username → id |
| `POST` | `/users/<id>/phone` · `/location` · `/tent` | Update phone (global), current location, or tent/camp location |
| `GET` `POST` | `/api/user-favorites` `/toggle` `/rate` | Read / toggle / rate favorites (UPSERT) |
| `GET` `POST` `DELETE` | `/api/dj-tags` | Read / add / remove collaborative DJ tags (keyed by set) |
| `GET` `PUT` | `/api/stages` `/api/stages/<name>` | Read / update stage geo-boxes |
| `POST` | `/api/geoloc` | Push a user's GPS → resolve & store stage |
| `GET` `POST` `DELETE` | `/api/events` `/api/events/last` | Read / create / undo SOS·lost·hype events |
| `GET` `POST` | `/weather` `/update-weather` | Read cached forecast / refresh from WeatherAPI |
| `GET` | `/api/journal?festival_id=` | The festival's notification journal (feeds the Journal screen) |
| `GET` | `/api/push/tick` | Cron tick: sends scheduled/countdown pushes due now, idempotent |
| `GET` `POST` | `/api/admin/refresh-lineup` | Re-scrape & diff-sync the line-up (stable `set_id`); secret-protected |

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.11
- A Firebase project (for `firebase_options.dart`, FCM, Auth, Storage)
- The backend API running (see its repo) — set its base URL in `lib/services/api_service.dart`

### Run locally
```bash
flutter pub get
# create a .env file at the project root (referenced in pubspec assets)
flutter run
```

### Build
Release builds (Android + iOS) are produced through **Codemagic**. App icons are generated via `flutter_launcher_icons`:
```bash
flutter pub run flutter_launcher_icons
```

> **Note:** secrets (Firebase config, API keys) are injected via environment variables / `.env` and are **not** committed.

---

## Roadmap

Ideas not yet implemented:
- **Per-festival FCM topics** (currently a single global `all_users` topic) so alerts only reach attendees of the same event.
- Polygon-based stage detection (currently bounding-box) for irregular stage areas.
- Map view with live friend pins instead of stage labels.
- Migrate state to a reactive solution (Riverpod/Bloc) if the app grows.

---

## Release notes

### 1.7.1 — 2026-06-27
- **Weather availability window.** The home weather section now opens exactly when
  the backend can first return a festival day. WeatherAPI counts today as day 1, so
  a 14-day window reaches *today + 13 days*; the availability date is computed as
  `start − 13 days` (was 14), removing a one-day gap where the app announced
  "weather available" but the server had nothing in range yet.

### 1.7.0 — 2026-06-23
- **Line-up changes in the Journal.** The Journal is now a single unified
  timeline with a **theme filter** (a chip row: *All* + one chip per theme).
  Line-up changes — added sets, time changes, cancellations, reinstated sets —
  appear under the **Programmation** theme alongside the other notifications, and
  can be isolated with one tap on the filter. These entries are generated
  server-side when the scraper re-syncs the line-up: thanks to a new diff-based
  sync, a set keeps its `set_id` when only its time changes (favorites, ratings
  and tags stay attached), a removed set is deactivated rather than erased, and
  every visible change is logged to the journal under the `programmation` theme.
- **Line-up change push.** Each line-up change is pushed to everyone (one
  notification per change); tapping it opens the Journal **pre-filtered to
  Programmation**. Receiving such a push also force-refreshes the cached
  timetable, so the Line-up screen shows the new time right away (instead of
  waiting for the next 12/18/22h revalidation slot).
- **Tent helper copy.** Reworded the tent-location hint on the profile screen.
- **About page.** New drawer entry showing the **installed app version** and build
  number (read from the platform via `package_info_plus`) — handy to check users
  are on the right build.

### 1.6.2 — 2026-06-21
- **Contextual filter counts in Search.** Each Day / Stage / Tag option now shows
  a count in parentheses = the number of distinct DJs that match given the *other*
  active filters and the text query (the facet itself is excluded, so options
  don't collapse to 0). Counts are by distinct set, so the same tag added by two
  users on one DJ counts once.

### 1.6.1 — 2026-06-21
- **Search tag filter polish.** The tag filter sheet now shows each tag's DJ
  count (`#techno (12)`) and is sorted alphabetically. In the results, each DJ
  tile's tag row is capped to a **single line** — the number of tags shown adapts
  to their actual width (a long `#melodictechno` takes the room of several short
  ones) — so all tiles share the same height.

### 1.6.0 — 2026-06-21
- **Search tab (merged with Tags).** The bottom-nav *Tags* tab is now **Search**:
  a search bar (matches DJ name first, also stage, day and tag) plus a row of
  **filter buttons** — Day / Stage / Tags — each opening a multi-select sheet.
  Filters combine (AND across categories, OR within one), so e.g. *Saturday +
  Area V* works (day labels shown in French). Tapping a result opens the DJ
  profile. Browses all DJs alphabetically by default; works even when no tags
  exist yet.
- **Cleaner Events screen.** Removed the redundant "Événements" header bar so the
  tab is consistent with the rest of the app (it renders under the shared app bar
  like the other tabs).
- **Greyed-out "locate" when there's no real position.** Members whose location
  is unset (the server's default `(0, 0)`, which would otherwise point off the
  African coast) now show a disabled location pin in the Team list and on the
  profile screen, instead of a tappable pin leading nowhere.
- **Admin: manual stage coordinates.** Besides capturing the current GPS position,
  admins can now type a stage corner / rally point's latitude & longitude by hand
  (new "Saisie manuelle" button on each stage card), handy when configuring a
  stage off-site.
- **Snappier stage coordinate capture.** The confirmation dialog now opens
  *immediately* on tap (before the slow GPS read), so rapid taps no longer stack
  up multiple dialogs; a re-entry guard prevents concurrent writes. The dialog
  also names the corner in plain French ("le coin avant-gauche", "le point de
  ralliement") instead of the raw key.
- **Find a friend's tent on the campsite.** Each member can save their tent's
  GPS location from their own profile; others then get a "Rejoindre" action
  (dedicated campground icon, distinct from the location pin) — both on the
  member's profile and directly in the **Team** list — to be guided there in
  Google Maps. Stored per festival. A day-0 push reminds everyone to save their
  tent before the music starts.
- **Gentle nudges to share location.** A graduated series of reminders (evening
  before + every 3 h on day 0) encourages enabling location sharing, each with a
  stronger reason (find your stage → better notifications → be found if lost →
  safety). They appear in the Journal with their own icons.
- **Drawer order.** *Journal* now sits right under *Live*. No separate search
  entry — Search lives in the bottom bar.
- **SOS events get their own Journal icon.** Real-time SOS/perdu/hype alerts now
  appear in the in-app Journal (backed by the API change); the Journal renders a
  dedicated **SOS** icon for `sos` entries instead of the generic bell. `hype`
  and `lost` already had icons.

### 1.5.8 — 2026-06-19
- **Consent prompt reaches existing users too.** The default-on location consent
  is now gated by a versioned marker, so the permission prompt fires once for
  **everyone on the next update** (existing testers included, whose toggle was
  off by default), not just on fresh installs. After it has run once, the saved
  choice is respected and never re-asked.

### 1.5.7 — 2026-06-19
- **Location sharing on by default after permission.** On first launch the app
  now asks for the OS location permission and, if granted, turns the
  "share my location" toggle ON automatically (instead of defaulting to off and
  requiring a manual flip).

### 1.5.6 — 2026-06-19
- **Set-reminder title tweak.** Favourite-set reminders now read “⏰ Get ready”
  (was “Ça commence bientôt !”); the body is unchanged.

### 1.5.5 — 2026-06-19
- **Themed hydration reminders.** The every-2h hydration reminder is no longer a
  single repeated line: each festival day now has its own escalating set of
  messages, from earnest to unhinged — camel (day 1), cactus (day 2), water-rich
  "fun fact" fruits that are conveniently never available on site (day 3). Texts
  are picked per day (ordered by `day_int`) and per slot; the last line repeats
  if a day has more slots than messages. All scheduled at festival-local time.

### 1.5.4 — 2026-06-19
- **Hydration reminder → Events.** Tapping the every-2h hydration reminder now
  opens the **Events** tab (where you log your drinks) instead of just opening
  the app.

### 1.5.3 — 2026-06-19
- **Per-type notification deep-links.** Tapping a notification now lands on the
  right place: scheduled pushes → **Journal**; favourite-set reminders (~10 min
  before a set) → **Live** (now/next); user events (SOS / lost / hype) keep
  opening the app normally (main screen). Set reminders route via a small intent
  picked up by the main screen, working from foreground, background, and a cold
  launch from the notification.

### 1.5.2 — 2026-06-19
- **Tap a scheduled notification → opens the Journal.** Tapping any scheduled
  push (daily spotlight, hourly gag, countdown, wrap-up — all carry
  `event_type: journal`) now deep-links straight to the Journal screen, whether
  the app was in the foreground, background, or terminated.

### 1.5.1 — 2026-06-19
- **Countdown pushes before the festival:** "J-N" notifications that ramp up as
  the event approaches (J-30, J-21, J-14, J-10, J-7, J-5, J-3, J-2, J-1), each
  fired once at 9 a.m. local. Some pull in the group's current top-rated DJs.
  They run through the same tick/Journal pipeline, so they're **live-testable
  right away** (no need to wait for the festival) and archived in the Journal
  (new hourglass icon). Backend-only logic; the app just renders them.

### 1.5.0 — 2026-06-19
- **Scheduled festival pushes + "Journal":** the app now receives playful,
  data-driven push notifications during the festival, all archived on a new
  **Journal** screen (drawer entry). Each festival day: a morning "spotlight"
  push at 8 a.m. naming the day's top-rated DJs (Bayesian trending, day-filtered),
  hourly running gags between 9 a.m. and 1 p.m. that crown a group member from
  the previous day's data (most "lost", biggest drinker + their favourite stage,
  hydration champion, energy/hype records…) plus same-day "juror" (most ratings)
  and "FOMO" (most favourites) awards, and a single wrap-up push the day after
  with the weekend's full leaderboard. The Journal is **server-sourced** (same
  for everyone, survives a missed push) with offline cache and pull-to-refresh;
  leaderboard/wrap-up entries appear there without being pushed. Notifications
  are gender-aware (new `gender` column on users). Backend-driven: one cron hits
  `/api/push/tick` and the schedule/texts live server-side.

### 1.4.0 — 2026-06-19
- **Trending — filter by day:** the Trending ranking now has a segmented day
  filter (**All** / Friday / Saturday / Sunday, built from the festival's actual
  days). Selecting a day shows only the sets scheduled that day, re-numbered from
  rank 1; the Bayesian score itself is still computed across the whole festival,
  so the filter only changes which sets are visible. The filter **always resets
  to "All"** each time you open the Trending tab. A dedicated empty state shows
  when a day has no rated sets yet.

### 1.3.2 — 2026-06-15
- **Fix:** the "Mon compte" screen no longer blocks behind a centred spinner on
  open. It now follows the same pattern as the rest of the app: local cached data
  is shown immediately, a background refresh is triggered on arrival, and the
  non-intrusive banner indicates the server update while it's in flight.

### 1.3.1 — 2026-06-15
- **Consistency:** the non-intrusive background-refresh banner now also appears
  on the **profile** ("Mon compte") screen, which reads its data from the team
  list — previously only the team screen showed it.

### 1.3.0 — 2026-06-15
- **Fix:** the **DJ-by-tag** tiles reacted to the global "my favourites / team"
  filter (showing a stage line and team fan avatars). That view is now neutral —
  it shows only photo, DJ name, tags, the favourite star and the rating.
- **Fix:** the **team** list and **profile photos** no longer show a centred
  spinner / "pop in" on every launch. The user list is now persisted locally and
  shown immediately (with the non-intrusive refresh banner), and cached photo
  URLs are re-applied on top.
- **Fix:** a saved **phone number** could show as "Non renseigné" after an app
  restart — the profile read the user list before it had loaded. The list is now
  cached locally and the profile updates as soon as it is available.
- **Trending:** the ranking now shows the **weighted (bayesian) score** under the
  raw average (it's what drives the order), and ties are broken deterministically
  (score → number of ratings → raw average → DJ name) so equal entries keep a
  stable order.

### 1.2.0 — 2026-06-15
- **Changed:** the "Mon compte" screen now edits the phone number inline
  (**Éditer → Valider/Annuler**) instead of the global save (floppy) button in
  the app bar, which has been removed. The phone is the only editable field, so
  it owns its own edit flow.
- **New:** phone numbers are validated and normalised to the canonical French
  format **`+33 6 XX XX XX XX`** on save (accepts `06…`, `6…`, `0033…`, `+33…`
  with spaces/dots/dashes); invalid or empty input is rejected.
- **Fix (data loss):** the old always-on save button wrote whatever was in the
  phone field on every tap — if the field was empty (e.g. the screen opened
  before the user list had loaded) it could **wipe the saved number**. The new
  edit/validate flow only writes a valid, explicitly-confirmed number, removing
  that vector. (Verified the location update path never touches the phone field
  server-side.)
- **Removed:** the manual location-refresh button — position already refreshes
  automatically on app open and on a "lost" alert, so it was redundant (and it
  mistakenly reused the photo-upload spinner). The coordinates display is kept.

### 1.1.3 — 2026-06-15
- **Fix:** toggling **location sharing** on the profile felt very slow — the
  switch and its confirmation snackbar only appeared after the GPS fix and the
  network round-trip had completed. The toggle now flips, persists the consent
  and shows the message immediately; the first position fix runs in the
  background (best-effort, and a failure no longer cancels the consent).
- **Perf:** team **profile photos** no longer "pop in" on every launch. The
  resolved Firebase Storage URLs are now persisted locally and re-applied at
  startup, so photos show instantly from the on-disk image cache while the URLs
  are re-validated in the background (previously `listAll()` + `getDownloadURL()`
  ran on every launch before any photo could appear).

### 1.1.2 — 2026-06-15
- **Fix:** the **Stages** screen showed the centred spinner together with the
  refresh banner, because `loadStages` did a blocking network fetch (cache only
  used as an error fallback) and the page also waited on the (always-network)
  user load before rendering. Stages are now loaded stale-while-revalidate
  (cached list shown immediately, refreshed in the background), and the screen
  no longer blocks on the user fetch — that runs in the background just to
  resolve the admin role. The centred spinner now only appears on the first
  launch before any cache exists.

### 1.1.1 — 2026-06-15
- **Fix:** the **Trending** and **DJ-by-tag** screens showed a centred loading
  spinner on every launch instead of the non-intrusive top banner, because their
  data (all users' ratings, collaborative tags) was never cached locally — there
  was genuinely nothing to display until the network responded. Both datasets are
  now persisted locally (per festival) and shown immediately on launch, with the
  background-refresh banner indicating the live update. The centred spinner now
  only appears on the very first launch, before any local cache exists.

### 1.1.0 — 2026-06-15
- **New:** non-intrusive **background-refresh banners**. The app shows locally
  cached data immediately and refreshes from the server in the background; while
  a refresh is in flight, a small floating pill (e.g. _"Mise à jour des
  tendances…"_) appears at the top of the relevant page and disappears on its
  own when fresh data arrives. It never blocks navigation — the user keeps
  browsing the cached data freely. Applied across the data-backed pages
  (home/live, line-up, timetable, trending, tags, team, stages, events) via a
  shared `backgroundLoads` signal in `AppDataManager` and the `FestivalBackground`
  wrapper.

### 1.0.5 — 2026-06-15
- **Fix:** the **Trending** and **DJ-by-tag** screens could briefly show an empty
  state at startup while their data was still loading in the background. They now
  show a loading indicator until the background data is ready, and only fall back
  to the empty state when there is genuinely nothing to display.

---

## Author

Built and maintained by **Antoine**.
Full-stack work across the Flutter client, the Flask/BigQuery API, Firebase integration, and the mobile CI/CD pipeline.

> _This README documents a personal/real-world project for portfolio purposes._
