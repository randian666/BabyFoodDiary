# Apricot Vibrant iOS UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a compileable iOS 17+ SwiftUI app that presents the five static screens from the Apricot Vibrant HTML reference.

**Architecture:** A lightweight root `App` owns only the selected tab and record-sheet visibility. Reusable colors, demo fixtures, pills, cards, food thumbnails, and the floating tab bar live in focused support files; each screen is a standalone SwiftUI view consuming the immutable fixtures.

**Tech Stack:** Swift 6, SwiftUI, SF Symbols, Xcode 26.6 / iOS 17 SDK.

## Global Constraints

- Create a native SwiftUI iOS app with a minimum deployment target of iOS 17.0.
- Recreate `style-variants/05-apricot-vibrant-full.html` as a warm static UI, primarily for a 390 × 844pt iPhone.
- Do not add persistence, network calls, image pickers, search/filter behavior, business calculations, or medical claims.
- Only local `@State` may drive static tab and record-screen presentation.
- Use sample fixture data and SF Symbols only; do not add package dependencies.

---

### Task 1: Create the buildable SwiftUI application shell and style tokens

**Files:**
- Create: `BabyFoodDiary/BabyFoodDiary.xcodeproj/project.pbxproj`
- Create: `BabyFoodDiary/BabyFoodDiary/App/BabyFoodDiaryApp.swift`
- Create: `BabyFoodDiary/BabyFoodDiary/Design/AppTheme.swift`
- Create: `BabyFoodDiary/BabyFoodDiaryTests/BabyFoodDiaryTests.swift`

**Interfaces:**
- Produces: `BabyFoodDiaryApp: App` and `AppTheme` color/spacing constants used by all screen files.

- [ ] **Step 1: Write a failing test for the palette contract**

```swift
import XCTest
@testable import BabyFoodDiary

final class BabyFoodDiaryTests: XCTestCase {
    func testPrimaryPaletteUsesApricotReferenceValues() {
        XCTAssertEqual(AppTheme.primaryHex, "FF7A3D")
        XCTAssertEqual(AppTheme.backgroundHex, "FFF8F2")
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: FAIL because the project and `AppTheme` do not exist.

- [ ] **Step 3: Create the Xcode project and minimal app implementation**

Create an iOS application target and a unit-test target in `project.pbxproj`, with sources under `BabyFoodDiary/BabyFoodDiary`. Implement the token file with this public contract:

```swift
import SwiftUI

