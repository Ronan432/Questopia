# FLUTTER.md — Questopia Flutter Architecture & Handover Documentation

> **Last Update:** October 8, 2026  
> **Target Framework:** Flutter 3.44.6 / Dart 3.12.2  
> **Branch:** `master`  
> **`flutter analyze`:** CLEAN (0 issues)  

---

## 1. Project Overview & Tech Stack

Questopia-RE is a high-performance cross-platform interpreter and library client for QSP (Quest Soft Player) interactive fiction games, built on Flutter with native C/C++ and Rust FFI.

- **Package Identifier:** `com.questopia.re`
- **Supported Platforms:** Android (API 26+), Windows (x64), Linux, macOS
- **Engine Bindings:** Native C-API QSP (`libqsp.so` on Android/Linux, `qsp.dll` on Windows) via Dart FFI (`dart:ffi`)
- **State Management:** Riverpod (`StateNotifierProvider`) with generation counters
- **Typography:** `Netflix Sans` (applied app-wide and dynamically injected into WebView CSS)
- **Design System:** Material 3 Expressive (`material_3_expressive`), dynamic theming (`dynamic_color`), active shape morphing
- **Localization:** 100% dynamic internationalization via ARB files (`app_en.arb`, `app_ru.arb`)

---

## 2. Critical Development Rules & Code Hygiene

1. **PROHIBITION OF `flutter test`:** Executing `flutter test` is strictly prohibited in all automated and manual workflows.
2. **ZERO STATIC STRINGS / HARDCODED TEXTS:** All UI labels, buttons, headers, dialogs, and messages must reside in `app_en.arb` and `app_ru.arb`, accessed exclusively via `AppLocalizations.of(context)!`.
3. **ENGLISH-ONLY CODE COMMENTS:** All code comments across Dart, C++, C, Rust, and Kotlin source files must be written strictly in English.
4. **SANDBOX REGISTRY ISOLATION:** Never write metadata, registry entries, or hidden dot-files into external shared storage. All persistent game records must go through `GameRegistry` inside `getApplicationSupportDirectory()`.
5. **MODULAR HELPER COHESION:** Utility and helper routines must be encapsulated in dedicated helper files under `lib/core/helpers/` (e.g. `sheet_helper.dart`, `path_picker_helper.dart`, `html_processor.dart`).
6. **EFFECTIVE SETTINGS LINKAGE:** Every setting field in `SettingsState` must have an active consumer and observable effect in the UI or runtime engine (blur, haptics, action height ratio, immersive mode, square posters, font family, etc.).

---

## 3. Core Architecture & Active Subsystems

### 3.1. Native QSP FFI Engine & Dual-Width Encoding
- **Windows C-API DLL:** Uses official C-API `qsp.dll` with 50 exports (`QSPInit`, `QSPLoadGameWorldFromData`, `QSPRestartGame`, `QSPGetMainDesc`, `QSPGetActions`, etc.) with statically linked Oniguruma regex.
- **Dynamic Dual-Width `wchar_t` (`QspUtf16` & `QspFfi`):** Automatically detects 2-byte (Windows MSVC) and 4-byte (Android/Linux Clang) `wchar_t` streams. Compilers configured with `-fshort-wchar` for cross-platform UTF-16 parity.
- **Correct FFI Types:** `QSP_BOOL` mapped to `Int8`, `QSP_BIGINT` mapped to `Int32`, preventing bit corruption on 64-bit calling conventions.

### 3.2. Thread-Safe Atomic GameRegistry (`GameRegistry`)
- **Storage Location:** `<app_support_dir>/questopia_games.json`.
- **Atomic File Lock:** Serialized writes via temporary file and atomic rename (`.tmp -> rename`).
- **Batch Operations & Ignored List:** Supports `batchUpsert()` and tracks `ignored` IDs to prevent deleted/hidden games from re-appearing during auto-discovery.

### 3.3. 3-Tier Game Import & Scanning Engine (`GameRepository`)
- **Tier A (Zero-Copy Instant Indexing):** Directly indexes accessible external folders in $<0.005\text{ s}$ without file duplication.
- **Tier B (Isolate Copy Fallback):** Asynchronous background isolate directory copy when direct reading is restricted on Android 11+ Scoped Storage.
- **Tier C (Archive Extraction):** Fast extraction for `.zip`, `.aqsp`, `.rar`, `.7z`, `.tar`, `.gz` using Rust FFI decoders and Dart fallback streams.
- **Isolate BFS Traversal & Deduplication:** Multi-threaded BFS search detects nested entry files (`.qsp` / `.gam`) up to depth 8. Prunes dead registry entries automatically and deduplicates across canonical absolute file paths and title+filesize signatures to eliminate duplicate entries.
- **Execution Tracing:** Microsecond-precision `Stopwatch` metrics for all scans and imports.

### 3.4. State Management & Generation Guard (`LibraryProvider`)
- **Generation-Guarded State:** `LibraryNotifier` uses a monotonic `_generation` counter to ensure background file scans never overwrite newly imported games.
- **Immediate State Injection:** Imported games appear immediately at the head of the library state before background validation.
- **Lifecycle Optimization:** Constructor runs zero eager network calls; catalog fetching is strictly on-demand.

