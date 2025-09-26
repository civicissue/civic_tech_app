# CivicTech Mobile + Admin — Implementation Plan

Act as my senior developer and implement gracefully step by step following best practices.

One-line elevator pitch: A Flutter + Firebase platform for citizens to report civic issues with photos and location, and for city staff to triage, track, and resolve them in real time.

---

Table of Contents
- Summary
- Architecture Overview
- Feature List (Epics → Features → Tasks)
- Epic Details (per feature: story, acceptance, data model, providers, file tree, snippets, QA, CI hints)
  - Epic 0: App Shell & Animated Splash
  - Epic 1: Authentication & Profile
  - Epic 2: Report Issue (Capture, Location, Submit)
  - Epic 3: My Reports (Track & Timeline)
  - Epic 4: Community Verification (Map/List, Upvotes)
  - Epic 5: Notifications (FCM)
  - Epic 6: Rewards & Leaderboard (MVP-lite)
  - Epic 7: Admin Portal (Web)
  - Epic 8: Geo-fencing Alerts (Optional)
  - Epic 9: Infrastructure & CI/CD
  - Epic 10: AI Enhancements (Optional Phase 2)
- Firebase specifics (Auth flows, Firestore & Storage rules)
- UI/UX guidance (screens, wireframes, micro-interactions)
- Non-functional requirements
- Developer ergonomics & standards
- Handoff docs
- Credentials needed
- Final checks: open questions & assumptions
- Sprint-style prioritization

---

Summary
- Goal: Deliver a production-ready, minimal, and scalable Flutter app (citizen) + Firebase backend + lightweight admin web.
- Constraints honored: Riverpod for state management; Firebase for Auth, Firestore, Storage, Cloud Functions, Hosting; optional ML in Phase 2.
- Based on planning folder:
  - Included: complete-project.md (problem, features, phases), mobile-app-layout.md (citizen UX areas).
  - Not included: brand/design tokens, finalized categories/departments, full admin requirements; these are listed under Open Questions.

---

Architecture Overview
- Mobile app: Flutter (Android/iOS, optionally Web) using Riverpod 2+.
- Admin portal: Flutter Web (shares models/providers) or React (if preferred); hosted on Firebase Hosting.
- Backend: Firebase Auth, Cloud Firestore, Cloud Storage, Cloud Functions (TypeScript), FCM.
- Maps & location: Google Maps SDK + Geolocator; optional geohash for nearby queries.
- Offline: Firestore offline persistence + optimistic UI for votes; media upload queued when online.

```mermaid path=null start=null
flowchart LR
  subgraph Client
    A[Flutter Citizen App]\n(Riverpod) --> B[Firebase Auth UI/custom]
    A --> C[Firestore]
    A --> D[Storage]
    A --> E[FCM]
    A --> M[Google Maps SDK]
    Admin[Admin Web (Flutter Web)] --> C
    Admin --> E
  end

  subgraph Firebase
    C[(Cloud Firestore)] <--> F[Cloud Functions]
    D[(Cloud Storage)] <--> F
    E[(FCM)] <--> F
  end

  F --> G[Routing & Notifications]
  F --> H[Analytics & Aggregations]
```

Data Flow (happy path)
- Citizen captures photo/video → uploads to Storage → gets path → submits report document to Firestore with GeoPoint and metadata.
- Cloud Function triggers on new report → optional: thumbnail, dedup scoring, notify admins.
- Admin changes status → Cloud Function notifies author via FCM.
- Citizen sees My Reports and Community Issues via Firestore queries with pagination.

---

Feature List (Epics → Features → Tasks)
- Epic 0: App Shell & Animated Splash
  - Features: Animated splash, app initialization, theme tokens
  - Tasks: Native splash (flutter_native_splash), animated in-app splash (Lottie/Rive), Riverpod bootstrap providers
- Epic 1: Authentication & Profile
  - Features: Sign-in (email, phone, Google, Apple), Profile, Roles (admin claim)
  - Tasks: Auth UI, user doc creation, profile edit, claim-based guards
- Epic 2: Report Issue
  - Features: Capture/Upload, Auto-location + reverse geocode, Categorize/Severity, Submit
  - Tasks: Camera/gallery, Storage upload, Geolocation, Category list, Firestore writes
