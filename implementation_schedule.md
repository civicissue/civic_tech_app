# Implementation Schedule

Act as my senior developer and implement gracefully step by step following best practices.

Goal: Sequence the work from foundation → MVP → admin → enhancements, with clear dependencies, DoD, QA checkpoints, and CI gates (no dates, only order and rigor). This file will be updated whenever you ask for a plan.

Legend
- Priority: High/Medium/Low
- Complexity: Low/Medium/High
- DoD = Definition of Done
- CI Gate = commands to pass locally and in CI

Prerequisites (before Step 1)
- Confirm or provide:
  - planning/categories_departments.json
  - planning/brand_tokens.json
- Credentials (non-secret placeholders):
  - Google Maps API key(s) for Android/iOS + Geocoding (restricted)
  - Apple Sign In credentials (Service ID, Key ID, Team ID, .p8)
  - Google OAuth client IDs (Android, iOS, Web if admin web)
  - reCAPTCHA/App Check setup for Phone Auth (if used)
  - FCM Web VAPID key (if any web targets)
- Firebase project already configured: OK

---

## Step 0 — App Shell & Animated Splash (Priority: High, Complexity: Low)
Objective: Deliver a polished animated splash and app shell that boots Riverpod and Firebase cleanly.

Tasks
- Configure native splash with flutter_native_splash for instant display.
- Implement in-app animated splash (Lottie or Rive) that displays while appInitProvider runs.
- Create appInitProvider to initialize Firebase, enable Firestore offline persistence, and warm up services.
- Tie navigation to init completion with a max timeout (e.g., 2.5s) to avoid blocking.

DoD
- No white flash; smooth transition from native splash to animated splash to Home.
- App initializes Firebase and providers during splash phase.

CI Gate
```powershell path=null start=null
flutter analyze
flutter test --name "Splash" --no-pub
```

---

## Step 1 — Project Foundation, Config, CI (Priority: High, Complexity: Medium)
Objective: Scaffold Flutter + Riverpod + Firebase; flavors; emulators; baseline CI.

Tasks
- Create app flavors: dev, stage, prod; ensure bundle ids/appIds unique.
- Initialize FlutterFire for all flavors; add firebase_core.
- Add base dependencies: flutter_riverpod, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging, firebase_analytics, google_maps_flutter, geolocator, geocoding, image_picker, permission_handler, uuid.
- Configure Firebase Emulators (auth, firestore, storage, functions).
- Add GitHub Actions workflow (analyze, test, emulator smoke).
- Add linting rules (flutter_lints) and pre-commit hook.
- Add App Check (planned but disabled in dev; on in prod).

DoD
- App starts with a placeholder Home screen.
- Emulators run locally; app can connect to emulators in dev.
- CI runs analyze + tests successfully on PR.

CI Gate
```powershell path=null start=null
flutter pub get
flutter analyze
flutter test --no-pub
firebase emulators:exec --only auth,firestore,storage "echo Emulators OK"
```

---

## Step 2 — Authentication & User Profile (Priority: High, Complexity: Medium)
Objective: Email/Google/Phone sign-in, user doc creation, profile editing.

Tasks
- Integrate firebase_auth and optional firebase_ui_auth for rapid screens.
- Implement userRepository and auth providers (Riverpod).
- On first sign-in, create /users/{uid} with minimal fields.
- Profile edit (displayName/photo).
- Custom claims for admins (via Cloud Function; allowlist).
- Update Firestore rules for users.

DoD
- Sign-in/out with Email and Google; Phone optional.
- /users/{uid} created; profile screen updates displayName/photo.
- Admin flag respected in app via claims.

CI Gate
```powershell path=null start=null
flutter test --name "Auth" --no-pub
firebase emulators:exec --only auth,firestore "npm test --workspace functions"
```

---

## Step 3 — Report Issue: Media Capture & Upload (Priority: High, Complexity: High)
Objective: Camera/gallery, progress, retries, Storage upload.

Tasks
- image_picker integration; compress images to reasonable size.
- Upload queue with progress; retry/backoff on failures.
- Store Storage path in model; optional downloadURL via Function.
- Storage rules for images.

DoD
- Capture from camera/gallery; upload succeeds with progress.
- Handles offline queue; resumes after app restart.

