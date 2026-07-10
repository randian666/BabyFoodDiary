import XCTest
@testable import BabyFoodDiary

final class BabyFoodDiaryTests: XCTestCase {
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
}
