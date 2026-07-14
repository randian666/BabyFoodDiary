import Foundation
import SwiftData
import SwiftUI
import Observation

// MARK: - View-facing value types

enum MealPeriod: String, CaseIterable, Identifiable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"

    var id: Self { self }
    var symbol: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "takeoutbag.and.cup.and.straw.fill"
        }
    }
    var color: Color {
        switch self {
        case .breakfast: return AppTheme.warning
        case .lunch: return Color.yellow
        case .dinner: return Color.purple.opacity(0.75)
        case .snack: return AppTheme.success
        }
    }

    static func inferred(at date: Date = .now) -> MealPeriod {
        switch Calendar.current.component(.hour, from: date) {
        case ..<10: return .breakfast
        case 10..<14: return .lunch
        case 14..<17: return .snack
        case 17..<21: return .dinner
        default: return .snack
        }
    }

    static func resolve(_ rawValue: String) -> MealPeriod? {
        MealPeriod(rawValue: rawValue)
    }
}

struct BabyVM {
    var name: String
    var birthDate: Date
    var gender: String
    var avatarData: Data?
    var ageText: String { Self.formatAge(from: birthDate) }

    /// Formats a birth date into a baby-age string like "10个月20天" (or "1岁2个月" once past a year).
    static func formatAge(from birthDate: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: birthDate, to: Date())
        let years = max(comps.year ?? 0, 0)
        let months = max(comps.month ?? 0, 0)
        let days = max(comps.day ?? 0, 0)
        return years >= 1 ? "\(years)岁\(months)个月" : "\(months)个月\(days)天"
    }
}

/// A recipe currently inside the 72-hour observation window (shown on the home 重点观察 section).
struct WatchEntry: Identifiable {
    let id: UUID
    let recipe: Recipe
    let hoursAgo: Int
    let lastReaction: Reaction
}

struct TodayMetrics {
    var watchText: String = "无"
    var longAgoText: String = "0 道"
    var recordedText: String = "0 餐"
}

enum RecordTimeFilter: String, CaseIterable, Identifiable {
    case days14, days30, all

    var id: Self { self }
    var title: String {
        switch self {
        case .days14: return "最近 14 天"
        case .days30: return "最近 30 天"
        case .all: return "所有时间"
        }
    }
    var dayCount: Int? {
        switch self {
        case .days14: return 14
        case .days30: return 30
        case .all: return nil
        }
    }
}

struct HistoryRecordVM: Identifiable {
    let id: UUID
    let date: Date
    let dateLabel: String
    let meal: String
    let timeText: String
    let dishes: [MealDish]
    let overallReaction: Reaction
    let note: String
    let photoData: Data?
    let livePhotoData: Data?
    let livePhotoAssetIdentifier: String?
    let livePhotoResourcesData: Data?
}

/// A single meal in which a recipe appeared, used by the recipe detail timeline.
struct RecipeOccurrence: Identifiable {
    let id: UUID
    let date: Date
    let meal: String
    let reaction: Reaction
}

/// Sort options for the recipe library list.
enum RecipeSort: String, CaseIterable {
    case byCount, byLastRecorded
    var title: String { self == .byCount ? "按记录次数" : "按上次记录时间" }
}

/// Derived, read-only data for a recipe's detail screen.
struct RecipeDetailVM {
    let recipe: Recipe
    let firstRecordedAt: Date?
    let lastRecordedAt: Date?
    let latestReaction: Reaction?
    let isInObservation: Bool
    let occurrences: [RecipeOccurrence]
}

struct RankRow: Identifiable {
    let id: UUID
    let recipe: Recipe
    let likeCount: Int
    let color: Color
}

struct AnalysisSummary {
    var rangeLabel: String = ""
    var total: Int = 0
    var counts: [Reaction: Int] = [.like: 0, .neutral: 0, .refused: 0, .allergy: 0]
    var ranking: [RankRow] = []
}

struct CalendarDay: Identifiable {
    let id = UUID()
    var date: Date? = nil
    let number: Int
    let isRecorded: Bool
    let isToday: Bool
    var isCurrentMonth: Bool = true
    var isSelected: Bool = false
}

struct CalendarWeekVM {
    var monthLabel: String = ""
    var days: [CalendarDay] = []
}

/// A full month grid (Monday-based) used by the history calendar.
struct CalendarMonthVM {
    var monthLabel: String = ""
    var days: [CalendarDay] = []
}