CI Gate
```powershell path=null start=null
flutter test --name "Media Upload" --no-pub
firebase emulators:exec --only storage "echo storage rules OK"
```

---

## Step 4 — Report Issue: Location + Reverse Geocoding (Priority: High, Complexity: Medium)
Objective: Auto-location, address lookup, editable.

Tasks
- geolocator permission + location fetch.
- geocoding reverse lookup; cache by coordinate rounding.
- Model fields: GeoPoint, geohash, address.
- UI controls for editable address.

DoD
- Upon permission, lat/lng + address auto-filled; user can edit.
- Graceful fallback if geocoding fails.

CI Gate
```powershell path=null start=null
flutter test --name "Location" --no-pub
```

---

## Step 5 — Report Issue: Submit Flow (Priority: High, Complexity: Medium)
Objective: Create report doc with validation and server timestamps.

Tasks
- Create ReportRepository; createReportControllerProvider.
- Validate inputs: category required; severity optional default.
- Firestore rules: authenticated create; authorId must match request.auth.uid.
- Cloud Function onCreate: optional thumbnail, admin notify placeholders.

DoD
- Submitting creates reports/{id} with expected fields; status = submitted.
- Rules and emulator tests pass.

CI Gate
```powershell path=null start=null
flutter test --name "Create Report" --no-pub
firebase emulators:exec --only firestore "echo firestore rules OK"
```

---

## Step 6 — My Reports: List + Detail + Timeline (Priority: High, Complexity: Medium)
Objective: Track own reports with status timeline.

Tasks
- myReportsProvider with pagination (createdAt DESC).
- reportDetailProvider; status_updates subcollection.
- Detail screen with media and timeline.

DoD
- List shows own reports; pagination works.
- Detail renders status timeline; updates live.

CI Gate
```powershell path=null start=null
flutter test --name "My Reports" --no-pub
```

---

## Step 7 — Community Verification: Nearby Map/List + Votes (Priority: Medium, Complexity: Medium)
Objective: Discover nearby issues; verify (vote) once per user.

Tasks
- Save geohash on reports; implement range queries for bounds.
- Map/list toggle with clustering.
- votes subcollection and Cloud Function to maintain votesCount.
- Rules to allow user write only at /votes/{uid}.

DoD
- Nearby list/map filters by category and status.
- Voting increments/decrements correctly; optimistic UI.

CI Gate
```powershell path=null start=null
flutter test --name "Community" --no-pub
firebase emulators:exec --only firestore "echo votes rules OK"
```

---

## Step 8 — Notifications (FCM) (Priority: High, Complexity: Medium)
Objective: Notify users on status changes.

Tasks
- Request notification permission; register tokens to /users/{uid}.fcmTokens.
- Cloud Function trigger on status_updates create → notify report author’s tokens.
- Deep link into report detail (optional for MVP).

DoD
- Status change generates push; tapping opens correct screen.

CI Gate
```powershell path=null start=null
flutter test --name "FCM" --no-pub
npm test --workspace functions
```

---

## Step 9 — Admin Portal (Flutter Web, Hosted) (Priority: Medium, Complexity: High)
Objective: Minimal admin dashboard to filter, assign, update status.

Tasks
- Bootstrap Flutter Web entrypoint (lib/admin_main.dart).
- Admin auth via Google SSO; role guard using claims.
- Dashboard: filters, list/table + map pane.
- Update status with note (writes to status_updates).
- Departments CRUD; simple routing rules stub.
- Host under Firebase Hosting target “admin”.

DoD
- Admin-only access enforced; can search/filter and update statuses.
- Deployed to Hosting under /admin (or separate subdomain).

CI Gate
```powershell path=null start=null
flutter build web --release -t lib/admin_main.dart --web-renderer canvaskit
# Hosting deploy runs only on main; preview channels for PRs
```

---

## Step 10 — Rewards & Leaderboard (MVP-lite) (Priority: Low, Complexity: Low)
Objective: Impact score, basic badges, leaderboard.

Tasks
- Increment impactScore on report creation and verified votes via Function.
- Badge thresholds as constants; update users.badges.
- Leaderboard query on users ordered by impactScore DESC with index.

DoD
- Impact score visible; badges awarded; leaderboard page lists top users.

CI Gate
```powershell path=null start=null
flutter test --name "Rewards" --no-pub
npm test --workspace functions
```

---

