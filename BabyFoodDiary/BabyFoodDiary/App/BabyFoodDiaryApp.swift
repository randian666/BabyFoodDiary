import SwiftUI

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
}

struct RootView: View {
    @State private var tab: AppTab = .home
    @State private var isRecording = false
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab { case .home: HomeView(); case .recipes: RecipeLibraryView(); case .analysis: AnalysisView(); case .history: HistoryView() }
            }
            FloatingTabBar(tab: $tab) { isRecording = true }
        }
        .sheet(isPresented: $isRecording) { MealRecordView() }
    }
}

struct ApricotCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.padding(16).background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 22)).shadow(color: AppTheme.primary.opacity(0.11), radius: 12, y: 6) }
}

struct FoodThumbnail: View {
    let recipe: Recipe; var size: CGFloat = 60
    var body: some View { Image(systemName: recipe.symbol).font(.system(size: size * 0.38, weight: .semibold)).foregroundStyle(.white.opacity(0.92)).frame(width: size, height: size).background(LinearGradient(colors: recipe.colors, startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: size * 0.24)) }
}

struct Pill: View {
    let text: String; var color: Color = AppTheme.primary; var body: some View { Text(text).font(.caption2.weight(.bold)).foregroundStyle(color).padding(.horizontal, 9).padding(.vertical, 5).background(color.opacity(0.13)).clipShape(Capsule()) }
}

struct PageTitle: View {
    let title: String; var trailing: String? = nil
    var body: some View { HStack { Text(title).font(.system(size: 23, weight: .bold)).foregroundStyle(AppTheme.ink); Spacer(); if let trailing { Label(trailing, systemImage: "line.3.horizontal.decrease.circle").font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) } }.padding(.top, 8) }
}

struct HomeView: View {
    var body: some View {
        ScrollView(showsIndicators: false) { VStack(spacing: 15) {
            HStack { VStack(alignment: .leading, spacing: 3) { Text("7月10日 周四").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text("泡泡的辅食日记").font(.system(size: 23, weight: .bold)) }; Spacer(); Image(systemName: "bell").frame(width: 42, height: 42).background(.white).clipShape(RoundedRectangle(cornerRadius: 15)).shadow(color: AppTheme.primary.opacity(0.12), radius: 8, y: 4) }
            ApricotCard { HStack(spacing: 13) { Circle().fill(LinearGradient(colors: [.orange.opacity(0.6), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 52, height: 52); VStack(alignment: .leading) { Text("泡泡").font(.title3.bold()); HStack { Pill(text: "10个月20天", color: AppTheme.warning); Pill(text: "男宝", color: .pink) } }; Spacer(); Image(systemName: "sun.max.fill").font(.title2).foregroundStyle(.yellow) } }.background(LinearGradient(colors: [AppTheme.warmSurface, .yellow.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 22))
            HStack { Text("今日概览").font(.headline); Spacer(); Text("2024年5月20日 ›").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }
            HStack(spacing: 10) { Metric(title: "重点观察", value: "无", color: AppTheme.secondaryInk); Metric(title: "好久没吃", value: "3 道", color: AppTheme.success); Metric(title: "已记录", value: "1 餐", color: AppTheme.primary) }
            HStack { Text("好久没吃的菜谱").font(.headline); Spacer(); Label("换一换", systemImage: "arrow.clockwise").font(.caption.weight(.bold)).foregroundStyle(AppTheme.primary) }
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 11) { ForEach(DemoData.recommendations) { recipe in VStack(alignment: .leading, spacing: 7) { FoodThumbnail(recipe: recipe, size: 124); Text(recipe.name).font(.subheadline.bold()).lineLimit(2); Text("已 \(recipe.days) 天未吃").font(.caption.weight(.medium)).foregroundStyle(AppTheme.secondaryInk); Pill(text: "✓ 安全复吃", color: AppTheme.success) }.frame(width: 144, alignment: .leading).padding(10).background(.white).clipShape(RoundedRectangle(cornerRadius: 19)).shadow(color: AppTheme.primary.opacity(0.1), radius: 8, y: 4) } }.padding(.vertical, 2) }
            ApricotCard { HStack { Image(systemName: "leaf.fill").foregroundStyle(AppTheme.success).frame(width: 42, height: 42).background(AppTheme.success.opacity(0.13)).clipShape(RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading) { Text("重点观察").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text("这几天没有需要特别观察的食材").font(.subheadline.weight(.semibold)) }; Spacer() } }
        }.padding(.horizontal, 17).padding(.top, 12).padding(.bottom, 108) }.background(AppTheme.background)
    }
}

struct Metric: View { let title: String; let value: String; let color: Color; var body: some View { ApricotCard { VStack(spacing: 5) { Text(title).font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text(value).font(.subheadline.bold()).foregroundStyle(color) }.frame(maxWidth: .infinity) }.padding(0) } }

struct RecipeLibraryView: View {
    var body: some View { ScrollView(showsIndicators: false) { VStack(spacing: 13) { PageTitle(title: "菜谱库"); HStack { Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.secondaryInk); Text("搜索食材或菜谱").font(.subheadline).foregroundStyle(AppTheme.secondaryInk); Spacer() }.padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 18)); ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(["全部", "主食", "肉食", "蔬菜", "水果"], id: \.self) { label in Text(label).font(.subheadline.bold()).foregroundStyle(label == "全部" ? .white : AppTheme.secondaryInk).padding(.horizontal, 14).padding(.vertical, 8).background(label == "全部" ? AppTheme.primary : .white).clipShape(Capsule()) } } }; HStack { Text("按记录次数⌄").font(.subheadline.bold()); Spacer(); Label("排序", systemImage: "arrow.up.arrow.down").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }; ForEach(DemoData.recipes) { recipe in ApricotCard { HStack(spacing: 12) { FoodThumbnail(recipe: recipe); VStack(alignment: .leading, spacing: 5) { Text(recipe.name).font(.subheadline.bold()); HStack { ForEach(recipe.categories, id: \.self) { Pill(text: $0, color: $0 == "肉食" ? .pink : AppTheme.warning) } }; Text("已记录 \(recipe.count) 次 · 上次 \(recipe.last)").font(.caption2.weight(.medium)).foregroundStyle(AppTheme.secondaryInk) }; Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(AppTheme.secondaryInk) } }.padding(0) } }.padding(.horizontal, 17).padding(.bottom, 108) }.background(AppTheme.background) }
}

