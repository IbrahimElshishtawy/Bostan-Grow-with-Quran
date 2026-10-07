# QURAN APP — MASTER ARCHITECTURE & IMPLEMENTATION PROMPT

## 0. ROLE

You are a Senior Flutter Software Architect, Mobile Engineer, Backend/API Integration Engineer, UX Engineer, Performance Engineer, and Security Engineer.

You are responsible for designing and implementing a production-ready Quran application using Flutter.

Do NOT treat this as a demo application.

The application must be:

* Production-ready
* Scalable
* Offline-first
* Responsive
* Adaptive
* Accessible
* Secure
* Testable
* Maintainable
* Modular
* Performance-oriented
* Suitable for real users
* Ready for Android and iOS
* Designed so additional platforms can be added later

Do not rush into building screens.

First establish the architecture and Core layer correctly.

---

# 1. PRODUCT VISION

Build a complete Quran companion application.

The application should combine:

1. Quran Mushaf
2. Quran reading
3. Audio recitation
4. Memorization
5. Revision
6. Search
7. Tafsir
8. Translation
9. Daily Quran goals
10. Khatmah plans
11. Reading progress
12. Bookmarks
13. Notes
14. Statistics
15. Notifications/reminders
16. Ramadan mode
17. Offline support
18. Firebase user account
19. Local persistence
20. Quran API integration
21. Optional Quran AI assistant architecture
22. Adaptive/responsive UI

The application must NOT be implemented as one large Flutter project with tightly coupled screens.

---

# 2. TECHNOLOGY STACK

Use Flutter and Dart.

Preferred stack:

### Flutter

* Flutter stable
* Dart stable
* Material 3
* Null safety
* Modern Flutter APIs

### State Management

Use:

* Riverpod
* flutter_riverpod
* Riverpod code generation if appropriate

Do NOT mix:

* Provider
* GetX
* Bloc
* Redux
* Riverpod

Use Riverpod as the primary state-management architecture.

---

# 3. LOCAL DATABASE

Use:

## Isar

Isar is the primary local database.

Use Isar for:

* Quran metadata
* Quran pages metadata
* verses
* bookmarks
* reading progress
* memorization progress
* memorization plans
* revision sessions
* downloaded audio metadata
* downloaded content metadata
* search cache
* tafsir cache
* translations cache
* user preferences
* app settings
* statistics
* daily goals
* khatmah progress
* last opened page
* last opened verse
* offline synchronization metadata

Do NOT use SharedPreferences as the main database.

SharedPreferences may only be used for very small primitive configuration values if genuinely necessary.

---

# 4. FIREBASE

Use Firebase for remote user/account functionality.

Firebase responsibilities:

## Firebase Authentication

Use for:

* anonymous authentication if required
* email/password if required
* Google Sign-In if enabled
* account linking
* session management
* user identity

Do not place business logic directly inside UI widgets.

Create:

```text
FirebaseAuthDataSource
AuthRepository
AuthUseCases
AuthProviders
```

---

# 5. FIREBASE USER DATA

Remote user-related data may include:

* user profile
* bookmarks synchronization
* reading progress synchronization
* memorization progress
* goals
* khatmah plans
* preferences
* notes
* statistics if synchronization is required
* device/session metadata where necessary

Use Firestore only for data that genuinely needs cloud synchronization.

Do NOT store large Quran datasets in Firestore.

Do NOT use Firestore as the primary Quran content database.

---

# 6. LOCAL-FIRST SYNCHRONIZATION

The application must work even without internet.

Architecture:

```text
UI
 ↓
Riverpod
 ↓
Use Cases
 ↓
Repository
 ↓
Local / Remote Data Sources
 ↓
Isar / Firebase / API
```

The Repository decides where data comes from.

Example:

```text
QuranRepository
    ↓
LocalQuranDataSource
RemoteQuranDataSource
```

Reading Quran pages should primarily use local data after initial synchronization.

---

# 7. QURAN API

Use Quran Foundation APIs for Quran-related remote content.

Possible content:

* Chapters
* Verses
* Mushaf pages
* Quran scripts
* Translations
* Tafsir
* Recitations
* Audio
* Search
* Juz
* Hizb
* Rub
* Manzil
* Page information

