# AGENTS.md - Questopia AI Developer Guidelines

This document serves as the single source of truth for AI agents (Gemini, Claude, GPT, etc.) working on the Questopia-RE codebase.

---

## 1. Project Philosophy & Design Language
- **Material 3 Expressive Design**:
  - Consistent segmented-list morph shaping using `MorphingSurface` and `getGroupedItemShape(index, total)`.
  - Spring-animated interactive buttons (`MorphingButton`, `MorphingOutlinedButton`).
  - Dynamic drawer drag handles (`CustomDrawerHandle`) on all bottom sheets.
  - Pure AMOLED Black (`#000000`) and True Neutral Monochrome color themes.
- **Strict Anti-Slop Discipline**:
  - **Zero Emoji Policy**: No emojis in any UI labels, titles, dialogs, buttons, or logs.
  - **Zero Redundant Subtitles**: Avoid repeating parent titles in subtitles or placeholder texts.
  - **Full Localization**: All user-facing strings must be localized in `values/strings.xml` (English) and `values-ru/strings.xml` (Russian).

---

## 2. Architecture & Code Modularity Rules
- **Keep Files Lean & Focused**:
  - Keep Compose UI files under 300–400 lines whenever possible.
  - Separate concerns into dedicated files:
    - Dialogs in `GameDialogs.kt`
    - Option drawers in `InGameOptionsMenuSheet.kt`
    - Save/Load slot management in `SaveSlotsSheet.kt`
    - Media handling in `GameMediaHelpers.kt`
    - WebView & item rendering in `GameWebViewComponents.kt`
- **State Hoisting**:
  - Never declare sub-sheet display states (`showSlotsSheetMode`, `showCheatModesSheet`, `showRestartDialog`) inside a composable that unmounts before the sub-sheet renders. Always hoist states to the parent coordinator (`GameMainCompose`).

---

## 3. QSP Engine & Web Interaction Rules
- **Multi-line `exec:` Execution**:
  - QSP `exec:` commands often span multiple lines and can contain Cyrillic or special characters.
  - `HtmlProcessor.java` encodes multi-line `exec:` blocks via `Pattern.DOTALL` and Base64 encoding.
  - `GameViewModel.java` decodes `base64:` URIs and replaces HTML breaks (`<br>`) with newlines (`\n`) before executing into native `QSPLib`.
- **WebView Zoom & Scroll Persistence**:
  - Retain zoom level and scroll position during recompositions by using `webView.tag != htmlContent` before reloading data.
- **Reverse Image Search**:
  - Upload raw image bytes as multipart/form-data (`upfile`) to `https://yandex.com/images/search?rpt=imageview&format=json...` and extract the target URL from `blocks[0].params.url`.

---

## 4. Build & Verification Commands
- **Android Build & ADB Push**:
  ```bash
  python build.py android
  ```
- **Desktop Build**:
  ```bash
  .\gradlew.bat :desktop:run
  ```
- **Static Analysis**:
  ```bash
  .\gradlew.bat lint
  ```