struct AnalysisView: View {
    var body: some View { ScrollView(showsIndicators: false) { VStack(spacing: 15) { PageTitle(title: "接受度分析", trailing: "筛选"); ApricotCard { VStack(spacing: 11) { Text("近14天（5.7-5.20）反应比例").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); ZStack { Circle().stroke(AppTheme.warmSurface, lineWidth: 17); Circle().trim(from: 0, to: 0.64).stroke(AppTheme.success, style: StrokeStyle(lineWidth: 17, lineCap: .round)).rotationEffect(.degrees(-90)); VStack { Text("11").font(.system(size: 34, weight: .bold)); Text("餐次记录").font(.caption).foregroundStyle(AppTheme.secondaryInk) } }.frame(width: 164, height: 164); HStack { ForEach(Reaction.allCases) { reaction in VStack(spacing: 4) { Circle().fill(reaction.color).frame(width: 8, height: 8); Text(reaction.title).font(.caption2); Text(reaction == .like ? "7" : reaction == .neutral ? "3" : "1").font(.caption.bold()) } .frame(maxWidth: .infinity) } } } }.background(LinearGradient(colors: [.white, AppTheme.warmSurface.opacity(0.5)], startPoint: .top, endPoint: .bottom)).clipShape(RoundedRectangle(cornerRadius: 22)); HStack { Text("菜谱接受度排行").font(.headline); Spacer(); Text("近14天").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }; ForEach(DemoData.recipes.prefix(4)) { recipe in ApricotCard { VStack(alignment: .leading, spacing: 9) { HStack { FoodThumbnail(recipe: recipe, size: 44); Text(recipe.name).font(.subheadline.bold()); Spacer(); Pill(text: "喜欢", color: AppTheme.success) }; GeometryReader { proxy in ZStack(alignment: .leading) { Capsule().fill(AppTheme.warmSurface); Capsule().fill(AppTheme.success).frame(width: proxy.size.width * 0.78) } }.frame(height: 8); Text("记录 \(recipe.count) 次 · 最近反应 喜欢").font(.caption).foregroundStyle(AppTheme.secondaryInk) } }.padding(0) } }.padding(.horizontal, 17).padding(.bottom, 108) }.background(AppTheme.background) }
}