The application must use the API as the source of remote Quran content.

However:

## IMPORTANT SECURITY RULE

NEVER place Quran Foundation `client_secret` inside the Flutter application.

Flutter must NEVER contain:

```text
client_secret
private API credentials
server-only credentials
```

If the Quran Foundation API requires server credentials:

```text
Flutter
   ↓
Application Backend
   ↓
Quran Foundation API
```

The backend owns:

```text
QF_CLIENT_ID
QF_CLIENT_SECRET
```

Flutter only communicates with the application's API.

---

# 8. API ARCHITECTURE

Create an API abstraction.

Do not call Dio directly from screens.

Architecture:

```text
Presentation
     ↓
Provider
     ↓
UseCase
     ↓
Repository
     ↓
RemoteDataSource
     ↓
ApiClient
     ↓
Dio
```

Create:

```text
ApiClient
ApiRequest
ApiResponse
ApiException
ApiError
NetworkException
TimeoutException
UnauthorizedException
ServerException
ParsingException
```

---

# 9. DIO

Use Dio as the HTTP client.

Configure:

* Base URL
* Connect timeout
* Receive timeout
* Send timeout
* Headers
* Interceptors
* Logging only in development
* Retry policy
* Authentication headers
* Request ID
* Error normalization
* Cancellation
* Network connectivity checks

Never enable verbose API logging in production.

Never log:

* access tokens
* refresh tokens
* passwords
* Firebase credentials
* private user information

---

# 10. NETWORK LAYER

Create a reusable network architecture.

Example:

```text
core/
  network/
    api_client.dart
    dio_factory.dart
    interceptors/
      auth_interceptor.dart
      request_id_interceptor.dart
      logging_interceptor.dart
      retry_interceptor.dart
    network_info.dart
    network_exceptions.dart
    api_result.dart
```

Use typed results instead of random exceptions spreading throughout the application.

Example concept:

```text
Result<T>
 ├── Success<T>
 └── Failure
```

---

# 11. CORE ARCHITECTURE

Create a strong reusable Core layer.

Recommended:

```text
lib/
│
├── core/
│   │
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── helpers/
│   ├── localization/
│   ├── navigation/
│   ├── network/
│   ├── permissions/
│   ├── platform/
│   ├── responsive/
│   ├── routing/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   ├── validators/
│   ├── widgets/
│   └── result/
│
├── features/
│
└── main.dart
```

---

# 12. CORE CONFIGURATION

Create environment-aware configuration.

Support:

```text
development
staging
production
```

Never hardcode:

* API URLs
* API keys
* environment-specific configuration

Create:

```text
AppConfig
EnvironmentConfig
```

---

# 13. CORE CONSTANTS

Create centralized constants for:

* API configuration
* timeouts
* cache duration
* pagination
* supported breakpoints
* database version
* audio quality
* maximum cache size
* file locations
* notification channels
* application limits

Do not create random constants inside widgets.

---

# 14. CORE ERROR SYSTEM

Create a unified error system.

Example:

```text
AppException
 ├── NetworkException
 ├── TimeoutException
 ├── AuthenticationException
 ├── AuthorizationException
 ├── CacheException
 ├── DatabaseException
 ├── ParsingException
 ├── ValidationException
 ├── ServerException
 └── UnknownException
```

Convert technical errors into user-friendly messages at the presentation boundary.

Never display:

```text
DioException(...)
SocketException(...)
SQL exception...
Stack trace...
```

to the user.

---

# 15. CORE STORAGE

Create:

```text
LocalStorage
IsarService
SecureStorage
CacheManager
```

Use:

### Isar

For structured application data.

### Secure Storage

For:

* sensitive tokens
* secure session information
* encryption keys if required

Do NOT store sensitive credentials in normal preferences.

---

# 16. ISAR ARCHITECTURE

Create database collections/entities for:

```text
QuranChapter
QuranVerse
QuranPage
QuranWord
QuranTranslation
QuranTafsir
Reciter
AudioDownload
Bookmark
ReadingProgress
MemorizationPlan
MemorizationItem
RevisionSession
DailyGoal
KhatmahPlan
UserPreference
AppSetting
ReadingSession
StatisticsRecord
SyncMetadata
```

