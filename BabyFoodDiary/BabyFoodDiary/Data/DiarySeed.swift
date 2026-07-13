import Foundation
import SwiftData

/// Seeds the SwiftData store with the demo content on first launch so the app is populated.
enum DiarySeed {
    struct SeedRecipe {
        let name: String
        let categories: [String]
        let symbol: String
        let colorHexA: String
        let colorHexB: String
    }

    static let seedRecipes: [SeedRecipe] = [
        SeedRecipe(name: "西兰花鸡肉小软饼", categories: ["主食", "肉食"], symbol: "leaf.fill",
                   colorHexA: "6FCF97", colorHexB: "F2C94C"),
        SeedRecipe(name: "南瓜小米粥", categories: ["主食"], symbol: "bowl.fill",
                   colorHexA: "FF9F45", colorHexB: "FFD166"),
        SeedRecipe(name: "胡萝卜土豆泥", categories: ["蔬菜"], symbol: "carrot.fill",
                   colorHexA: "FF9A3D", colorHexB: "F78CA8"),
        SeedRecipe(name: "紫薯山药泥", categories: ["水果"], symbol: "circle.fill",
                   colorHexA: "B388EB", colorHexB: "F7A8C4"),
        SeedRecipe(name: "胡萝卜牛肉丸", categories: ["肉食"], symbol: "circle.hexagongrid.fill",
                   colorHexA: "EB5757", colorHexB: "FFB366"),
        SeedRecipe(name: "玉米豌豆软饭", categories: ["主食", "蔬菜"], symbol: "fork.knife",
                   colorHexA: "FFC857", colorHexB: "8EE66A"),
        SeedRecipe(name: "苹果红枣泥", categories: ["水果"], symbol: "apple.logo",
                   colorHexA: "FF7AA5", colorHexB: "F9CB6C")
    ]

    static func populate(into context: ModelContext) {
        let entities = seedRecipes.map { recipe in
            RecipeEntity(
                name: recipe.name,
                categories: recipe.categories,
                symbol: recipe.symbol,
                colorHexA: recipe.colorHexA,
                colorHexB: recipe.colorHexB
            )
        }
        entities.forEach { context.insert($0) }

        // Keep recipe indices handy for building sample meal records.
        func dish(for index: Int, reaction: Reaction) -> DishSnapshot {
            DishSnapshot(
                id: UUID(),
                recipeID: entities[index].id,
                name: entities[index].name,
                symbol: entities[index].symbol,
                colorHexA: entities[index].colorHexA,
                colorHexB: entities[index].colorHexB,
                reactionRaw: reaction.rawValue
            )
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        func day(_ offset: Int, _ hour: Int, _ minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        struct Sample {
            let date: Date
            let meal: String
            let reaction: Reaction
            let recipeIndices: [Int]
            let note: String
        }

        let samples: [Sample] = [
            Sample(date: day(0, 8, 30), meal: "早餐", reaction: .like, recipeIndices: [1],
                   note: "吃得开心，胃口很好，便便正常。"),
            Sample(date: day(0, 12, 30), meal: "午餐", reaction: .like, recipeIndices: [0, 2],
                   note: "主动张嘴，吃得很满足。"),
            Sample(date: day(0, 18, 15), meal: "晚餐", reaction: .neutral, recipeIndices: [1],
                   note: "少量打嗝，无其他不适。"),
            Sample(date: day(-1, 19, 0), meal: "晚餐", reaction: .allergy, recipeIndices: [4],
                   note: "嘴角轻微泛红，已记录观察 72 小时。"),
            Sample(date: day(-2, 8, 10), meal: "早餐", reaction: .like, recipeIndices: [0],
                   note: "吃完一份还想，状态很好。"),
            Sample(date: day(-3, 14, 40), meal: "加餐", reaction: .like, recipeIndices: [2],
                   note: "接受度不错。"),
            Sample(date: day(-5, 12, 20), meal: "午餐", reaction: .like, recipeIndices: [0, 1],
                   note: "搭配着吃，光盘。"),
            Sample(date: day(-7, 8, 0), meal: "早餐", reaction: .refused, recipeIndices: [2],
                   note: "今天不太想吃，吐出来两次。"),
            Sample(date: day(-9, 12, 50), meal: "午餐", reaction: .like, recipeIndices: [0],
                   note: "吃得很香。"),
            Sample(date: day(-12, 18, 30), meal: "晚餐", reaction: .neutral, recipeIndices: [1],
                   note: "食量一般。"),
            Sample(date: day(-16, 9, 15), meal: "早餐", reaction: .like, recipeIndices: [3],
                   note: "第一次吃紫薯，喜欢。"),
            Sample(date: day(-18, 13, 0), meal: "午餐", reaction: .neutral, recipeIndices: [5],
                   note: "软饭嚼得还不错。"),
            Sample(date: day(-21, 10, 0), meal: "加餐", reaction: .like, recipeIndices: [6],
                   note: "苹果红枣泥很合口味。")
        ]

        for sample in samples {
            let dishes = sample.recipeIndices.map { dish(for: $0, reaction: sample.reaction) }
            let record = MealRecordEntity(
                date: sample.date,
                meal: sample.meal,
                overallReaction: sample.reaction,
                note: sample.note,
                dishes: dishes
            )
            context.insert(record)
        }

        try? context.save()
    }
}