/// Payload used both to pre-fill the record sheet and to persist a meal record.
struct MealRecordForm {
    var editingID: UUID?
    var date: Date
    var meal: String
    var reaction: Reaction
    var note: String
    var photoData: Data?
    var livePhotoData: Data?
    var livePhotoAssetIdentifier: String?
    var livePhotoResourcesData: Data?
    var dishes: [DishSnapshot]

    static var blank: MealRecordForm {
        MealRecordForm(
            editingID: nil,
            date: .now,
            meal: DiaryStore.inferredMeal(),
            reaction: .like,
            note: "",
            photoData: nil,
            livePhotoData: nil,
            livePhotoAssetIdentifier: nil,
            livePhotoResourcesData: nil,
            dishes: []
        )
    }

    /// Pre-fill with a single recipe (used from home recommendations & recipe library).
    static func prefill(recipe: Recipe) -> MealRecordForm {
        var form = blank
        form.dishes = [DishSnapshot(recipe: recipe, reaction: .like)]
        return form
    }
}

extension DishSnapshot {
    init(recipe: Recipe, reaction: Reaction) {
        self.init(
            id: UUID(),
            recipeID: recipe.id,
            name: recipe.name,
            symbol: recipe.symbol,
            iconID: recipe.iconID,
            colorHexA: recipe.colorHexA,
            colorHexB: recipe.colorHexB,
            reactionRaw: reaction.rawValue
        )
    }
}

extension MealDish {
    init(snapshot: DishSnapshot) {
        self.init(
            id: snapshot.id,
            name: snapshot.name,
            symbol: snapshot.symbol,
            iconID: snapshot.iconID ?? FoodIconCatalog.defaultID,
            colorHexA: snapshot.colorHexA,
            colorHexB: snapshot.colorHexB,
            reaction: snapshot.reaction
        )
    }
}

// MARK: - DiaryStore

@Observable
final class DiaryStore {
    private let context: ModelContext

    private(set) var recipes: [Recipe] = []
    private(set) var recommendations: [Recipe] = []
    private(set) var watchEntries: [WatchEntry] = []
    private(set) var historyRecords: [HistoryRecordVM] = []
    private(set) var analysis = AnalysisSummary()
    private var analysisSummaries: [RecordTimeFilter: AnalysisSummary] = [:]
    private(set) var baby = BabyVM(name: "泡泡", birthDate: .now, gender: "男宝", avatarData: nil)
    private(set) var todayMetrics = TodayMetrics()
    private(set) var calendarWeek = CalendarWeekVM()
    private(set) var recipeDetails: [UUID: RecipeDetailVM] = [:]
    private(set) var todayLabel = ""
    private(set) var overviewDateLabel = ""

    var babyName: String { baby.name }