- Epic 3: My Reports
  - Features: List, Detail, Status timeline
  - Tasks: Queries by author, detail screen, subcollection timeline
- Epic 4: Community Verification
  - Features: Nearby map/list, Upvote/verify, Duplicate merge indicator
  - Tasks: Geohash storage, range queries, vote subcollection + Cloud Function counters
- Epic 5: Notifications
  - Features: Token registration, topic/user notifications
  - Tasks: Permissions, token save, Functions to send on status changes
- Epic 6: Rewards & Leaderboard (MVP-lite)
  - Features: Impact score, Badges, Leaderboard
  - Tasks: Simple counters, scheduled aggregation, public leaderboard query
- Epic 7: Admin Portal
  - Features: Auth (Google SSO), Dashboard (filter/map), Assignments, Status updates, Departments mgmt
  - Tasks: Role guard, query tools, status update UI, Functions for side effects
- Epic 8: Geo-fencing Alerts (Optional)
  - Features: Background geofence near hotspots
  - Tasks: Background location, on-device radius check, optional topics
- Epic 9: Infrastructure & CI/CD
  - Features: Emulators, Rules, Indexes, GitHub Actions, Hosting deploy
  - Tasks: configs, scripts, workflows
- Epic 10: AI Enhancements (Optional Phase 2)
  - Features: Image classification, Crowd-priority scoring
  - Tasks: Model selection/inference (on-device or Functions), scoring function

---

Epic 0: App Shell & Animated Splash

Feature: Animated Splash and App Bootstrap
- Description & User story: As a user, I want a polished animated splash while the app initializes so I perceive fast, quality startup.
- Acceptance criteria
  - Native splash shows instantly; transitions seamlessly to an in-app animated splash (Lottie/Rive) while Firebase initializes and providers warm up.
  - Animation completes or is skipped once initialization is done; time out fallback of 2.5s to avoid blocking.
- Data/Providers
  - appInitProvider: FutureProvider<void> that initializes Firebase, loads remote config (optional), requests permissions (deferred), and preloads theme tokens.
  - splashControllerProvider: StateProvider<bool> to control animation visibility.
- File tree
```text path=null start=null
lib/
  app/
    app.dart
    bootstrap.dart
    splash/
      animated_splash.dart
      assets/animated_splash.json   # Lottie asset (placeholder)
```
- Minimal sample code
```dart path=null start=null
final appInitProvider = FutureProvider<void>((ref) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Warm up Firestore and Messaging if needed
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
});
```
- QA checklist
  - Functional: No white flash; splash lasts until init completes or timeout; handles cold and warm starts.
  - Edge: Offline first run; slow init; animation asset missing ⇒ fallback to static logo.
  - Security: No secrets embedded in the asset; assets licensed properly.
- Deployment/CI hints
  - Use flutter_native_splash for native layer; commit config under flutter_native_splash.yaml.

---

Epic 1: Authentication & Profile

Feature: Sign-in (email, phone, Google, Apple)
- Description & User story: As a citizen, I want simple sign-in so I can submit and track issues.
- Acceptance criteria
  - Can sign in with email/password, phone (with verification), Google; Apple on iOS.
  - First sign-in creates /users/{uid} with basic profile.
  - Sign-out works; auth state reflected in UI.
- Data model
  - Collection: users
    - uid (doc id), displayName, email, phone, photoURL, role: 'citizen'|'admin', impactScore:int, badges:[string], fcmTokens:{token: platform/meta}, createdAt, updatedAt, lastKnownLocation: GeoPoint?
  - Indexes
    - users: role ASC, impactScore DESC (for admin list/leaderboard)
- Provider map
  - authStateProvider: StreamProvider<User?>
  - currentUserDocProvider(uid): StreamProvider<UserDoc?>
  - signInControllerProvider: AsyncNotifier<void>
  - userRepositoryProvider: Provider<UserRepository>
