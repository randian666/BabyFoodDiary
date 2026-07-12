import XCTest
@testable import BabyFoodDiary

final class BabyFoodDiaryTests: XCTestCase {
    func testFrequentlyRecordedRecipesOrdersByCountThenMostRecentDate() {
        let recipes = [
            Recipe(name: "低频", categories: [], count: 2, last: "2024-05-22", days: 1, symbol: "leaf.fill", colors: [.green]),
            Recipe(name: "同次较早", categories: [], count: 8, last: "2024-05-10", days: 1, symbol: "leaf.fill", colors: [.green]),
            Recipe(name: "最高频", categories: [], count: 12, last: "2024-05-01", days: 1, symbol: "leaf.fill", colors: [.green]),
            Recipe(name: "同次较新", categories: [], count: 8, last: "2024-05-18", days: 1, symbol: "leaf.fill", colors: [.green])
        ]

        XCTAssertEqual(
            DemoData.frequentlyRecordedRecipes(from: recipes, limit: 3).map(\.name),
            ["最高频", "同次较新", "同次较早"]
        )
    }

    func testHomeFrequentlyRecordedRecipesUsesTheTopThreeRecipeNames() {
        XCTAssertEqual(
            DemoData.frequentlyRecordedRecipes(from: DemoData.recipes).map(\.name),
            ["西兰花鸡肉小软饼", "南瓜小米粥", "胡萝卜土豆泥"]
        )
    }

    func testPrimaryPaletteUsesApricotReferenceValues() {
        XCTAssertEqual(AppTheme.primaryHex, "FF7A3D")
        XCTAssertEqual(AppTheme.backgroundHex, "FFF8F2")
    }

    func testDemoRecipesContainTheThreeHomeRecommendations() {
        XCTAssertEqual(DemoData.recommendations.map(\.name), [
            "西兰花鸡肉小软饼",
            "南瓜小米粥",
            "胡萝卜土豆泥"
        ])
    }

    func testExportDocumentContainsAllTopLevelCollections() throws {
        let url = try ExportDocument.makeURL()
        let data = try Data(contentsOf: url)
        let document = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertNotNil(document["baby"])
        XCTAssertNotNil(document["recipes"])
        XCTAssertNotNil(document["mealRecords"])
    }

    func testSettingsViewCanBeConstructed() {
        _ = SettingsView()
    }
}
