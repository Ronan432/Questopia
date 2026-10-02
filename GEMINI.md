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
  - **Android**: Custom-compiled NDK `libqsp.so` with CMake + `libquestopia_rust.so` via Cargo
  - **Windows Desktop**: MSVC-compiled 64-bit `qsp.dll` + `questopia_rust.dll`
- **Networking**: `io.ktor:ktor-client-core` (Asynchronous HTTP engine)
- **Persistence & State**: Multiplatform Settings, Kotlinx Serialization, Java NIO / Android Storage Access Framework (SAF)
- **Image Pipeline**: Coil 2.7.0 with Coroutine-backed memory and disk caching

---

## 2. Project Architecture & Directory Layout

The repository is organized into modular subprojects separating platform-specific lifecycle bindings from reusable domain logic, UI components, and native binaries.

```
Questopia/
├── app/                                 # Android Application Module
│   ├── src/main/java/org/qp/android/
│   │   ├── dto/                         # Data transfer objects & models
│   │   ├── helpers/                     # Native bridges, archive unpacking, utils, audio, locale
│   │   │   └── native_core/             # RustEngineCore.kt JNI bridge with safe fallback
│   │   ├── model/                       # QSP engine bindings, repositories, services
│   │   └── ui/                          # Jetpack Compose screens, activities, themes
│   │       ├── common/                  # Centralized MorphingUi.kt (MorphingSurface, getGroupedItemShape, CustomDrawerHandle)
│   │       ├── game/                    # In-game activity, dark dialogs, SaveSlotsSheet, CheatModesSheet (QSPSaveEditor)
│   │       ├── settings/                # Unified Material 3 Expressive settings & drawer selection dialogs
│   │       ├── stock/                   # Game stock & catalog browser (clean, no-slop lists)
│   │       └── theme/                   # Material 3 dynamic, Monochrome & AMOLED neutral themes
│   └── src/main/cpp/                    # CMakeLists.txt & native QSP C/C++ sources
├── desktop/                             # Windows Desktop Application Module
│   ├── src/main/java/com/libqsp/jni/    # JNI native bridge interface (QSPLib)
│   ├── src/main/kotlin/org/qp/desktop/  # Compose Desktop application entry & UI
│   │   ├── engine/                      # DesktopQspEngine state & RustEngineCore manager
│   │   ├── model/                       # GameItem & DesktopAppSettings models
│   │   ├── theme/                       # DesktopTheme system (3 modes, 9 palettes)
│   │   └── ui/                          # NavigationRail, Library, Stock, Play, Settings
│   └── src/main/resources/              # Embedded qsp.dll, questopia_rust.dll & official app assets
├── native-rust/                         # High-Performance Rust Native Core
│   ├── Cargo.toml                       # Rust crate manifest (jni, zip, flate2, serde)
│   └── src/
│       ├── lib.rs                       # JNI Exports for Android & Desktop
│       ├── archive.rs                   # Streaming & memory-mapped Zip/QSP decompressor
│       ├── html_parser.rs               # Zero-copy fast HTML/BBCode cleaner & span extractor
│       └── audio_mixer.rs               # 32-bit float audio buffer mixer with soft-limiter
├── build.py                             # Automated Build, Deploy & Multithreaded Wireless ADB Port Discovery Tool
├── gradle/                              # Gradle wrapper and version catalogs
│   └── libs.versions.toml               # Unified dependency & plugin version management
├── libs/native/windows-x64/             # Compiled Windows 64-bit DLLs (qsp.dll, questopia_rust.dll)
├── build.gradle                         # Root build configuration
└── settings.gradle                      # Subproject inclusion (:app, :desktop)
```

---

## 3. Native QSP Engine & Rust Native Core Architecture

The runtime employs a dual-native strategy combining the battle-tested QSP C interpreter with modern, memory-safe Rust acceleration.

