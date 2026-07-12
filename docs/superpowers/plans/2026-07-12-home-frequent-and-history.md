# 首页常吃菜谱与历史记录精简 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 移除历史记录页的筛选入口，并在首页展示按记录次数排序的最近常吃菜谱。

**Architecture:** 在现有 `DemoData` 中添加一个纯排序函数，将“常吃”规则集中为可单测的数据逻辑。`HomeView` 调用该函数呈现横向卡片，`HistoryView` 直接使用不含 trailing 参数的现有标题组件。

**Tech Stack:** Swift 5、SwiftUI、XCTest、Xcode 项目 `BabyFoodDiary`。

## Global Constraints

- 使用已有 `DemoData.recipes` 的 `count` 和 `last` 字段，不引入持久化或第三方依赖。
- 首页展示 3 道菜谱，按 `count` 降序；次数相同时按 ISO 日期字符串 `last` 降序。
- 维持现有杏色主题、横向滚动卡片与底部安全间距。
- 不修改用户已有的未提交代码、工程配置或无关文件。

---

### Task 1: 可测试的常吃菜谱排序

**Files:**
- Modify: `BabyFoodDiary/BabyFoodDiary/App/BabyFoodDiaryApp.swift:29-44`
- Test: `BabyFoodDiary/BabyFoodDiaryTests/BabyFoodDiaryTests.swift:5-29`

**Interfaces:**
- Produces: `DemoData.frequentlyRecordedRecipes(from:limit:) -> [Recipe]`，供首页和单元测试使用。

- [ ] **Step 1: 写入失败的排序测试**

```swift
func testFrequentlyRecordedRecipesOrdersByCountThenMostRecentDate() {
    let recipes = [
        Recipe(name: "低频", categories: [], count: 2, last: "2024-05-22", days: 1, symbol: "leaf.fill", colors: [.green]),
        Recipe(name: "同次较早", categories: [], count: 8, last: "2024-05-10", days: 1, symbol: "leaf.fill", colors: [.green]),
        Recipe(name: "最高频", categories: [], count: 12, last: "2024-05-01", days: 1, symbol: "leaf.fill", colors: [.green]),
        Recipe(name: "同次较新", categories: [], count: 8, last: "2024-05-18", days: 1, symbol: "leaf.fill", colors: [.green])
    ]
    XCTAssertEqual(DemoData.frequentlyRecordedRecipes(from: recipes, limit: 3).map(\.name), ["最高频", "同次较新", "同次较早"])
}
```

- [ ] **Step 2: 运行测试并确认其因缺少 API 失败**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath BabyFoodDiary/build`

Expected: 编译失败，提示 `DemoData` 没有 `frequentlyRecordedRecipes` 成员。

- [ ] **Step 3: 实现最小排序 API**

```swift
static func frequentlyRecordedRecipes(from recipes: [Recipe], limit: Int = 3) -> [Recipe] {
    Array(recipes.sorted {
        $0.count == $1.count ? $0.last > $1.last : $0.count > $1.count
    }.prefix(limit))
}
```

- [ ] **Step 4: 运行测试并确认通过**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath BabyFoodDiary/build`

Expected: `TEST SUCCEEDED`，包括新增排序测试与既有测试。

- [ ] **Step 5: 提交数据逻辑和测试**

Run: `git add BabyFoodDiary/BabyFoodDiary/App/BabyFoodDiaryApp.swift BabyFoodDiary/BabyFoodDiaryTests/BabyFoodDiaryTests.swift`

Run: `git commit -m "feat: rank frequently recorded recipes"`

### Task 2: 首页模块与历史记录标题

**Files:**
- Modify: `BabyFoodDiary/BabyFoodDiary/App/BabyFoodDiaryApp.swift:103-118, 202-214`
- Test: `BabyFoodDiary/BabyFoodDiaryTests/BabyFoodDiaryTests.swift:5-41`

**Interfaces:**
- Consumes: `DemoData.frequentlyRecordedRecipes(from:limit:) -> [Recipe]`。
- Produces: 首页“最近常吃”横向菜谱卡片；历史记录页无筛选入口。

- [ ] **Step 1: 写入首页数据测试**

```swift
func testHomeFrequentlyRecordedRecipesUsesTheTopThreeRecipeNames() {
    XCTAssertEqual(
        DemoData.frequentlyRecordedRecipes(from: DemoData.recipes).map(\.name),
        ["西兰花鸡肉小软饼", "南瓜小米粥", "胡萝卜土豆泥"]
    )
}
```

- [ ] **Step 2: 运行测试确认数据契约**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath BabyFoodDiary/build`

Expected: `TEST SUCCEEDED`，数据契约确认首页应呈现的 3 个菜谱。

- [ ] **Step 3: 在首页接入常吃模块并移除历史筛选入口**

在 `HomeView` 的“好久没吃的菜谱”横向列表后、`ApricotCard` 前插入：

```swift
HStack { Text("最近常吃").font(.headline); Spacer(); Text("按记录次数").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 11) {
        ForEach(DemoData.frequentlyRecordedRecipes(from: DemoData.recipes)) { recipe in
            VStack(alignment: .leading, spacing: 7) {
                HomeRecipeThumbnail(recipe: recipe)
                Text(recipe.name).font(.subheadline.bold()).lineLimit(2)
                Text("已吃 \(recipe.count) 次").font(.caption.weight(.medium)).foregroundStyle(AppTheme.primary)
                Text("上次 \(recipe.last)").font(.caption2.weight(.medium)).foregroundStyle(AppTheme.secondaryInk)
            }.frame(width: 148, alignment: .leading).padding(10).background(.white).clipShape(RoundedRectangle(cornerRadius: 19)).apricotElevation(.card)
        }
    }.padding(.vertical, 2)
}
```

将 `HistoryView` 的 `PageTitle(title: "历史记录", trailing: "筛选")` 改为 `PageTitle(title: "历史记录")`。

- [ ] **Step 4: 运行完整测试和 Debug 构建**

Run: `xcodebuild test -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath BabyFoodDiary/build && xcodebuild build -project BabyFoodDiary/BabyFoodDiary.xcodeproj -scheme BabyFoodDiary -sdk iphonesimulator -derivedDataPath BabyFoodDiary/build`

Expected: 测试结果为 `TEST SUCCEEDED`，构建结果为 `BUILD SUCCEEDED`。

- [ ] **Step 5: 提交页面改动**

Run: `git add BabyFoodDiary/BabyFoodDiary/App/BabyFoodDiaryApp.swift BabyFoodDiary/BabyFoodDiaryTests/BabyFoodDiaryTests.swift`

Run: `git commit -m "feat: show frequently eaten recipes on home"`

## Final Verification

- [ ] 运行 `git diff --check`，确认无空白错误。
- [ ] 运行 Task 2 的完整测试与构建命令，保留成功输出作为验收依据。
- [ ] 检查首页模块位于“好久没吃的菜谱”和“重点观察”之间，标题为“最近常吃”，显示前三项及次数、上次日期。
- [ ] 检查历史记录页标题行不再传递 `trailing: "筛选"`。
