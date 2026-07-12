# 设置页与 JSON 导出 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a warm Apricot-style settings screen for baby details and system-shareable JSON export.

**Architecture:** `RootView` owns settings presentation; `SettingsView` keeps editable data in local state. `ExportDocument` writes existing fixture data to temporary JSON and `ActivityShareSheet` shares it.

**Tech Stack:** SwiftUI, Foundation, UIKit, iOS 17+.

## Global Constraints

- Keep 22pt cards, warm orange soft shadows, and 44pt touch targets.
- No persistence, networking, photo library, or third-party dependencies.
- Export UTF-8 `baby-food-diary-export.json` with `baby`, `recipes`, and `mealRecords` keys.

---

### Task 1: JSON export and share adapter

**Files:**
- Modify: `BabyFoodDiary/BabyFoodDiary/App/BabyFoodDiaryApp.swift`
- Modify: `BabyFoodDiary/BabyFoodDiaryTests/BabyFoodDiaryTests.swift`

**Interfaces:** Produces `ExportDocument.makeURL() throws -> URL` and `ActivityShareSheet`.

- [ ] Write a failing test that obtains `ExportDocument.makeURL()`, decodes its JSON object, and asserts `baby`, `recipes`, and `mealRecords` keys exist.
- [ ] Run `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`; expect an undefined-type failure. If Simulator is unavailable, record it.
- [ ] Implement export with `JSONSerialization.data(withJSONObject:options:)`, write atomically to `FileManager.default.temporaryDirectory.appendingPathComponent("baby-food-diary-export.json")`, and wrap `UIActivityViewController` in `UIViewControllerRepresentable`.
- [ ] Run `xcodebuild build -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/BabyFoodDiaryDerivedData CODE_SIGNING_ALLOWED=NO`; expect `BUILD SUCCEEDED`.
- [ ] Commit the source and test changes with message `feat: add JSON export document`.

### Task 2: Settings entry point and screen

**Files:**
- Modify: `BabyFoodDiary/BabyFoodDiary/App/BabyFoodDiaryApp.swift`

**Interfaces:** Consumes `ExportDocument.makeURL()` and `ActivityShareSheet`; produces `SettingsView`.

- [ ] Write a failing test that constructs `SettingsView()`.
- [ ] Run the same test command; expect the type to be undefined.
- [ ] Add `isSettingsPresented` to `RootView`, replace Home's bell with a labeled 44pt gear button, and present `SettingsView` full screen.
- [ ] Build `SettingsView` with close control, gradient avatar, local editable nickname/month-age/gender fields, data-management description, primary “导出 JSON” button, `ActivityShareSheet`, and inline export error text.
- [ ] Run the generic iOS build command above; expect `BUILD SUCCEEDED`.
- [ ] Commit source changes with message `feat: add baby settings screen`.
