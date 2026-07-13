import XCTest
@testable import BabyFoodDiary

final class BabyFoodDiaryTests: XCTestCase {
    func testFirstIngredientWins() {
        XCTAssertEqual(FoodIconCatalog.matchingIconID(for: "西兰花鸡肉小软饼"), "broccoli")
    }

    func testLongestAliasWinsAtSamePosition() {
        XCTAssertEqual(FoodIconCatalog.matchingIconID(for: "金针菇鸡蛋羹"), "enoki")
        XCTAssertEqual(FoodIconCatalog.matchingIconID(for: "虾仁蔬菜粥"), "shrimp")
    }

    func testAliasesAndFallback() {
        XCTAssertEqual(FoodIconCatalog.matchingIconID(for: "西红柿牛肉面"), "tomato")
        XCTAssertEqual(FoodIconCatalog.matchingIconID(for: "宝宝特制小软饼"), FoodIconCatalog.defaultID)
    }

    func testSeedRecipesHaveIngredientIcons() {
        XCTAssertEqual(FoodIconCatalog.matchingIconID(for: "南瓜小米粥"), "pumpkin")
        XCTAssertEqual(FoodIconCatalog.matchingIconID(for: "胡萝卜土豆泥"), "carrot")
    }

    func testLegacySnapshotDecodesWithoutIconID() throws {
        let json = #"{"id":"00000000-0000-0000-0000-000000000001","recipeID":null,"name":"旧菜谱","symbol":"circle.fill","colorHexA":"FFB366","colorHexB":"FF8A3D","reactionRaw":"like"}"#
        let snapshot = try JSONDecoder().decode(DishSnapshot.self, from: XCTUnwrap(json.data(using: .utf8)))
        XCTAssertNil(snapshot.iconID)
    }

    func testExportDocumentContainsAllTopLevelCollections() throws {
        let payload: [String: Any] = [
            "baby": ["name": "测试", "birthDate": "2025-01-01", "age": "1岁", "gender": "男宝"],
            "recipes": [["name": "南瓜粥", "categories": ["蔬菜"], "recordCount": 3, "lastRecordedAt": "2026-07-10"]],
            "mealRecords": [["date": "2026-07-10", "meal": "午餐", "time": "12:00", "dishes": [["name": "南瓜粥", "reaction": "like"]], "note": "吃得很好"]]
        ]
        let url = try ExportDocument.makeURL(payload: payload)
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let root = try XCTUnwrap(json)
        XCTAssertNotNil(root["baby"])
        XCTAssertNotNil(root["recipes"])
        XCTAssertNotNil(root["mealRecords"])
    }

    func testBackupArchiveRoundTripPreservesDataAndPhotos() throws {
        let photoBytes = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]) // fake JPEG header
        let payload: [String: Any] = [
            "version": 2,
            "baby": ["name": "泡泡", "gender": "男宝", "avatar": "photos/avatar.jpg"],
            "mealRecords": [
                ["meal": "午餐", "dishes": [["name": "南瓜粥", "reaction": "like"]], "photo": "photos/0001.jpg"]
            ]
        ]
        let bundle = BackupBundle(
            payload: payload,
            files: ["photos/avatar.jpg": photoBytes, "photos/0001.jpg": Data([1, 2, 3, 4, 5])]
        )

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("bfd-roundtrip-\(UUID().uuidString).zip")
        try BackupArchive.writeZip(bundle, to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let restored = try BackupArchive.readZip(at: url)

        // data.json decoded back into payload
        XCTAssertEqual(restored.payload["version"] as? Int, 2)
        XCTAssertNotNil(restored.payload["baby"])
        XCTAssertEqual(restored.files.count, 2)
        XCTAssertEqual(restored.files["photos/avatar.jpg"], photoBytes)
        XCTAssertEqual(restored.files["photos/0001.jpg"], Data([1, 2, 3, 4, 5]))
    }
}
