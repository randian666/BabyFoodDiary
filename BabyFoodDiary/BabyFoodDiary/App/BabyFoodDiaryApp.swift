import SwiftUI
import UIKit

@main
struct BabyFoodDiaryApp: App {
    var body: some Scene { WindowGroup { RootView() } }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home, recipes, analysis, history
    var id: Self { self }
    var title: String { ["首页", "菜谱", "分析", "历史"][Self.allCases.firstIndex(of: self)!] }
    var symbol: String { ["house", "book.closed", "chart.bar", "clock"][Self.allCases.firstIndex(of: self)!] }
}

enum Reaction: String, CaseIterable, Identifiable {
    case like, neutral, refused, allergy
    var id: Self { self }
    var title: String { ["喜欢", "一般", "拒绝", "需观察"][Self.allCases.firstIndex(of: self)!] }
    var symbol: String { ["face.smiling", "face.dashed", "face.dashed", "exclamationmark.triangle"][Self.allCases.firstIndex(of: self)!] }
    var color: Color { [AppTheme.success, AppTheme.warning, AppTheme.danger, Color.purple][Self.allCases.firstIndex(of: self)!] }
}

struct Recipe: Identifiable {
    let id = UUID(); let name: String; let categories: [String]; let count: Int; let last: String; let days: Int; let symbol: String; let colors: [Color]
}

enum DemoData {
    static let recommendations = [
        Recipe(name: "西兰花鸡肉小软饼", categories: ["主食", "肉食"], count: 12, last: "2024-05-18", days: 16, symbol: "leaf.fill", colors: [.green.opacity(0.72), .yellow.opacity(0.72)]),
        Recipe(name: "南瓜小米粥", categories: ["主食"], count: 8, last: "2024-05-12", days: 18, symbol: "bowl.fill", colors: [.orange.opacity(0.75), .yellow.opacity(0.68)]),
        Recipe(name: "胡萝卜土豆泥", categories: ["蔬菜"], count: 6, last: "2024-05-15", days: 15, symbol: "carrot.fill", colors: [.orange.opacity(0.8), .pink.opacity(0.55)])
    ]
    static let recipes = recommendations + [
        Recipe(name: "紫薯山药泥", categories: ["水果"], count: 4, last: "2024-04-28", days: 37, symbol: "circle.fill", colors: [.purple.opacity(0.7), .pink.opacity(0.5)]),
        Recipe(name: "胡萝卜牛肉丸", categories: ["肉食"], count: 1, last: "2024-04-10", days: 55, symbol: "circle.hexagongrid.fill", colors: [.red.opacity(0.7), .orange.opacity(0.5)])
    ]

    static func frequentlyRecordedRecipes(from recipes: [Recipe], limit: Int = 3) -> [Recipe] {
        Array(recipes.sorted {
            $0.count == $1.count ? $0.last > $1.last : $0.count > $1.count
        }.prefix(limit))
    }
}

struct MealDish: Identifiable {
    let name: String; let symbol: String; let colors: [Color]; let reaction: Reaction
    var id: String { name }
}

enum MealDishFixtures {
    static let breakfast = [
        MealDish(name: "南瓜小米粥", symbol: "bowl.fill", colors: [.orange.opacity(0.75), .yellow.opacity(0.68)], reaction: .like),
        MealDish(name: "蒸蛋黄", symbol: "circle.fill", colors: [.yellow.opacity(0.75), .orange.opacity(0.45)], reaction: .neutral),
        MealDish(name: "苹果泥", symbol: "apple.logo", colors: [.pink.opacity(0.75), .red.opacity(0.48)], reaction: .like)
    ]
    static let lunch = [
        MealDish(name: "西兰花鸡肉小软饼", symbol: "leaf.fill", colors: [.green.opacity(0.72), .yellow.opacity(0.72)], reaction: .like),
        MealDish(name: "胡萝卜土豆泥", symbol: "carrot.fill", colors: [.orange.opacity(0.8), .pink.opacity(0.55)], reaction: .neutral),
        MealDish(name: "番茄泥", symbol: "circle.fill", colors: [.red.opacity(0.7), .orange.opacity(0.5)], reaction: .like)
    ]
}