- File tree
```text path=null start=null
lib/
  features/auth/
    data/user_repository.dart
    providers/auth_providers.dart
    ui/auth_gate.dart
    ui/sign_in_screen.dart
  common/
    widgets/app_scaffold.dart
```
- Minimal sample code
```dart path=null start=null
class UserDoc {
  final String uid;
  final String? displayName;
  final String? email;
  final String role; // 'citizen' or 'admin'
  final int impactScore;
  const UserDoc({required this.uid, this.displayName, this.email, this.role = 'citizen', this.impactScore = 0});
  factory UserDoc.fromMap(String id, Map<String, dynamic> m) => UserDoc(
    uid: id,
    displayName: m['displayName'],
    email: m['email'],
    role: m['role'] ?? 'citizen',
    impactScore: (m['impactScore'] ?? 0) as int,
  );
  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'email': email,
    'role': role,
    'impactScore': impactScore,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
```
```dart path=null start=null
final authStateProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());
final userRepositoryProvider = Provider((ref) => UserRepository(ref.read));
final currentUserDocProvider = StreamProvider<UserDoc?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((d) => d.exists ? UserDoc.fromMap(d.id, d.data()!) : null);
});
```
- QA checklist
  - Functional: All providers update on auth state changes; first login writes user doc; error states surfaced.
  - Edge cases: Deleted user doc; email not verified; phone reCAPTCHA fail; Apple without name on first sign-in.
  - Security: Firestore rules enforce user can read/write only own profile fields; admin role via custom claims only.
- Deployment/CI hints
  - emulator: firebase emulators:exec --only auth,firestore "flutter test"
  - flutter analyze; unit tests for mapping and guards.

Feature: Profile
- Story: As a user, I can view/edit my display name and photo.
- Acceptance: Update persists; offline queue; reflects across sessions.
- Data: users fields displayName, photoURL.
- Providers
  - profileControllerProvider: AsyncNotifier<void>
- QA: Validate max lengths, disallow script tags, image size/type.

Feature: Roles (admin claim)
- Story: As an admin, I can access admin portal; citizens cannot.
- Acceptance: Admin gets isAdmin flag from token; routes guarded.
- Data: users.role is informational; actual gate via custom claims.
- Providers: isAdminProvider: Provider<bool>

---

Epic 2: Report Issue (Capture, Location, Submit)

Feature: Capture/Upload Media
- Story: As a citizen, I can attach a photo (or short video), so staff can see the issue.
- Acceptance
  - Can capture from camera or pick from gallery.
  - Upload shows progress; retries on flaky network; max size 10 MB image.
- Data model
  - Storage path: reports/{reportId}/{uuid}.jpg
  - Firestore reports doc stores storagePath and optional downloadURL (derived via Function if needed).
- Providers
  - storageServiceProvider: Provider<StorageService>
  - mediaUploadControllerProvider: AsyncNotifier<UploadResult>
- Minimal snippet
```dart path=null start=null
class ReportMedia {
  final String storagePath; // reports/{id}/{uuid}.jpg
  final String? downloadURL;
  const ReportMedia({required this.storagePath, this.downloadURL});
}
```

Feature: Auto-location + Reverse Geocode
- Story: As a citizen, I want the app to auto-fill my location and address.
- Acceptance: On permission grant, captures lat/lng; reverse geocodes address; can edit manually.
- Data model
  - reports.location: GeoPoint
  - reports.geohash: string (for range queries)
  - reports.address: string
- Providers
  - geolocatorProvider: Provider<Geolocator>
  - locationControllerProvider: AsyncNotifier<LatLng?>
  - mapsServiceProvider: Provider<MapsService>

Feature: Categorize/Severity
- Story: As a citizen, I select category (pothole/garbage/streetlight/other) and severity.
- Acceptance: Category required; severity optional with default.
- Data: reports.category: enum string; reports.severity: 'low'|'medium'|'high'

Feature: Submit Report
- Story: As a citizen, I can submit a report and track it.
- Acceptance
  - Creates reports/{id} with initial status 'submitted'.
  - Status changes appear in timeline.
- Data model
  - Collection: reports
    - id, authorId, category, severity, description, media:[{storagePath,downloadURL}], location:GeoPoint, geohash, address, status:'submitted'|'acknowledged'|'in_progress'|'resolved'|'invalid', departmentId?, assignedTo?, votesCount:int, crowdVerifiedCount:int, duplicateOf?, createdAt, updatedAt
  - Subcollection: reports/{id}/status_updates
    - status, note, actorId, createdAt
  - Indexes
    - reports: status ASC, createdAt DESC
    - reports: authorId ASC, createdAt DESC
    - reports: category ASC, status ASC, createdAt DESC
