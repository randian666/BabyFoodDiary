import Foundation
import SwiftData
import SwiftUI

// MARK: - Color hex helper

extension Color {
    /// Initializes a color from a hex string (`RGB`, `RRGGBB` or `RRGGBBAA`). Falls back to orange.
    init(hex: String) {
        let sanitized = hex.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
            .map { String($0) }.joined()
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r, g, b, a: Double
        switch sanitized.count {
        case 3: // RGB
            r = Double((value >> 8 & 0xF) * 17) / 255
            g = Double((value >> 4 & 0xF) * 17) / 255
            b = Double((value & 0xF) * 17) / 255
            a = 1
        case 6: // RRGGBB
            r = Double(value >> 16 & 0xFF) / 255
            g = Double(value >> 8 & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        case 8: // RRGGBBAA
            r = Double(value >> 24 & 0xFF) / 255
            g = Double(value >> 16 & 0xFF) / 255
            b = Double(value >> 8 & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            r = 1; g = 0.478; b = 0.239; a = 1 // AppTheme.primary
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Category & dish encoding helpers

enum DiaryCodec {
    /// Separator used to join multi-value strings before persistence (a control char unlikely to appear in data).
    static let separator: Character = "\u{001F}"

    static func encodeList(_ items: [String]) -> String {
        items.joined(separator: String(separator))
    }

    static func decodeList(_ raw: String) -> [String] {
        raw.split(separator: separator).map { String($0) }
    }
}

// MARK: - Persistent models (SwiftData)

/// A recipe template that the user can record meals against.
@Model
final class RecipeEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoriesRaw: String
    var symbol: String
    /// `unassigned` exists only during migration; normal recipes persist a catalog ID.
    var iconID: String = "unassigned"
    var colorHexA: String
    var colorHexB: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        categories: [String],
        symbol: String,
        iconID: String = "unassigned",
        colorHexA: String,
        colorHexB: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoriesRaw = DiaryCodec.encodeList(categories)
        self.symbol = symbol
        self.iconID = iconID
        self.colorHexA = colorHexA
        self.colorHexB = colorHexB
        self.createdAt = createdAt
    }

    var categories: [String] { DiaryCodec.decodeList(categoriesRaw) }
    var colors: [Color] { [Color(hex: colorHexA), Color(hex: colorHexB)] }
}

/// A snapshot of a single dish within a meal record (immutable at save time).
struct DishSnapshot: Codable, Identifiable {
    var id: UUID
    var recipeID: UUID?
    var name: String
    var symbol: String
    /// Optional so historical JSON snapshots remain decodable after the icon catalog was added.
    var iconID: String? = nil
    var colorHexA: String
    var colorHexB: String
    var reactionRaw: String

    var reaction: Reaction { Reaction(rawValue: reactionRaw) ?? .neutral }
    var colors: [Color] { [Color(hex: colorHexA), Color(hex: colorHexB)] }
}

/// One saved meal (breakfast/lunch/dinner/snack) with its dishes, reaction and note.
@Model
final class MealRecordEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mealRaw: String
    var overallReactionRaw: String
    var note: String
    var photoData: Data?
    @Attribute(.externalStorage) var livePhotoData: Data?
    var livePhotoAssetIdentifier: String?
    var livePhotoResourcesData: Data?
    var dishesJSON: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        meal: String,
        overallReaction: Reaction,
        note: String = "",
        photoData: Data? = nil,
        livePhotoData: Data? = nil,
        livePhotoAssetIdentifier: String? = nil,
        livePhotoResourcesData: Data? = nil,
        dishes: [DishSnapshot] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.mealRaw = meal
        self.overallReactionRaw = overallReaction.rawValue
        self.note = note
        self.photoData = photoData
        self.livePhotoData = livePhotoData
        self.livePhotoAssetIdentifier = livePhotoAssetIdentifier
        self.livePhotoResourcesData = livePhotoResourcesData
        self.dishesJSON = (try? JSONEncoder().encode(dishes))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    var meal: String { mealRaw }
    var overallReaction: Reaction { Reaction(rawValue: overallReactionRaw) ?? .neutral }

    var dishes: [DishSnapshot] {
        guard let data = dishesJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([DishSnapshot].self, from: data) else {
            return []
        }
        return decoded
    }
}

/// The single baby profile shown across the app.
@Model
final class BabyProfileEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date?
    var gender: String
    var avatarData: Data?
    var ageText: String = "" // legacy: superseded by birthDate, kept for migration safety

    init(id: UUID = UUID(), name: String, birthDate: Date? = nil, gender: String, avatarData: Data? = nil) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.avatarData = avatarData
    }
}
