# Questopia-RE - Comprehensive Engineering & Architecture Specification

Welcome to the definitive architecture, design system, and technical handbook for **Questopia-RE**, a modern, high-performance, multiplatform Interactive Fiction and QSP Text Quest engine designed for **Android** (`com.questopia.re`) and **Windows Desktop (x64)**.

---

## 1. Executive System Overview

Questopia-RE modernizes the classic Quest Soft Player (QSP) ecosystem by providing an expressive, hardware-accelerated, and secure runtime built on contemporary multiplatform technologies.

### Key Technical Specifications
- **Core Languages**: Kotlin 2.0.21, Java 21, Modern C/C++ (C11/C++17), High-Performance Rust (2021 Edition)
- **UI Framework**: Compose Multiplatform & Jetpack Compose (Material 3 Expressive Design System)
- **Graphics & Rendering Pipeline**:
  - **Vulkan Hardware Acceleration**: Default graphics pipeline via Skiko / Android Vulkan backend (`VK_KHR_surface`, hardware texture streaming).
  - **Skia / Skiko Vector Engine**: Smooth 60/120 FPS animations, subpixel text rasterization, dynamic blur shaders.
- **Native Runtime**:
  - **Android**: Custom-compiled NDK `libqsp.so` with CMake + `libquestopia_rust.so` via Cargo JNI exports.
  - **Windows Desktop**: MSVC-compiled 64-bit `qsp.dll` + `questopia_rust.dll`.
- **Networking**: `io.ktor:ktor-client-core` with OkHttp engine (Asynchronous HTTP/XML repository parser).
- **Persistence & State**: Multiplatform Settings, Kotlinx Serialization, Java NIO / Android Storage Access Framework (SAF).
- **Image Pipeline**: Coil 2.7.0 with Coroutine-backed memory/disk caching and adaptive icon support.

---

## 2. Comprehensive Directory & File Map