enum AppTheme {
    static let backgroundHex = "FFF8F2"
    static let primaryHex = "FF7A3D"
    static let background = Color(red: 1, green: 0.973, blue: 0.949)
    static let surface = Color.white
    static let ink = Color(red: 0.239, green: 0.141, blue: 0.090)
    static let secondaryInk = Color(red: 0.612, green: 0.471, blue: 0.376)
    static let primary = Color(red: 1, green: 0.478, blue: 0.239)
    static let warmSurface = Color(red: 1, green: 0.941, blue: 0.894)
    static let success = Color(red: 0.18, green: 0.62, blue: 0.36)
    static let warning = Color(red: 0.91, green: 0.57, blue: 0.08)
    static let danger = Color(red: 0.91, green: 0.31, blue: 0.36)
    static let cardCornerRadius: CGFloat = 22
}
```

Use `BabyFoodDiaryApp` to launch `RootView()` (defined in Task 3).

- [ ] **Step 4: Run the test to verify it passes**

Run: same command as Step 2.

Expected: PASS with one test executed.

- [ ] **Step 5: Commit**

```bash
git add BabyFoodDiary
git commit -m "feat: scaffold SwiftUI baby food diary app"
```

### Task 2: Add fixture models and reusable Apricot-style components

**Files:**
- Create: `BabyFoodDiary/BabyFoodDiary/Models/DemoData.swift`
- Create: `BabyFoodDiary/BabyFoodDiary/Components/ApricotComponents.swift`
- Modify: `BabyFoodDiary/BabyFoodDiaryTests/BabyFoodDiaryTests.swift`

**Interfaces:**
- Consumes: `AppTheme`.
- Produces: `Recipe`, `MealRecord`, `Reaction`, `DemoData.recipes`, `ApricotCard`, `StatusPill`, `FoodThumbnail`, `SectionHeader`.

- [ ] **Step 1: Write a failing fixture test**

```swift
func testDemoRecipesContainTheThreeHomeRecommendations() {
    XCTAssertEqual(DemoData.recommendations.map(\.name), [
        "西兰花鸡肉小软饼", "南瓜小米粥", "胡萝卜土豆泥"
    ])
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: FAIL because `DemoData` is absent.

- [ ] **Step 3: Implement immutable fixture models and components**

Define `Recipe` with `name`, `categories`, `recordCount`, `lastRecorded`, `daysSinceLastMeal`, `symbol`, and `gradient`. Define `Reaction` (`like`, `neutral`, `refused`, `allergy`) with a Chinese title, SF Symbol, and theme color. Populate the named recommendations plus the additional recipes appearing in the reference.

Implement components using this shape:

```swift
struct ApricotCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(16).background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .shadow(color: AppTheme.primary.opacity(0.10), radius: 12, y: 6)
    }
}
```

`FoodThumbnail` must present the given SF Symbol on a two-color gradient; `StatusPill` must present a compact rounded label; `SectionHeader` must offer a title and optional trailing content.

- [ ] **Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add BabyFoodDiary/BabyFoodDiary BabyFoodDiary/BabyFoodDiaryTests
git commit -m "feat: add demo data and reusable UI components"
```

### Task 3: Build root navigation, floating tab bar, Home, and Recipe Library

**Files:**
- Create: `BabyFoodDiary/BabyFoodDiary/App/RootView.swift`
- Create: `BabyFoodDiary/BabyFoodDiary/Components/FloatingTabBar.swift`
- Create: `BabyFoodDiary/BabyFoodDiary/Screens/HomeView.swift`
- Create: `BabyFoodDiary/BabyFoodDiary/Screens/RecipeLibraryView.swift`
- Modify: `BabyFoodDiary/BabyFoodDiaryTests/BabyFoodDiaryTests.swift`

**Interfaces:**
- Consumes: `DemoData`, `Recipe`, `ApricotCard`, `StatusPill`, `FoodThumbnail`, `SectionHeader`.
- Produces: `AppTab`, `RootView`, `FloatingTabBar` and the first two screen views.

- [ ] **Step 1: Write a failing navigation-state test**

```swift
func testAppTabHasFourPrimaryDestinations() {
    XCTAssertEqual(AppTab.allCases, [.home, .recipes, .analysis, .history])
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: FAIL because `AppTab` is absent.

- [ ] **Step 3: Implement the root and two screens**

Create `enum AppTab: CaseIterable { case home, recipes, analysis, history }` and use a root `ZStack` with `@State private var selectedTab: AppTab = .home` and `@State private var isRecording = false`. Switch content by selected tab and show `MealRecordView` with `.sheet(isPresented:)`.

Build the custom floating bar with four labeled SF Symbol tabs and a center orange circular plus button. Home must include the baby identity card, three overview metrics, a horizontal recommendation row, and the observation card. Recipe Library must include visual-only search, category chips, sort row, and recipe cards based on the HTML content. Make page content scrollable behind the persistent tab bar.

- [ ] **Step 4: Run test and compile verification**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: PASS; app and test targets build.

- [ ] **Step 5: Commit**

```bash
git add BabyFoodDiary
git commit -m "feat: add home and recipe library interface"
```

### Task 4: Build analysis, history, and meal-record static screens

**Files:**
- Create: `BabyFoodDiary/BabyFoodDiary/Screens/AnalysisView.swift`
- Create: `BabyFoodDiary/BabyFoodDiary/Screens/HistoryView.swift`
- Create: `BabyFoodDiary/BabyFoodDiary/Screens/MealRecordView.swift`

**Interfaces:**
- Consumes: all components from Task 2 and `AppTab` / `RootView` from Task 3.
- Produces: `AnalysisView`, `HistoryView`, `MealRecordView` for the final three reference screens.

- [ ] **Step 1: Write failing view-construction tests**

```swift
func testStaticScreenViewsCanBeConstructed() {
    _ = AnalysisView()
    _ = HistoryView()
    _ = MealRecordView()
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: FAIL because the three view types do not exist.

- [ ] **Step 3: Implement three static SwiftUI screens**

`AnalysisView` must show the 14-day title, a ring visualization using `Circle().trim(from:to:)`, reaction legend pills, and recipe acceptance cards. `HistoryView` must show a date-filter affordance and grouped cards for 今天、昨天 and earlier sample dates. `MealRecordView` must be a scrollable form-style screen with a back/dismiss button, date/meal rows, selected recipe, photo placeholder, four reaction choices, notes placeholder, and a full-width orange save-style button. None of these controls mutate fixtures.

- [ ] **Step 4: Run tests and build**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add BabyFoodDiary
git commit -m "feat: add analysis history and meal record screens"
```

### Task 5: Visual QA at the target phone size

**Files:**
- Modify if needed: screen and component files under `BabyFoodDiary/BabyFoodDiary`

**Interfaces:**
- Consumes: complete app target.
- Produces: final compileable UI matching the supplied visual direction.

- [ ] **Step 1: Build for the selected simulator**

Run: `xcodebuild build -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 2: Launch and inspect each tab at 390 × 844pt**

Run the app in an iPhone simulator, switch across all tabs, and present the record sheet. Check that no title, card, chip, or floating bar is clipped; ensure background, card radius, warm shadow, and orange active state match the HTML reference.

- [ ] **Step 3: Correct only visual regressions found during inspection**

Keep all controls presentation-only. Rebuild after any adjustment.

- [ ] **Step 4: Run final build and tests**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add BabyFoodDiary
git commit -m "fix: refine apricot vibrant UI layout"
```
