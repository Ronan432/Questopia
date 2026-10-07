# FLUTTER.md — Questopia Flutter Migration Master Architecture & Roadmap

This document serves as the authoritative architectural specification and migration blueprint for porting **Questopia** to **Flutter** across Android, iOS, and Desktop (Windows x64).

---

## 1. Executive Summary & Design Directive

- **Core Goal**: Complete, 100% faithful port of all interactive game engine features, QSP 5.8.0 C core logic, Save Editor/Cheat Sheets, Media Handling, and Remote Catalog Sync.
- **UI Design Freedom**: **Redesigning the UI is explicitly permitted.** The UI does NOT need to mirror the Kotlin Compose layout pixel-for-pixel. Modernized Material 3 Expressive Flutter components can be used to deliver an optimized user experience, provided that **100% of functionality, dialogs, state flows, and engine features are preserved.**
- **Zero Emoji Policy**: Zero emojis across the entire application UI, dialogs, headers, buttons, logs, or error messages.
- **Native / Rust Companion Strategy**: **Rust code does NOT need to be rewritten or converted into Dart.** The pre-compiled Rust native library (`questopia_rust`) will either be directly invoked via `dart:ffi` / `flutter_rust_bridge`, or replaced by pure Dart packages (`archive`, `html`, `charset_converter`) where appropriate, avoiding redundant conversion effort.

---

## 2. Target Technology Stack & Package Mapping

| Subsystem / Layer | Current Stack (Kotlin / C / Rust) | Target Flutter Stack | Rationale & Package Details |
| :--- | :--- | :--- | :--- |
| **Language & SDK** | Kotlin & Java 21, Android SDK 35 | Dart 3.x (Sound Null Safety) & Flutter | Unified cross-platform SDK. |
| **UI Framework** | AndroidX Jetpack Compose (M3) | `flutter/material.dart` (Material 3) | Modernized Material 3 components. |
| **Native Engine** | C QSP 5.8.0 Engine (`libqsp.so` / `qsp.dll`) | `dart:ffi` C-Bindings | Direct native binding to QSP C shared library via FFI. |
| **Rust Companion / Helpers** | Rust Native (`questopia_rust`) | Direct `dart:ffi` OR Pure Dart (`archive`, `html`, `charset_converter`) | **No conversion needed.** Reused as compiled binary via FFI or handled by Dart ecosystem. |
| **State Management** | LiveData / ViewModel | Riverpod (`AsyncNotifier`) / Bloc | Immutable UI states and reactive state flows. |
| **Navigation** | Android Intent / Activity | `go_router` | Declarative routing, deep-linking, modal sheet sub-routes. |
| **Networking** | Ktor Client | `dio` + `json_serializable` | Remote stock repository fetch with retry & logging interceptors. |
| **Local Storage** | SharedPreferences / SAF File API | `shared_preferences` + `file_picker` | Local preferences and Storage Access Framework integration. |
| **In-Game WebView** | Android WebView | `flutter_inappwebview` / `webview_flutter` | Custom JS bridge, zoom control, OGV.js WASM video playback. |

---

## 3. Detailed Architectural Modules & Responsibilities

### 3.1 C QSP 5.8.0 Native Engine FFI Bridge (`lib/core/native/qsp_ffi.dart`)
The core QSP engine is written in C. The Flutter port will bind directly using `dart:ffi`:
- **Native Memory Management**: `Pointer<Utf16>` conversion for QSP string data.
- **Engine Lifecycle**: `qspInit()`, `qspTerminate()`, `qspLoadGameWorldFromData()`, `qspRestartGame()`.
- **Execution & Evaluation**: `qspExecString()`, `qspExecLocationCode()`, `qspCalculateNumExpr()`, `qspCalculateStrExpr()`.
- **State Queries**: `qspGetMainDesc()`, `qspGetVarsDesc()`, `qspGetActions()`, `qspGetObjects()`, `qspGetAllVariables()`, `qspGetAllLocations()`.
- **Engine Callbacks (`NativeCallable`)**: Bindings for `onShowMessage`, `onShowImage`, `onPlayFile`, `onShowMenu`, `onInputBox`, `onSetTimer`, `onOpenGameStatus`, `onSaveGameStatus`.

### 3.2 Native Rust Library & Alternative Strategy
- **Direct Binary Reuse (No Code Conversion)**: The compiled Rust binary (`libquestopia_rust.so` / `questopia_rust.dll`) can be called directly via `dart:ffi` or `flutter_rust_bridge` for ZIP extraction, charset conversion, and HTML parsing.
- **Pure Dart Ecosystem Fallback**: Alternatively, standard Flutter packages (`archive` for Zip Slip safe extraction, `html` for DOM parsing, and `charset_converter` for Windows-1251 / KOI8-R) can be used without needing to touch or port Rust source code.

