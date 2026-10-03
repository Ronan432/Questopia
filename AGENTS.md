# AGENTS.md — Questopia-RE Master Architectural Specification & Guidelines

This document is the authoritative developer manual and technical specification for AI coding agents (Gemini, Claude, GPT, etc.) and human contributors working on the **Questopia-RE** project.

---

## 1. Project Overview & Technology Stack

**Questopia-RE** is a modern, high-performance, cross-platform interpreter and management suite for QSP (Quest Soft Player) interactive fiction games.

- **Android Client (`:app`)**:
  - **Framework**: Kotlin & Java 21, AndroidX Jetpack Compose (Material 3 Expressive).
  - **Native Engine**: C-based QSP 5.8.0 core compiled via Android NDK/CMake alongside a high-performance Rust companion library (`questopia_rust`).
  - **Image Pipeline**: Coil 2.x with aggressive memory/disk caching and custom URI resolvers.
  - **Network / Storage**: Ktor Client (remote repository sync), Anggrayudi SimpleStorage / DocumentFileCompat (SAF).
- **Desktop Client (`:desktop`)**:
  - **Framework**: Kotlin Compose Multiplatform for Desktop (Windows x64).
  - **Native Bridge**: Direct JNI bindings to `qsp.dll` and `questopia_rust.dll`.
- **Rust Native Acceleration (`:native-rust`)**:
  - High-throughput ZIP/QSP archive extraction with Zip Slip immunity and encoding detection.
  - Hardware-accelerated 32-bit floating-point audio mixing.
  - SIMD-accelerated HTML/BBCode tag stripping and sanitizer.

---

## 2. Complete Repository Directory & Filemap

```
Questopia/
├── .github/                              # GitHub Actions CI/CD workflows (CI build, testing)
├── gradle/
│   ├── wrapper/                          # Gradle wrapper binaries & properties
│   └── libs.versions.toml                # Centralized Gradle version catalog
├── app/                                  # Android Application Module
│   ├── build.gradle                      # Module build config (Java 21, NDK CMake toolchain)
│   ├── proguard-rules.pro                # ProGuard / R8 optimization and keep rules
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml       # App declarations, permissions, file providers
│       │   ├── cpp/                      # QSP 5.8.0 C core source & JNI wrapper
│       │   ├── java/                     # Android Kotlin / Java source packages
│       │   │   ├── com/libqsp/jni/       # QSPLib JNI native interface declarations
│       │   │   └── org/qp/android/
│       │   │       ├── QuestopiaApplication.java  # Application singleton & dependency initialization
│       │   │       ├── dto/stock/                 # Game metadata & remote list DTOs
│       │   │       ├── helpers/                   # Utility classes, Coil helper, Rust bridge
│       │   │       │   ├── native_core/           # RustEngineCore.kt JNI runtime bridge
│       │   │       │   └── utils/                 # Path, File, Stream, Color, Locale, Base64 utils
│       │   │       ├── model/                     # Business logic, services & repository layer
│       │   │       │   ├── archive/               # Multi-encoding ZIP extractor (ArchiveUnpack.kt)
│       │   │       │   ├── lib/                   # QSP engine state, proxy contracts & LibProxyImpl
│       │   │       │   ├── repository/            # LocalGame & RemoteGameRepository (Ktor)
│       │   │       │   └── service/               # AudioPlayer, HtmlProcessor, ImageProvider
│       │   │       └── ui/                        # UI Presentation Layer (Jetpack Compose)
│       │   │           ├── common/                # Shared Morphing UI & CustomDrawerHandle
│       │   │           ├── dialogs/               # GameDialogType enum contracts
│       │   │           ├── game/                  # In-game screens, dialogs, sheets & webview
│       │   │           ├── settings/              # Settings screens & segmented preference components
│       │   │           ├── stock/                 # Library & store screens, cards & navigation
│       │   │           └── theme/                 # QuestopiaTheme, AMOLED & ColorSchemes
│       │   └── res/                      # Android resources (drawables, layouts, strings, themes)
│       └── test/                         # Unit and integration test suites
├── desktop/                              # Desktop Application Module (Compose Multiplatform)
│   ├── build.gradle.kts                  # Desktop build script
│   └── src/main/
│       ├── java/                         # Desktop JNI bridge
│       ├── kotlin/org/qp/desktop/        # Desktop Compose UI, screen coordinators, engine bindings
│       └── resources/                    # Bundled Windows x64 DLLs and graphical assets
├── native-rust/                          # Rust Companion Native Library
│   ├── Cargo.toml                        # Rust dependencies (jni, zip, flate2, serde, memmap2)
│   └── src/                              # Rust source files (archive, audio, html, xml, lib)
├── build.py                              # Python orchestrator for fast build & multi-channel Wireless ADB
├── build.gradle                          # Root Gradle build script
├── settings.gradle                       # Root settings script
├── gradle.properties                     # JVM options & AndroidX build parameters
├── AGENTS.md                             # AI Agent Architecture & Guidelines (this file)
└── README.md                             # Project overview
```