Do not blindly create all entities if a better normalized design exists.

Analyze relationships first.

Avoid:

* duplicate data
* giant documents
* unnecessary serialization
* unnecessary indexes

Create indexes based on actual access patterns.

---

# 17. QURAN DATA

Support:

### Mushaf

* QCF V2
* Uthmani
* other supported scripts when appropriate

The Mushaf renderer must NOT be manually drawn page by page.

Use official/appropriate Quran data and rendering assets.

Store metadata locally where practical.

The application must support page-level navigation.

Target the selected Mushaf layout correctly.

---

# 18. MUSHAF ENGINE

Create a dedicated:

```text
MushafEngine
```

Responsibilities:

* page loading
* page navigation
* verse-to-page mapping
* page-to-verse mapping
* current page
* current verse
* bookmarks
* highlighting
* reading position
* page prefetching
* offline loading
* caching

Do NOT put Mushaf logic inside `MushafPage`.

---

# 19. QURAN READER

Features:

* 604-page Mushaf where the selected edition uses that pagination
* page swipe
* page jump
* juz navigation
* hizb navigation
* surah navigation
* verse navigation
* bookmarks
* last-read position
* verse highlighting
* night mode
* reading mode
* font/display preferences where applicable

Use lazy loading and prefetching.

Never load the entire Quran UI tree into memory unnecessarily.

---

# 20. AUDIO SYSTEM

Create a dedicated audio module.

Use a suitable Flutter audio package.

Responsibilities:

* reciter selection
* play/pause
* seek
* speed
* repeat
* verse repeat
* range repeat
* background playback
* audio focus
* headphone events
* interruption handling
* notification controls
* download management
* offline playback

Architecture:

```text
AudioController
AudioPlayerService
AudioRepository
AudioCacheManager
AudioState
```

Do not manage audio directly from UI screens.

---

# 21. MEMORIZATION SYSTEM

Create a complete memorization module.

Features:

* create memorization plan
* choose surah
* choose verse range
* choose duration
* daily target
* revision schedule
* completed verses
* weak verses
* review sessions
* memorization statistics

Example:

```text
7 Day Plan

Day 1
1 → 5

Day 2
1 → 10

Day 3
6 → 15
```

The algorithm must be isolated from the UI.

Create:

```text
MemorizationPlanner
RevisionEngine
MemorizationScoring
```

---

# 22. MEMORIZATION TEST

Support:

* continue the verse
* previous verse
* next verse
* missing word
* random verse
* verse ordering
* audio recall

Do not make claims about religious correctness based solely on AI.

If speech recognition is later added, keep it as a replaceable service.

---

# 23. DAILY GOALS

Support:

* pages/day
* verses/day
* minutes/day
* audio/day
* memorization/day

Track:

```text
today
week
month
overall
```

---

# 24. KHATMAH SYSTEM

Support:

* 7-day Khatmah
* 15-day Khatmah
* 30-day Khatmah
* 60-day Khatmah
* custom Khatmah

Calculate:

```text
remaining pages
remaining days
required daily pages
completed percentage
```

Must work offline.

---

# 25. SEARCH

Create a dedicated search module.

Search Quran content.

Support:

* Arabic
* translations
* exact phrase
* partial phrase
* surah filter
* juz filter
* result navigation

Architecture:

```text
SearchRepository
SearchLocalDataSource
SearchRemoteDataSource
SearchEngine
SearchQuery
SearchResult
```

Cache repeated searches when appropriate.

---

# 26. TAFSIR

Support trusted Tafsir sources.

Tafsir must always be clearly separated from Quran text.

Architecture:

```text
TafsirRepository
TafsirSource
TafsirCache
```

Never generate Tafsir as if it were authenticated religious source material.

---

# 27. TRANSLATIONS

Support multiple translations.

Architecture must allow adding languages without changing the core reader.

Example:

```text
Arabic
English
French
...
```

Do not hardcode translation language logic into UI.

---

