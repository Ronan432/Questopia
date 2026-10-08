# FLUTTER.md — Questopia Flutter Handover & Development Log

> **Last Update:** October 8, 2026 (Custom Windows TitleBar, Material You Logo & Window TitleBar Integration)  
> **Branch:** `flutter`  
> **`flutter analyze`:** CLEAN (0 issues)  

> ⚠️ **CRITICAL DOCUMENTATION AND EXECUTION RULES (NEVER DELETE OR TRUNCATE):**  
> 1. **HISTORY MUST NEVER BE DELETED:** NO historical information, items, or development details in this document can be deleted, shortened, or summarized. All new developments must be appended at the end as new numbered items (e.g., 2.30, 2.31...).  
> 2. **FLUTTER TEST PROHIBITION:** Running the `flutter test` command during development and validation processes is STRICTLY PROHIBITED. All future AI agents and developers must adhere to this rule.  
> 3. **STATIC STRING / HARDCODED TEXT PROHIBITION:** No text, title, subtitle, dialog, setting, or button label in the UI can be written as a hardcoded static string. All texts must be added to `app_en.arb` and `app_ru.arb` and retrieved dynamically via `AppLocalizations.of(context)!`.  
> 4. **ENGLISH CODE COMMENTS RULE:** All code comments within source files (`.dart`, `.cpp`, `.rs`, `.kt`, etc.) must be written exclusively in English. No Turkish comments are permitted in the codebase.

---

## 1. Project Overview

Questopia-RE is an interpreter + library application for QSP (Quest Soft Player) interactive fiction games. The project has been fully migrated to a **Flutter-first** architecture.

- **Package Name:** `com.questopia.re`
- **Version:** `3.25.5+202505`
- **Min SDK:** Android API 26
- **Flutter / Dart:** Flutter 3.44.6 / Dart 3.12.2 (SDK Constraint: `>=3.1.0 <4.0.0`)
- **Font Family:** `Netflix Sans` (Across the entire app and WebView CSS)
- **Language Support:** Turkish removed entirely; defaults to global English/Russian.
- **Architecture:** Riverpod `StateNotifierProvider`, Layered Architecture (Core, Features, Theme, Providers).
- **Design:** Material 3 Expressive (`material_3_expressive` 1.0.9), dynamic coloring with `dynamic_color` integration, responsive grid layouts.

---

## 2. Complete Development History & Summary of Changes

### 2.1. Complete Removal of Turkish Language Support
- Removed `lib/core/l10n/app_tr.arb` and `lib/core/l10n/app_localizations_tr.dart`.
- Cleaned up `tr` imports and locale delegation from `app_localizations.dart`.
- Removed `lang == 'tr'` checks from `game_media.dart`.
- Updated unit tests (`test/game_media_test.dart` and `test/widget_test.dart`).

### 2.2. Typography and Font Updates
- Set default font family to `Netflix Sans` in `QuestopiaTheme`.
- Added `"Netflix Sans"` prefix to WebView CSS font-family in `GameScreen`.

### 2.3. Settings Screen Redesign & Expressive M3E Enhancements (`SettingsScreen`)
- **Category Buttons (%30 Enlarged + Morph Shaping):** Reimplemented category menu buttons using `M3EButton.icon` with custom height (`52dp`) and expressive spring animations.
- **Switch Controls & Checkmarks (`M3ESwitch`):** Integrated `M3ESwitch` with `selectedIcon: const Icon(Icons.check, size: 16)`.
- **Cleaned Subtitles:** Removed subtitle text below secondary options for a clean, single-line modern list.
- **Dynamic Color Scheme (`dynamic_color`):** Implemented `_m3eColorSchemeFrom` to bind dynamic colors seamlessly to `M3ETheme`.

### 2.4. Remote Catalog, Download & RAR Archive Extraction Fixes (`GameRepository` & `RemoteGame`)
- **Modern Web Catalog Parser (`parseWebCatalogHtml`):** Parsed `https://qsp.org/games` directly for accurate cover poster URLs and game metadata.
- **Progressive Poster Loading & Caching:** Added fallback image loading chains and cached downloaded posters locally as `poster.jpg`.
- **Redirect Resolution & Archive Extraction:** Integrated `tar -xf`, Rust FFI (`rust_extract_archive`), and ZipDecoder to resolve archive extraction errors (including `.rar` files).

### 2.5. Catalog Sorting, Filtering & Pagination (`LibraryScreen` & `LibraryProvider`)
- **Sorting & Filters:** Added Comments, Name, Updated, Added, Likes, Downloads, Plays sorting options and language filters.
- **Pagination:** Supported `https://qsp.org/games?sort=...&page=X` with high-contrast pagination buttons.
- **M3E Cards & Search Bar:** Designed expressive cover cards and pill-shaped search bars (`surfaceContainerHigh`).

### 2.6. Game Screen, Options Menu & Media Interception (`GameScreen`)
- **Advanced Options Menu (`_showOptionsMenu`):** Styled game options with `SegmentedListSection` cards matching the settings screen.
- **WebView2 Loading Fix:** Configured `InAppWebViewInitialData` with base URL `https://questopia.local/` to eliminate black screens.
- **Case-Insensitive Media Resolution (`_interceptMedia`):** Added `_resolveCaseInsensitiveFile` to handle backslashes and case-insensitive asset paths.

