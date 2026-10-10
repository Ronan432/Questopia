# FLUTTER.md — Questopia Flutter Architecture & Handover Documentation

> **Last Update:** October 10, 2026  
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
4. **FILE LENGTH LIMIT (< 300 LINES):** Every source file in the project must be strictly maintained under 300 lines. When a widget or helper exceeds 300 lines, it must be decomposed into dedicated sub-components, views, or section files.
5. **DRY & REUSABLE ARCHITECTURE:** Eliminate duplicate implementations across screens and sheets. Shared features (dialogs, sheets, bottom navigation bars, header search bars, settings tile builders) must be encapsulated in reusable helper or widget files under `lib/core/helpers/` or dedicated feature widgets.
6. **UNIFIED CONTEXT DIALOG ARCHITECTURE:** All modal pop-ups, confirmation dialogs, input prompts, error alerts, and crash reports must utilize `showQuestopiaDialog` and `QuestopiaDialog` / `QuestopiaConfirmationDialog` with morph-shaping animations and backdrop blur, eliminating raw disparate `AlertDialog` implementations.
7. **SANDBOX REGISTRY ISOLATION:** Never write metadata, registry entries, or hidden dot-files into external shared storage. All persistent game records must go through `GameRegistry` inside `getApplicationSupportDirectory()`.
8. **MODULAR HELPER COHESION:** Utility and helper routines must be encapsulated in dedicated helper files under `lib/core/helpers/` (e.g. `sheet_helper.dart`, `dialog_helper.dart`, `path_picker_helper.dart`, `html_processor.dart`).
9. **EFFECTIVE SETTINGS LINKAGE:** Every setting field in `SettingsState` must have an active consumer and observable effect in the UI or runtime engine (blur, haptics, action height ratio, immersive mode, square posters, font family, etc.).
10. **STANDARDIZED COMMIT FORMAT AND USER-FRIENDLY DESCRIPTIONS:** Commit subject lines must strictly adhere to standardized conventional prefix syntax (e.g. `Feat: <reason>`, `Fix: <reason>`, `Ci: <reason>`). Never put multi-line descriptions or markdown headers in commit titles. Commit descriptions/bodies must be written in plain, easily understandable user-facing English explaining what changed and why.
11. **BAN ON `&` SYMBOL:** The ampersand character (`&`) is strictly forbidden across all user-facing UI strings, headers, button labels, documentation, and commit messages. Always use the full word "and" or "ve".

---

## 3. Core Architecture and Active Subsystems

### 3.1. Native QSP FFI Engine and Dual-Width Encoding
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
- **Tier C (Archive Extraction):** Fast extraction for `.zip`, `.aqsp`, `.rar`, `.7z`, `.tar`, `.gz` using Rust FFI decoders, system `bsdtar` (Windows/Linux/macOS), and Dart fallback streams with Zip Slip protection.
- **Isolate BFS Traversal & Deduplication:** Multi-threaded BFS search detects nested entry files (`.qsp` / `.gam`) up to depth 8. Prunes dead registry entries automatically and deduplicates across canonical absolute file paths and title+filesize signatures to eliminate duplicate entries.

### 3.4. State Management and Generation Guard (`LibraryProvider`)
- **Generation-Guarded State:** `LibraryNotifier` uses a monotonic `_generation` counter to ensure background file scans never overwrite newly imported games.
- **Immediate State Injection:** Imported games appear immediately at the head of the library state before background validation.
- **Lifecycle Optimization:** Constructor runs zero eager network calls; catalog fetching is strictly on-demand.

### 3.5. Game Player, Media Pipeline, and Modal Dialogs (`GameScreen`)
- **Native Video Decoding & Hardware Acceleration:** Powered by `video_player` (ExoPlayer on Android, Media Foundation on Windows) hardware decoders via `QspMedia` and `QspVideo`, replacing fragile webviews with smooth looping playback while keeping the native decoder payload out of the app bundle.
- **Ogg Theora Fallback (`QspOgvVideo`):** The platform decoder cannot read Theora, so `.ogv` and `.ogg` files are routed to the bundled OGV.js WebAssembly decoder rendered in a hidden WebView. Every other container stays on the hardware decoder.
- **High-Performance HTML Rendering (`QspHtmlView`):** Native flutter HTML parser rendering rich typography, custom styled interactive links, and embedded asset image/video elements.
- **Unified Engine Dialog System (`GameDialogsHost`):** Message (`GameMessageDialog`), prompt input (`GameInputDialog`), interactive choice menus (`GameMenuDialog`), runtime error diagnostics (`GameErrorDialog`), image/video preview (`GameImagePreviewDialog`), and QSP console execution (`GameExecutorDialog`) all presented through `showQuestopiaDialog`.