# 28. BOOKMARKS

Support:

* bookmark verse
* bookmark page
* bookmark collection
* bookmark title
* notes
* color/category if useful

Sync with Firebase when signed in.

Offline-first behavior:

```text
Local write
    ↓
UI updates immediately
    ↓
Sync queue
    ↓
Firebase
```

---

# 29. SYNC ENGINE

Create a proper synchronization system.

```text
SyncManager
SyncQueue
SyncOperation
SyncConflictResolver
SyncMetadata
```

Operations:

```text
CREATE
UPDATE
DELETE
```

Support:

* retry
* exponential backoff
* offline queue
* conflict handling
* idempotency
* last successful sync
* failed operation tracking

Never block reading Quran because synchronization failed.

---

# 30. FIREBASE SYNC RULE

The user should always be able to:

```text
Open app
Read Quran
Use offline features
```

even if:

* Firebase is unavailable
* API unavailable
* internet unavailable

Cloud synchronization is secondary to the local experience.

---

# 31. AUTHENTICATION STATES

Create explicit states:

```text
unknown
checking
anonymous
authenticated
signedOut
error
```

Do not make every screen independently check Firebase auth.

Use centralized auth state.

---

# 32. RIVERPOD ARCHITECTURE

Organize providers by feature.

Example:

```text
features/
  quran/
    presentation/
      providers/
        quran_providers.dart
        mushaf_providers.dart
        reading_progress_provider.dart
```

Avoid global provider files containing everything.

Provider responsibilities must be clear.

---

# 33. STATE TYPES

Separate:

### UI State

Examples:

```text
loading
loaded
empty
error
```

### Domain State

Examples:

```text
ReadingProgress
MemorizationProgress
AudioState
```

### Persistent State

Stored in:

```text
Isar
Firebase
```

Do not confuse these layers.

---

# 34. UI ARCHITECTURE

Use:

```text
Feature
 ├── data
 ├── domain
 └── presentation
```

Example:

```text
features/quran/
│
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── providers/
    ├── pages/
    ├── widgets/
    └── controllers/
```

---

# 35. RESPONSIVE DESIGN

The application MUST work on:

* small phones
* normal phones
* large phones
* foldables
* tablets
* large tablets
* desktop-sized windows where Flutter platform support is enabled

Do NOT write:

```dart
if (isPhone)
if (isTablet)
if (deviceType == ...)
```

Use available window size.

Use:

```text
MediaQuery.sizeOf
LayoutBuilder
SafeArea
```

and adaptive breakpoints.

Flutter's official guidance recommends making layout decisions based on available window size rather than hardware/device type.

---

# 36. BREAKPOINT SYSTEM

Create a centralized responsive system.

Example:

```text
Compact
< 600

Medium
600 - 839

Expanded
>= 840
```

Do not scatter these numbers throughout the application.

Create:

```text
AppBreakpoints
ResponsiveValue
ResponsiveLayout
AdaptiveNavigation
```

Adjust these thresholds after real-device testing.

---

# 37. NAVIGATION ADAPTATION

Compact:

```text
BottomNavigationBar / NavigationBar
```

Medium:

```text
NavigationRail where appropriate
```

Expanded:

```text
NavigationRail / NavigationDrawer / multi-column layout
```

The actual navigation should depend on available width, not device name.

---

# 38. LARGE SCREEN READER

On large screens:

```text
┌────────────┬───────────────────────┐
│ Navigation │                       │
│            │      Quran Page       │
│            │                       │
│            │                       │
└────────────┴───────────────────────┘
```

On small screens:

```text
┌─────────────────────┐
│                     │
│     Quran Page      │
│                     │
│                     │
├─────────────────────┤
│ Home Quran ...      │
└─────────────────────┘
```

Do not simply stretch phone UI to tablet.

---

# 39. SAFE AREA

All important content must respect:

* status bar
* navigation bar
* display cutouts
* rounded corners
* foldable hinges
* keyboard
* system UI

Use SafeArea and MediaQuery appropriately.

---

# 40. TYPOGRAPHY

Create a centralized typography system.

Support:

* Arabic
* English
* multiple font sizes
* accessibility text scaling