struct RootView: View {
    @State private var tab: AppTab = .home
    @State private var isRecording = false
    @State private var isSettingsPresented = false
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home: HomeView { isSettingsPresented = true }
                case .recipes: RecipeLibraryView()
                case .analysis: AnalysisView()
                case .history: HistoryView()
                }
            }
            FloatingTabBar(tab: $tab) { isRecording = true }
        }
        .sheet(isPresented: $isRecording) { MealRecordView() }
        .fullScreenCover(isPresented: $isSettingsPresented) { SettingsView() }
    }
}

enum ApricotElevation {
    case card, control, primary
    var color: Color { AppTheme.primary.opacity(opacity) }
    var opacity: Double { switch self { case .card: return 0.10; case .control: return 0.08; case .primary: return 0.34 } }
    var radius: CGFloat { switch self { case .card: return 12; case .control: return 6; case .primary: return 12 } }
    var y: CGFloat { switch self { case .card: return 6; case .control: return 3; case .primary: return 7 } }
}

extension View {
    func apricotElevation(_ level: ApricotElevation) -> some View {
        shadow(color: level.color, radius: level.radius, y: level.y)
    }
}

struct ApricotCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.padding(16).background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 22)).apricotElevation(.card) }
}

struct FoodThumbnail: View {
    let recipe: Recipe; var size: CGFloat = 60
    var body: some View { Image(systemName: recipe.symbol).font(.system(size: size * 0.38, weight: .semibold)).foregroundStyle(.white.opacity(0.92)).frame(width: size, height: size).background(LinearGradient(colors: recipe.colors, startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: size * 0.24)).apricotElevation(.control) }
}

struct Pill: View {
    let text: String; var color: Color = AppTheme.primary; var body: some View { Text(text).font(.caption2.weight(.bold)).foregroundStyle(color).padding(.horizontal, 9).padding(.vertical, 5).background(color.opacity(0.13)).clipShape(Capsule()).apricotElevation(.control) }
}

struct PageTitle: View {
    let title: String; var trailing: String? = nil
    var body: some View { HStack { Text(title).font(.system(size: 23, weight: .bold)).foregroundStyle(AppTheme.ink); Spacer(); if let trailing { Label(trailing, systemImage: "line.3.horizontal.decrease.circle").font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) } }.padding(.top, 8) }
}

struct HomeView: View {
    let showSettings: () -> Void
    var body: some View {
        ScrollView(showsIndicators: false) { VStack(spacing: 17) {
            HStack { VStack(alignment: .leading, spacing: 3) { Text("7月10日 周四").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text("泡泡的辅食日记").font(.system(size: 21, weight: .bold)).foregroundStyle(AppTheme.ink) }; Spacer(); Button(action: showSettings) { Label("设置", systemImage: "gearshape").labelStyle(.iconOnly).font(.body.weight(.semibold)).foregroundStyle(AppTheme.ink).frame(width: 44, height: 44).background(.white).clipShape(RoundedRectangle(cornerRadius: 15)).apricotElevation(.control) }.accessibilityLabel("设置") }
            HStack(spacing: 14) { RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [.orange.opacity(0.62), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 52, height: 52).apricotElevation(.primary); VStack(alignment: .leading, spacing: 7) { Text("泡泡").font(.title3.bold()); HStack(spacing: 6) { Pill(text: "10个月20天", color: AppTheme.warning); Pill(text: "男宝", color: .pink) } }; Spacer(); Image(systemName: "sun.max").font(.title2).foregroundStyle(.yellow) }.padding(16).background(LinearGradient(colors: [AppTheme.warmSurface, .yellow.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 22)).apricotElevation(.card)
            HStack { Text("今日概览").font(.headline); Spacer(); Text("2024年5月20日 ›").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }
            HStack(spacing: 10) { Metric(title: "重点观察", value: "无", color: AppTheme.secondaryInk); Metric(title: "好久没吃", value: "3 道", color: AppTheme.success); Metric(title: "已记录", value: "1 餐", color: AppTheme.primary) }
            HStack { Text("好久没吃的菜谱").font(.headline); Spacer(); Label("换一换", systemImage: "arrow.clockwise").font(.caption.weight(.bold)).foregroundStyle(AppTheme.primary) }
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 11) { ForEach(DemoData.recommendations) { recipe in VStack(alignment: .leading, spacing: 7) { HomeRecipeThumbnail(recipe: recipe); Text(recipe.name).font(.subheadline.bold()).lineLimit(2); Text("已 \(recipe.days) 天未吃").font(.caption.weight(.medium)).foregroundStyle(AppTheme.secondaryInk); Pill(text: "✓ 安全复吃", color: AppTheme.success) }.frame(width: 148, alignment: .leading).padding(10).background(.white).clipShape(RoundedRectangle(cornerRadius: 19)).apricotElevation(.card) } }.padding(.vertical, 2) }
            ApricotCard { HStack { Image(systemName: "leaf").foregroundStyle(AppTheme.success).frame(width: 42, height: 42).background(AppTheme.success.opacity(0.13)).clipShape(RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading) { Text("重点观察").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text("这几天没有需要特别观察的食材").font(.subheadline.weight(.semibold)) }; Spacer() } }
        }.padding(.horizontal, 17).padding(.top, 12).padding(.bottom, 108) }.background(AppTheme.background)
    }
}