- Providers
  - reportRepositoryProvider: Provider<ReportRepository>
  - createReportControllerProvider: AsyncNotifier<String /*reportId*/>
  - myReportsProvider(uid): QueryProvider<List<ReportDoc>>
- File tree
```text path=null start=null
lib/
  features/report/
    data/report_repository.dart
    models/report.dart
    providers/report_providers.dart
    ui/create_report_screen.dart
    ui/report_detail_screen.dart
```
- Minimal snippet
```dart path=null start=null
class ReportDoc {
  final String id;
  final String authorId;
  final String category;
  final String status;
  final GeoPoint location;
  final String? address;
  final int votesCount;
  const ReportDoc({required this.id, required this.authorId, required this.category, required this.status, required this.location, this.address, this.votesCount = 0});
  factory ReportDoc.fromMap(String id, Map<String, dynamic> m) => ReportDoc(
    id: id,
    authorId: m['authorId'],
    category: m['category'],
    status: m['status'],
    location: m['location'],
    address: m['address'],
    votesCount: (m['votesCount'] ?? 0) as int,
  );
}
```
- QA checklist
  - Functional: Upload retry; permission denial path; mandatory fields; offline queue.
  - Edge: Large photos; GPS disabled; duplicate submissions; description with emojis; device time skew.
  - Security: Only authenticated create; authorId enforced server-side in Function or Security Rule; content type restrictions.
- Deployment/CI hints: Run firebase emulators with storage and firestore tests for security rules on create.

---

Epic 3: My Reports (Track & Timeline)

Feature: List & Detail
- Story: As a citizen, I can see my reported issues sorted by latest.
- Acceptance: Paginated list; tapping opens detail; shows status and last update.
- Providers
  - myReportsProvider(uid): StreamProvider<List<ReportDoc>> with limit/nextPage
  - reportDetailProvider(id): StreamProvider<ReportDoc?>

Feature: Status Timeline
- Story: As a citizen, I can view a timeline of changes.
- Acceptance: Shows ordered status_updates; includes actor and note.
- Data: reports/{id}/status_updates
- QA: Verify ordering; permissions (author and admins can read all).

---

Epic 4: Community Verification (Map/List, Upvotes)

Feature: Nearby map/list
- Story: As a citizen, I can browse nearby issues.
- Acceptance: List and map; filters by category/status; paginated.
- Data: reports with geohash for bounds queries.
- Providers: nearbyReportsProvider(bounds): FutureProvider<List<ReportDoc>>

Feature: Upvote/Verify
- Story: As a citizen, I can verify the issue exists (one vote per user).
- Acceptance: Voting increments counter; user can unvote.
- Data model
  - Subcollection: reports/{id}/votes/{uid}: {value:true, createdAt}
  - Cloud Function maintains reports.votesCount and crowdVerifiedCount.
- QA: Prevent duplicate votes; offline vote queued and merged.

---

Epic 5: Notifications (FCM)

Feature: Token registration
- Story: App registers device token and stores it on /users/{uid}.fcmTokens.
- Acceptance: Token refreshed on change; unsubscribed on sign-out.
- Providers: fcmServiceProvider; notificationsControllerProvider

Feature: Status change notifications
- Story: When admin updates a report, the author is notified.
- Acceptance: Cloud Function triggers on status_updates; sends to author tokens.
- QA: Permission prompts; background/terminated handling; deep-links to detail.

---

Epic 6: Rewards & Leaderboard (MVP-lite)

Feature: Impact score and badges
- Story: Reporting/verification contributes to impactScore; badges awarded at thresholds.
- Data: users.impactScore, users.badges; scheduled Function to compute.

Feature: Leaderboard
- Story: View top reporters citywide.
- Data: query users ordered by impactScore DESC; composite index.

---

Epic 7: Admin Portal (Web)

Feature: Auth + Guard
- Google SSO only; Cloud Function assigns custom claim admin:true by email allowlist.

Feature: Dashboard
- Filter by status/category/date; map view; list view; CSV export (later).

Feature: Assignment & Status updates
- Admin adds status updates with note; optional assignee.

Feature: Departments Management
- CRUD departments used by routing rules.