Never hardcode font sizes everywhere.

Create:

```text
AppTypography
ArabicTypography
QuranTypography
```

Quran text typography must be isolated from normal UI typography.

---

# 41. ACCESSIBILITY

Support:

* text scaling
* semantic labels
* screen readers
* high contrast
* touch target sizes
* reduced motion where appropriate
* readable Arabic typography
* accessibility-friendly colors

Do not make accessibility an afterthought.

---

# 42. THEME

Create:

```text
AppTheme
LightTheme
DarkTheme
ColorScheme
Typography
Spacing
Radius
Elevation
```

Do not scatter colors like:

```dart
Color(0xff...)
```

throughout widgets.

---

# 43. DESIGN LANGUAGE

Visual direction:

* premium
* calm
* spiritual
* modern
* minimal
* Islamic without excessive decoration
* excellent Arabic typography
* subtle emerald / deep green
* warm neutral background
* restrained gold accents
* strong hierarchy
* comfortable reading experience

Avoid:

* excessive gradients
* excessive glassmorphism
* huge decorative Islamic patterns
* visual clutter
* unnecessary animations

The Quran must remain the visual priority.

---

# 44. HOME DASHBOARD

Home should show:

```text
Greeting

Daily Quran Goal
Progress

Continue Reading

Current Surah
Current Ayah

Quick Actions

Mushaf
Audio
Memorization
Search

Memorization Review

Khatmah Progress

Daily Statistics
```

The home screen must be useful within 2–3 seconds of opening.

---

# 45. PERFORMANCE

Optimize:

* startup
* database reads
* database writes
* API calls
* image loading
* Quran page rendering
* audio loading
* scrolling
* animations
* memory
* rebuilds

Avoid:

```text
watching huge providers unnecessarily
```

Use selective provider watching.

Use:

```text
select
family
autoDispose
pagination
lazy loading
prefetching
```

where appropriate.

---

# 46. DATABASE PERFORMANCE

Never:

* query entire Quran unnecessarily
* repeatedly deserialize the same data
* write to Isar on every pixel movement
* save reading position continuously

For reading position:

Use a controlled persistence strategy.

Example:

```text
UI movement
    ↓
debounce
    ↓
save position
```

---

# 47. API PERFORMANCE

Implement:

* caching
* request deduplication
* pagination
* timeout
* retry
* cancellation
* conditional fetching
* stale-while-revalidate where useful

Do not make the same request repeatedly because a widget rebuilt.

---

# 48. OFFLINE CACHE

Create cache policies.

Example:

```text
Quran text
→ permanent/local

Metadata
→ long cache

Tafsir
→ persistent cache

Search
→ short cache

Audio
→ user-managed downloads
```

Cache policy must be explicit.

---

# 49. AUDIO STORAGE

Downloaded audio must not be stored inside Isar as large binary blobs.

Store:

```text
file path
download status
reciter
surah
quality
size
version
```

Store actual audio in the appropriate application file storage.

---

# 50. FILE MANAGEMENT

Create:

```text
AppFileManager
AudioFileManager
DownloadManager
```

Handle:

* file existence
* corrupted files
* partial downloads
* retry
* deletion
* storage cleanup
* free storage detection

---

# 51. PHONE STORAGE MANAGEMENT

Show users:

```text
Downloaded Audio
Used Storage
Available Storage
```

Allow:

```text
Delete download
Delete all audio
Clear cache
```

Never delete user-created data without explicit action.

---

# 52. NETWORK STATES

Support:

```text
Online
Offline
Poor Connection
Connecting
Server Error
```

Offline should be a normal application state, not an exception.

---

# 53. LOADING STATES

Every major feature must have:

* skeleton/loading
* empty
* success
* error
* offline

Do not leave screens blank while waiting.

---

# 54. ERROR UX

Use user-friendly messages.

Example:

```text
تعذر تحميل المحتوى الآن.
يمكنك المحاولة مرة أخرى أو متابعة المحتوى المحفوظ على جهازك.
```

Provide:

```text
Retry
Use Offline Data
```

when applicable.

---

# 55. SECURITY

Protect:

* Firebase sessions
* API credentials
* local sensitive data
* user notes
* user identity
* network traffic

Do not:

* hardcode secrets
* log tokens
* expose backend secrets
* trust remote input blindly

Validate all remote data before storing it.

---

# 56. DATA VALIDATION

All external data must be validated.

For every API model:

```text
JSON
 ↓
DTO
 ↓
Validation
 ↓
Domain Entity
 ↓
Repository
```

Do not pass raw JSON through the application.

---

# 57. DTO / MODEL SEPARATION

Separate:

```text
RemoteModel
LocalModel
DomainEntity
```

when their responsibilities differ.

Do not automatically use one model for every layer.

---

# 58. DOMAIN LAYER

Business logic must live in use cases/services.

Examples:

```text
GetCurrentReadingPosition
SaveReadingPosition
GetMushafPage
CreateKhatmah
CalculateDailyTarget
RecordReadingSession
GetMemorizationPlan
RecordRevision
SearchQuran
GetTafsir
DownloadAudio
SyncUserData
```

Widgets must NOT contain these rules.

---

# 59. NAVIGATION

Use centralized routing.

Support:

```text
Home
Mushaf
Reader
Search
Audio
Memorization
Khatmah
Bookmarks
Tafsir
Settings
Statistics
Profile
```

Deep links should be considered from the beginning.

Example:

```text
/quran/2/255
/quran/page/42
/surah/2
```

---

# 60. DEEP LINKING

If the user opens a Quran link:

```text
surah + ayah
```

the application should navigate directly to the relevant content.

Do not implement deep linking as a last-minute feature.

---

# 61. NOTIFICATIONS

Architecture should support:

* daily Quran reminder
* memorization reminder
* revision reminder
* Khatmah reminder

Notifications must be configurable.

Do not spam users.

---

# 62. STATISTICS

Track:

```text
pages read
verses read
reading sessions
reading minutes
audio minutes
memorized verses
revision sessions
Khatmah progress
daily streak
```

Statistics must be useful, not addictive.

---

# 63. PRIVACY

User data should be minimized.

Do not collect unnecessary personal information.

The application must work without requiring unnecessary registration.

Anonymous usage should be supported where possible.

---

# 64. FIREBASE ANALYTICS

If analytics is enabled:

Track only meaningful product events.

Examples:

```text
quran_opened
verse_opened
audio_started
memorization_started
khatmah_created
search_used
bookmark_created
```

Never send Quran content or private notes as analytics parameters.

---

# 65. AI ASSISTANT

Design the architecture so an AI assistant can be added later.

DO NOT let an LLM directly invent Quranic facts or Tafsir.

Architecture:

```text
User
 ↓
AI Assistant
 ↓
Retrieval Layer
 ↓
Verified Quran/Tafsir Sources
 ↓
LLM
 ↓
Source-aware Response
```

AI must clearly distinguish:

```text
Quran text
Tafsir
Translation
AI-generated explanation
```

Never present AI-generated content as Quran or authenticated Tafsir.

---

# 66. FEATURE MODULES

Recommended:

```text
features/
│
├── auth/
├── home/
├── quran/
├── mushaf/
├── reader/
├── audio/
├── memorization/
├── revision/
├── search/
├── tafsir/
├── translations/
├── bookmarks/
├── khatmah/
├── goals/
├── statistics/
├── notifications/
├── profile/
├── settings/
└── ai_assistant/
```

Do not create meaningless folders.

Each feature must own its:

```text
data
domain
presentation
```

---

# 67. CORE WIDGETS

Create reusable UI primitives:

```text
AppScaffold
AppCard
AppButton
AppIconButton
AppTextField
AppLoading
AppError
AppEmpty
AppBottomSheet
AppDialog
ResponsiveLayout
AdaptiveNavigation
```

Do not create 20 versions of the same button.

---

# 68. DESIGN SYSTEM

Create reusable:

```text
Spacing
Radius
Elevation
Colors
Typography
Icons
Animation durations
Breakpoints
```

Everything should come from the design system.

---

# 69. TESTING

Testing is mandatory.

Create:

## Unit tests

For:

* Khatmah calculations
* memorization algorithms
* revision scheduling
* search logic
* parsing
* validators
* sync logic
* cache logic

## Repository tests

Test:

* local
* remote
* fallback
* offline

## Widget tests

Test:

* home
* reader
* navigation
* responsive layouts
* error states

## Integration tests

Test:

```text
login
read Quran
bookmark
offline
audio
memorization
sync
logout
```

---

# 70. RESPONSIVE TESTING

Test at minimum:

```text
Small phone
Medium phone
Large phone
Tablet portrait
Tablet landscape
Foldable-like width
Desktop-sized window
```

Do not assume one emulator represents all devices.

---

# 71. PERFORMANCE TESTING

Measure:

* startup time
* frame rendering
* memory usage
* Isar query performance
* API latency
* audio startup
* page switching
* scrolling
* rebuild counts

Avoid premature optimization but measure real bottlenecks.

---

# 72. CODE QUALITY

Follow:

* SOLID
* DRY
* KISS
* separation of concerns
* dependency inversion
* composition over inheritance

Avoid:

* god classes
* god providers
* giant widgets
* giant repositories
* giant service classes
* circular dependencies
* duplicated business logic

---

# 73. DEPENDENCY RULES

Architecture direction:

```text
presentation
    ↓
domain
    ↓
data
```

Never:

```text
domain → Flutter UI
domain → Firebase
domain → Dio
domain → Isar
```

Domain must remain as independent as practical.

---

# 74. DEPENDENCY INJECTION

Use Riverpod for dependency injection.

Examples:

```text
apiClientProvider
isarProvider
firebaseAuthProvider
quranRepositoryProvider
audioServiceProvider
syncManagerProvider
```

Do not instantiate infrastructure manually inside widgets.

---

# 75. STARTUP FLOW

Application startup:

```text
main()
 ↓
Flutter binding
 ↓
Environment configuration
 ↓
Firebase initialization
 ↓
Isar initialization
 ↓
Dependency registration
 ↓
Local migration check
 ↓
Auth state initialization
 ↓
Initial synchronization if necessary
 ↓
runApp()
```

Do not block the entire application on non-essential network operations.

---

# 76. DATABASE MIGRATIONS

Database schema changes must be planned.

Never casually delete local data when the schema changes.

Create a migration strategy.

Test migrations.

---

# 77. API VERSIONING

Do not tightly couple the application to undocumented API behavior.

Create API adapters.

If API version changes:

```text
Remote API
 ↓
Adapter
 ↓
Domain
```

The rest of the application should remain stable.

---

# 78. DOCUMENTATION

Create:

```text
README.md
ARCHITECTURE.md
DATA_ARCHITECTURE.md
API_ARCHITECTURE.md
OFFLINE_FIRST.md
SYNC_ARCHITECTURE.md
RESPONSIVE_DESIGN.md
SECURITY.md
TESTING.md
```

Document major architectural decisions.

---

# 79. IMPLEMENTATION ORDER

DO NOT implement everything at once.

Use this order:

## PHASE 0 — ANALYSIS

Inspect the project.

Determine:

* current Flutter version
* current dependencies
* current architecture
* current files
* current problems

Do not overwrite working code blindly.

---

## PHASE 1 — CORE

Build:

```text
config
errors
result
network
storage
theme
responsive
routing
utilities
```

Make Core stable before features.

---

## PHASE 2 — DATABASE

Implement:

```text
Isar
entities
repositories
migrations
local data sources
```

Test database operations.

---

## PHASE 3 — FIREBASE

Implement:

```text
Firebase initialization
Auth
user repository
Firestore synchronization abstraction
```

---

## PHASE 4 — API

Implement:

```text
Dio
API client
Quran API adapter
DTOs
remote data sources
repositories
```

Keep secrets outside Flutter.

---

## PHASE 5 — QURAN ENGINE

Implement:

```text
Mushaf
pages
verses
page mapping
reading position
offline loading
```

---

## PHASE 6 — AUDIO

Implement:

```text
player
reciters
downloads
background audio
repeat
offline audio
```

---

## PHASE 7 — USER FEATURES