struct HomeRecipeThumbnail: View {
    let recipe: Recipe
    var body: some View { Image(systemName: recipe.symbol).font(.system(size: 29, weight: .semibold)).foregroundStyle(.white.opacity(0.78)).frame(maxWidth: .infinity).frame(height: 80).background(LinearGradient(colors: recipe.colors, startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 14)) }
}

struct Metric: View { let title: String; let value: String; let color: Color; var body: some View { VStack(spacing: 5) { Text(title).font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(color) }.frame(maxWidth: .infinity).padding(.vertical, 13).padding(.horizontal, 6).background(title == "好久没吃" ? LinearGradient(colors: [.white, AppTheme.warmSurface], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)).clipShape(RoundedRectangle(cornerRadius: 22)).apricotElevation(.card) } }

struct RecipeLibraryView: View {
    var body: some View { ScrollView(showsIndicators: false) { VStack(spacing: 12) { PageTitle(title: "菜谱库"); HStack { Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.secondaryInk); Text("搜索食材或菜谱").font(.subheadline).foregroundStyle(AppTheme.secondaryInk); Spacer() }.padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 18)).apricotElevation(.control); ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(["全部", "主食", "肉食", "蔬菜", "水果"], id: \.self) { label in Text(label).font(.subheadline.bold()).foregroundStyle(label == "全部" ? .white : AppTheme.secondaryInk).padding(.horizontal, 14).padding(.vertical, 8).background(label == "全部" ? AppTheme.primary : .white).clipShape(Capsule()).apricotElevation(.control) } } }; HStack(spacing: 5) { Text("按记录次数").font(.subheadline).foregroundStyle(AppTheme.ink); Image(systemName: "chevron.down").font(.caption.bold()).foregroundStyle(AppTheme.primary); Spacer(); Label("排序", systemImage: "line.3.horizontal.decrease").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }; ForEach(DemoData.recipes) { recipe in ApricotCard { HStack(spacing: 12) { FoodThumbnail(recipe: recipe); VStack(alignment: .leading, spacing: 5) { Text(recipe.name).font(.subheadline.bold()); HStack { ForEach(recipe.categories, id: \.self) { Pill(text: $0, color: $0 == "肉食" ? .pink : AppTheme.warning) } }; Text("已记录 \(recipe.count) 次 · 上次 \(recipe.last)").font(.caption2.weight(.medium)).foregroundStyle(AppTheme.secondaryInk) }; Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(AppTheme.secondaryInk) } }.padding(0) } }.padding(.horizontal, 17).padding(.bottom, 108) }.background(AppTheme.background) }
}

struct AnalysisView: View {
    var body: some View { ScrollView(showsIndicators: false) { VStack(spacing: 15) { PageTitle(title: "接受度分析", trailing: "筛选"); ApricotCard { VStack(spacing: 10) { Text("近14天（5.7-5.20）反应比例").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); ReactionRatioDonut(); HStack(spacing: 10) { Legend(text: "喜欢 64%·18", color: AppTheme.success); Legend(text: "一般 21%·6", color: AppTheme.warning); Legend(text: "拒绝 11%·3", color: AppTheme.danger); Legend(text: "过敏 4%·1", color: .purple) } } }.background(LinearGradient(colors: [.white, AppTheme.warmSurface.opacity(0.5)], startPoint: .top, endPoint: .bottom)).clipShape(RoundedRectangle(cornerRadius: 22)); HStack { Text("菜谱接受度排行榜").font(.headline); Spacer(); Text("更多").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }; AcceptanceRanking() }.padding(.horizontal, 17).padding(.bottom, 108) }.background(AppTheme.background) }
}