Notes
- Keep V1 minimal: Flutter Web to reuse models/providers; hosting at /admin.

---

Epic 8: Geo-fencing Alerts (Optional)
- Background location permission; on-device check against nearby unresolved issues; local notifications; throttle to avoid spam.

---

Epic 9: Infrastructure & CI/CD
- Emulators (auth, firestore, storage, functions) for local tests.
- Rules & Indexes committed to repo.
- GitHub Actions for analyze, test, emulator tests, and Hosting deploy of admin web.

---

Epic 10: AI Enhancements (Optional Phase 2)
- Start simple: rule-based crowd-priority using votes and duplicates within 50–100m radius.
- Later: TensorFlow Lite on-device model or Cloud Vision/Vertex hosted inference via HTTPS Function.

---

Firebase specifics

Recommended auth flows
- Email/Password with email verification.
- Phone (with SafetyNet/Play Integrity + reCAPTCHA for web).
- Google Sign-In (citizen + admin); Apple Sign-In (iOS); Facebook optional.

Firestore rules (skeleton)
```js path=null start=null
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }
    function isAdmin() { return isSignedIn() && request.auth.token.admin == true; }
    function isOwner(uid) { return isSignedIn() && request.auth.uid == uid; }

    match /users/{uid} {
      allow read: if isOwner(uid) || isAdmin();
      allow create: if isOwner(uid);
      allow update: if isOwner(uid) && !("role" in request.resource.data);
      allow delete: if false;
    }

    match /reports/{reportId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && request.resource.data.authorId == request.auth.uid;
      allow update: if isAdmin() || (isSignedIn() && resource.data.authorId == request.auth.uid && resource.data.status == 'submitted');
      allow delete: if isAdmin();

      match /status_updates/{sid} {
        allow read: if isSignedIn();
        allow create: if isAdmin();
        allow update, delete: if isAdmin();
      }

      match /votes/{uid} {
        allow read: if isSignedIn();
        allow create, update: if isOwner(uid) && request.resource.data.keys().hasOnly(['value','createdAt']) ;
        allow delete: if isOwner(uid);
      }
    }

    match /departments/{id} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    match /admin_settings/{doc} {
      allow read, write: if isAdmin();
    }
  }
}
```

Storage rules (skeleton)
```js path=null start=null
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isSignedIn() { return request.auth != null; }
    function isAdmin() { return isSignedIn() && request.auth.token.admin == true; }

    match /reports/{reportId}/{fileName} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && request.resource.size < 10 * 1024 * 1024 && request.resource.contentType.matches('image/.*|video/.*');
    }

    match /users/{uid}/profile/{fileName} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && uid == request.auth.uid && request.resource.contentType.matches('image/.*');
    }
  }
}
```

Firestore indexes (suggested)
```json path=null start=null
{
  "indexes": [
    {"collectionGroup": "reports", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "status", "order": "ASCENDING"},
      {"fieldPath": "createdAt", "order": "DESCENDING"}
    ]},
    {"collectionGroup": "reports", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "authorId", "order": "ASCENDING"},
      {"fieldPath": "createdAt", "order": "DESCENDING"}
    ]},
    {"collectionGroup": "reports", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "category", "order": "ASCENDING"},
      {"fieldPath": "status", "order": "ASCENDING"},
      {"fieldPath": "createdAt", "order": "DESCENDING"}
    ]}
  ]
}
```

---

UI/UX guidance (Apple HIG-inspired minimalism + glassmorphism)

Screens
0) Animated Splash
- Priority content: Brand mark, subtle animated shape or Lottie loop; progress tied to appInitProvider.
- Micro-interactions: Fade-in, 180–240ms; reduce motion flag shortens or disables animation.
- Accessibility: High contrast logo, voiceover reads "Loading" with progress.

1) Home / Report Issue
- Priority content: Camera entry, last location chip, category picker, submit CTA.
- Wireframe
```text path=null start=null
[Header: CivicTech]
[Card: Glassmorphism]
  [Camera thumbnail] [Add Photo]
  [Location: • 12.9716,77.5946  (Change)]
  [Address (auto)........................]
  [Category: (Pothole ▾)] [Severity: (Medium ▾)]
  [Description...........................]
  [Submit]
```
- Micro-interactions: Haptic on submit; progress toasts for upload; auto-focus description after media added.
- Visual hierarchy: Large submit button; translucent cards; blurred background; 16pt base spacing; 24pt between sections.
- Accessibility: Dynamic type; minimum 4.5:1 contrast; announce errors with semantics.