Implement:

```text
bookmarks
notes
goals
Khatmah
statistics
```

---

## PHASE 8 — MEMORIZATION

Implement:

```text
plans
revision
testing
progress
```

---

## PHASE 9 — SEARCH / TAFSIR / TRANSLATION

Implement:

```text
search
translations
Tafsir
```

---

## PHASE 10 — HOME

Build the production dashboard using the actual domain data.

Do NOT build a fake static dashboard first.

---

## PHASE 11 — RESPONSIVE UI

Test and adapt:

```text
compact
medium
expanded
```

---

## PHASE 12 — OFFLINE / SYNC

Implement:

```text
offline queue
sync
conflict handling
retry
```

---

## PHASE 13 — SECURITY / PRIVACY

Audit:

* credentials
* logs
* Firebase rules
* API access
* local data
* permissions
* analytics
* privacy

---

## PHASE 14 — TESTING

Run:

```text
flutter analyze
flutter test
integration tests
```

Fix all important issues.

---

## PHASE 15 — PRODUCTION HARDENING

Check:

* release build
* performance
* startup
* memory
* crashes
* offline behavior
* API failures
* database migrations
* Firebase rules
* accessibility
* responsive layouts

---

# 80. VERY IMPORTANT AI AGENT RULES

When implementing this project:

1. Do not blindly create files.
2. Inspect existing architecture first.
3. Do not delete working functionality without justification.
4. Do not duplicate existing services.
5. Do not create duplicate models.
6. Do not put business logic in widgets.
7. Do not call APIs directly from UI.
8. Do not call Firebase directly from every screen.
9. Do not access Isar directly from UI.
10. Do not expose API secrets.
11. Do not create unnecessary packages.
12. Do not add a package unless there is a clear reason.
13. Do not use multiple state-management solutions.
14. Do not use SharedPreferences as the database.
15. Do not store large audio files in Isar.
16. Do not store the entire Quran remotely in Firestore.
17. Do not depend on internet for basic Quran reading.
18. Do not hardcode responsive layouts for individual devices.
19. Do not lock the app to one device size.
20. Do not sacrifice readability for decoration.
21. Do not generate fake Quran text.
22. Do not generate fake Tafsir.
23. Do not represent AI-generated content as religious source material.
24. Do not hide errors.
25. Do not silently swallow exceptions.
26. Do not perform expensive work in build().
27. Do not introduce unnecessary rebuilds.
28. Do not load unnecessary data.
29. Do not create giant providers.
30. Do not create giant repositories.
31. Keep every layer independently testable.

---

# 81. BEFORE CODING

First produce:

1. Current project analysis
2. Proposed architecture
3. Folder structure
4. Dependency list
5. Isar schema
6. Firebase architecture
7. API architecture
8. Sync architecture
9. Responsive strategy
10. Feature dependency graph
11. Implementation phases
12. Risks
13. Required packages
14. Security considerations

DO NOT start implementation until the architecture is internally consistent.

---

# 82. AFTER EACH PHASE

Report:

```text
PHASE:
STATUS:

Implemented:
- ...

Files added:
- ...

Files modified:
- ...

Architecture decisions:
- ...

Tests:
- ...

Issues:
- ...

Next phase:
- ...
```

Do not claim completion without actually verifying the implementation.

---

# 83. DEFINITION OF DONE

A feature is NOT complete merely because its UI exists.

A feature is complete only when:

```text
UI
+
State
+
Domain logic
+
Repository
+
Local storage
+
Remote integration
+
Error handling
+
Offline behavior
+
Loading state
+
Empty state
+
Testing
+
Responsive behavior
```

are correctly handled where applicable.

---

# 84. FINAL QUALITY BAR

The final application should feel like:

```text
A serious Quran product
```

not:

```text
A Flutter tutorial project
```

The architecture should make it possible to add future features without rewriting the existing application.

Prioritize:

1. Quran correctness
2. Reliability
3. Reading experience
4. Offline availability
5. Performance
6. Security
7. Accessibility
8. Maintainability
9. Scalability
10. Visual quality

Do not prioritize feature count over quality.

END OF MASTER PROMPT