struct Legend: View { let text: String; let color: Color; var body: some View { HStack(spacing: 3) { Circle().fill(color).frame(width: 7, height: 7); Text(text).font(.caption2.weight(.semibold)) } } }

struct AcceptanceRanking: View {
    private let rows: [(Recipe, String, Color)] = [
        (DemoData.recipes[1], "89%", AppTheme.success),
        (DemoData.recipes[0], "78%", AppTheme.success),
        (DemoData.recipes[4], "67%", AppTheme.success),
        (DemoData.recipes[3], "50%", AppTheme.warning)
    ]
    var body: some View {
        ApricotCard {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.0.id) { index, row in
                    HStack(spacing: 11) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(index == 3 ? AppTheme.secondaryInk : .white)
                            .frame(width: 24, height: 24)
                            .background(index == 0 ? AppTheme.primary : index == 3 ? AppTheme.warmSurface : AppTheme.primary.opacity(0.56))
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                        FoodThumbnail(recipe: row.0, size: 40)
                        Text(row.0.name).font(.subheadline.bold()).lineLimit(1)
                        Spacer(minLength: 4)
                        Pill(text: row.1, color: row.2)
                    }
                    .padding(.vertical, 9)
                    if index < rows.count - 1 { Divider().overlay(AppTheme.warmSurface) }
                }
            }
        }
        .padding(0)
    }
}

struct ReactionRatioDonut: View {
    private let width: CGFloat = 21
    var body: some View {
        ZStack {
            Circle().stroke(AppTheme.warmSurface, lineWidth: width)
            Circle().trim(from: 0.000, to: 0.640).stroke(AppTheme.success, style: StrokeStyle(lineWidth: width, lineCap: .round)).rotationEffect(.degrees(-90))
            Circle().trim(from: 0.650, to: 0.860).stroke(AppTheme.warning, style: StrokeStyle(lineWidth: width, lineCap: .round)).rotationEffect(.degrees(-90))
            Circle().trim(from: 0.870, to: 0.980).stroke(AppTheme.danger, style: StrokeStyle(lineWidth: width, lineCap: .round)).rotationEffect(.degrees(-90))
            Circle().trim(from: 0.990, to: 1.000).stroke(Color(red: 0.56, green: 0.42, blue: 0.72), style: StrokeStyle(lineWidth: width, lineCap: .round)).rotationEffect(.degrees(-90))
            VStack(spacing: -2) {
                Text("28").font(.system(size: 30, weight: .bold)).foregroundStyle(AppTheme.ink) + Text("餐").font(.subheadline.weight(.bold))
                Text("总记录").font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(width: 172, height: 172)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("近14天反应比例：喜欢18餐，一般6餐，拒绝3餐，过敏1餐")
    }
}

struct HistoryView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                PageTitle(title: "历史记录", trailing: "筛选")
                HistoryCalendar()
                HistoryRecordCard(date: "5月20日 周一", meal: "早餐", time: "08:30", dishes: MealDishFixtures.breakfast, overallReaction: .like, note: "吃得开心，胃口很好，便便正常。")
                HistoryRecordCard(date: "5月19日 周日", meal: "午餐", time: "12:30", dishes: MealDishFixtures.lunch, overallReaction: .neutral, note: "少量打嗝，无其他不适。")
            }
            .padding(.horizontal, 17)
            .padding(.bottom, 108)
        }
        .background(AppTheme.background)
    }
}

struct HistoryCalendar: View {
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    private let dates = [13, 14, 15, 16, 17, 18, 19]
    private let recordedDates: Set<Int> = [13, 16, 18]
    var body: some View {
        ApricotCard {
            VStack(spacing: 11) {
                HStack { Text("2024年5月").font(.system(size: 17, weight: .bold)); Spacer(); Image(systemName: "chevron.left"); Image(systemName: "chevron.right") }.foregroundStyle(AppTheme.secondaryInk)
                HStack { ForEach(weekdays, id: \.self) { Text($0).font(.caption.weight(.bold)).foregroundStyle(AppTheme.secondaryInk.opacity(0.72)).frame(maxWidth: .infinity) } }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 7) {
                    ForEach(dates, id: \.self) { date in CalendarDateCell(date: date, isRecorded: recordedDates.contains(date), isSelected: date == 19) }
                }
            }
        }
    }
}