---

## 3. Modular File Architecture & Responsibilities

### Android In-Game UI Subsystem (`org.qp.android.ui.game`)
To maintain high context efficiency and prevent giant monolithic files, in-game responsibilities are partitioned into dedicated, single-responsibility files:

| File | Primary Responsibility |
| :--- | :--- |
| **`GameActivity.kt`** | Activity lifecycle, Intent parsing, ViewModel attachment, Android back button handling, and top-level `GameMainCompose` Scaffold. (~380 lines) |
| **`GameModels.kt`** | Immutable UI state models: `InputDialogData`, `MessageDialogData`, `MenuDialogData`, `ErrorDialogData`, and `SlotInfo`. |
| **`GameDialogs.kt`** | `GameDialogsHost` hosting all 8 standard QSP engine dialogs (User Input, Executor, Message, Selection Menu, Enhanced Error Diagnostics, Fullscreen Image Preview, Close Confirmation, External File Load). |
| **`InGameOptionsMenuSheet.kt`** | The 3-dot bottom options drawer (`InGameOptionsMenuSheet`), segmented expressive menu groups, and restart confirmation dialog. |
| **`SaveSlotsSheet.kt`** | In-game save and load drawer with 60 manual slots across 10 pages, dedicated standalone Auto-save card, and external file selector triggers. |
| **`CheatModesSheet.kt`** | **QSPSaveEditor & Cheat Modes**: Zero-latency variable manipulation, freeze monitor, teleportation picker, item inventory modifier, and cheat console. |
| **`GameMediaHelpers.kt`** | Image clipboard copier, MediaStore gallery saver, Yandex Reverse Image Search JSON multipart uploader, and `PosterContextMenuSheet`. |
| **`GameWebViewComponents.kt`** | `GameHtmlWebView` (zoom-persisting, custom JavaScript bridge, hit-test long-click listener) and `GameListItemCard` (morphing surface, responsive 1/2 column grid support). |
| **`GameViewModel.java`** | Core ViewModel managing the game loop, QSP JNI callbacks, audio synchronization, background dispatching, and LiveData state observers. |

---

## 4. Core Architectural Principles & Strict Rules

### 1. State Hoisting Rule for Dialogs & Bottom Sheets
- **Rule**: Never declare a sub-sheet state (`showSlotsSheetMode`, `showCheatModesSheet`, `showRestartDialog`) inside a composable that dismisses itself before the target sub-sheet renders.
- **Implementation**: Hoist all modal sub-sheet states to the parent coordinator (`GameMainCompose`). Pass clean callback lambdas (`onSaveClick`, `onLoadClick`, `onCheatsClick`, `onRestartClick`) to `InGameOptionsMenuSheet`.

