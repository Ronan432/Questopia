# CLEANUP.md — Code Cleanup Rules & Procedure

> **Status:** Reference document. Nothing in this file runs on its own.
> **Invocation:** Cleanup happens **only when the user explicitly asks for it.**
> **Related:** [FLUTTER.md](FLUTTER.md) — architecture and standing project rules.

---

## 0. When To Run A Cleanup

**Do not start a cleanup on your own initiative.** A cleanup is a refactor, not a
bug fix, and refactors change files that already work.

Run one only when the user says something equivalent to:

- "clean up the code"
- "clear out dead code"
- "do a code review / audit"
- "reduce file sizes"
- "find duplication"
- names a specific file and asks for it to be simplified

If the user asks for a feature, build that feature. Do not bundle unrelated
cleanup into the same change.

---

## 1. Non Negotiable Guardrails

These override every other instruction in this document.

| # | Rule |
|---|---|
| 1.1 | **Never push unless asked.** Writing code is not permission to push. |
| 1.2 | **Never delete on a hunch.** Every removal is proven by a reference count first. |
| 1.3 | **Never change behaviour while cleaning.** Wiring up an unused setting, fixing a wrong value, or altering a threshold is a **feature change**, not cleanup. Leave it, report it. |
| 1.4 | **Never touch what the user did not ask about.** Leave unrelated working tree edits alone. |
| 1.5 | **Never touch generated files by hand.** `app_localizations*.dart` is produced by `flutter gen-l10n`. Edit the `.arb` files instead. |
| 1.6 | **Never restructure risky subsystems casually.** Anything touching the native FFI layer, the asset server, or the WebView player stays untouched unless the request names it. |
| 1.7 | **`flutter analyze` must be clean before and after.** Any new warning fails the cleanup. |
| 1.8 | **`flutter test` is prohibited** (FLUTTER.md rule 1). Verify with reference counting and builds instead. |

---

## 2. Procedure

### Step 1 — Establish the baseline

```powershell
flutter analyze          # must be clean before starting
git status --short       # note what is already modified; do not touch it
```

### Step 2 — Measure before touching anything

```powershell
# Files over the 300 line limit
Get-ChildItem lib -Recurse -Filter *.dart |
  ForEach-Object { $n = (Get-Content $_.FullName | Measure-Object -Line).Lines
                   if ($n -gt 300) { [pscustomobject]@{ Satir = $n
                     Dosya = $_.FullName } } } | Sort-Object Satir -Descending

# Reference count for a symbol, excluding the file that defines it
$files = Get-ChildItem lib -Recurse -Filter *.dart | Where-Object { $_.Name -ne 'target.dart' }
foreach ($s in @('symbolName', 'ClassName')) {
  $n = 0; foreach ($f in $files) {
    $n += (Select-String -Path $f.FullName -Pattern "\b$s\b" -ErrorAction SilentlyContinue).Count }
  "$s -> $n"
}
```

**A symbol with a non zero count is used. Stop there.**

### Step 3 — Classify every candidate

| Class | Meaning | Action |
|---|---|---|
| **Dead** | Zero references anywhere | Safe to delete |
| **Live but repeated** | Two or more copies of identical logic | Extract to a shared helper |
| **Live constant repeated** | Same literal written several times | Extract to one named constant |
| **Bug** | Wrong value, dead branch, broken signature | Report separately, fix only if asked |
| **Feature gap** | Setting exists but nothing reads it | Report, do not wire up |
| **Risky** | FFI, native binding, recently working feature | Leave alone |

### Step 4 — Delete dead code only

Delete whole functions and fields. Never leave an empty body, a commented out
copy, or a "reserved for future" stub.

### Step 5 — Consolidate only exact duplicates

Consolidate only when the copies are byte identical or differ solely in a name.
Verify the values match before merging:

```powershell
Select-String -Path a.dart -Pattern '0xFF[0-9A-F]{6}' |
  ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
```

If two lists hold different sets of values, **do not merge them.** That is a
design decision, not a duplicate.

### Step 6 — Verify

```powershell
flutter analyze
flutter build apk --release --target-platform android-arm64 --split-per-abi --tree-shake-icons
flutter build windows --release --tree-shake-icons
```

### Step 7 — Report honestly

State what was removed, what was deliberately left, and what was found but not
touched. Never claim a cleanup changed behaviour when it did not.

---

## 3. What Counts As Dead Code

Proven by reference count of **zero** across `lib/`.

- Functions and getters never called
- Classes never instantiated
- Fields assigned but never read
- Private helpers left behind by a replaced subsystem
- Aliases kept "for backwards compatibility" with no remaining caller
- Enums with no case ever switched on

A method that is only referenced from a test file that itself tests dead code is
still dead. A method referenced from a platform channel, a build file, or an
FFI symbol lookup is **not** dead.