### 2.7. Settings Cards & Row Spacing (%30 Expansion)
- Expanded row padding (`minVerticalPadding: 18`), icons (24px), and titles (`fontSize: 16`) for touch/click comfort.

### 2.8. Game Player KMP Restoration, 3-Tab Bottom Navigation & Heavy Debug Logging
- **3-Tab Bottom Navigation (`NavigationBar` / `NavigationRail`):** Story (mainDesc), Status (varsDesc), and Inventory (objects) tabs with notification badges and loading indicators.
- **Heavy Debug Logging:** Added comprehensive FFI call, callback, and media interception logging.

### 2.9. SAVES Menu Redesign, M3E Morph Shaping & Save-Load Tabs (`SaveSlotsSheet`)
- Split save and load tabs with M3E morph shaping buttons and segmented list styling.

### 2.10. MANAGE_EXTERNAL_STORAGE Permission & Questopia Logo Integration
- Added `MANAGE_EXTERNAL_STORAGE` permissions and integrated `assets/images/app_logo.png` across Android mipmap folders.

### 2.11. In-App FilesystemPicker Configuration (`path_picker_helper.dart`)
- Integrated `FilesystemPicker` for in-app internal folder exploration and game importing.

### 2.12. `flutter test` Prohibition Rule
- Formally documented the strict rule against running `flutter test`.

### 2.13. QSP Game Startup (Location Execution) Fix (`game_engine_provider.dart`)
- Added `ffi.restartGame(refresh: true)` right after loading game data to execute initial location code and populate game state.

### 2.14. Manual Command Button & Local Library Caching
- Added `Type Command` dialog option and cached local game scans to prevent redundant disk reads.

### 2.15. Infinite Dialog Loop Fix & Re-Render Optimization
- Integrated `closeDialog()` on dismiss and added state-change checks in `_refreshState()` to avoid redundant rebuilds.

### 2.16. %100 Monochromatic Color Scheme & Bottom Sheet Overflow Fix
- Added pure grayscale monochrome palette and wrapped settings bottom sheets in `SingleChildScrollView` to prevent `RenderFlex` overflows.

### 2.17. Case-Insensitive File Resolution & SHOWIMAGE Fix
- Handled empty image events and case-insensitive asset lookups.

### 2.18. Dynamic (Monet) Theme Option & UI Cleanup
- Restored Dynamic Monet wallpaper theme option and removed redundant preview cards from color accent picker.

### 2.19. Settings Modularization & Slider Alignment (`SettingsPickerSheets` & `SheetHelper`)
- Modularized pickers into `SettingsPickerSheets` and constrained bottom sheet maximum height via `SheetHelper`.

### 2.20. Lana Monochrome Accent Re-Addition
- Restored `monochrome` accent option across ARB files and picker sheets.

### 2.21. %100 Dynamic Localization Enforcement
- Ensured all setting screen texts are fully localized via `AppLocalizations.of(context)!`.

### 2.23. Custom Window TitleBar Button Styling & Instant Click Response (`WindowTitleBar`)
- Styled window control buttons with rectangular shapes (`BorderRadius.zero`, `NoSplash`) and integrated `DragToMoveArea` for zero-latency dragging and clicking.

### 2.24. Desktop-Specific Left-Side `NavigationRail` (`LibraryScreen`)
- Implemented responsive desktop navigation rail shifting from bottom navigation bar on Windows, macOS, and Linux.

### 2.25. Navigation Rail Settings & Confirmed Add Game Integration (`LibraryScreen`)
- Added 4 destinations to desktop `NavigationRail`: Library, Catalog, Settings, and Add Game with a 1-step confirmation dialog before importing.

### 2.26. Desktop Inline Settings & M3E Morph Shaping Buttons (`LibraryScreen`)
- Configured instant inline settings loading on desktop without push animations, hidden top-right actions in desktop mode, and M3E morph shaping dialog buttons.

### 2.27. Double TitleBar Bug Fix (`SettingsScreen` & `LibraryScreen`)
- Added `isInline` parameter to `SettingsScreen` to eliminate duplicate titlebars when loaded inline on desktop.

### 2.28. TitleBar Button Performance Optimization (`WindowTitleBar`)
- Replaced slow `FutureBuilder` with synchronous `WindowListener` state tracking (`_isMaximized`) for instant button feedback.

### 2.29. Sidebar Logo Integration & Modal Sheet Boundary Restriction (`WindowTitleBar` & `SheetHelper`)
- Positioned `QuestopiaLogoIcon` cleanly in the top custom title bar (`WindowTitleBar`) and constrained modal bottom sheets so they never overlap the title bar.

### 2.30. Floating Pill Style Bottom Navigation (`LibraryScreen`)
- **Profile Pill Bottom Navigation:** Configured mobile/Android bottom navigation bar (`NavigationBar`) with a modern floating pill / capsule style (rounded container with side margins, soft shadow, and fully rounded pill corners matching Material 3 Expressive guidelines).

---

## 3. Verification Status

```powershell
flutter analyze   # CLEAN (0 issues)
```

- All functionalities are 100% verified at the code analysis level.