struct CalendarDateCell: View {
    let date: Int; let isRecorded: Bool; let isSelected: Bool
    var body: some View {
        VStack(spacing: 4) {
            Text("\(date)").font(.subheadline.weight(.bold)).foregroundStyle(isSelected ? .white : (date > 21 ? AppTheme.secondaryInk.opacity(0.65) : AppTheme.ink)).frame(maxWidth: .infinity).padding(.vertical, 7).background(isSelected ? AppTheme.primary : .clear).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: isSelected ? AppTheme.primary.opacity(0.32) : .clear, radius: 7, y: 4)
            Circle().fill(isRecorded && !isSelected ? AppTheme.primary : .clear).frame(width: 5, height: 5)
        }
    }
}

struct HistoryRecordCard: View {
    let date: String; let meal: String; let time: String; let dishes: [MealDish]; let overallReaction: Reaction; let note: String
    var body: some View {
        ApricotCard {
            VStack(alignment: .leading, spacing: 11) {
                Text(date).font(.subheadline.weight(.bold)).foregroundStyle(AppTheme.primary)
                HStack(spacing: 8) {
                    Image(systemName: meal == "早餐" ? "sun.max.fill" : "sun.max").foregroundStyle(AppTheme.warning)
                    Text(meal).font(.headline)
                    Text(time).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
                }
                HStack(alignment: .top, spacing: 14) {
                    HistoryMealPhoto(dish: dishes[0])
                    VStack(spacing: 8) {
                        ForEach(dishes) { dish in
                            HStack {
                                Text(dish.name).font(.subheadline.weight(.bold)).foregroundStyle(AppTheme.ink)
                                Spacer()
                                Text(dish.reaction.title).font(.subheadline.weight(.bold)).foregroundStyle(dish.reaction.color)
                                Image(systemName: dish.reaction == .like ? "face.smiling" : "face.dashed").foregroundStyle(dish.reaction.color)
                            }
                        }
                    }
                }
                Divider().overlay(AppTheme.warmSurface)
                HStack {
                    Text("整体接受度").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
                    Spacer()
                    Pill(text: overallReaction.title, color: overallReaction.color)
                }
                Text("宝宝状态：\(note)").font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.secondaryInk).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 1)
            }
        }
    }
}

struct MealDishThumbnail: View {
    let dish: MealDish; let size: CGFloat
    var body: some View { Image(systemName: dish.symbol).font(.system(size: size * 0.38, weight: .semibold)).foregroundStyle(.white.opacity(0.9)).frame(width: size, height: size).background(LinearGradient(colors: dish.colors, startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: size * 0.26)).apricotElevation(.control) }
}