## Step 11 — Geo-fencing Alerts (Optional) (Priority: Low, Complexity: Medium)
Objective: Local alerts near unresolved hotspots.

Tasks
- Background location permissions; scan nearby geohashes locally.
- Local notifications with throttle; battery-friendly intervals.
- Feature flag to disable in regions with privacy constraints.

DoD
- Device shows local alert when entering radius of unresolved high-severity issues.

CI Gate
```powershell path=null start=null
flutter test --name "Geofencing" --no-pub
```

---

## Step 12 — AI Enhancements (Optional Phase 2) (Priority: Low, Complexity: High)
Objective: Image classification and crowd-priority scoring.

Tasks
- Start with rule-based crowd-priority (votes + density within 100m).
- Later integrate TFLite or Cloud Vision via HTTPS Function; store predictedCategory/severity.

DoD
- Crowd-priority score impacts admin sorting; optional ML toggled via remote config.

CI Gate
```powershell path=null start=null
flutter test --name "Priority Scoring" --no-pub
npm test --workspace functions
```

---

## Step 13 — Production Hardening & Release (Priority: High, Complexity: Medium)
Objective: Ship-quality readiness.

Tasks
- Enable App Check in prod; enforce in rules for Firestore/Storage.
- Privacy policy link; terms; data retention policy reflected in docs.
- Crashlytics and Analytics events instrumented.
- Performance review: indexes, pagination, thumbnails, caching.
- Accessibility audit: contrast, labels, dynamic type.
- Store listing assets; versioning; feature flags default sane.

DoD
- App runs stable on low-end devices; no unindexed queries; no P0 accessibility issues.

CI Gate
```powershell path=null start=null
flutter analyze
flutter test --no-pub
```

---

## Cross-cutting QA Checkpoints (run at each step)
- Emulator-based rule tests for any new collection or rule change.
- Negative tests: unauthorized writes, cross-user access, invalid content types.
- Offline tests: submit report while offline; verify sync on reconnect.
- Performance tests: query loads within acceptable bounds; images thumbnailed.

## Security Controls to Verify Along the Way
- Firestore rules deny role escalation; user can only write their own profile safe subset.
- Reports create requires auth; authorId == request.auth.uid.
- votes enforce one document per user; Functions sanitize and validate inputs.
- Storage rules limit size and contentType; EXIF stripping on thumbnails (in Function).
- Admin actions guarded by custom claims; portal reads/writes limited accordingly.
- App Check enforced in prod environments.

## Dependencies Overview (high level)
- Step 1 → 2 → 3 → 4 → 5 → 6 is linear (MVP core).
- Step 7 (Community) depends on 5 (reports data) and geohash from 4.
- Step 8 (Notifications) depends on 6 (status_updates usage).
- Step 9 (Admin) depends on 2 (claims), 5 (reports), 6 (status_updates).
- Steps 10–12 optional and depend on MVP + basic community/notifications.

## Risk Notes and Mitigations
- Media upload reliability: use background-safe upload + retry/backoff; test on flaky network.
- Geolocation accuracy: allow manual edit and attach accuracy meters; store accuracy if available.
- Abuse (spam/NSFW): add report flagging, rate-limit via Functions; enable App Check.
- Performance: enforce indexes; avoid unbounded streams; use pagination and map clustering.
- Privacy: avoid exposing PII; restrict media URLs; consider signed URLs or Storage Security Rules relying on auth gate.

## Credential Injection Plan (no secrets in repo)
- Android: Place Google Maps API key via manifest placeholder and restrict by SHA + package.
- iOS: Add key to Info.plist and restrict by bundle id; enable Apple Sign In capability.
- Web (if admin web shows map): use restricted key for web referer domains only.
- Use environment-specific keys via --dart-define or per-flavor files kept out of VCS.

## Example commands for local milestones
```powershell path=null start=null
# Configure Firebase for flavors (run once per flavor)
flutterfire configure --project {{FIREBASE_PROJECT_ID}} --out lib/firebase_options_dev.dart

# Run with dev flavor and connect to emulators
flutter run --dart-define=FLAVOR=dev

# Build admin web
flutter build web --release -t lib/admin_main.dart --web-renderer canvaskit
```

## What to implement next
- Confirm categories_departments.json and brand_tokens.json.
- Proceed with Step 0 (App Shell & Animated Splash), then Step 1 (Foundation).