### 3.5. Game Player, WebView2 & Pre-Cached $O(1)$ Media Resolution (`GameScreen`)
- **Edge-to-Edge Square Viewport:** WebView is rendered edge-to-edge without rounded card margins, filling the screen corners completely.
- **Universal Video Playback & Seamless Looping:** Converts all video formats (`.mp4`, `.webm`, `.ogv`, `.ogg`, `.m4v`, `.mov`) in `<img>` tags to `<video autoplay loop muted playsinline>` backed by a self-recovering JS loop script and WASM OGVPlayer fallback, preserving fixed media boundaries without text shifting.
- **Image-Aware Action Buttons:** Dynamically detects and renders images inside action names (`<img src="...">`) or `act.image` with dedicated sleek icon-tile styling for pure-image actions and leading thumbnails for text actions.
- **Adaptive RPG Inventory Tab:** Renders objects with case-insensitive local asset image resolution. Pure-image inventory items render in a responsive square-tile grid (`childAspectRatio: 1.0`), while named items display in a structured list with 52x52 square image previews.
- **High-Contrast Dialog Engine (`GameDialogsHost`):** Formatted with theme-aware `surfaceContainerHigh` surfaces, sanitized HTML text, and explicit high-contrast typography across all QSP dialogs (Message, Input, Menu, Error, Restart).
- **Pre-Cached Asset Index:** Builds a case-insensitive, backslash-normalized, Unicode-tolerant asset index (`_cachedAssetIndex`) in a background isolate upon game launch with zero-disk interception.
- **3-Tab Navigation:** Story (`mainDesc`), Status (`varsDesc`), and Inventory (`objects`) tabs with real-time badges.

### 3.6. UI / UX Design System & Active Morph Shaping
- **Active Morph Shaping:** Dynamic radius transitions between compact Rounded Rectangles (`BorderRadius.circular(8)`) when unselected, and full Stadium Pills (`BorderRadius.circular(24)`) when selected.
- **Blurred Backdrop Sheets (`showQuestopiaSheet`):** Bottom sheets and drawer menus utilize root navigator coverage and `BackdropFilter` Gaussian blur (`sigma: 8`) to smoothly dim and blur the entire scaffold, including the top app bar header and background content.
- **Phone-Optimized Compact Grid:** Responsive 2-column grid layout on mobile screens (`< 600dp`) with downscaled posters (90dp), tightened typography, and compact actions, while preserving full-size cards on desktop/tablets.
- **Mobile Navigation:** Integrated reactive bubble navigation (`_buildMobileBottomBar`) with active selection bubble morphing, optional backdrop blur (`isNavBarBlur`), zero-latency reactive viewport, and haptic feedback.
- **Desktop Navigation:** Left-side borderless `NavigationRail` with instant inline settings.
- **High-Performance Posters (`GamePoster`):** Memory-capped GPU texture caching via `extended_image` and native vector rendering via `flutter_svg`. Short-circuits missing/SVG covers to avoid network ANRs.

---

## 4. Key Project Files & Responsibilities

| File Path | Description |
| :--- | :--- |
| `lib/core/native/qsp_ffi.dart` | Low-level Dart FFI bindings to QSP C-API with verified struct layouts and type signatures. |
| `lib/core/native/qsp_utf16.dart` | Memory-safe UTF-16 / UTF-32 dual-width string converter and native struct populator. |
| `lib/core/helpers/sheet_helper.dart` | Root-navigator modal bottom sheet engine with Gaussian backdrop blur. |
| `lib/core/helpers/html_processor.dart` | Sanitizer, video tag converter, and OGV/WASM injector for QSP HTML output. |
| `lib/core/helpers/path_picker_helper.dart` | Platform-aware native folder picker and Android Scoped Storage directory resolver. |
| `lib/features/library/data/game_registry.dart` | Thread-safe, atomic, file-locked JSON registry stored in internal sandbox directory. |
| `lib/features/library/data/game_repository.dart` | 3-Tier import pipeline (zero-copy, isolate copy, archive unpacker) and isolate BFS scanner. |
| `lib/features/library/providers/library_provider.dart` | Riverpod library state notifier with generation-guarded background refresh. |
| `lib/features/library/presentation/library_screen.dart` | Responsive library/catalog UI with active morph filter chips, blur bottom bar, and search. |
| `lib/features/library/presentation/widgets/game_poster.dart` | Memory-capped, ANR-free poster image loader with SVG vector fallback. |
| `lib/features/game/presentation/game_screen.dart` | Game interpreter view, WebView runner, image action buttons, and RPG inventory grid. |
| `lib/features/settings/presentation/settings_screen.dart` | Expressive M3E settings screen with morph category buttons and dynamic theming. |

---

## 5. Verification & Quality Assurance

All features must maintain 0 static analysis issues before commit:

```powershell
flutter analyze
```