### 3.6. UI / UX Design System, Morph Shaping, and Modularity
- **Unified Modal Dialog Morph Shaping (`showQuestopiaDialog` & `QuestopiaDialog`):** Dialogs enter with a dynamic curved morph transition interpolating from 40px radius down to 28px standard curvature, combined with scale tweening, and animated Gaussian backdrop blur (`sigma: 8.0`).
- **Frosted Glass Bottom Sheets (`showQuestopiaSheet`):** Modal bottom sheets feature `SafeArea` enforcement, full-screen background Gaussian blur (`sigma: 10.0`), translucent frosted surfaces, elevated drag handles with animated scaling upon interaction, and centered header pills.
- **Swipeable Horizontal Navigation:** Both `LibraryScreen` (Local Library, Remote Catalog, Settings) and `SettingsScreen` (Appearance, General, Typography, Media, Sound, Storage, About) feature horizontal swipeable `PageView` animations coordinated with category chips and bottom bars.
- **Strict File Modularity:** Heavy controllers are broken into clean sub-views (e.g. `LocalGamesView`, `CatalogGamesView`, `AppearanceSection`, `TypographyMediaSection`, `SoundStorageAboutSection`), ensuring all files remain under 300 lines with zero code duplication.

---

## 4. Key Project Files and Responsibilities

| File Path | Description |
| :--- | :--- |
| `lib/core/native/qsp_ffi.dart` | Low-level Dart FFI bindings to QSP C-API with verified struct layouts and type signatures. |
| `lib/core/native/qsp_utf16.dart` | Memory-safe UTF-16 / UTF-32 dual-width string converter and native struct populator. |
| `lib/core/helpers/sheet_helper.dart` | Root-navigator modal bottom sheet engine with Gaussian backdrop blur and interactive drag handle. |
| `lib/core/helpers/dialog_helper.dart` | Unified modal dialog engine featuring active morph shaping, scale transitions, and Gaussian backdrop blur. |
| `lib/core/helpers/html_processor.dart` | Sanitizer, video tag converter, and entity decoder for QSP HTML output. |
| `lib/core/helpers/path_picker_helper.dart` | Platform-aware native file/folder picker and Android Scoped Storage directory resolver. |
| `lib/core/media/qsp_media.dart` | Unified media rendering widget combining native `video_player` hardware video and image loaders. |
| `lib/core/media/qsp_ogv_video.dart` | WebAssembly Ogg Theora decoder hosted in a WebView for formats the platform decoder rejects. |
| `lib/core/theme/game_colors.dart` | Fixed high contrast reading surface colors for the game text panes. |
| `lib/core/media/qsp_html_view.dart` | Native HTML widget renderer with custom widget builder for video and image tags. |
| `lib/features/library/data/game_repository.dart` | 3-Tier import pipeline (zero-copy, isolate copy, archive unpacker) and isolate BFS scanner. |
| `lib/features/library/presentation/library_screen.dart` | Modular hub with swipeable PageView navigation connecting library, catalog, and inline settings. |
| `lib/features/library/presentation/views/local_games_view.dart` | Grid view for installed local games with instant play and context actions. |
| `lib/features/library/presentation/views/catalog_games_view.dart` | Remote catalog view with sort chips, search filter, and page bar. |
| `lib/features/settings/presentation/settings_screen.dart` | Expressive M3E settings container with horizontal category chips and swipeable section pages. |
| `lib/features/game/presentation/dialogs/game_dialogs_host.dart` | Central host dispatcher rendering engine dialogs via `QuestopiaDialog`. |

---

## 5. Verification and Quality Assurance

All features must maintain 0 static analysis issues before commit:

```powershell
flutter analyze
```

---

## 6. Git and Commit Message Standards

All commits in the repository must adhere to the following standards:

### 6.1. Subject Line Format
The first line (subject) must be concise and use standard conventional prefixes:
- `Feat: <short summary of new feature/capability>`
- `Fix: <short summary of bug fix or issue resolution>`
- `Ci: <short summary of CI/CD or workflow adjustments>`
- `Refactor: <short summary of code refactoring without feature changes>`
- `Docs: <short summary of documentation updates>`
- `Chore: <short summary of maintenance tasks or dependency bumps>`

> **Rule:** Never use markdown headers, hashes, or multi-line paragraphs in the commit subject line.

### 6.2. Commit Description / Body
- Must be separated from the subject line by a single blank line.
- Written strictly in **simple, accessible, plain English** using clear user-facing language.
- Use concise bullet points to explain what was changed and the user-facing benefit or reason.
- Avoid overcomplicated technical jargon where simple explanations suffice.

#### Example:
```text
Refactor: Unified context dialogs and morph-shaping animations

- Replaced scattered raw dialogs with showQuestopiaDialog and QuestopiaDialog.
- Added animated morph-shaping transition and backdrop blur to all dialogs.
- Modularized game dialog components to keep all files under 300 lines.
- Updated FLUTTER.md architecture documentation.
```