2) My Reports
- Priority: Status chips, last updated, filter.
- Micro: Pull-to-refresh; skeleton shimmer; lazy list.
- Accessibility: Labels for status; large tap targets.

3) Community Issues (Map/List)
- Priority: Map with pins; filter by category/status; list for low-end devices.
- Micro: Pin clustering; tap to open sheet; recenter button.
- Accessibility: High-contrast pins; voiceover labels for pins.

4) Report Detail
- Priority: Media carousel; status timeline; upvote control.
- Micro: Hero transition from list; optimistic upvote; share deep link.
- Accessibility: Alt text from description; large hit areas.

5) Rewards & Leaderboard
- Priority: Impact score bar; badges; top reporters.
- Micro: Confetti for badge earned; subdued animations.
- Accessibility: Color-independent status; readable ranks.

6) Admin Dashboard (Web)
- Priority: Filter panel; data table; map pane.
- Micro: Keyboard shortcuts (/, arrows); bulk select; toasts on actions.
- Accessibility: Table semantics; focus rings; high-contrast mode.

Spacing system
- 8pt grid; 16pt padding on edges; 24–32pt for section separation; min touch target 44x44pt.

---

Non-functional requirements
- Security
  - Enforce custom claims for admin; deploy rules alongside code; validate inputs in Functions.
  - Sanitize text (strip scripts), validate media type/size; restrict PII exposure.
- Performance
  - Pagination: limit 20–30 items; indexed queries only; use geohash for nearby.
  - Caching: Riverpod providers keepAlive where sensible; memoize reverse geocoding.
  - Thumbnails: generate 800px previews via Functions.
- Offline & sync
  - Enable Firestore persistence; optimistic updates for votes; conflict resolution: last-write-wins with server timestamps; show conflict toasts when merges occur.

---

Developer ergonomics & standards
- Pubspec dependencies (no versions)
  - firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging, firebase_analytics
  - flutter_riverpod, riverpod_annotation, hooks_riverpod (optional)
  - firebase_ui_auth (for rapid auth screens)
  - google_maps_flutter, geolocator, geocoding
  - image_picker, permission_handler, path_provider, uuid, intl
  - json_annotation, build_runner, json_serializable
  - flutter_lints
- Project conventions
  - Folder structure: lib/features/<feature>/{data,models,providers,ui}; lib/common/{widgets,utils,services}
  - Naming: snake_case files; PascalCase classes; provider suffix Provider.
  - Lints: enable flutter_lints; no dynamic unless necessary; avoid runtime type.
- Analyzer config (skeleton)
```yaml path=null start=null
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_const_constructors: true
    always_declare_return_types: true
    avoid_print: true
```
- Git hooks (Windows-friendly)
```bash path=null start=null
# .git/hooks/pre-commit (make executable)
flutter format --set-exit-if-changed . || exit 1
flutter analyze || exit 1
flutter test || exit 1
```
- GitHub Actions (Flutter + Firebase Hosting skeleton)
```yaml path=null start=null
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --no-pub
  emu-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm install -g firebase-tools
      - run: firebase emulators:exec --project demo-project "echo Emulators OK"
  deploy-admin:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: flutter build web --release -t lib/admin_main.dart --web-renderer canvaskit
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          channelId: live
          target: admin
```

---

Handoff docs
- README sections to add
  - Project overview, architecture diagram
  - Getting started (FlutterFire configure, run emulators, run app)
  - Environments (dev/stage/prod), app configuration (flavors)
  - Deploying Functions and Hosting
  - Testing strategy and emulator workflow
- Code review checklist
  - Uses indexed queries; no unbounded streams
  - Rules covered for any new collection
  - Providers testable; no heavy logic in widgets
  - Errors surfaced to UI; no silent catches
  - Strings localized-ready; no magic numbers
- Release checklist
  - Android: appId, signing, Play Console metadata, privacy policy URL
  - iOS: bundle id, provisioning, Sign in with Apple configured, Push capability
  - Firebase: SHA certs, APNs keys uploaded, Dynamic Links (if used)
  - Maps: API key in AndroidManifest/Info.plist; restrict by package/bundle and SHA