    init(context: ModelContext) {
        self.context = context
        bootstrap()
        refresh()
    }

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([RecipeEntity.self, MealRecordEntity.self, BabyProfileEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: First-launch seeding

    private func bootstrap() {
        if migrateTasteNotesIfPresent() { return }
        let recipeCount = (try? context.fetchCount(FetchDescriptor<RecipeEntity>())) ?? 0
        if recipeCount == 0 { DiarySeed.populate(into: context) }
        let recipes = (try? context.fetch(FetchDescriptor<RecipeEntity>())) ?? []
        for recipe in recipes where recipe.iconID == "unassigned" {
            recipe.iconID = FoodIconCatalog.matchingIconID(for: recipe.name)
        }
        let babies = (try? context.fetch(FetchDescriptor<BabyProfileEntity>())) ?? []
        if let baby = babies.first {
            // Migrated/older stores may have no birth date yet — backfill a sensible default.
            if baby.birthDate == nil {
                baby.birthDate = Self.ageReferenceDate()
                try? context.save()
            }
        } else {
            context.insert(BabyProfileEntity(name: "泡泡", birthDate: Self.ageReferenceDate(), gender: "男宝"))
            try? context.save()
        }
        try? context.save()
    }

    /// One-time import for data copied from the companion app "宝宝尝鲜记".
    /// The source files are placed in this app's Documents directory by the deployment tool.
    @discardableResult
    private func migrateTasteNotesIfPresent() -> Bool {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let source = documents.appendingPathComponent("baby-taste-notes-data-v4.json")
        guard let data = try? Data(contentsOf: source),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sourceRecipes = payload["recipes"] as? [[String: Any]],
              let sourceMeals = payload["meals"] as? [[String: Any]] else { return false }

        let oldRecipes = (try? context.fetch(FetchDescriptor<RecipeEntity>())) ?? []
        let oldMeals = (try? context.fetch(FetchDescriptor<MealRecordEntity>())) ?? []
        let oldBabies = (try? context.fetch(FetchDescriptor<BabyProfileEntity>())) ?? []
        oldRecipes.forEach(context.delete); oldMeals.forEach(context.delete); oldBabies.forEach(context.delete)

        var recipesBySourceID: [String: RecipeEntity] = [:]
        for item in sourceRecipes {
            guard let name = item["name"] as? String else { continue }
            let category = item["category"] as? String ?? "其他"
            let recipe = RecipeEntity(name: name, categories: [category], symbol: "circle.fill",
                                      iconID: FoodIconCatalog.matchingIconID(for: name),
                                      colorHexA: "FFB366", colorHexB: "FF8A3D")
            context.insert(recipe)
            if let id = item["id"] as? String { recipesBySourceID[id] = recipe }
        }

        let photos = documents.appendingPathComponent("MealPhotos", isDirectory: true)
        let formatter = ISO8601DateFormatter()
        for item in sourceMeals {
            let date = (item["date"] as? String).flatMap(formatter.date(from:)) ?? .now
            let dishes = ((item["recipes"] as? [[String: Any]]) ?? []).compactMap { dish -> DishSnapshot? in
                guard let sourceID = dish["recipeId"] as? String, let recipe = recipesBySourceID[sourceID] else { return nil }
                let reaction = dish["reaction"] as? String ?? "neutral"
                return DishSnapshot(id: UUID(), recipeID: recipe.id, name: recipe.name, symbol: recipe.symbol,
                                    iconID: recipe.iconID, colorHexA: recipe.colorHexA, colorHexB: recipe.colorHexB,
                                    reactionRaw: reaction == "dislike" ? "refused" : reaction)
            }
            let imageData = (item["imageId"] as? String).flatMap { try? Data(contentsOf: photos.appendingPathComponent($0)) }
            let meal = ["breakfast": "早餐", "lunch": "午餐", "dinner": "晚餐", "snack": "加餐"][item["mealType"] as? String ?? ""] ?? "加餐"
            let reaction = ((item["overallReaction"] as? String) == "dislike") ? Reaction.refused : ((item["overallReaction"] as? String) == "like" ? Reaction.like : Reaction.neutral)
            context.insert(MealRecordEntity(date: date, meal: meal, overallReaction: reaction,
                                            note: item["notes"] as? String ?? "", photoData: imageData, dishes: dishes))
        }
        context.insert(BabyProfileEntity(name: "宝宝", birthDate: Self.ageReferenceDate(), gender: "男宝"))
        try? context.save()
        try? FileManager.default.removeItem(at: source)
        try? FileManager.default.removeItem(at: photos)
        return true
    }

    /// A reference birth date ~10 months 20 days ago, used to seed/backfill the demo baby age.
    static func ageReferenceDate() -> Date {
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .month, value: -10, to: Date()) ?? Date()
        return calendar.date(byAdding: .day, value: -20, to: base) ?? base
    }

    // MARK: Read & derive

    func refresh() {
        let recipeEntities = (try? context.fetch(
            FetchDescriptor<RecipeEntity>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        let records = (try? context.fetch(
            FetchDescriptor<MealRecordEntity>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        let babyEntities = (try? context.fetch(FetchDescriptor<BabyProfileEntity>())) ?? []

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        func recordsReferencing(_ recipeID: UUID) -> [MealRecordEntity] {
            records.filter { $0.dishes.contains { $0.recipeID == recipeID } }
        }

        func inObservation(_ rel: [MealRecordEntity]) -> Bool {
            guard let lastRec = rel.max(by: { $0.date < $1.date }) else { return false }
            let hours = calendar.dateComponents([.hour], from: lastRec.date, to: .now).hour ?? 0
            guard hours < 72 else { return false }
            return lastRec.overallReaction == .allergy || rel.count <= 1
        }

        // Recipes with derived stats
        let recipeViews: [Recipe] = recipeEntities.map { entity in
            let rel = recordsReferencing(entity.id)
            let lastDate = rel.map(\.date).max()
            let last = lastDate.map { Self.lastDateFormatter.string(from: $0) } ?? "—"
            let days: Int = {
                guard let ld = lastDate else { return 0 }
                return calendar.dateComponents([.day], from: calendar.startOfDay(for: ld), to: today).day ?? 0
            }()
            return Recipe(
                id: entity.id,
                name: entity.name,
                categories: entity.categories,
                count: rel.count,
                last: last,
                days: days,
                symbol: entity.symbol,
                iconID: entity.iconID,
                colorHexA: entity.colorHexA,
                colorHexB: entity.colorHexB
            )
        }
        self.recipes = recipeViews

        self.recipeDetails = Dictionary(uniqueKeysWithValues: recipeEntities.compactMap { entity in
            guard let recipe = recipeViews.first(where: { $0.id == entity.id }) else { return nil }
            let related = recordsReferencing(entity.id)
            let occurrences = related.map {
                RecipeOccurrence(id: $0.id, date: $0.date, meal: $0.meal, reaction: $0.overallReaction)
            }
            .sorted { $0.date > $1.date }
            return (entity.id, RecipeDetailVM(
                recipe: recipe,
                firstRecordedAt: related.map(\.date).min(),
                lastRecordedAt: related.map(\.date).max(),
                latestReaction: occurrences.first?.reaction,
                isInObservation: inObservation(related),
                occurrences: occurrences
            ))
        })

        // Recommendations: ≥1 record, ≥14 days since last, not in observation, last not allergy
        var recs: [Recipe] = []
        for entity in recipeEntities {
            let rel = recordsReferencing(entity.id)
            guard let lastRec = rel.max(by: { $0.date < $1.date }) else { continue }
            guard lastRec.overallReaction != .allergy else { continue }
            guard !inObservation(rel) else { continue }
            let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastRec.date), to: today).day ?? 0
            guard daysSince >= 14 else { continue }
            if let view = recipeViews.first(where: { $0.id == entity.id }) { recs.append(view) }
        }
        recs.sort { $0.days > $1.days }
        self.recommendations = recs

        // Baby
        if let be = babyEntities.first {
            baby = BabyVM(name: be.name, birthDate: be.birthDate ?? Self.ageReferenceDate(), gender: be.gender, avatarData: be.avatarData)
        }

        // Today label & metrics
        todayLabel = Self.headerDateFormatter.string(from: .now)
        overviewDateLabel = Self.overviewDateFormatter.string(from: .now)

        // 重点观察: recipes currently in the 72-hour observation window, newest first.
        var watches: [WatchEntry] = []
        for entity in recipeEntities {
            let rel = recordsReferencing(entity.id)
            guard inObservation(rel), let lastRec = rel.max(by: { $0.date < $1.date }) else { continue }
            guard let view = recipeViews.first(where: { $0.id == entity.id }) else { continue }
            let hours = calendar.dateComponents([.hour], from: lastRec.date, to: .now).hour ?? 0
            watches.append(WatchEntry(id: entity.id, recipe: view, hoursAgo: max(hours, 0), lastReaction: lastRec.overallReaction))
        }
        watches.sort { $0.hoursAgo < $1.hoursAgo }
        self.watchEntries = watches

        let todayRecordCount = records.filter { calendar.isDateInToday($0.date) }.count
        todayMetrics = TodayMetrics(
            watchText: watches.isEmpty ? "无" : "\(watches.count) 种",
            longAgoText: recs.isEmpty ? "无" : "\(recs.count) 道",
            recordedText: "\(todayRecordCount) 餐"
        )

        let summaries = Dictionary(uniqueKeysWithValues: RecordTimeFilter.allCases.map { filter in
            (filter, analysis(for: filter, records: records, today: today))
        })
        self.analysisSummaries = summaries
        self.analysis = summaries[.days14] ?? AnalysisSummary()

        // History
        self.historyRecords = records.map { rec in
            HistoryRecordVM(
                id: rec.id,
                date: rec.date,
                dateLabel: Self.fullDateFormatter.string(from: rec.date),
                meal: rec.meal,
                timeText: Self.timeFormatter.string(from: rec.date),
                dishes: rec.dishes.map { MealDish(snapshot: $0) },
                overallReaction: rec.overallReaction,
                note: rec.note.isEmpty ? "暂无备注。" : rec.note,
                photoData: rec.photoData,
                livePhotoData: rec.livePhotoData,
                livePhotoAssetIdentifier: rec.livePhotoAssetIdentifier,
                livePhotoResourcesData: rec.livePhotoResourcesData
            )
        }

        // Calendar week
        self.calendarWeek = Self.buildCalendarWeek(today: today, records: records, calendar: calendar)
    }

    // MARK: Library filter helper

    func libraryRecipes(search: String, category: String, sort: RecipeSort = .byCount, ascending: Bool = false) -> [Recipe] {
        let filtered = recipes.filter { recipe in
            let matchesSearch = search.isEmpty
                || recipe.name.contains(search)
                || recipe.categories.contains { $0.contains(search) }
            let matchesCategory = category == "全部" || recipe.categories.contains(category)
            return matchesSearch && matchesCategory
        }
        switch sort {
        case .byCount:
            // Primary key: record count. Direction flips high/low; name is a stable tie-break.
            return filtered.sorted { a, b in
                if a.count != b.count { return ascending ? a.count < b.count : a.count > b.count }
                return a.name < b.name
            }
        case .byLastRecorded:
            // Primary key: days since last record (smaller = more recent). Recipes with no record
            // always sink to the bottom regardless of direction.
            return filtered.sorted { a, b in
                if (a.count == 0) != (b.count == 0) { return a.count != 0 }
                if a.days != b.days { return ascending ? a.days < b.days : a.days > b.days }
                return a.name < b.name
            }
        }
    }

    func historyRecords(for filter: RecordTimeFilter) -> [HistoryRecordVM] {
        guard let dayCount = filter.dayCount else { return historyRecords }
        let today = Calendar.current.startOfDay(for: .now)
        let start = Calendar.current.date(byAdding: .day, value: -(dayCount - 1), to: today) ?? today
        return historyRecords.filter { $0.date >= start }
    }

    func analysis(for filter: RecordTimeFilter) -> AnalysisSummary {
        analysisSummaries[filter] ?? analysis
    }

    private func analysis(for filter: RecordTimeFilter, records: [MealRecordEntity], today: Date) -> AnalysisSummary {
        let windowRecords: [MealRecordEntity]
        let rangeLabel: String
        if let dayCount = filter.dayCount {
            let start = Calendar.current.date(byAdding: .day, value: -(dayCount - 1), to: today) ?? today
            windowRecords = records.filter { $0.date >= start }
            rangeLabel = "\(Self.shortDateFormatter.string(from: start))-\(Self.shortDateFormatter.string(from: today))"
        } else {
            windowRecords = records
            rangeLabel = "所有时间"
        }

        var counts: [Reaction: Int] = [.like: 0, .neutral: 0, .refused: 0, .allergy: 0]
        for record in windowRecords { counts[record.overallReaction, default: 0] += 1 }

        var rows: [RankRow] = []
        for recipe in recipes {
            let likes = windowRecords.reduce(into: 0) { count, record in
                count += record.dishes.filter { $0.recipeID == recipe.id && $0.reaction == .like }.count
            }
            guard likes > 0 else { continue }
            rows.append(RankRow(
                id: recipe.id,
                recipe: recipe,
                likeCount: likes,
                color: AppTheme.success
            ))
        }
        rows.sort { $0.likeCount == $1.likeCount ? $0.recipe.name < $1.recipe.name : $0.likeCount > $1.likeCount }
        return AnalysisSummary(rangeLabel: rangeLabel, total: windowRecords.count, counts: counts, ranking: rows)
    }

    // MARK: Mutations

    /// Creates and persists a new recipe (from "添加新食谱"), returning a view value ready to snapshot into a meal.
    @discardableResult
    func addRecipe(name: String) -> Recipe {
        let entity = RecipeEntity(name: name, categories: [], symbol: "circle.fill", iconID: FoodIconCatalog.matchingIconID(for: name), colorHexA: "FFB366", colorHexB: "FF8A3D")
        context.insert(entity)
        try? context.save()
        refresh()
        return Recipe(id: entity.id, name: entity.name, categories: entity.categories, count: 0, last: "—", days: 0, symbol: entity.symbol, iconID: entity.iconID, colorHexA: entity.colorHexA, colorHexB: entity.colorHexB)
    }

    func updateRecipeIcon(id: UUID, iconID: String) {
        var descriptor = FetchDescriptor<RecipeEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let recipe = try? context.fetch(descriptor).first else { return }
        recipe.iconID = FoodIconCatalog.icon(id: iconID).id
        try? context.save()
        refresh()
    }

    func updateRecipeCategories(id: UUID, categories: [String]) {
        var descriptor = FetchDescriptor<RecipeEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let recipe = try? context.fetch(descriptor).first else { return }
        recipe.categoriesRaw = DiaryCodec.encodeList(categories)
        try? context.save()
        refresh()
    }

    func saveMealRecord(_ form: MealRecordForm) {
        if let id = form.editingID, let existing = record(id: id) {
            existing.date = form.date
            existing.mealRaw = form.meal
            existing.overallReactionRaw = form.reaction.rawValue
            existing.note = form.note
            existing.photoData = form.photoData
            existing.livePhotoData = form.livePhotoData
            existing.livePhotoAssetIdentifier = form.livePhotoAssetIdentifier
            existing.livePhotoResourcesData = form.livePhotoResourcesData
            existing.dishesJSON = Self.encodeDishes(form.dishes)
            existing.updatedAt = .now
        } else {
            context.insert(MealRecordEntity(
                date: form.date,
                meal: form.meal,
                overallReaction: form.reaction,
                note: form.note,
                photoData: form.photoData,
                livePhotoData: form.livePhotoData,
                livePhotoAssetIdentifier: form.livePhotoAssetIdentifier,
                livePhotoResourcesData: form.livePhotoResourcesData,
                dishes: form.dishes
            ))
        }
        try? context.save()
        refresh()
    }

    func deleteMealRecord(id: UUID) {
        guard let existing = record(id: id) else { return }
        context.delete(existing)
        try? context.save()
        refresh()
    }

    func form(forRecordID id: UUID) -> MealRecordForm? {
        guard let rec = record(id: id) else { return nil }
        return MealRecordForm(
            editingID: id,
            date: rec.date,
            meal: rec.meal,
            reaction: rec.overallReaction,
            note: rec.note,
            photoData: rec.photoData,
            livePhotoData: rec.livePhotoData,
            livePhotoAssetIdentifier: rec.livePhotoAssetIdentifier,
            livePhotoResourcesData: rec.livePhotoResourcesData,
            dishes: rec.dishes
        )
    }

    func updateBaby(name: String, birthDate: Date, gender: String) {
        let babyEntities = (try? context.fetch(FetchDescriptor<BabyProfileEntity>())) ?? []
        if let entity = babyEntities.first {
            entity.name = name
            entity.birthDate = birthDate
            entity.gender = gender
        } else {
            context.insert(BabyProfileEntity(name: name, birthDate: birthDate, gender: gender))
        }
        try? context.save()
        refresh()
    }

    func updateAvatar(_ data: Data?) {
        let babyEntities = (try? context.fetch(FetchDescriptor<BabyProfileEntity>())) ?? []
        if let entity = babyEntities.first {
            entity.avatarData = data
        } else {
            context.insert(BabyProfileEntity(name: "宝宝", birthDate: Self.ageReferenceDate(), gender: "男宝", avatarData: data))
        }
        try? context.save()
        refresh()
    }

    // MARK: Export payload

    private static let avatarPhotoPath = "photos/avatar.jpg"

    func exportPayload() -> [String: Any] {
        var mealRecords: [[String: Any]] = []
        for (index, vm) in historyRecords.enumerated() {
            let prefix = String(format: "photos/%04d", index + 1)
            var entry: [String: Any] = [
                "date": Self.lastDateFormatter.string(from: vm.date),
                "meal": vm.meal,
                "time": vm.timeText,
                "dishes": vm.dishes.map { ["name": $0.name, "reaction": $0.reaction.rawValue] },
                "note": vm.note
            ]
            if vm.photoData != nil { entry["photo"] = "\(prefix).jpg" }
            if vm.livePhotoData != nil { entry["livePhoto"] = "\(prefix).live" }
            mealRecords.append(entry)
        }

        var babyDict: [String: Any] = [
            "name": baby.name,
            "birthDate": Self.isoDateFormatter.string(from: baby.birthDate),
            "age": baby.ageText,
            "gender": baby.gender
        ]
        if baby.avatarData != nil { babyDict["avatar"] = Self.avatarPhotoPath }

        return [
            "version": 2,
            "baby": babyDict as [String: Any],
            "recipes": recipes.map { recipe in
                [
                    "name": recipe.name,
                    "categories": recipe.categories,
                    "recordCount": recipe.count,
                    "lastRecordedAt": recipe.last
                ] as [String: Any]
            },
            "mealRecords": mealRecords
        ]
    }

    /// Builds a backup bundle: structured payload (→ data.json) plus photo blobs keyed by their
    /// JSON-referenced relative paths.
    func buildBackup() -> BackupBundle {
        let payload = exportPayload()
        var files: [String: Data] = [:]
        if let avatar = baby.avatarData {
            files[Self.avatarPhotoPath] = avatar
        }
        for (index, vm) in historyRecords.enumerated() {
            let prefix = String(format: "photos/%04d", index + 1)
            if let photo = vm.photoData { files["\(prefix).jpg"] = photo }
            if let live = vm.livePhotoData { files["\(prefix).live"] = live }
        }
        return BackupBundle(payload: payload, files: files)
    }

    // MARK: Import payload

    struct ImportPayload: Codable {
        struct Baby: Codable {
            let name: String
            let birthDate: String?
            let age: String?
            let gender: String
            let avatar: String?
        }
        struct RecipeItem: Codable {
            let name: String
            let categories: [String]?
            let recordCount: Int?
            let lastRecordedAt: String?
        }
        struct MealRecordItem: Codable {
            let date: String?
            let meal: String
            let time: String?
            let dishes: [DishItem]?
            let note: String?
            let photo: String?
            let livePhoto: String?
        }
        struct DishItem: Codable {
            let name: String
            let reaction: String?
        }

        let baby: Baby
        let recipes: [RecipeItem]?
        let mealRecords: [MealRecordItem]?
    }

    struct ImportSummary {
        let babyName: String
        let totalRecipes: Int
        let newRecipes: Int
        let totalRecords: Int
        let photos: Int
    }

    /// ZIP bundle import (v2 backups, includes photos).
    func importBackup(_ bundle: BackupBundle) throws -> ImportSummary {
        let data = try JSONSerialization.data(withJSONObject: bundle.payload, options: [])
        let payload = try JSONDecoder().decode(ImportPayload.self, from: data)
        return applyImport(payload, photos: bundle.files)
    }

    private func applyImport(_ payload: ImportPayload, photos: [String: Data]) -> ImportSummary {
        let birthDate = payload.baby.birthDate
            .flatMap { Self.isoDateFormatter.date(from: $0) } ?? Date()
        let babyName = payload.baby.name
        let babyGender = payload.baby.gender

        let existingRecipeNames = Set(recipes.map { $0.name })
        let importRecipes = payload.recipes ?? []
        let newRecipes = importRecipes.filter { !existingRecipeNames.contains($0.name) }
        let importRecords = payload.mealRecords ?? []

        // 1. Update baby profile (and avatar if referenced & present)
        updateBaby(name: babyName, birthDate: birthDate, gender: babyGender)
        if let avatarPath = payload.baby.avatar, let data = photos[avatarPath] {
            updateAvatar(data)
        }

        // 2. Add only new recipes (dedup by name)
        for recipe in newRecipes {
            let entity = RecipeEntity(
                name: recipe.name,
                categories: recipe.categories ?? [],
                symbol: "circle.fill",
                iconID: FoodIconCatalog.matchingIconID(for: recipe.name),
                colorHexA: "FFB366",
                colorHexB: "FF8A3D"
            )
            context.insert(entity)
        }
        if !newRecipes.isEmpty {
            try? context.save()
            refresh()
        }

        // 3. Import meal records (with photos when referenced)
        let isoFormatter = Self.isoDateFormatter
        let currentRecipes = recipes
        var photoCount = 0
        for record in importRecords {
            let date = record.date.flatMap { isoFormatter.date(from: $0) } ?? Date()
            let dishes: [DishSnapshot] = (record.dishes ?? []).map { dish in
                let matched = currentRecipes.first(where: { $0.name == dish.name })
                return DishSnapshot(
                    id: UUID(),
                    recipeID: matched?.id,
                    name: dish.name,
                    symbol: matched?.symbol ?? "circle.fill",
                    iconID: matched?.iconID ?? FoodIconCatalog.matchingIconID(for: dish.name),
                    colorHexA: matched?.colorHexA ?? "FFB366",
                    colorHexB: matched?.colorHexB ?? "FF8A3D",
                    reactionRaw: dish.reaction ?? "neutral"
                )
            }
            let overallReaction = dishes.first?.reaction ?? .neutral
            let photoData = record.photo.flatMap { photos[$0] }
            let livePhotoData = record.livePhoto.flatMap { photos[$0] }
            if photoData != nil { photoCount += 1 }
            context.insert(MealRecordEntity(
                date: date,
                meal: record.meal,
                overallReaction: overallReaction,
                note: record.note ?? "",
                photoData: photoData,
                livePhotoData: livePhotoData,
                dishes: dishes
            ))
        }
        try? context.save()
        refresh()

        return ImportSummary(
            babyName: babyName,
            totalRecipes: importRecipes.count,
            newRecipes: newRecipes.count,
            totalRecords: importRecords.count,
            photos: photoCount
        )
    }

    // MARK: Helpers

    private func record(id: UUID) -> MealRecordEntity? {
        var descriptor = FetchDescriptor<MealRecordEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    static func inferredMeal() -> String {
        MealPeriod.inferred().rawValue
    }

    static func encodeDishes(_ dishes: [DishSnapshot]) -> String {
        (try? JSONEncoder().encode(dishes)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    private static func buildCalendarWeek(today: Date, records: [MealRecordEntity], calendar: Calendar) -> CalendarWeekVM {
        let weekday = calendar.component(.weekday, from: today) // 1 = Sunday ... 7 = Saturday
        let mondayOffset = (weekday + 5) % 7 // Monday = 0
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) ?? today

        var days: [CalendarDay] = []
        for offset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: offset, to: monday) ?? monday
            let isRecorded = records.contains { calendar.isDate($0.date, inSameDayAs: day) }
            days.append(CalendarDay(
                number: calendar.component(.day, from: day),
                isRecorded: isRecorded,
                isToday: calendar.isDateInToday(day)
            ))
        }
        return CalendarWeekVM(monthLabel: monthLabelFormatter.string(from: monday), days: days)
    }

    /// Builds a Monday-based month grid for the month containing `anchor`, marking recorded days,
    /// today, and the user's selected day. Used by the history calendar for date filtering.
    func calendarMonth(anchor: Date, selected: Date?) -> CalendarMonthVM {
        var calendar = Self.gregorian
        calendar.timeZone = .current
        let records = historyRecords.map(\.date)

        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: anchor)) ?? anchor
        // Weekday: 1 = Sunday ... 7 = Saturday. Convert to Monday-based leading offset.
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (firstWeekday + 5) % 7 // Monday = 0
        let gridStart = calendar.date(byAdding: .day, value: -leading, to: firstOfMonth) ?? firstOfMonth

        let range = calendar.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<29
        let totalCells = ((leading + range.count + 6) / 7) * 7 // whole weeks

        var days: [CalendarDay] = []
        for offset in 0..<totalCells {
            let day = calendar.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
            let inMonth = calendar.isDate(day, equalTo: firstOfMonth, toGranularity: .month)
            let isRecorded = records.contains { calendar.isDate($0, inSameDayAs: day) }
            days.append(CalendarDay(
                date: day,
                number: calendar.component(.day, from: day),
                isRecorded: isRecorded,
                isToday: calendar.isDateInToday(day),
                isCurrentMonth: inMonth,
                isSelected: selected.map { calendar.isDate(day, inSameDayAs: $0) } ?? false
            ))
        }
        return CalendarMonthVM(monthLabel: Self.monthLabelFormatter.string(from: firstOfMonth), days: days)
    }

    /// Builds a Monday–Sunday week (7 days) containing `anchor`, marking recorded days, today, and
    /// the selected day. Used by the history calendar (a single week strip with prev/next navigation).
    func calendarWeek(anchor: Date, selected: Date?) -> CalendarWeekVM {
        var calendar = Self.gregorian
        calendar.timeZone = .current
        let records = historyRecords.map(\.date)

        let weekday = calendar.component(.weekday, from: anchor) // 1 = Sunday ... 7 = Saturday
        let mondayOffset = (weekday + 5) % 7 // Monday = 0
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: anchor) ?? anchor

        var days: [CalendarDay] = []
        for offset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: offset, to: monday) ?? monday
            let isRecorded = records.contains { calendar.isDate($0, inSameDayAs: day) }
            days.append(CalendarDay(
                date: day,
                number: calendar.component(.day, from: day),
                isRecorded: isRecorded,
                isToday: calendar.isDateInToday(day),
                isCurrentMonth: true,
                isSelected: selected.map { calendar.isDate(day, inSameDayAs: $0) } ?? false
            ))
        }
        return CalendarWeekVM(monthLabel: Self.monthLabelFormatter.string(from: anchor), days: days)
    }

    // MARK: Date formatters

    private static let gregorian: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "zh_CN")
        return c
    }()

    private static let headerDateFormatter: DateFormatter = makeFormatter("M月d日 EEE")
    private static let overviewDateFormatter: DateFormatter = makeFormatter("yyyy年M月d日")
    private static let fullDateFormatter: DateFormatter = makeFormatter("M月d日 EEE")
    private static let shortDateFormatter: DateFormatter = makeFormatter("M.d")
    private static let timeFormatter: DateFormatter = makeFormatter("HH:mm")
    private static let lastDateFormatter: DateFormatter = makeFormatter("yyyy-MM-dd")
    private static let isoDateFormatter: DateFormatter = makeFormatter("yyyy-MM-dd")
    private static let monthLabelFormatter: DateFormatter = makeFormatter("yyyy年M月")

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = gregorian
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = format
        return f
    }
}
