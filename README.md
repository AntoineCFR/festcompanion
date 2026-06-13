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
- **5-point rating** per set, with aggregated views of who-liked-what.
- Fully **offline-tolerant**: optimistic local updates with background sync to the server.

### 🏷️ Collaborative DJ tags
- Any user can add free-text **tags** (no spaces, auto-prefixed with `#`) to a set; everyone sees them, each chip carrying its author's avatar — like the notes.
- Tap your own tag to remove it (with confirmation).
- A dedicated **"DJ by tag"** screen lets you pick any existing tag and browse every DJ that matches it.

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

### 🌦️ At-a-glance home
- Live **weather forecast** for the festival days (pulled from WeatherAPI, cached server-side).
- **Countdown timer** to the first set (derived from the festival's own timetable).
- Quick access to your current location / stage.

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
│  │  • GeolocBackground    │   │            │ festivals · festival_users │
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
| **Push** | `firebase_messaging` + `flutter_local_notifications` (foreground display) |
| **Auth & media** | `firebase_auth`, `firebase_storage`, `image_picker`, `cached_network_image` |
| **Location** | `geolocator`, `location` (foreground fixes only) |
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
│   ├── fcm_service.dart      #   push notification wiring
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

- **Bayesian ranking on tiny samples.** With ~15 users and only a handful of ratings per set, a plain average lets a single 5★ top the chart. The "Trending" screen uses a Bayesian average — `(C·m + Σ) / (C + n)` with a tuned confidence constant `C` — to pull thinly-rated sets toward the global mean. It runs client-side over already-cached ratings, so it costs no extra round-trip.

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
| `GET` `POST` | `/api/user-favorites` `/toggle` `/rate` | Read / toggle / rate favorites (UPSERT) |
| `GET` `POST` `DELETE` | `/api/dj-tags` | Read / add / remove collaborative DJ tags (keyed by set) |
| `GET` `PUT` | `/api/stages` `/api/stages/<name>` | Read / update stage geo-boxes |
| `POST` | `/api/geoloc` | Push a user's GPS → resolve & store stage |
| `GET` `POST` `DELETE` | `/api/events` `/api/events/last` | Read / create / undo SOS·lost·hype events |
| `GET` `POST` | `/weather` `/update-weather` | Read cached forecast / refresh from WeatherAPI |

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

## Author

Built and maintained by **Antoine**.
Full-stack work across the Flutter client, the Flask/BigQuery API, Firebase integration, and the mobile CI/CD pipeline.

> _This README documents a personal/real-world project for portfolio purposes._
