import XCTest
@testable import BabyFoodDiary

final class BabyFoodDiaryTests: XCTestCase {
    func testPrimaryPaletteUsesApricotReferenceValues() {
        XCTAssertEqual(AppTheme.primaryHex, "FF7A3D")
        XCTAssertEqual(AppTheme.backgroundHex, "FFF8F2")
    }
}