```
Questopia/
├── app/                                                 # Android Application Module
│   ├── build.gradle                                     # Android build config, NDK CMake bindings & dependencies
│   ├── proguard-rules.pro                               # R8/ProGuard obfuscation & keep rules (JNI, Compose, Models)
│   ├── src/main/
│   │   ├── AndroidManifest.xml                          # Manifest (Activities, SAF/Storage permissions, Intent filters)
│   │   ├── cpp/                                         # Native QSP C/C++ Engine
│   │   │   ├── CMakeLists.txt                           # CMake configuration for libqsp.so
│   │   │   ├── bindings/                                # JNI bindings connecting Java/Kotlin to QSP C core
│   │   │   │   ├── android_callbacks.c
│   │   │   │   └── qsp_wrapper.cpp
│   │   │   └── qsp/                                     # Upstream QSP core library (C11 interpreter engine)
│   │   ├── java/org/qp/android/
│   │   │   ├── QuestopiaApplication.java                # Application entry point, crash handler & global initializers
│   │   │   ├── dto/stock/                               # Data Transfer Objects
│   │   │   │   ├── GameData.java                        # Primary unified game model (local & remote attributes)
│   │   │   │   ├── RemoteDataList.java                  # XML root container for repository stock parsing
│   │   │   │   └── RemoteGameData.java                  # Remote repository game item schema
│   │   │   ├── helpers/                                 # Utilities, helpers, and low-level bridges
│   │   │   │   ├── CoilHelper.java                      # Custom Coil ImageLoader setup & caching strategy
│   │   │   │   ├── ErrorType.java                       # Categorized runtime error enumerations
│   │   │   │   ├── native_core/
│   │   │   │   │   └── RustEngineCore.kt                # High-performance Rust JNI bridge with Kotlin fallback
│   │   │   │   └── utils/                               # Helper utility singletons
│   │   │   │       ├── Base64Util.java                  # Fast Base64 encoding/decoding
│   │   │   │       ├── ColorUtil.java                   # Hex/RGB color parsing & conversions
│   │   │   │       ├── DirUtil.java                     # Recursive directory size calculation & tree traversal
│   │   │   │       ├── FileUtil.java                    # SAF DocumentFile & Java File operations, MIME detection
│   │   │   │       ├── JsonUtil.kt                      # Kotlinx/JSON serialization & .gameInfo helpers
│   │   │   │       ├── LocaleHelper.kt                  # Runtime multi-language switching (EN, TR, RU)
│   │   │   │       ├── PathUtil.java                    # Relative & absolute path sanitization
│   │   │   │       ├── StreamUtil.java                  # Byte stream piping & buffered I/O
│   │   │   │       ├── StringUtil.java                  # String trimming, sanitization & encoding helpers
│   │   │   │       ├── ThreadUtil.java                  # Main thread & worker thread dispatchers
│   │   │   │       ├── ViewUtil.java                    # View hierarchy & keyboard management
│   │   │   │       └── XmlUtil.kt                       # Fast streaming XmlPullParser for remote game repositories
│   │   │   ├── model/                                   # Domain logic, background services & repositories
│   │   │   │   ├── archive/
│   │   │   │   │   └── ArchiveUnpack.kt                 # Zip/RAR game archive extraction with progress callback
│   │   │   │   ├── lib/                                 # QSP Engine native interface & proxy
│   │   │   │   │   ├── LibGameState.java                # Game state snapshots & execution flags
│   │   │   │   │   ├── LibIConfig.java                  # Native engine configuration contract
│   │   │   │   │   ├── LibIProxy.java                   # JNI callback proxy interface (UI <-> Engine)
│   │   │   │   │   ├── LibProxyImpl.java                # Implementation of QSP lifecycle and command dispatch
│   │   │   │   │   ├── LibRefIRequest.java              # Request tokens & command hooks
│   │   │   │   │   └── LibWindowType.java               # QSP window target enumerations (Main, Vars, Acts, Inv)
│   │   │   │   ├── notify/
│   │   │   │   │   └── NotifyBuilder.java               # Android system notifications for downloads/unpacking
│   │   │   │   ├── repository/
│   │   │   │   │   ├── LocalGame.java                   # Local game disk scanner, .gameInfo reader & metadata writer
│   │   │   │   │   └── RemoteGameRepository.kt          # Asynchronous Ktor HTTP client for remote XML catalogs
│   │   │   │   └── service/                             # Runtime background services
│   │   │   │       ├── AudioPlayer.java                 # Multi-channel sound and music player (MediaPlayer/SoundPool)
│   │   │   │       ├── HtmlProcessor.java               # BBCode/HTML parser, image tag transformer & text sanitizer
│   │   │   │       └── ImageProvider.java               # Game directory image asset resolver & caching provider
│   │   │   └── ui/                                      # User Interface Layer (Jetpack Compose & Material 3)
│   │   │       ├── common/                              # Reusable Compose components
│   │   │       │   ├── ExpressiveSearchBar.kt           # M3 Expressive expandable search bar with clear & cancel
│   │   │       │   └── MorphingUi.kt                    # Centralized spring-animated MorphingSurface, buttons, handles
│   │   │       ├── dialogs/
│   │   │       │   └── GameDialogType.java              # In-game modal dialog category enums
│   │   │       ├── game/                                # Active Game Interface & Overlay Screens
│   │   │       │   ├── CheatModesSheet.kt               # QSPSaveEditor & 0ms optimistic variable cheat controller
│   │   │       │   ├── GameActivity.kt                  # Main game host activity, WebView container & dialog manager
│   │   │       │   ├── GameInterface.java               # JavaScript interface bridge for WebView text interaction
│   │   │       │   ├── GameLibRequest.java              # Async game action request commands
│   │   │       │   └── GameViewModel.java               # Game session state, audio observer & native lib dispatcher
│   │   │       ├── settings/                            # App Settings & Preferences
│   │   │       │   ├── SettingsActivity.kt              # Settings host activity with edge-to-edge support
│   │   │       │   ├── SettingsComponents.kt            # Equal-height (56dp) expressive cards, switches & dialogs
│   │   │       │   ├── SettingsController.java          # SharedPreferences persistence & default values
│   │   │       │   └── SettingsMainScreen.kt            # Settings screen layout (Appearance, Audio, Engine, About)
│   │   │       ├── stock/                               # Game Catalog & Browser
│   │   │       │   ├── GameComponents.kt                # 2-column grid cards, morphing play/install buttons, sheets
│   │   │       │   ├── StockActivity.kt                 # Main launcher activity, SAF picker & intent receiver
│   │   │       │   ├── StockNavigation.kt               # 54dp compact expressive navigation bar without text clutter
│   │   │       │   ├── StockScreens.kt                  # Main horizontal pager (Home, Repository, Settings)
│   │   │       │   └── StockViewModel.java              # Game catalog synchronization, folder size calc & downloads
│   │   │       └── theme/
│   │   │           └── Theme.kt                         # Material 3 dynamic color, Monochrome & pure AMOLED schemes
│   │   └── res/                                         # Android Resources (drawables, mipmaps, strings, XMLs)
│   │       ├── values/strings.xml                       # Base English strings
│   │       ├── values-ru/strings.xml                    # Russian localization
│   │       └── values-tr/strings.xml                    # Turkish localization
│   └── test/ / androidTest/                             # Unit tests & Instrumentation tests
├── desktop/                                             # Windows Desktop Application Module
│   ├── build.gradle.kts                                 # Compose Desktop build configuration
│   └── src/main/
│       ├── java/com/libqsp/jni/
│       │   └── QSPLib.java                              # Desktop JNI bridge loading qsp.dll
│       ├── kotlin/org/qp/desktop/
│       │   ├── Main.kt                                  # Desktop application window entry & navigation state
│       │   ├── engine/
│       │   │   ├── DesktopQspEngine.kt                  # Desktop QSP execution thread & state machine
│       │   │   └── RustEngineCore.kt                    # Desktop Rust core wrapper loading questopia_rust.dll
│       │   ├── model/
│       │   │   └── GameModel.kt                         # Desktop game & settings data classes
│       │   ├── theme/
│       │   │   └── DesktopTheme.kt                      # Desktop Material 3 Expressive theme palettes
│       │   └── ui/
│       │       ├── DesktopNavigationRail.kt             # Side navigation rail for desktop layout
│       │       ├── GamePlayScreen.kt                    # Split-pane interactive fiction reading interface
│       │       ├── LibraryScreen.kt                     # Local installed quest catalog grid
│       │       ├── SettingsScreen.kt                    # Desktop preferences & keybinding configuration
│       │       ├── StockScreen.kt                       # Remote quest browser & downloader
│       │       └── common/
│       │           ├── AppLogo.kt                       # Questopia vector logo rendering
│       │           └── MorphingUi.kt                    # Desktop spring morphing surfaces and cards
│       └── resources/                                   # Bundled DLLs & Assets
│           ├── app_logo.png                             # Questopia application icon
│           └── win32-x86-64/
│               ├── qsp.dll                              # 64-bit QSP native library
│               └── questopia_rust.dll                   # 64-bit Rust acceleration library
├── native-rust/                                         # High-Performance Rust Native Core
│   ├── Cargo.toml                                       # Rust crate manifest (jni, zip, flate2, serde, cpal)
│   └── src/
│       ├── lib.rs                                       # JNI C-ABI export functions for Android & Desktop
│       ├── archive.rs                                   # Memory-mapped Zip/QSP zero-copy archive extractor
│       ├── audio_mixer.rs                               # 32-bit float stereo software audio mixer with tanh limiter
│       └── html_parser.rs                               # Zero-allocation HTML/BBCode span tokenizer & text cleaner
├── libs/native/windows-x64/                             # Precompiled Windows x64 DLL artifacts
├── build.py                                             # Automated Build, Deploy & Wireless ADB Discovery Tool
├── build.gradle                                         # Root Gradle build script
├── settings.gradle                                      # Gradle subprojects inclusion (:app, :desktop)
└── gradle/libs.versions.toml                            # Unified Gradle version catalog
```