### 2. Design System & Anti-Slop Guidelines
- **Strict Zero Emoji Policy**: Never use emojis anywhere in the UI (titles, labels, buttons, subtitles, dialogs, error messages, or logs).
- **Segmented-List Morph Shaping**:
  - Always use `MorphingSurface` with `getGroupedItemShape(index, total)` for grouped list items.
  - Buttons must use `MorphingButton` or `MorphingOutlinedButton` with spring tactile haptic feedback.
- **Custom Drawer Handles**: Every `ModalBottomSheet` must use `dragHandle = { CustomDrawerHandle() }`.
- **Theme Consistency**:
  - Pure Black AMOLED (`#000000`) for high-contrast OLED panels.
  - Pure Neutral Monochrome (zero blue tint) in dark mode.
- **No Redundant Subtitles**: Never duplicate the title text as a placeholder subtitle in menu items.

### 3. Responsive Action Button Layout (1-Col vs 2-Col)
- For in-game action buttons in `GameMainCompose`:
  ```kotlin
  val columnCount = if (actionsList.size == 1) 1 else 2
  LazyVerticalGrid(
      columns = GridCells.Fixed(columnCount),
      horizontalArrangement = Arrangement.spacedBy(8.dp),
      verticalArrangement = Arrangement.spacedBy(8.dp)
  ) {
      gridItemsIndexed(actionsList) { index, item ->
          GameListItemCard(item = item, shape = RoundedCornerShape(16.dp), onClick = { ... })
      }
  }
  ```
  - When 1 action exists: full-width card.
  - When 2+ actions exist: clean 2-column balanced grid.

---

## 5. QSP Engine Interoperability & Multi-Line `exec:` Handling

### Multi-Line `exec:` Command Bridge
QSP games frequently embed complex multi-line code inside HTML links:
```html
<a href="exec:
  min=1
  goto 'location'
">Action</a>
```
- **HtmlProcessor Rule**: `HtmlProcessor.java` processes `EXEC_PATTERN` using `Pattern.DOTALL`. Multi-line `exec:` payloads are Base64 encoded (`base64:...`) before reaching the WebView.
- **GameViewModel Rule**: When `shouldOverrideUrlLoading` intercepts an `exec:` URI:
  1. If prefixed with `base64:`, decode bytes to UTF-8.
  2. If encoded as standard URI, URL-decode and replace any `<br>`, `<br/>`, or `<p>` tags with literal `\n`.
  3. Execute clean multi-line statements into `QSPLib.execString(...)`.

### WebView Zoom & Scroll Stability
To prevent WebView flickering or resetting zoom levels upon LiveData updates:
- Set `webView.tag = htmlContent`.
- In `update` block, check `if (webView.tag != htmlContent)` before invoking `loadDataWithBaseURL`.
- Enable `settings.setSupportZoom(true)` and `settings.builtInZoomControls = true` while keeping `settings.displayZoomControls = false`.

### Yandex Reverse Image Search JSON Endpoint
When performing visual search for local game images:
- **Endpoint**: `https://yandex.com/images/search?rpt=imageview&format=json&request=%7B%22blocks%22%3A%5B%7B%22block%22%3A%22b-page_type_search-by-image__link%22%7D%5D%7D`
- **Method**: HTTP POST with `multipart/form-data` containing image bytes under field `upfile` with `image/jpeg` content type.
- **Parsing**: Parse JSON response `blocks[0].params.url` and launch browser intent directly to `https://yandex.com/images/search?<params>`.

---

## 6. Localization Discipline

All user-facing text must be declared in strings XML files:
- **English**: `app/src/main/res/values/strings.xml`
- **Russian**: `app/src/main/res/values-ru/strings.xml`

Never hardcode string literals inside Composable functions or Activities.

---

## 7. Build, Verification & Deployment

- **Android Full Build & Wireless ADB Installation**:
  ```bash
  python build.py android
  ```
- **Desktop Client Run**:
  ```bash
  .\gradlew.bat :desktop:run
  ```
- **Verification Workflow**:
  1. Apply code changes.
  2. Run `python build.py android`.
  3. Verify clean exit code 0 and successful device streaming install.