struct HistoryView: View {
    var body: some View { ScrollView(showsIndicators: false) { VStack(spacing: 14) { PageTitle(title: "历史记录", trailing: "最近14天"); Text("最近 14 天数据").font(.caption.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(AppTheme.secondaryInk); HistoryDay(title: "今天 · 07月10日", recipe: DemoData.recipes[0], meal: "午餐", reaction: .like); HistoryDay(title: "昨天 · 07月09日", recipe: DemoData.recipes[1], meal: "早餐", reaction: .neutral); HistoryDay(title: "07月07日 周一", recipe: DemoData.recipes[3], meal: "晚餐", reaction: .like) }.padding(.horizontal, 17).padding(.bottom, 108) }.background(AppTheme.background) }
}

struct HistoryDay: View { let title: String; let recipe: Recipe; let meal: String; let reaction: Reaction; var body: some View { VStack(alignment: .leading, spacing: 9) { Text(title).font(.subheadline.bold()).foregroundStyle(AppTheme.ink); ApricotCard { HStack { FoodThumbnail(recipe: recipe); VStack(alignment: .leading, spacing: 5) { Text(meal).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text(recipe.name).font(.subheadline.bold()); Pill(text: reaction.title, color: reaction.color) }; Spacer(); Image(systemName: "square.and.pencil").foregroundStyle(AppTheme.secondaryInk) } }.padding(0) } } }

struct FloatingTabBar: View {
    @Binding var tab: AppTab; let add: () -> Void
    var body: some View { ZStack { HStack(spacing: 0) { tabItem(.home); tabItem(.recipes); Spacer().frame(width: 58); tabItem(.analysis); tabItem(.history) }.padding(.horizontal, 8).frame(height: 62).background(.white).clipShape(Capsule()).shadow(color: AppTheme.primary.opacity(0.26), radius: 16, y: 8); Button(action: add) { Image(systemName: "plus").font(.title3.bold()).foregroundStyle(.white).frame(width: 54, height: 54).background(LinearGradient(colors: [.orange.opacity(0.75), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(Circle()).shadow(color: AppTheme.primary.opacity(0.4), radius: 9, y: 5) }.offset(y: -7) }.padding(.horizontal, 18).padding(.bottom, 12) }
    private func tabItem(_ item: AppTab) -> some View { Button { tab = item } label: { VStack(spacing: 3) { Image(systemName: item.symbol).font(.system(size: 18, weight: .semibold)).frame(width: 42, height: 28).background(tab == item ? AppTheme.warmSurface : .clear).clipShape(Capsule()); Text(item.title).font(.caption2.weight(.bold)) }.foregroundStyle(tab == item ? AppTheme.primary : AppTheme.secondaryInk).frame(maxWidth: .infinity) } }
}

struct MealRecordView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View { NavigationStack { ScrollView(showsIndicators: false) { VStack(spacing: 15) { HStack { Text("记录一餐").font(.title2.bold()); Spacer(); Button("取消") { dismiss() }.foregroundStyle(AppTheme.secondaryInk) }; FormCard(title: "日期", value: "2024年5月20日", symbol: "calendar"); FormCard(title: "餐次", value: "午餐", symbol: "sun.max"); ApricotCard { VStack(alignment: .leading, spacing: 11) { Text("本餐菜谱").font(.subheadline.bold()); HStack { FoodThumbnail(recipe: DemoData.recipes[0], size: 48); Text(DemoData.recipes[0].name).font(.subheadline.bold()); Spacer(); Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.secondaryInk) }; Label("添加菜谱或食物", systemImage: "plus.circle").font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.primary) } }; ApricotCard { VStack(alignment: .leading, spacing: 10) { Text("照片（可选）").font(.subheadline.bold()); Image(systemName: "camera.fill").font(.title2).foregroundStyle(AppTheme.secondaryInk).frame(maxWidth: .infinity, minHeight: 92).background(AppTheme.warmSurface.opacity(0.55)).clipShape(RoundedRectangle(cornerRadius: 16)) } }; ApricotCard { VStack(alignment: .leading, spacing: 11) { Text("整体反应").font(.subheadline.bold()); HStack { ForEach(Reaction.allCases) { reaction in VStack(spacing: 6) { Image(systemName: reaction.symbol).font(.title3); Text(reaction.title).font(.caption2.bold()) }.foregroundStyle(reaction == .like ? .white : reaction.color).frame(maxWidth: .infinity).padding(.vertical, 10).background(reaction == .like ? reaction.color : reaction.color.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 13)) } } } }; ApricotCard { VStack(alignment: .leading, spacing: 8) { Text("备注（可选）").font(.subheadline.bold()); Text("记录食量、反应或饮食情况…").font(.subheadline).foregroundStyle(AppTheme.secondaryInk).frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading) } }; Text("保存记录").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(AppTheme.primary).clipShape(RoundedRectangle(cornerRadius: 18)) }.padding(17) }.background(AppTheme.background) }.presentationDetents([.large]) }
}

struct FormCard: View { let title: String; let value: String; let symbol: String; var body: some View { ApricotCard { HStack { Image(systemName: symbol).foregroundStyle(AppTheme.primary).frame(width: 26); Text(title).font(.subheadline.bold()); Spacer(); Text(value).font(.subheadline).foregroundStyle(AppTheme.secondaryInk); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(AppTheme.secondaryInk) } }.padding(0) } }