---

## 3. Native QSP Engine & Rust Native Core Architecture

The runtime employs a dual-native architecture combining the classic QSP C interpreter with modern, memory-safe Rust acceleration.

### 1. JNI Bridge Layer (`com.libqsp.jni.QSPLib` / `LibProxyImpl.java`)
- **Lifecycle & Execution Management**:
  - `init()` / `terminate()`: Initializes or destroys the underlying QSP engine state.
  - `restartGame(boolean)`: Resets execution and restarts the active story from entry location.
  - `loadGameWorldFromData(byte[], boolean)`: Loads compiled quest bytecode (`.qsp`/`.gam`) directly into memory.
  - `saveGameAsData(boolean)` / `openSavedGameFromData(byte[], boolean)`: Serializes and restores execution snapshots.
  - `executeString(String, boolean)`: Executes arbitrary QSP script statements (used by cheat tools and dynamic actions).
- **Callback Dispatching**:
  - Intercepts native events (`RefreshInt`, `SetTimer`, `PlayFile`, `CloseFile`, `ShowMenu`, `InputBox`, `MsgBox`) and dispatches them safely to the Android Main Thread and Compose UI state observers.

### 2. High-Performance Rust Native Core (`native-rust`)
- **Memory-Mapped Archive Streamer (`archive.rs`)**:
  - Directly inspects and extracts assets from compressed `.qsp` / `.zip` files into memory streams without writing intermediate files to physical flash storage, minimizing I/O latency.
- **Fast HTML/BBCode Span Tokenizer (`html_parser.rs`)**:
  - Zero-copy HTML/BBCode sanitizer capable of cleaning and converting 100,000+ words of interactive fiction prose into structured text spans in sub-millisecond execution times.
- **Low-Latency Audio Buffer Mixer (`audio_mixer.rs`)**:
  - 32-bit floating-point multi-channel audio mixer with anti-clipping hyperbolic tangent (`tanh`) soft-limiting protection.
- **Graceful Kotlin Fallback**:
  - If the Rust dynamic library is unavailable on a target architecture, `RustEngineCore.kt` automatically falls back to native Kotlin/Java implementations (`ZipInputStream`, `HtmlCompat`, `MediaPlayer`).

