# Questopia - Comprehensive Engineering & Architecture Specification

Welcome to the definitive architecture, design system, and technical handbook for **Questopia**, a modern, high-performance, multiplatform Interactive Fiction and QSP Text Quest engine designed for **Android** and **Windows Desktop (x64)**.

---

## 1. Executive System Overview

Questopia modernizes the classic Quest Soft Player (QSP) ecosystem by providing an expressive, hardware-accelerated, and secure runtime built on contemporary multiplatform technologies.

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
│   │       ├── common/                  # Reusable MorphingUi, Expressive UI primitives
│   │       ├── game/                    # In-game activity, dark dialogs, save slots, CheatModesSheet (QSPSaveEditor)
│   │       ├── settings/                # Unified Material 3 Expressive settings & dark selection dialogs
│   │       ├── stock/                   # Game stock & catalog browser (clean, no-slop lists)
│   │       └── theme/                   # Material 3 dynamic & AMOLED themes
│   └── src/main/cpp/                    # CMakeLists.txt & native QSP C/C++ sources (variable/location exporters)
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
├── build.py                             # Automated Build, Deploy & Instant Launch Python Tool
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
- **Desktop Dynamic DLL Fallback Loader**:
  - 3-tier loading mechanism: System Library Path -> `libs/native/windows-x64/` -> JAR classpath extraction to temporary directory.

### 2. High-Performance Rust Native Core (`native-rust`)
- **Memory-Mapped Archive Streamer (`archive.rs`)**:
  - Direct reading of assets from `.qsp` / `.zip` archives into memory without extracting files to flash storage, mitigating disk wear and ensuring zero startup lag.
  - Hardened Zip Slip path traversal defenses.
- **Fast HTML/BBCode Span Tokenizer (`html_parser.rs`)**:
  - Scans and strips HTML tags from 100,000+ word interactive fiction texts in microseconds.
  - Extracts image URIs and formats styled text spans directly into compact binary structures, keeping Compose UI thread framerates locked at 120 FPS.
- **Low-Latency Audio Buffer Mixer (`audio_mixer.rs`)**:
  - Donated 32-bit float stereo mixing with soft-clipping protection (`tanh` limiter) and in-place crossfading.
- **Non-Breaking Side-by-Side Verification**:
  - `RustEngineCore.kt` on Android and Desktop attempts to link `questopia_rust`. If absent or on legacy platforms, it automatically falls back to the Java/C engine without breaking functionality.

---

## 4. UI/UX & Expressive Design System

Questopia implements a modern, cohesive Material 3 Expressive design system shared across Android and Desktop.

### Key Visual & Functional Principles
1. **Dynamic Scrolling Search Bar**:
   - The search bar resides within the main scrollable container rather than being pinned statically, sliding out of view on scroll down to maximize screen estate for quest content.
2. **Deep Dark Dialogs & Menus**:
   - In-game options menu (`ModalBottomSheet`), save/load slot sheets (`SaveSlotsSheet`), select menu dialogs (`menuDialogData`), and settings preference selection dialogs (`ExpressiveListPreferenceItem`) feature deeply darkened surfaces (`#101216` on dark, `#000000` on AMOLED) with high-contrast nested container shapes.
3. **Unified Grouped Settings Cards**:
   - Grouped cards (`ExpressiveSettingsGroup`) with dynamic corner radiusing (`getGroupedItemShape`), clear checkmark indicators (`Icons.Filled.Check`), and zero redundant section title clutter.
4. **Expressive Morph Shaping & Spring Clamping**:
   - Animated corner radii in `MorphingUi.kt` are strictly bounded with `.coerceAtLeast(0.dp)` to prevent negative corner size exceptions caused by spring damping bounce.
5. **AMOLED & Dynamic Color Support**:
   - **AMOLED**: True pure black (`#000000`) background and base surfaces with tiered low-luminance container elevations (`#0A0A0A`, `#141414`, `#1E1E1E`, `#282828`).
   - **Dynamic Colors**: Material You dynamic color harmonisation on Android 12+ (API 31+).
6. **Strict Internationalization (i18n)**:
   - 100% of user-facing strings are dynamically bound to resource bundles (`R.string.*` / `strings.xml`), ensuring 1:1 translation across English, Turkish, and Russian. Zero hardcoded text in code.

---

## 5. Build, Compilation & Distribution Guide

### Prerequisites
- **JDK**: Java Development Kit 21+ (`JAVA_HOME` pointing to JDK 21)
- **Android SDK**: Build Tools 35.0.0, NDK 27.0.12077973, CMake 3.22.1
- **Rust Toolchain**: `rustc` & `cargo` 1.80+
- **Windows Toolchain**: Visual Studio 2022 Build Tools (MSVC x64)

### Automated Single-Command Build Tool (`build.py`)
```powershell
# Build and run Android debug build on connected device/emulator
python build.py android

# Build and run Windows desktop app
python build.py desktop
```

### Android Manual Build Commands
```powershell
# Build debug APK
.\gradlew assembleDebug

# Build optimized universal release APK with R8 minification
.\gradlew assembleRelease
```

---

## 6. Git, CI/CD & Contribution Guidelines

### 1. GitHub Fork & Authentication
- **Repository**: `https://github.com/Ronan432/Questopia`
- **Owner**: `Ronan432`
- **PAT Token**: Set via Git Remote / GitHub Secrets (`ghp_***`)


### 2. Commit Message Standard
- All git commit messages **MUST be written in simple, clear, user-friendly English** so that contributors and end users immediately understand the changes made.
- Format: `<Action / Component>: <Simple description>` (e.g. `First commit`, `Add cheat mode save editor`, `Fix AMOLED background contrast`, `Update CI release workflow`).

### 3. GitHub Actions CI/CD & Automated Pre-Releases
- Workflow file: `.github/workflows/android-build.yml`
- Automated triggers: On push to `master` / `main` and manual `workflow_dispatch`.
- **Pre-Release Workflow**: Automatically compiles a minimized, universal Android APK supporting all ABIs (`ARM64-v8a`, `ARMeabi-v7a`, `x86`, `x86_64`) and publishes a GitHub Pre-Release with the APK attached.
- **Fork Enablement**: To run Actions on the fork, go to **Actions** $\rightarrow$ **"I understand my workflows, go ahead and enable them"**, and ensure **Settings $\rightarrow$ Actions $\rightarrow$ General $\rightarrow$ Workflow permissions** is set to **Read and write permissions**.