---

Credentials needed (besides Firebase project already configured)
- Google Maps Platform API key(s)
  - Android SDK, iOS SDK, Geocoding, Places (optional)
  - Restrict by package name + SHA-1/SHA-256 (Android) and bundle id (iOS)
- Apple Sign In
  - Service ID, Key ID, Team ID, private key (.p8)
- Google OAuth (for Google Sign-In)
  - OAuth client IDs for Android, iOS, and Web (if web admin)
- Phone Auth (Web)
  - reCAPTCHA keys or SafetyNet/Play Integrity configuration
- FCM Web (if web client): VAPID key
- Android keystore (upload + release) and iOS signing certificates/profiles
- Optional (Phase 2)
  - Cloud Vision/Vertex AI API key and model endpoint (if using hosted inference)
  - Sentry/Crashlytics DSN (Crashlytics already via Firebase)

---

Now act as my senior QA specialist and check the plan for security, edge-cases, & test coverage gaps.

QA Pass
- Security
  - Verify rules deny role escalation and cross-user writes; test with emulators.
  - Ensure Functions validate authorId and sanitize strings; strip EXIF GPS from thumbnails if privacy is a concern.
  - Token management: remove tokens on sign-out; handle token rotation.
- Edge cases
  - Offline report creation with pending media upload; ensure retries persist after app kill.
  - Duplicate detection: avoid accidental merges; present merge suggestion only.
  - Geocoding failures; fallback to lat/lng only.
  - Phone auth abuse: rate limit with Functions; enable App Check.
- Tests
  - Unit: model mappers; providers (with riverpod test); validators.
  - Widget: create report flow; my reports list pagination.
  - Integration: emulator tests for rules (create report, vote, status update by admin only).
  - Functions: trigger tests for vote counter, notifications, thumbnail creation.

---

Act as a senior designer at Apple and propose UI improvements using visual hierarchical depth, glassmorphism, and minimalism following Apple’s HIG principles.

Design Improvements
- Visual depth
  - Use blurred translucent cards over subtle city map illustration; strong elevation for destructive actions.
- Minimal inputs
  - Progressive disclosure: only show severity after category chosen.
  - Smart defaults: pre-fill location; single primary CTA per screen.
- Motion
  - Gentle 150–200ms transitions; reduce motion setting respected.
- Accessibility
  - Dynamic Type tested Large/Extra Large; VoiceOver labels for map pins and status chips; sufficient tap targets.

---

Final checks

Open questions and assumptions (please provide or confirm)
- Provide finalized list of categories and departments with routing rules.
  - Required file: planning/categories_departments.json (categories[], departments[], routing rules).
- Branding/design tokens
  - Required file: planning/brand_tokens.json (colors, typography, iconography, spacing scale).
- Admin portal tech choice
  - Prefer Flutter Web; confirm if React is required.
- Geo-fencing policy
  - Is background location allowed? Provide copy and thresholds.
- Privacy policy & data retention
  - Provide URLs and retention rules for media and reports.
- Rewards mechanics
  - Provide thresholds and badge names; partner integrations if any.

Sprint-style prioritization and dependency order
- High
  - Epic 1: Auth & Profile (Complexity: Medium)
  - Epic 2: Report Issue (Complexity: High)
  - Epic 3: My Reports (Complexity: Medium)
  - Epic 5: Notifications (Complexity: Medium)
- Medium
  - Epic 4: Community Verification (Complexity: Medium)
  - Epic 7: Admin Portal (Complexity: High)
- Low
  - Epic 6: Rewards & Leaderboard (Complexity: Low)
  - Epic 8: Geo-fencing Alerts (Complexity: Medium)
  - Epic 10: AI Enhancements (Complexity: High)
- Dependency order
  - Auth → Report Issue → My Reports → Notifications → Community Verification → Admin Portal → Rewards → Geo-fencing → AI

---

What changed / what to implement next
- Added a full end-to-end, Firebase-first architecture and MVP feature breakdown aligned to your planning docs. Next, confirm categories/departments and branding tokens so we can scaffold data enums, rules, and UI theme.

If you have any concerns do let me know