### 1. JNI Bridge Layer (`com.libqsp.jni.QSPLib`)
- **Lifecycle & Execution**:
  - `init()` / `terminate()`: Manages QSP runtime context and memory allocation.
  - `restartGame(boolean)`: Restarts active quest execution.
  - `loadGameWorldFromData(byte[], boolean)`: Loads quest bytecode from memory.
  - `saveGameAsData(boolean)` / `openSavedGameFromData(byte[], boolean)`: Serializes/deserializes execution snapshots.

### 2. High-Performance Rust Native Core (`native-rust`)
- **Memory-Mapped Archive Streamer (`archive.rs`)**:
  - Direct reading of assets from `.qsp` / `.zip` archives into memory without extracting files to flash storage.
- **Fast HTML/BBCode Span Tokenizer (`html_parser.rs`)**:
  - Scans and strips HTML tags from 100,000+ word interactive fiction texts in microseconds.
- **Low-Latency Audio Buffer Mixer (`audio_mixer.rs`)**:
  - Donated 32-bit float stereo mixing with soft-clipping protection (`tanh` limiter).

---

## 4. UI/UX & Expressive Design System

Questopia implements a modern, cohesive Material 3 Expressive design system shared across Android and Desktop.

### Key Visual & Functional Principles
1. **Centralized Morphing & Drawer Handles (`MorphingUi.kt`)**:
   - `CustomDrawerHandle` (spring-animated `----` handle bar) and `MorphingSurface` are centralized in `org.qp.android.ui.common.MorphingUi.kt`.
2. **Unified Deep Dark Drawers & Neutral Monochrome Themes**:
   - In-game options menu (`ModalBottomSheet`), save/load slot sheets (`SaveSlotsSheet`), context menus (`showActionSheet`), and settings preference selection dialogs (`ExpressiveListPreferenceItem`) feature deeply darkened, neutral surfaces without bluish tints.
   - AMOLED mode uses pure black (`#000000`). Standard Dark and Monochrome modes use neutral dark grey (`#262626` / `#1E1E1E`).
3. **Instant Variable Cheat Controls (0 ms Latency)**:
   - Cheat Modes Sheet (`CheatModesSheet.kt`) uses optimistic in-memory overrides for variable quick-add buttons (`+100`, `+1k`, `MAX`, `0`), updating the UI in 0 milliseconds without freezing during QSP thread execution.
   - All variable action controls use circular (`CircleShape`) icon containers.
   - Teleport location cards use grouped morphing surfaces (`getGroupedItemShape`) matching the Settings menu style without code duplication.
   - Inventory item deletion requires confirmation warning dialogs.
4. **Mandatory Edge Vibration Scope**:
   - Boundary scroll vibration is active **exclusively in Settings** (`SettingsMainScreen.kt`). Scroll edge vibration is completely disabled in the game UI/WebView (`GameActivity.kt`) to ensure smooth, uninhibited reading.
5. **Strict Internationalization (i18n)**:
   - 100% of user-facing strings are dynamically bound to resource bundles (`R.string.*` / `strings.xml`), ensuring 1:1 translation across English, Turkish, and Russian.

---

## 5. Build, Compilation & Distribution Guide

### Prerequisites
- **JDK**: Java Development Kit 21+ (`JAVA_HOME` pointing to JDK 21)
- **Android SDK**: Build Tools 35.0.0, NDK 27.0.12077973, CMake 3.22.1
- **Rust Toolchain**: `rustc` & `cargo` 1.80+

### Automated Build & Wireless ADB Tool (`build.py`)
```powershell
# Auto-discover Wireless ADB ports (30000-49151) via multithreaded socket scan and launch app
python build.py android
```

---

## 6. Git, CI/CD & Contribution Guidelines

### Commit Message Standard
- All git commit messages **MUST be written in simple, clear, user-friendly English**.
- Format: `<Action / Component>: <Simple description>` (e.g. `Centralize MorphingUi and drawer handles`, `Disable game interface scroll vibration`, `Fix dark theme monochrome background`).