### 3.3 In-Game WebView & OGV.js Video Streaming (`lib/features/game/presentation/widgets/game_webview.dart`)
- **HTML Cleanup & Regex**: `HtmlProcessor` equivalent converting multi-line `exec:` commands into Base64 (`href="exec:base64:..."`) and normalizing line breaks (`<br>`).
- **OGV.js WASM Fallback**: Automatic conversion of `.ogv` / `.ogg` image sources into `<video>` tags with embedded `ogv.js` decoders.
- **Local Media Proxying**: Custom URI scheme or embedded local web server (`https://questopia.local/`) intercepting local game assets to resolve CORS policies.

### 3.4 In-Game Save Editor & Cheat Sheet (`lib/features/game/presentation/sheets/cheat_modes_sheet.dart`)
- **6 Navigation Tabs**:
  1. *VariablesTab*: Filter variables (Numeric, String, Array), live variable editing.
  2. *LocksTab*: Freeze Monitor — lock variable values in place during gameplay.
  3. *TeleportTab*: Instant location teleportation via `qspExecLocationCode`.
  4. *InventoryTab*: Item inventory modification.
  5. *ConsoleTab*: Interactive QSP execution console.
  6. *DiffTab*: Snapshot difference monitor.
- **100% Rollback Safety**: Take an `initialSnapshot` on sheet open; restore state if the user cancels out via back gesture.

### 3.5 Save/Load Manager (`lib/features/game/presentation/sheets/save_slots_sheet.dart`)
- 60 manual save slots organized into 10 pages.
- Standalone Auto-Save card.
- External save file import/export (.sav).

### 3.6 Stock Catalog & Download Manager (`lib/features/stock`)
- Remote game catalog sync via Dio (`RemoteGameRepository`).
- Automatic background ZIP download with Zip Slip protected extraction.
- Local games list with directory size calculation, favoriting, and metadata parser (`.gameInfo`).

---

## 4. Migration Execution Plan (Phase Roadmap)

- **FAZ 0 — Keşif ve Envanter**: Completed (`docs/00_ENVANTER.md`).
- **FAZ 1 — Mimari Eşleme Tablosu**: Map every Composable and ViewModel to Flutter equivalents (`docs/01_MIMARI_ESLEME.md`).
- **FAZ 2 — Proje İskeleti**: `flutter create` with bundle ID `com.questopia.re`, clean architecture folders, `analysis_options.yaml`, `AppLog` wrapper.
- **FAZ 3 — Tasarım Sistemi**: Material 3 Light/Dark/AMOLED theme, custom drawer handles, responsive layouts.
- **FAZ 4 — Veri Katmanı**: Dio remote repository, Drift local game database, archive unpacker.
- **FAZ 5 — Domain & State**: Pure Dart Use Cases, Riverpod/Bloc Notifiers for game loop and cheat editor.
- **FAZ 6 — UI & Navigasyon**: Stock Library, In-Game WebView, Game Dialogs Host (8 dialog types), Save Slots, Cheat Editor.
- **FAZ 7 — Native Integration**: Native C FFI binding (`libqsp.so` / `qsp.dll`), OGV.js media proxy, Yandex reverse image search.
- **FAZ 8 — Veri Göçü**: Migrate legacy SharedPreferences and save files.
- **FAZ 9 — Parite Doğrulaması**: Parity matrix checklist (`docs/09_PARITE.md`), golden tests, unit tests.
- **FAZ 10 — CI/CD ve Yayın**: Android AAB, iOS IPA, and Windows x64 build configuration.

---

## 5. Architectural Principles & Safety Rules

1. **No Inline Comments Rule**: No comments (`//`, `/* */`) in Flutter production Dart files.
2. **Single Logging Wrapper**: All logs must route through `AppLog.d(tag, message)`.
3. **State Hoisting for Sub-Sheets**: Parent coordinator manages all modal sheet states.
4. **Localization**: All string resources stored in ARB files (`app_en.arb`, `app_ru.arb`).
5. **Multi-line `exec:` Bridge**: Decode Base64 payloads and execute clean statements into `qspExecString`.

---

## 6. Current Progress & Next Steps

- **Completed**: FAZ 0 Inventory (`docs/00_ENVANTER.md`) and Master Plan (`FLUTTER.md`).
- **Awaiting User Confirmation**: Please answer the 6 decision questions in `docs/00_ENVANTER.md` to proceed to FAZ 1.