struct HistoryMealPhoto: View {
    let dish: MealDish
    var body: some View {
        Image(systemName: "photo.fill")
            .font(.system(size: 28, weight: .medium))
            .foregroundStyle(.white.opacity(0.92))
            .frame(width: 130, height: 104)
            .background(LinearGradient(colors: dish.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .apricotElevation(.control)
            .accessibilityLabel("餐后照片")
    }
}

struct FloatingTabBar: View {
    @Binding var tab: AppTab; let add: () -> Void
    var body: some View { ZStack { HStack(spacing: 0) { tabItem(.home); tabItem(.recipes); Spacer().frame(width: 58); tabItem(.analysis); tabItem(.history) }.padding(.horizontal, 8).frame(height: 62).background(.white).clipShape(Capsule()).apricotElevation(.primary); Button(action: add) { Image(systemName: "plus").font(.system(size: 26, weight: .medium)).foregroundStyle(.white).frame(width: 54, height: 54).background(LinearGradient(colors: [Color(red: 1, green: 0.60, blue: 0.36), Color(red: 1, green: 0.42, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)).overlay { Circle().stroke(.white.opacity(0.42), lineWidth: 1).padding(1) }.clipShape(Circle()).shadow(color: AppTheme.primary.opacity(0.50), radius: 8, y: 8).shadow(color: AppTheme.ink.opacity(0.14), radius: 3, y: 2) }.offset(y: -7) }.padding(.horizontal, 18).padding(.bottom, 12) }
    private func tabItem(_ item: AppTab) -> some View { Button { tab = item } label: { VStack(spacing: 3) { Image(systemName: item.symbol).font(.system(size: 18, weight: .semibold)).frame(width: 42, height: 28).background(tab == item ? AppTheme.warmSurface : .clear).clipShape(Capsule()); Text(item.title).font(.caption2.weight(.bold)) }.foregroundStyle(tab == item ? AppTheme.primary : AppTheme.secondaryInk).frame(maxWidth: .infinity) } }
}

struct MealRecordView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack { ScrollView(showsIndicators: false) { VStack(spacing: 14) {
            HStack { Button { dismiss() } label: { Image(systemName: "chevron.left").font(.headline).frame(width: 40, height: 40).background(.white).clipShape(RoundedRectangle(cornerRadius: 14)).apricotElevation(.control) }; Spacer(); Text("记录一餐").font(.title3.bold()); Spacer(); Text("清空").font(.caption.weight(.bold)).foregroundStyle(AppTheme.secondaryInk) }
            ApricotCard { VStack(alignment: .leading, spacing: 4) { Text("日期").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); HStack { Text("2024年5月20日").font(.headline); Spacer(); Image(systemName: "chevron.right").foregroundStyle(AppTheme.primary) } } }
            VStack(alignment: .leading, spacing: 8) { Text("选择餐次").font(.subheadline.bold()); HStack(spacing: 7) { ForEach(["早餐", "午餐", "晚餐", "加餐"], id: \.self) { MealOption(title: $0, isSelected: $0 == "早餐") } } }
            VStack(alignment: .leading, spacing: 8) { Text("选择菜谱").font(.subheadline.bold()); ApricotCard { VStack(spacing: 0) { ForEach(Array(MealDishFixtures.breakfast.enumerated()), id: \.element.id) { index, dish in VStack(spacing: 0) { HStack { MealDishThumbnail(dish: dish, size: 38); Text(dish.name).font(.subheadline.bold()); Spacer(); Pill(text: dish.reaction == .like ? "喜欢" : "一般", color: dish.reaction.color); Image(systemName: "xmark").font(.caption).foregroundStyle(AppTheme.secondaryInk) }.padding(.vertical, 8); if index < MealDishFixtures.breakfast.count - 1 { Divider().overlay(AppTheme.warmSurface) } } } } }; Label("添加其他食物", systemImage: "plus").font(.subheadline.weight(.bold)).foregroundStyle(AppTheme.primary).frame(maxWidth: .infinity, alignment: .center).padding(.top, 2) }
            VStack(alignment: .leading, spacing: 8) { Text("上传照片（选填）").font(.subheadline.bold()); Image(systemName: "camera").foregroundStyle(AppTheme.secondaryInk).frame(maxWidth: .infinity, minHeight: 64).background(AppTheme.warmSurface.opacity(0.6)).clipShape(RoundedRectangle(cornerRadius: 16)) }
            VStack(alignment: .leading, spacing: 8) { Text("接受度").font(.subheadline.bold()); HStack(spacing: 7) { ForEach(Reaction.allCases) { ReactionOption(reaction: $0, isSelected: $0 == .like) } } }
            VStack(alignment: .leading, spacing: 8) {
                Text("备注（选填）").font(.subheadline.bold())
                Text("记录食量、反应或饮食情况…")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    .padding(12)
                    .background(AppTheme.warmSurface.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay { RoundedRectangle(cornerRadius: 16).stroke(AppTheme.warmSurface, lineWidth: 1) }
            }
            Text("保存").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15).background(LinearGradient(colors: [.orange.opacity(0.72), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 17)).apricotElevation(.primary)
        }.padding(17) }.background(AppTheme.background) }.presentationDetents([.large])
    }
}

struct MealOption: View { let title: String; let isSelected: Bool; var body: some View { Text(title).font(.caption.weight(.bold)).foregroundStyle(isSelected ? .white : AppTheme.secondaryInk).frame(maxWidth: .infinity).padding(.vertical, 10).background(isSelected ? LinearGradient(colors: [.orange.opacity(0.72), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)).clipShape(RoundedRectangle(cornerRadius: 15)).apricotElevation(isSelected ? .primary : .control) } }

struct ReactionOption: View { let reaction: Reaction; let isSelected: Bool; var body: some View { VStack(spacing: 3) { Image(systemName: reaction.symbol).font(.system(size: 19, weight: .medium)); Text(reaction.title).font(.caption2.weight(isSelected ? .bold : .semibold)) }.foregroundStyle(reaction.color).frame(maxWidth: .infinity).padding(.vertical, 8).background(isSelected ? reaction.color.opacity(0.15) : .white).clipShape(RoundedRectangle(cornerRadius: 14)).shadow(color: isSelected ? reaction.color.opacity(0.28) : AppTheme.primary.opacity(0.08), radius: isSelected ? 2 : 6, y: isSelected ? 4 : 3) } }

struct FormCard: View { let title: String; let value: String; let symbol: String; var body: some View { ApricotCard { HStack { Image(systemName: symbol).foregroundStyle(AppTheme.primary).frame(width: 26); Text(title).font(.subheadline.bold()); Spacer(); Text(value).font(.subheadline).foregroundStyle(AppTheme.secondaryInk); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(AppTheme.secondaryInk) } }.padding(0) } }

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = "泡泡"
    @State private var monthAge = "10个月20天"
    @State private var gender = "男宝"
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var isShareSheetPresented = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 17) {
                    header
                    profileCard
                    dataManagementCard
                    exportButton
                    if let exportError {
                        Label(exportError, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 17)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .background(AppTheme.background)
            .sheet(isPresented: $isShareSheetPresented) {
                if let exportURL {
                    ActivityShareSheet(activityItems: [exportURL])
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Label("关闭", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .apricotElevation(.control)
            }
            .accessibilityLabel("关闭设置")
            Spacer()
            Text("设置").font(.title3.bold()).foregroundStyle(AppTheme.ink)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var profileCard: some View {
        ApricotCard {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.orange.opacity(0.68), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 88, height: 88)
                        .apricotElevation(.primary)
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                }
                VStack(alignment: .leading, spacing: 12) {
                    SettingsTextField(title: "宝宝昵称", text: $nickname, symbol: "heart.fill")
                    SettingsTextField(title: "月龄", text: $monthAge, symbol: "calendar")
                    VStack(alignment: .leading, spacing: 8) {
                        Label("性别", systemImage: "person.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                        Picker("性别", selection: $gender) {
                            Text("男宝").tag("男宝")
                            Text("女宝").tag("女宝")
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
        }
    }

    private var dataManagementCard: some View {
        ApricotCard {
            VStack(alignment: .leading, spacing: 9) {
                Label("数据管理", systemImage: "externaldrive.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Text("导出包含宝宝资料、菜谱和用餐记录的 JSON 文件，便于自行备份或迁移。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var exportButton: some View {
        Button(action: exportJSON) {
            Label("导出 JSON", systemImage: "square.and.arrow.up")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(LinearGradient(colors: [.orange.opacity(0.70), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .apricotElevation(.primary)
        }
        .accessibilityHint("生成并分享宝宝辅食数据 JSON 文件")
    }

    private func exportJSON() {
        do {
            exportURL = try ExportDocument.makeURL()
            exportError = nil
            isShareSheetPresented = true
        } catch {
            exportURL = nil
            exportError = "导出失败，请稍后重试。"
        }
    }
}

struct SettingsTextField: View {
    let title: String
    @Binding var text: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            TextField(title, text: $text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(AppTheme.warmSurface.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(AppTheme.warmSurface, lineWidth: 1) }
        }
    }
}

struct ExportDocument {
    static func makeURL() throws -> URL {
        let document: [String: Any] = [
            "baby": [
                "name": "泡泡",
                "age": "10个月20天",
                "gender": "男宝"
            ],
            "recipes": DemoData.recipes.map { recipe in
                [
                    "name": recipe.name,
                    "categories": recipe.categories,
                    "recordCount": recipe.count,
                    "lastRecordedAt": recipe.last
                ]
            },
            "mealRecords": [
                mealRecord(date: "2024-05-20", meal: "早餐", time: "08:30", dishes: MealDishFixtures.breakfast, note: "吃得开心，胃口很好，便便正常。"),
                mealRecord(date: "2024-05-19", meal: "午餐", time: "12:30", dishes: MealDishFixtures.lunch, note: "少量打嗝，无其他不适。")
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("baby-food-diary-export.json")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func mealRecord(
        date: String,
        meal: String,
        time: String,
        dishes: [MealDish],
        note: String
    ) -> [String: Any] {
        [
            "date": date,
            "meal": meal,
            "time": time,
            "dishes": dishes.map { ["name": $0.name, "reaction": $0.reaction.rawValue] },
            "note": note
        ]
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