### Dead Code Found In This Project (as of the last audit)

Recorded so the next cleanup does not rediscover it from scratch.

| Location | What |
|---|---|
| `html_processor.dart` | `wrapVideos`, `videoBootstrapScript`, `ogvBootstrapScript`, `stripImageTags`, `mimeTypeForPath` |
| `qsp_models.dart` | `QspVar` |
| `qsp_path_resolver.dart` | `updatePreloadedIndex` |
| `game_repository.dart` | `hideGame`, `writeGameInfo` |

---

## 4. Duplication Inventory

Known repeats, grouped by payoff. Extract from the top down.

| Priority | Duplication | Locations |
|---|---|---|
| P0 | Path resolution implemented four times | `game_engine_provider`, `qsp_path_resolver`, `game_message_dialog`, `game_audio` |
| P0 | Sheet skeleton repeated six times | `settings_picker_sheets` |
| P0 | Single key value copy written thirty three times | `settings_provider` |
| P0 | Registration epilogue repeated five times | `game_repository` |
| P0 | HTML tag stripping regex repeated across files | `game_repository`, `game_screen`, dialogs |
| P0 | Header pill widget exists in three versions | `sheet_helper`, `settings_picker_sheets`, `poster_menu_sheet` |
| P1 | Desktop platform detection repeated eight times | across the app |
| P1 | Grid layout block identical in two views | `local_games_view`, `catalog_games_view` |
| P1 | Selectable chip built twice | `catalog_filter_bar`, `settings_screen` |
| P1 | Launch game flow duplicated | `local_games_view`, `catalog_games_view` |
| P1 | Text field decoration repeated three times | cheat sheets |
| P2 | User agent and referer header block repeated | `game_repository`, `game_poster`, `game_media` |
| P2 | Typeface and font size limits written as literals | `questopia_theme`, `game_screen`, picker |

### Extraction Rules

- One source of truth per value
- Name the constant after its meaning, not its type
- Put shared helpers in `lib/core/helpers/` or `lib/core/widgets/`
- Keep every new file under 300 lines
- **If two copies differ in any value, do not merge them**

---

## 5. Known Issues That Are NOT Cleanup

Report these, do not fix them during a cleanup pass.

| Severity | Issue | Location |
|---|---|---|
| Critical | Loopback media server serves any local path without an allow list | `ogv_asset_server` |
| High | Save event handler loads instead of saving | `game_engine_provider` |
| High | Missing mounted guard after await can throw | `library_provider` |
| High | Path resolver rebuilt on every frame | `game_media_viewer` |
| High | Download stream handle not closed on failure | `game_repository` |
| Medium | Sound setting has no effect | `game_audio` |
| Medium | Video mute setting has no effect | `qsp_media` |
| Medium | Typeface setting never reaches the game text | `game_screen` |
| Medium | Hardcoded user facing strings not localized | many files |
| Medium | Empty catch blocks swallow engine errors | `qsp_callbacks` and others |

Fixing any of these changes behaviour and therefore needs its own explicit
request.

---

## 6. File Size Policy

| Range | Action |
|---|---|
| Under 300 lines | Fine |
| 300 to 500 | Split when touching the file anyway |
| Over 500 | Must be split |

Split along responsibility, not by arbitrary line count. A natural split point
is a distinct concern: a parser, a downloader, a set of picker screens.

Never split a file purely to satisfy the limit if the result would scatter
related logic across many small files with no clear owner.

---

## 7. Commit Format

Follow FLUTTER.md rule 10.

```
Chore: Remove code left behind by the old video approach

- Deleted the leftover web view helper functions that nothing called anymore.

- Deleted a model class and a helper method that were never used.

- The library is about 200 lines shorter and the app size is unchanged.
```

- Prefix is one of `Feat`, `Fix`, `Chore`, `Refactor`, `Docs`, `Ci`
- One line, no markdown, no headers
- Blank line, then short plain English bullets
- Explain the user visible benefit, not the mechanics
- Never use the ampersand character

Keep cleanup commits separate from feature commits. Do not mix them.

---

## 8. Final Checklist

- [ ] User explicitly asked for cleanup
- [ ] `flutter analyze` clean before and after
- [ ] Every deletion proven by a zero reference count
- [ ] No behaviour changed anywhere
- [ ] No generated file edited by hand
- [ ] Risky subsystems untouched
- [ ] Unrelated working tree changes left alone
- [ ] New or edited files under 300 lines
- [ ] Android and Windows builds succeed
- [ ] Nothing pushed unless asked
- [ ] Report states what was left out and why

---

## 9. Summary

Cleanup is a **surgical, verified, behaviour preserving** activity. It is not an
opportunity to redesign. When in doubt, leave the code alone and report it.

**The measure of a good cleanup is not how much was deleted, it is how little
broke.**