---

## 4. UI/UX & Material 3 Expressive Design System

Questopia implements a modern, cohesive Material 3 Expressive design language optimized for ergonomics, responsiveness, and dark-mode comfort.

### Visual & Behavioral Principles

#### 1. 2-Column Responsive Adaptive Grid (`GameComponents.kt`)
- **Grid Layout**: Both Home (`InstalledGamesList`) and Repository (`RemoteGamesList`) use a 2-column grid (`LazyVerticalGrid(columns = GridCells.Fixed(2))`).
- **Slightly Squarish Proportion**: Card covers use `height(130.dp)` with `RoundedCornerShape(14.dp)` to achieve a balanced, modern semi-square proportion (~1:1.15 aspect ratio).
- **Full-Width Spans**: Search bars, multi-selection batch action headers, and empty state placeholders span across both columns (`span = { GridItemSpan(2) }`).
- **Accurate Folder Size**: Calculates the recursive size of entire game directories (`DirUtil.calculateDirSize`) and formats them cleanly on the bottom-left of each card.
- **Fallback App Logo**: Safe adaptive icon rendering using `AsyncImage(model = R.mipmap.ic_launcher)` preventing vector decoding crashes.

#### 2. Spring-Animated Morphing Controls (`MorphingUi.kt`)
- **Spring Physics**: Corner radius transitions animate using `spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessMediumLow)`.
- **Morphing Action Buttons**: Play and Install (Download) buttons located at the bottom-right of game cards smoothly morph from `18.dp` to `8.dp` corner radius on press.
- **Custom Drawer Handle**: Standardized spring-morphing handle (`----`) across all bottom sheets (`SaveSlotsSheet`, `CheatModesSheet`, `GameCard` context menus).

#### 3. Streamlined 54dp Navigation Bar (`StockNavigation.kt`)
- **Clean Icon-Only Interface**: Text labels are eliminated to prevent visual noise; height is condensed to `54.dp`.
- **Animated Indicator**: Active pill indicator smoothly animates width (`animateDpAsState` from 0dp to 56dp) on tab change.
- **Haptic Feedback**: Key tap feedback on navigation selection and action button clicks.

#### 4. In-Game Reading & Cheat Overlay Architecture (`GameActivity.kt`, `CheatModesSheet.kt`)
- **0 ms Latency Optimistic Cheat Controls**: Quick-add buttons (`+100`, `+1k`, `MAX`, `0`) update local UI state immediately while queuing native engine mutations in the background.
- **Deep Neutral Dark Themes**: Pure AMOLED (`#000000`) and Neutral Dark Grey (`#262626` / `#1E1E1E`) eliminate unwanted bluish tint in dark environments.
- **Scoped Vibration Policy**: Scroll edge haptics are strictly confined to `SettingsMainScreen.kt` and disabled inside game WebView reading views to ensure undisturbed reading.

#### 5. Uniform Settings Preference Cards (`SettingsComponents.kt`)
- **Equal Heights**: All preference rows enforce a uniform minimum height (`minHeight = 56.dp`) and standardized padding (`horizontal = 16.dp, vertical = 12.dp`).
- **Grouped Shapes**: Items in card groups dynamically calculate shapes via `getGroupedItemShape(index, count, radius)`.

---

## 5. Build, Compilation & Distribution Guide

### Development Environment Prerequisites
- **JDK**: Java Development Kit 21+ (`JAVA_HOME` pointing to JDK 21)
- **Android SDK**: Build Tools 35.0.0, NDK 27.0.12077973, CMake 3.22.1
- **Rust Toolchain**: `rustc` & `cargo` 1.80+ (for building `native-rust` libraries)
- **Python**: Python 3.10+ (for `build.py` orchestration script)

### Build & Deployment Workflow (`build.py`)
```powershell
# Build Android APK, detect wireless ADB device (ports 30000-49151), install and launch
python build.py android

# Build Desktop Windows x64 distribution
python build.py desktop

# Clean all Gradle and Cargo build artifacts
python build.py clean
```

---

## 6. Git, CI/CD & Agent Governance Standards

### Agent Engineering Rules
1. **Context Discipline & Token Efficiency**:
   - Never dump entire large source files (>150 lines). Always locate target line ranges first.
   - Use progressive disclosure and targeted symbol searches.
2. **Anti-Slop & Output Discipline**:
   - Zero narration before tool executions. Run tools directly.
   - Avoid speculative refactors or unwanted boilerplate.
3. **Commit Message Standard**:
   - All Git commit messages **MUST be written in simple, clear, user-friendly English**.
   - Format: `<type>: <description>` (e.g. `feat: redesign game cards grid, add morph buttons and polish navigation bar`).
