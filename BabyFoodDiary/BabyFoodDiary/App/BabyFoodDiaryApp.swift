import SwiftUI
import UIKit
import SwiftData
import Photos
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Quick Action support

private extension Notification.Name {
    static let recordMealQuickAction = Notification.Name("BabyFoodDiary.recordMealQuickAction")
}

private enum DiaryQuickActionCenter {
    private(set) static var hasPendingRecordMeal = false

    static func requestRecordMeal() {
        hasPendingRecordMeal = true
        NotificationCenter.default.post(name: .recordMealQuickAction, object: nil)
    }

    static func consumeRecordMeal() -> Bool {
        guard hasPendingRecordMeal else { return false }
        hasPendingRecordMeal = false
        return true
    }
}

final class DiarySceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard connectionOptions.shortcutItem?.type == "record" else { return }
        DiaryQuickActionCenter.requestRecordMeal()
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard shortcutItem.type == "record" else {
            completionHandler(false)
            return
        }
        DiaryQuickActionCenter.requestRecordMeal()
        completionHandler(true)
    }
}

final class DiaryAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(type: "record", localizedTitle: "记录一餐", localizedSubtitle: nil,
                                      icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill"), userInfo: nil)
        ]
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = DiarySceneDelegate.self
        }
        return configuration
    }

    func consumeRecordMealLaunchAction() -> Bool {
        DiaryQuickActionCenter.consumeRecordMeal()
    }
}

@main
struct BabyFoodDiaryApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: DiaryAppDelegate
    let container: ModelContainer
    @State private var store: DiaryStore

    init() {
        let container = try! DiaryStore.makeContainer()
        self.container = container
        _store = State(initialValue: DiaryStore(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView(consumeLaunchQuickAction: appDelegate.consumeRecordMealLaunchAction)
                .environment(store)
                .modelContainer(container)
        }
    }
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
    let id: UUID
    let name: String
    let categories: [String]
    let count: Int
    let last: String
    let days: Int
    let symbol: String
    let iconID: String
    let colorHexA: String
    let colorHexB: String
    var colors: [Color] { [Color(hex: colorHexA), Color(hex: colorHexB)] }

    init(id: UUID = UUID(), name: String, categories: [String], count: Int, last: String, days: Int, symbol: String, iconID: String = FoodIconCatalog.defaultID, colorHexA: String, colorHexB: String) {
        self.id = id; self.name = name; self.categories = categories; self.count = count; self.last = last; self.days = days; self.symbol = symbol; self.iconID = iconID; self.colorHexA = colorHexA; self.colorHexB = colorHexB
    }
}

struct MealDish: Identifiable {
    let id: UUID
    let name: String
    let symbol: String
    let iconID: String
    let colorHexA: String
    let colorHexB: String
    var reaction: Reaction
    var colors: [Color] { [Color(hex: colorHexA), Color(hex: colorHexB)] }

    init(id: UUID = UUID(), name: String, symbol: String, iconID: String = FoodIconCatalog.defaultID, colorHexA: String, colorHexB: String, reaction: Reaction) {
        self.id = id; self.name = name; self.symbol = symbol; self.iconID = iconID; self.colorHexA = colorHexA; self.colorHexB = colorHexB; self.reaction = reaction
    }
}

/// Identifiable payload used to present the record sheet (new or editing an existing record).
struct RecordSeed: Identifiable {
    let id: UUID
    let form: MealRecordForm
}

private struct IconEditTarget: Identifiable {
    let id = UUID()
    let dishID: UUID?
    let recipeID: UUID?
}

private enum HomeOverviewDestination: Identifiable, Equatable {
    case watch, longAgo

    var id: String {
        switch self {
        case .watch: return "watch"
        case .longAgo: return "longAgo"
        }
    }
}

struct RootView: View {
    @Environment(DiaryStore.self) private var store
    let consumeLaunchQuickAction: () -> Bool
    @State private var tab: AppTab = .home
    @State private var recordSeed: RecordSeed?
    @State private var selectedRecipe: Recipe?
    @State private var overviewDestination: HomeOverviewDestination?
    @State private var isSettingsPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    HomeView(
                        showSettings: { isSettingsPresented = true },
                        onRecipeTap: { selectedRecipe = $0 },
                        onShowWatch: { overviewDestination = .watch },
                        onShowLongAgo: { overviewDestination = .longAgo },
                        onShowHistory: { tab = .history }
                    )
                case .recipes: RecipeLibraryView(onRecipeTap: { selectedRecipe = $0 })
                case .analysis: AnalysisView(onRecipeTap: { selectedRecipe = $0 })
                case .history: HistoryView()
                }
            }
            FloatingTabBar(tab: tab, select: selectTab) { recordSeed = RecordSeed(id: UUID(), form: .blank) }
        }
        .sheet(item: $recordSeed) { seed in MealRecordView(form: seed.form) }
        .sheet(item: $overviewDestination) { destination in
            RecipeOverviewSheet(destination: destination)
        }
        .fullScreenCover(item: $selectedRecipe) { recipe in
            RecipeDetailView(
                recipe: recipe,
                onRecord: {
                    selectedRecipe = nil
                    DispatchQueue.main.async {
                        recordSeed = RecordSeed(id: UUID(), form: .prefill(recipe: recipe))
                    }
                },
                onViewHistory: {
                    selectedRecipe = nil
                    tab = .history
                }
            )
        }
        .fullScreenCover(isPresented: $isSettingsPresented) { SettingsView() }
        .onAppear {
            guard consumeLaunchQuickAction() else { return }
            openRecordFromQuickAction()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recordMealQuickAction)) { _ in
            _ = consumeLaunchQuickAction()
            openRecordFromQuickAction()
        }
    }

    private func selectTab(_ newTab: AppTab) {
        tab = newTab
    }

    private func openRecordFromQuickAction() {
        selectedRecipe = nil
        overviewDestination = nil
        isSettingsPresented = false
        DispatchQueue.main.async {
            recordSeed = RecordSeed(id: UUID(), form: .blank)
        }
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
    var body: some View { FoodIconThumbnail(iconID: recipe.iconID, symbol: recipe.symbol, colors: recipe.colors, size: size) }
}

struct FoodIconThumbnail: View {
    let iconID: String; let symbol: String; let colors: [Color]; var size: CGFloat = 60
    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            if UIImage(named: iconID) != nil {
                Image(iconID).resizable().scaledToFit().padding(size * 0.15)
            } else {
                Image(systemName: symbol).font(.system(size: size * 0.38, weight: .semibold)).foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24))
        .apricotElevation(.control)
    }
}

/// Baby avatar: shows the chosen photo, or the warm-orange gradient (optionally with a fallback symbol) when none is set.
struct BabyAvatar: View {
    let data: Data?
    var size: CGFloat
    var cornerRadius: CGFloat
    var fallbackSymbol: String? = nil
    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [.orange.opacity(0.62), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        if let fallbackSymbol {
                            Image(systemName: fallbackSymbol)
                                .font(.system(size: size * 0.48, weight: .medium))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct Pill: View {
    let text: String; var color: Color = AppTheme.primary; var body: some View { Text(text).font(.caption2.weight(.bold)).foregroundStyle(color).padding(.horizontal, 9).padding(.vertical, 5).background(color.opacity(0.13)).clipShape(Capsule()).apricotElevation(.control) }
}

struct AnimatedNumberText: View {
    let value: Int
    let suffix: String
    let font: Font
    let color: Color
    var delay: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedValue = 0
    @State private var hasAppeared = false

    var body: some View {
        Text("\(displayedValue)\(suffix)")
            .font(font)
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(displayedValue)))
            .onAppear { animateInitialValue() }
            .onChange(of: value) { _, newValue in
                guard hasAppeared else { return }
                if reduceMotion {
                    displayedValue = newValue
                } else {
                    withAnimation(.easeOut(duration: 0.42)) { displayedValue = newValue }
                }
            }
    }

    private func animateInitialValue() {
        guard !hasAppeared else { return }
        hasAppeared = true
        guard !reduceMotion else { displayedValue = value; return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.48)) { displayedValue = value }
        }
    }
}

struct PageTitle: View {
    let title: String; var trailing: String? = nil
    var body: some View { HStack { Text(title).font(.system(size: 23, weight: .bold)).foregroundStyle(AppTheme.ink); Spacer(); if let trailing { Label(trailing, systemImage: "line.3.horizontal.decrease.circle").font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) } }.padding(.top, 8) }
}

struct HomeView: View {
    @Environment(DiaryStore.self) private var store
    let showSettings: () -> Void
    let onRecipeTap: (Recipe) -> Void
    let onShowWatch: () -> Void
    let onShowLongAgo: () -> Void
    let onShowHistory: () -> Void

    @State private var refreshRotation: Double = 0
    @State private var shuffledRecommendations: [Recipe] = []
    @State private var showAvatarPreview = false

    private var displayedRecommendations: [Recipe] {
        shuffledRecommendations.isEmpty ? store.recommendations : shuffledRecommendations
    }

    var body: some View {
        ScrollView(showsIndicators: false) { VStack(spacing: 17) {
            HStack { VStack(alignment: .leading, spacing: 3) { Text(store.todayLabel).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text("\(store.baby.name)的辅食日记").font(.system(size: 21, weight: .bold)).foregroundStyle(AppTheme.ink) }; Spacer(); Button(action: showSettings) { Label("设置", systemImage: "gearshape").labelStyle(.iconOnly).font(.body.weight(.semibold)).foregroundStyle(AppTheme.ink).frame(width: 44, height: 44).background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 15)).apricotElevation(.control) }.accessibilityLabel("设置") }
            HStack(spacing: 14) {
                if store.baby.avatarData != nil {
                    Button { showAvatarPreview = true } label: {
                        BabyAvatar(data: store.baby.avatarData, size: 52, cornerRadius: 18).apricotElevation(.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("查看宝宝头像")
                } else {
                    BabyAvatar(data: nil, size: 52, cornerRadius: 18).apricotElevation(.primary)
                }
                VStack(alignment: .leading, spacing: 7) { Text(store.baby.name).font(.title3.bold()); HStack(spacing: 6) { Pill(text: store.baby.ageText, color: AppTheme.warning); Pill(text: store.baby.gender, color: .pink) } }
                Spacer()
                TimelineView(.periodic(from: .now, by: 60)) { context in let currentMeal = MealPeriod.inferred(at: context.date); Image(systemName: currentMeal.symbol).font(.title2).foregroundStyle(currentMeal.color).accessibilityLabel("当前餐次：\(currentMeal.rawValue)") }
            }
            .padding(16).background(LinearGradient(colors: [AppTheme.warmSurface, .yellow.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 22)).apricotElevation(.card)
            HStack { Text("今日概览").font(.headline); Spacer(); Text("\(store.overviewDateLabel) ›").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk) }
            HStack(spacing: 10) {
                Button(action: onShowWatch) { Metric(title: "重点观察", value: store.todayMetrics.watchText, color: AppTheme.secondaryInk) }
                Button(action: onShowLongAgo) { Metric(title: "好久没吃", value: store.todayMetrics.longAgoText, color: AppTheme.success) }
                Button(action: onShowHistory) { Metric(title: "已记录", value: store.todayMetrics.recordedText, color: AppTheme.primary) }
            }
            .buttonStyle(.plain)
            HStack { Text("好久没吃的菜谱").font(.headline); Spacer(); Button { shuffleRecommendations() } label: { HStack(spacing: 3) { Image(systemName: "arrow.clockwise").font(.caption.weight(.bold)).rotationEffect(.degrees(refreshRotation)); Text("换一换").font(.caption.weight(.bold)) }.foregroundStyle(AppTheme.primary) }.buttonStyle(.plain) }
            if displayedRecommendations.isEmpty {
                Text("暂无推荐，菜谱记录满 14 天后会在这里提醒复吃").font(.subheadline).foregroundStyle(AppTheme.secondaryInk).frame(maxWidth: .infinity).padding(.vertical, 22)
            } else {
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 11) { ForEach(displayedRecommendations) { recipe in recommendationCard(recipe) }.padding(.vertical, 2) } }
            }
            HStack { Text("重点观察").font(.headline); Spacer(); if !store.watchEntries.isEmpty { Text("\(store.watchEntries.count) 种").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.warning) } }
            if store.watchEntries.isEmpty {
                ApricotCard { HStack { Image(systemName: "leaf").foregroundStyle(AppTheme.success).frame(width: 42, height: 42).background(AppTheme.success.opacity(0.13)).clipShape(RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading) { Text("重点观察").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text("这几天没有需要特别观察的食材").font(.subheadline.weight(.semibold)) }; Spacer() } }
            } else {
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 11) { ForEach(store.watchEntries) { entry in watchCard(entry) }.padding(.vertical, 2) } }
            }
        }.padding(.horizontal, 17).padding(.top, 12).padding(.bottom, 108) }.background(AppTheme.background)
        .animation(.easeInOut(duration: 0.3), value: displayedRecommendations.map(\.id))
        .fullScreenCover(isPresented: $showAvatarPreview) {
            if let avatarData = store.baby.avatarData {
                AvatarPreviewView(photoData: avatarData)
            }
        }
    }

    private func shuffleRecommendations() {
        let base = store.recommendations
        if base.count > 1 {
            var candidate = base.shuffled()
            while candidate.map(\.id) == base.map(\.id) {
                candidate = base.shuffled()
            }
            shuffledRecommendations = candidate
        }
        withAnimation(.easeInOut(duration: 0.5)) { refreshRotation += 360 }
    }

    @ViewBuilder
    private func recommendationCard(_ recipe: Recipe) -> some View {
        Button { onRecipeTap(recipe) } label: {
            HomeRecipeCard(
                recipe: recipe,
                detail: "已 \(recipe.days) 天未吃",
                badge: "✓ 安全复吃",
                badgeColor: AppTheme.success
            )
        }.buttonStyle(.plain)
    }

    @ViewBuilder
    private func watchCard(_ entry: WatchEntry) -> some View {
        HomeRecipeCard(
            recipe: entry.recipe,
            detail: "\(entry.hoursAgo) 小时前 · \(entry.lastReaction.title)",
            badge: entry.lastReaction == .allergy ? "需观察" : "观察中",
            badgeColor: entry.lastReaction == .allergy ? AppTheme.danger : AppTheme.warning
        )
    }
}

private struct HomeRecipeCard: View {
    let recipe: Recipe
    let detail: String
    let badge: String
    let badgeColor: Color

    var body: some View {
        HStack(spacing: 12) {
            FoodIconThumbnail(iconID: recipe.iconID, symbol: recipe.symbol, colors: recipe.colors, size: 78)
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(1)
                Pill(text: badge, color: badgeColor)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 220, height: 98, alignment: .leading)
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 19))
        .apricotElevation(.card)
    }
}

struct Metric: View {
    let title: String
    let value: String
    let color: Color

    private var number: Int? { Int(value.prefix(while: { $0.isNumber })) }
    private var suffix: String { String(value.drop(while: { $0.isNumber })) }

    var body: some View {
        VStack(spacing: 5) {
            Text(title).font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
            if let number {
                AnimatedNumberText(value: number, suffix: suffix, font: .system(size: 20, weight: .bold), color: color)
            } else {
                Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .padding(.horizontal, 6)
        .background(title == "好久没吃" ? LinearGradient(colors: [AppTheme.surface, AppTheme.warmSurface], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [AppTheme.surface, AppTheme.surface], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .apricotElevation(.card)
    }
}

private struct RecipeOverviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DiaryStore.self) private var store
    let destination: HomeOverviewDestination

    private var title: String { destination == .watch ? "重点观察" : "好久没吃" }
    private var description: String {
        destination == .watch
            ? "新菜谱或出现异常反应后的 72 小时内，建议持续留意宝宝状态。"
            : "已超过 14 天未食用，且最近无过敏记录的菜谱。可少量搭配熟悉菜谱重新尝试。"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .padding(14)
                        .background(AppTheme.warmSurface.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 17))

                    if destination == .watch {
                        watchContent
                    } else {
                        longAgoContent
                    }
                }
                .padding(17)
            }
            .background(AppTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }.foregroundStyle(AppTheme.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var watchContent: some View {
        if store.watchEntries.isEmpty {
            overviewEmptyState(icon: "leaf", text: "这几天没有需要特别观察的食材")
        } else {
            ForEach(store.watchEntries) { entry in
                ApricotCard {
                    HStack(spacing: 12) {
                        FoodThumbnail(recipe: entry.recipe, size: 52)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(entry.recipe.name).font(.subheadline.bold())
                            Text("\(entry.hoursAgo) 小时前记录 · \(entry.lastReaction.title)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryInk)
                            Pill(text: entry.lastReaction == .allergy ? "需观察" : "观察中", color: entry.lastReaction == .allergy ? AppTheme.danger : AppTheme.warning)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var longAgoContent: some View {
        if store.recommendations.isEmpty {
            overviewEmptyState(icon: "clock", text: "暂无超过 14 天未食用的菜谱")
        } else {
            ForEach(store.recommendations) { recipe in
                ApricotCard {
                    HStack(spacing: 12) {
                        FoodThumbnail(recipe: recipe, size: 52)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(recipe.name).font(.subheadline.bold())
                            Text("上次记录：\(recipe.last)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryInk)
                            Pill(text: "已 \(recipe.days) 天未吃", color: AppTheme.success)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func overviewEmptyState(icon: String, text: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(text)
        }
        .frame(maxWidth: .infinity, minHeight: 230)
    }
}

struct RecipeLibraryView: View {
    @Environment(DiaryStore.self) private var store
    let onRecipeTap: (Recipe) -> Void
    @State private var searchText = ""
    @State private var category = "全部"
    @State private var sortField: RecipeSort = .byCount
    @State private var sortAscending = false
    private let categories = ["全部", "主食", "肉食", "蔬菜", "水果"]
    var body: some View { ScrollView(showsIndicators: false) { VStack(spacing: 12) { PageTitle(title: "菜谱库"); HStack { Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.secondaryInk); TextField("搜索食材或菜谱", text: $searchText).font(.subheadline).foregroundStyle(AppTheme.ink); Spacer() }.padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 18)).apricotElevation(.control); ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(categories, id: \.self) { label in Button { category = label } label: { Text(label).font(.subheadline.bold()).foregroundStyle(label == category ? .white : AppTheme.secondaryInk).padding(.horizontal, 14).padding(.vertical, 8).background(label == category ? AppTheme.primary : .white).clipShape(Capsule()).apricotElevation(.control) }.buttonStyle(.plain) } } }; HStack(spacing: 5) { Button { sortField = (sortField == .byCount) ? .byLastRecorded : .byCount } label: { HStack(spacing: 4) { Text(sortField.title).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.ink); Image(systemName: "arrow.up.arrow.down").font(.caption2.weight(.bold)).foregroundStyle(AppTheme.primary) }.padding(.horizontal, 8).padding(.vertical, 4).background(AppTheme.warmSurface.opacity(0.6)).clipShape(RoundedRectangle(cornerRadius: 10)).contentShape(Rectangle()) }.buttonStyle(.plain); Spacer(); Button { sortAscending.toggle() } label: { HStack(spacing: 4) { Image(systemName: sortAscending ? "arrow.up" : "arrow.down").font(.caption.weight(.bold)).foregroundStyle(.white).frame(width: 20, height: 20).background(AppTheme.primary).clipShape(RoundedRectangle(cornerRadius: 6)); Text("排序").font(.caption.weight(.semibold)).foregroundStyle(sortAscending ? AppTheme.primary : AppTheme.secondaryInk) }.padding(.horizontal, 8).padding(.vertical, 4).background(sortAscending ? AppTheme.primary.opacity(0.12) : AppTheme.warmSurface.opacity(0.6)).clipShape(RoundedRectangle(cornerRadius: 10)).contentShape(Rectangle()) }.buttonStyle(.plain) }; ForEach(store.libraryRecipes(search: searchText, category: category, sort: sortField, ascending: sortAscending)) { recipe in Button { onRecipeTap(recipe) } label: { ApricotCard { HStack(spacing: 12) { FoodThumbnail(recipe: recipe); VStack(alignment: .leading, spacing: 5) { Text(recipe.name).font(.subheadline.bold()); HStack { ForEach(recipe.categories, id: \.self) { Pill(text: $0, color: $0 == "肉食" ? .pink : AppTheme.warning) } }; HStack(spacing: 0) { Text("已记录 "); Text("\(recipe.count)").fontWeight(.bold).foregroundStyle(AppTheme.primary); Text(" 次 · 上次 \(recipe.last)") }.font(.caption2.weight(.medium)).foregroundStyle(AppTheme.secondaryInk) }; Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(AppTheme.secondaryInk) } }.padding(0) }.buttonStyle(.plain) } }.padding(.horizontal, 17).padding(.bottom, 108) }.background(AppTheme.background) }
}

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DiaryStore.self) private var store
    let recipe: Recipe
    let onRecord: () -> Void
    let onViewHistory: () -> Void
    @State private var iconEditTarget: IconEditTarget?

    private var currentRecipe: Recipe { store.recipes.first(where: { $0.id == recipe.id }) ?? recipe }

    private var detail: RecipeDetailVM {
        store.recipeDetails[recipe.id] ?? RecipeDetailVM(
            recipe: recipe,
            firstRecordedAt: nil,
            lastRecordedAt: nil,
            latestReaction: nil,
            isInObservation: false,
            occurrences: []
        )
    }

    private var status: (text: String, color: Color) {
        if detail.isInObservation { return ("观察中", AppTheme.warning) }
        if detail.latestReaction == .allergy { return ("需谨慎观察", AppTheme.danger) }
        if recipe.count == 0 { return ("新菜谱", AppTheme.warning) }
        if recipe.days >= 14 { return ("适合少量重新尝试", AppTheme.success) }
        return ("适合继续记录", AppTheme.success)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .apricotElevation(.control)
                    }
                    .accessibilityLabel("返回菜谱库")
                    Spacer()
                    Pill(text: status.text, color: status.color)
                }

                VStack(spacing: 10) {
                    Button { iconEditTarget = IconEditTarget(dishID: nil, recipeID: currentRecipe.id) } label: {
                        FoodThumbnail(recipe: currentRecipe, size: 112)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("修改\(currentRecipe.name)图标")
                    Text(recipe.name).font(.system(size: 29, weight: .bold)).multilineTextAlignment(.center)
                    Text(recipe.categories.isEmpty ? "自定义菜谱" : recipe.categories.joined(separator: " · "))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryInk)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
                    RecipeDetailMetric(title: "上次记录", value: dateText(detail.lastRecordedAt), subtitle: lastSubtitle)
                    RecipeDetailMetric(title: "记录次数", value: "\(recipe.count) 次", subtitle: reactionSubtitle)
                    RecipeDetailMetric(title: "首次记录", value: dateText(detail.firstRecordedAt), subtitle: nil)
                    RecipeDetailMetric(title: "观察期", value: detail.isInObservation ? "观察中" : "已结束", subtitle: detail.isInObservation ? "持续留意宝宝状态" : "暂无近期观察")
                }

                if !detail.occurrences.isEmpty {
                    detailSection(title: "最近反应") {
                        VStack(spacing: 0) {
                            ForEach(Array(detail.occurrences.prefix(3).enumerated()), id: \.element.id) { index, occurrence in
                                RecipeOccurrenceRow(occurrence: occurrence)
                                if index < min(detail.occurrences.count, 3) - 1 { Divider().overlay(AppTheme.warmSurface) }
                            }
                        }
                    }

                    detailSection(title: "近期出现在") {
                        let occurrence = detail.occurrences[0]
                        HStack {
                            Text(occurrence.meal).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(dateText(occurrence.date)).font(.subheadline.weight(.bold))
                        }
                    }
                } else {
                    detailSection(title: "记录情况") {
                        Text("还没有记录过这道菜谱，准备好后可以记录今天做了什么。")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }
                }
            }
            .padding(.horizontal, 17)
            .padding(.top, 14)
            .padding(.bottom, 124)
        }
        .background(AppTheme.background)
        .sheet(item: $iconEditTarget) { target in
            FoodIconPickerSheet(selectedID: currentRecipe.iconID) { icon in
                if let recipeID = target.recipeID { store.updateRecipeIcon(id: recipeID, iconID: icon.id) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 11) {
                Button(action: onViewHistory) {
                    Text("查看历史记录").font(.headline).foregroundStyle(AppTheme.primary)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(AppTheme.surface)
                        .overlay { RoundedRectangle(cornerRadius: 17).stroke(AppTheme.primary.opacity(0.52), lineWidth: 1.4) }
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                }
                Button(action: onRecord) {
                    Text("记录今天做了").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(LinearGradient(colors: [.orange.opacity(0.72), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                        .apricotElevation(.primary)
                }
            }
            .padding(.horizontal, 17)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(AppTheme.background.opacity(0.96))
        }
    }

    private var lastSubtitle: String {
        guard detail.lastRecordedAt != nil else { return "尚未记录" }
        return recipe.days == 0 ? "今天" : "已 \(recipe.days) 天"
    }

    private var reactionSubtitle: String {
        guard let reaction = detail.latestReaction else { return "等待第一次记录" }
        return "最近：\(reaction.title)"
    }

    @ViewBuilder
    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.title3.bold())
            ApricotCard { content() }
        }
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else { return "—" }
        return Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
}

private struct RecipeDetailMetric: View {
    let title: String
    let value: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
            Text(value).font(.system(size: 22, weight: .bold)).lineLimit(1).minimumScaleFactor(0.74)
            if let subtitle { Text(subtitle).font(.caption.weight(.medium)).foregroundStyle(AppTheme.secondaryInk).lineLimit(1) }
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(15)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .apricotElevation(.card)
    }
}

private struct RecipeOccurrenceRow: View {
    let occurrence: RecipeOccurrence

    var body: some View {
        HStack {
            Text(Self.dateFormatter.string(from: occurrence.date) + " · " + occurrence.meal)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Label(occurrence.reaction.title, systemImage: occurrence.reaction == .like ? "face.smiling" : "face.dashed")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(occurrence.reaction.color)
        }
        .padding(.vertical, 8)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
}

struct AnalysisView: View {
    @Environment(DiaryStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chartProgress: CGFloat = 0
    @State private var timeFilter: RecordTimeFilter = .days14
    let onRecipeTap: (Recipe) -> Void
    private func legendText(_ title: String, reaction: Reaction, summary: AnalysisSummary) -> String {
        let count = summary.counts[reaction] ?? 0
        let percent = summary.total > 0 ? Int(Double(count) / Double(summary.total) * 100) : 0
        return "\(title) \(percent)%·\(count)"
    }
    var body: some View {
        let summary = store.analysis(for: timeFilter)
        ScrollView(showsIndicators: false) {
            VStack(spacing: 15) {
                pageHeader(title: "接受度分析")
                ApricotCard {
                    VStack(spacing: 10) {
                        Text(analysisDescription(summary: summary)).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
                        ReactionRatioDonut(summary: summary, progress: chartProgress)
                        HStack(spacing: 10) { Legend(text: legendText("喜欢", reaction: .like, summary: summary), color: AppTheme.success); Legend(text: legendText("一般", reaction: .neutral, summary: summary), color: AppTheme.warning); Legend(text: legendText("拒绝", reaction: .refused, summary: summary), color: AppTheme.danger); Legend(text: legendText("过敏", reaction: .allergy, summary: summary), color: .purple) }
                            .opacity(chartProgress)
                    }
                }
                .background(LinearGradient(colors: [.white, AppTheme.warmSurface.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                Text("菜谱喜欢次数排行榜").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                AcceptanceRanking(ranking: summary.ranking, emptyText: "\(timeFilter.title)暂无足够数据", onRecipeTap: onRecipeTap)
            }
            .padding(.horizontal, 17)
            .padding(.bottom, 108)
        }
        .background(AppTheme.background)
        .onAppear {
            guard chartProgress == 0 else { return }
            if reduceMotion {
                chartProgress = 1
            } else {
                withAnimation(.easeOut(duration: 0.72)) { chartProgress = 1 }
            }
        }
    }

    private func analysisDescription(summary: AnalysisSummary) -> String {
        timeFilter == .all ? "所有时间反应比例" : "\(timeFilter.title)（\(summary.rangeLabel)）反应比例"
    }

    private func pageHeader(title: String) -> some View {
        HStack {
            Text(title).font(.system(size: 23, weight: .bold)).foregroundStyle(AppTheme.ink)
            Spacer()
            TimeFilterMenu(selection: $timeFilter)
        }
        .padding(.top, 8)
    }
}

private struct TimeFilterMenu: View {
    @Binding var selection: RecordTimeFilter

    var body: some View {
        Menu {
            ForEach(RecordTimeFilter.allCases) { option in
                Button { selection = option } label: {
                    Label(option.title, systemImage: selection == option ? "checkmark" : "")
                }
            }
        } label: {
            Label(selection.title, systemImage: "line.3.horizontal.decrease.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }
}

struct Legend: View { let text: String; let color: Color; var body: some View { HStack(spacing: 3) { Circle().fill(color).frame(width: 7, height: 7); Text(text).font(.caption2.weight(.semibold)) } } }

struct AcceptanceRanking: View {
    let ranking: [RankRow]
    var emptyText: String = "暂无足够数据"
    let onRecipeTap: (Recipe) -> Void
    var body: some View {
        ApricotCard {
            VStack(spacing: 0) {
                if ranking.isEmpty {
                    Text(emptyText).font(.subheadline).foregroundStyle(AppTheme.secondaryInk).frame(maxWidth: .infinity).padding(.vertical, 18)
                } else {
                    ForEach(Array(ranking.enumerated()), id: \.element.id) { index, row in
                        Button { onRecipeTap(row.recipe) } label: {
                            HStack(spacing: 11) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(index == 0 ? AppTheme.primary : AppTheme.primary.opacity(0.56))
                                    .clipShape(RoundedRectangle(cornerRadius: 9))
                                FoodThumbnail(recipe: row.recipe, size: 40)
                                Text(row.recipe.name).font(.subheadline.bold()).lineLimit(1)
                                Spacer(minLength: 4)
                                AnimatedNumberText(value: row.likeCount, suffix: " 次喜欢", font: .caption2.weight(.bold), color: row.color, delay: Double(index) * 0.07)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(row.color.opacity(0.13))
                                    .clipShape(Capsule())
                                    .apricotElevation(.control)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("打开菜谱详情")
                        .padding(.vertical, 9)
                        if index < ranking.count - 1 { Divider().overlay(AppTheme.warmSurface) }
                    }
                }
            }
        }
        .padding(0)
    }
}

struct ReactionRatioDonut: View {
    let summary: AnalysisSummary
    let progress: CGFloat
    private let width: CGFloat = 21
    private let segments: [(Reaction, Color)] = [(.like, AppTheme.success), (.neutral, AppTheme.warning), (.refused, AppTheme.danger), (.allergy, Color(red: 0.56, green: 0.42, blue: 0.72))]

    private var slices: [(Double, Double, Color)] {
        guard summary.total > 0 else { return [] }
        let gap = 0.012
        var start = 0.0
        var result: [(Double, Double, Color)] = []
        for index in segments.indices {
            let reaction = segments[index].0
            let count = summary.counts[reaction] ?? 0
            guard count > 0 else { continue }
            let frac = Double(count) / Double(summary.total)
            let end = min(start + max(frac - gap, 0.004), 1)
            result.append((start, end, segments[index].1))
            start = min(end + gap, 1)
            if start >= 1 { break }
        }
        return result
    }

    var body: some View {
        let total = summary.total
        ZStack {
            Circle().stroke(AppTheme.warmSurface, lineWidth: width)
            ForEach(Array(slices.enumerated()), id: \.offset) { _, slice in
                Circle().trim(from: slice.0, to: slice.0 + (slice.1 - slice.0) * Double(progress)).stroke(slice.2, style: StrokeStyle(lineWidth: width, lineCap: .round)).rotationEffect(.degrees(-90))
            }
            VStack(spacing: -2) {
                Text("\(total)").font(.system(size: 30, weight: .bold)).foregroundStyle(AppTheme.ink) + Text("餐").font(.subheadline.weight(.bold))
                Text("总记录").font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(width: 172, height: 172)
        .scaleEffect(0.92 + 0.08 * progress)
        .opacity(0.45 + 0.55 * progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let parts = segments.map { "\($0.0.title) \(summary.counts[$0.0] ?? 0) 餐" }.joined(separator: "，")
        return "统计范围 \(summary.rangeLabel)，共 \(summary.total) 餐：" + parts
    }
}

struct HistoryView: View {
    @Environment(DiaryStore.self) private var store
    @State private var editingSeed: RecordSeed?
    @State private var imagePreview: HistoryImagePreviewSession?
    @State private var weekAnchor: Date = .now
    @State private var selectedDate: Date?
    @State private var displayMode: HistoryDisplayMode = .recipe
    @State private var pendingDeletion: HistoryRecordVM?

    private var displayedRecords: [HistoryRecordVM] {
        if let selectedDate {
            return store.historyRecords.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        }
        return store.historyRecords(for: .days14)
    }

    private var emptyText: String {
        selectedDate == nil ? "最近 14 天暂无记录" : "这一天还没有记录"
    }

    /// The right-arrow is only enabled when the displayed week is before the current week.
    private var canGoNext: Bool {
        let cal = Calendar.current
        let thisWD = cal.component(.weekday, from: .now)
        let thisMonday = cal.date(byAdding: .day, value: -(thisWD + 5) % 7, to: cal.startOfDay(for: .now))!
        let anchorWD = cal.component(.weekday, from: weekAnchor)
        let anchorMonday = cal.date(byAdding: .day, value: -(anchorWD + 5) % 7, to: cal.startOfDay(for: weekAnchor))!
        return anchorMonday < thisMonday
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    Text("历史记录")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    HistoryDisplayModePicker(selection: $displayMode)
                }
                .padding(.top, 8)
                HistoryCalendar(
                    week: store.calendarWeek(anchor: weekAnchor, selected: selectedDate),
                    onSelectDay: { date in
                        if let selectedDate, Calendar.current.isDate(selectedDate, inSameDayAs: date) {
                            self.selectedDate = nil
                        } else {
                            selectedDate = date
                        }
                    },
                    onPrev: { weekAnchor = Calendar.current.date(byAdding: .day, value: -7, to: weekAnchor) ?? weekAnchor },
                    onNext: { weekAnchor = Calendar.current.date(byAdding: .day, value: 7, to: weekAnchor) ?? weekAnchor },
                    canGoNext: canGoNext
                )
                if displayMode == .recipe, displayedRecords.isEmpty {
                    Text(emptyText).font(.subheadline).foregroundStyle(AppTheme.secondaryInk).frame(maxWidth: .infinity).padding(.vertical, 30)
                } else if displayMode == .photos {
                    HistoryPhotoGrid(records: displayedRecords, onSelect: openImagePreview)
                } else {
                    ForEach(displayedRecords) { vm in
                        Button { editingSeed = RecordSeed(id: vm.id, form: store.form(forRecordID: vm.id) ?? .blank) } label: {
                            HistoryRecordCard(
                                date: vm.dateLabel,
                                meal: vm.meal,
                                time: vm.timeText,
                                dishes: vm.dishes,
                                overallReaction: vm.overallReaction,
                                note: vm.note,
                                photoData: vm.photoData,
                                onPhotoTap: {
                                    openImagePreview(vm)
                                },
                                onDelete: {
                                    pendingDeletion = vm
                                }
                            )
                        }.buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 17)
            .padding(.bottom, 108)
        }
        .background(AppTheme.background)
        .sheet(item: $editingSeed) { seed in MealRecordView(form: seed.form) }
        .fullScreenCover(item: $imagePreview) { session in
            HistoryImagePreviewView(previews: session.previews, initialIndex: session.initialIndex)
        }
        .alert("删除记录", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )) {
            Button("取消", role: .cancel) { pendingDeletion = nil }
            Button("删除", role: .destructive) {
                if let vm = pendingDeletion {
                    store.deleteMealRecord(id: vm.id)
                    pendingDeletion = nil
                }
            }
        } message: {
            Text("删除后无法恢复，确定删除这条用餐记录吗？")
        }
    }

    private func openImagePreview(_ record: HistoryRecordVM) {
        let previews = displayedRecords.compactMap(HistoryImagePreview.init(record:))
        guard let index = previews.firstIndex(where: { $0.recordID == record.id }) else { return }
        imagePreview = HistoryImagePreviewSession(previews: previews, initialIndex: index)
    }
}

private enum HistoryDisplayMode: Equatable {
    case recipe
    case photos
}

private struct HistoryDisplayModePicker: View {
    @Binding var selection: HistoryDisplayMode

    var body: some View {
        HStack(spacing: 4) {
            modeButton(.recipe, icon: "rectangle.grid.1x2")
            modeButton(.photos, icon: "photo.on.rectangle")
        }
        .padding(4)
        .background(AppTheme.warmSurface.opacity(0.72))
        .clipShape(Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("历史记录展示模式")
    }

    private func modeButton(_ mode: HistoryDisplayMode, icon: String) -> some View {
        Button { selection = mode } label: {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(selection == mode ? .white : AppTheme.secondaryInk)
                .frame(width: 36, height: 30)
                .background(selection == mode ? AppTheme.primary : .clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode == .recipe ? "图文模式" : "图片模式")
        .accessibilityAddTraits(selection == mode ? .isSelected : [])
    }
}

private struct HistoryPhotoGrid: View {
    let records: [HistoryRecordVM]
    let onSelect: (HistoryRecordVM) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    private var photoRecords: [HistoryRecordVM] {
        records.filter { record in
            guard let data = record.photoData else { return false }
            return UIImage(data: data) != nil
        }
    }

    var body: some View {
        if photoRecords.isEmpty {
            ContentUnavailableView("暂无照片", systemImage: "photo.on.rectangle.angled", description: Text("记录一餐时添加的照片会显示在这里"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(photoRecords) { record in
                    Button { onSelect(record) } label: {
                        HistoryPhotoTile(record: record)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(record.dateLabel) \(record.meal) 的照片")
                }
            }
        }
    }
}

private struct HistoryPhotoTile: View {
    let record: HistoryRecordVM

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let data = record.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.dateLabel).font(.caption.weight(.bold))
                Text("\(record.meal) · \(record.timeText)").font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(10)
        }
        .overlay(alignment: .topTrailing) {
            if record.livePhotoAssetIdentifier != nil || record.livePhotoData != nil {
                Image(systemName: "livephoto")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
                    .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .apricotElevation(.control)
    }
}

private struct HistoryImagePreview: Identifiable {
    let recordID: UUID
    var id: UUID { recordID }
    let photoData: Data
    let livePhotoData: Data?
    let livePhotoAssetIdentifier: String?
    let livePhotoResourcesData: Data?

    init?(record: HistoryRecordVM) {
        guard let photoData = record.photoData, UIImage(data: photoData) != nil else { return nil }
        self.recordID = record.id
        self.photoData = photoData
        self.livePhotoData = record.livePhotoData
        self.livePhotoAssetIdentifier = record.livePhotoAssetIdentifier
        self.livePhotoResourcesData = record.livePhotoResourcesData
    }
}

private struct HistoryImagePreviewSession: Identifiable {
    let id = UUID()
    let previews: [HistoryImagePreview]
    let initialIndex: Int
}

struct HistoryCalendar: View {
    let week: CalendarWeekVM
    let onSelectDay: (Date) -> Void
    let onPrev: () -> Void
    let onNext: () -> Void
    let canGoNext: Bool
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    var body: some View {
        ApricotCard {
            VStack(spacing: 11) {
                HStack {
                    Text(week.monthLabel).font(.system(size: 17, weight: .bold)).foregroundStyle(AppTheme.ink)
                    Spacer()
                    Button(action: onPrev) { Image(systemName: "chevron.left").font(.subheadline.weight(.bold)) }.foregroundStyle(AppTheme.secondaryInk).buttonStyle(.plain)
                    Button(action: onNext) { Image(systemName: "chevron.right").font(.subheadline.weight(.bold)) }.foregroundStyle(canGoNext ? AppTheme.secondaryInk : AppTheme.secondaryInk.opacity(0.32)).disabled(!canGoNext).buttonStyle(.plain)
                }
                HStack { ForEach(weekdays, id: \.self) { Text($0).font(.caption.weight(.bold)).foregroundStyle(AppTheme.secondaryInk.opacity(0.72)).frame(maxWidth: .infinity) } }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 7) {
                    ForEach(week.days) { day in
                        if let date = day.date {
                            Button { onSelectDay(date) } label: { CalendarDateCell(day: day) }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct CalendarDateCell: View {
    let day: CalendarDay
    private var textColor: Color {
        if day.isSelected { return .white }
        if !day.isCurrentMonth { return AppTheme.secondaryInk.opacity(0.4) }
        if day.isToday { return AppTheme.primary }
        return AppTheme.ink
    }
    private var indicatorColor: Color {
        if day.isSelected { return .white.opacity(0.9) }
        if day.isRecorded { return AppTheme.primary }
        if day.isToday { return AppTheme.primary.opacity(0.4) }
        return .clear
    }
    var body: some View {
        VStack(spacing: 4) {
            Text("\(day.number)").font(.subheadline.weight(.bold)).foregroundStyle(textColor).frame(maxWidth: .infinity).padding(.vertical, 7).background(day.isSelected ? AppTheme.primary : (day.isToday ? AppTheme.primary.opacity(0.12) : .clear)).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: day.isSelected ? AppTheme.primary.opacity(0.32) : .clear, radius: 7, y: 4)
            Circle().fill(indicatorColor).frame(width: 5, height: 5)
        }
    }
}

struct HistoryRecordCard: View {
    let date: String; let meal: String; let time: String; let dishes: [MealDish]; let overallReaction: Reaction; let note: String; let photoData: Data?
    let onPhotoTap: () -> Void
    var onDelete: () -> Void
    var body: some View {
        ApricotCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Text(date).font(.subheadline.weight(.bold)).foregroundStyle(AppTheme.primary)
                    Spacer()
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.secondaryInk)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                        .highPriorityGesture(TapGesture().onEnded(onDelete))
                        .accessibilityLabel("删除记录")
                }
                HStack(spacing: 8) {
                    let mealPeriod = MealPeriod.resolve(meal)
                    Image(systemName: mealPeriod?.symbol ?? "fork.knife").foregroundStyle(mealPeriod?.color ?? AppTheme.warning)
                    Text(meal).font(.headline)
                    Text(time).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
                }
                HStack(alignment: .top, spacing: 14) {
                    if let first = dishes.first {
                        historyPhoto(first)
                    }
                    VStack(spacing: 8) {
                        ForEach(dishes) { dish in
                            HStack(spacing: 6) {
                                Text(displayName(dish.name))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                HStack(spacing: 2) {
                                    Text(dish.reaction.title).font(.subheadline.weight(.bold)).foregroundStyle(dish.reaction.color)
                                    Image(systemName: dish.reaction == .like ? "face.smiling" : "face.dashed").foregroundStyle(dish.reaction.color)
                                }
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

    @ViewBuilder
    private func historyPhoto(_ dish: MealDish) -> some View {
        let photo = HistoryMealPhoto(dish: dish, photoData: photoData)
        if let photoData, UIImage(data: photoData) != nil {
            photo
                .contentShape(RoundedRectangle(cornerRadius: 15))
                .highPriorityGesture(TapGesture().onEnded(onPhotoTap))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("全屏查看图片")
        } else {
            photo
        }
    }

    private func displayName(_ name: String) -> String {
        name.count > 6 ? String(name.prefix(6)) + "…" : name
    }
}

struct MealDishThumbnail: View {
    let dish: MealDish; let size: CGFloat
    var body: some View { FoodIconThumbnail(iconID: dish.iconID, symbol: dish.symbol, colors: dish.colors, size: size) }
}

struct HistoryMealPhoto: View {
    let dish: MealDish; let photoData: Data?
    var body: some View {
        Group {
            if let data = photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "photo.fill").font(.system(size: 28, weight: .medium)).foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(width: 130, height: 104)
        .background(LinearGradient(colors: dish.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .apricotElevation(.control)
        .accessibilityLabel("餐后照片")
    }
}

private struct HistoryImagePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let previews: [HistoryImagePreview]
    @State private var selectedIndex: Int

    init(previews: [HistoryImagePreview], initialIndex: Int) {
        self.previews = previews
        _selectedIndex = State(initialValue: initialIndex)
    }

    private var preview: HistoryImagePreview { previews[selectedIndex] }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            previewContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(preview.id)
                .gesture(
                    DragGesture(minimumDistance: 24)
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            if value.translation.width < 0 {
                                showNextImage()
                            } else {
                                showPreviousImage()
                            }
                        }
                )

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("关闭图片预览")
                }
                Spacer()
            }
            .padding(18)
        }
        .statusBarHidden()
    }

    private func showNextImage() {
        guard selectedIndex < previews.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.22)) { selectedIndex += 1 }
    }

    private func showPreviousImage() {
        guard selectedIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.22)) { selectedIndex -= 1 }
    }

    private var previewContent: some View {
        Group {
            if let resourceData = preview.livePhotoResourcesData,
               let resources = try? JSONDecoder().decode(LivePhotoSandbox.Resources.self, from: resourceData) {
                LocalLivePhotoPreview(resources: resources, fallbackPhotoData: preview.photoData)
            } else if let assetIdentifier = preview.livePhotoAssetIdentifier {
                LivePhotoAssetPreview(assetIdentifier: assetIdentifier, fallbackPhotoData: preview.photoData)
            } else if let livePhotoData = preview.livePhotoData,
               let livePhoto = try? NSKeyedUnarchiver.unarchivedObject(ofClass: PHLivePhoto.self, from: livePhotoData) {
                ZStack {
                    if let image = UIImage(data: preview.photoData) {
                        Image(uiImage: image).resizable().scaledToFit()
                    }
                    LivePhotoPlayer(livePhoto: livePhoto)
                }
            } else if let image = UIImage(data: preview.photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            } else {
                Color.black
            }
        }
    }
}

private struct AvatarPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let photoData: Data

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image = UIImage(data: photoData) {
                Image(uiImage: image).resizable().scaledToFit().padding(18)
            }
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline.weight(.bold)).foregroundStyle(.white).frame(width: 44, height: 44).background(.black.opacity(0.55)).clipShape(Circle())
                    }
                    .accessibilityLabel("关闭头像预览")
                }
                Spacer()
            }
            .padding(18)
        }
        .statusBarHidden()
    }
}

private struct LivePhotoAssetPreview: View {
    let assetIdentifier: String
    let fallbackPhotoData: Data
    @State private var livePhoto: PHLivePhoto?

    var body: some View {
        ZStack {
            if let image = UIImage(data: fallbackPhotoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.black
            }
            if let livePhoto {
                LivePhotoPlayer(livePhoto: livePhoto)
            }
        }
        .task(id: assetIdentifier) {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            guard let asset = assets.firstObject else { return }

            let options = PHLivePhotoRequestOptions()
            options.isNetworkAccessAllowed = true
            let targetSize = CGSize(width: UIScreen.main.bounds.width * UIScreen.main.scale, height: UIScreen.main.bounds.height * UIScreen.main.scale)
            PHImageManager.default().requestLivePhoto(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { result, _ in
                guard let result else { return }
                DispatchQueue.main.async { livePhoto = result }
            }
        }
    }
}

private struct LocalLivePhotoPreview: View {
    let resources: LivePhotoSandbox.Resources
    let fallbackPhotoData: Data
    @State private var livePhoto: PHLivePhoto?

    var body: some View {
        ZStack {
            if let image = UIImage(data: fallbackPhotoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.black
            }
            if let livePhoto {
                LivePhotoPlayer(livePhoto: livePhoto)
            }
        }
        .task(id: resources) {
            guard let urls = LivePhotoSandbox.urls(for: resources) else { return }
            PHLivePhoto.request(
                withResourceFileURLs: urls,
                placeholderImage: UIImage(data: fallbackPhotoData),
                targetSize: CGSize(width: UIScreen.main.bounds.width * UIScreen.main.scale, height: UIScreen.main.bounds.height * UIScreen.main.scale),
                contentMode: .aspectFit
            ) { result, _ in
                guard let result else { return }
                DispatchQueue.main.async { livePhoto = result }
            }
        }
    }
}

private enum LivePhotoSandbox {
    struct Resources: Codable, Hashable {
        let folderName: String
        let photoFilename: String
        let videoFilename: String
    }

    private static var rootURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LivePhotos", isDirectory: true)
    }

    static func urls(for resources: Resources) -> [URL]? {
        let folder = rootURL.appendingPathComponent(resources.folderName, isDirectory: true)
        let photoURL = folder.appendingPathComponent(resources.photoFilename)
        let videoURL = folder.appendingPathComponent(resources.videoFilename)
        guard FileManager.default.fileExists(atPath: photoURL.path),
              FileManager.default.fileExists(atPath: videoURL.path) else { return nil }
        return [photoURL, videoURL]
    }

    static func copy(assetIdentifier: String, completion: @escaping (Data?) -> Void) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = assets.firstObject else { completion(nil); return }

        let assetResources = PHAssetResource.assetResources(for: asset)
        guard let photo = assetResources.first(where: { $0.type == .fullSizePhoto })
                ?? assetResources.first(where: { $0.type == .photo }),
              let video = assetResources.first(where: { $0.type == .fullSizePairedVideo })
                ?? assetResources.first(where: { $0.type == .pairedVideo }) else {
            completion(nil)
            return
        }

        let folderName = UUID().uuidString
        let folder = rootURL.appendingPathComponent(folderName, isDirectory: true)
        let photoURL = folder.appendingPathComponent("photo." + fileExtension(for: photo, fallback: "heic"))
        let videoURL = folder.appendingPathComponent("video." + fileExtension(for: video, fallback: "mov"))

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            completion(nil)
            return
        }

        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        let group = DispatchGroup()
        let errorQueue = DispatchQueue(label: "LivePhotoSandbox.copy")
        var writeError: Error?
        for (resource, url) in [(photo, photoURL), (video, videoURL)] {
            group.enter()
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
                if let error {
                    errorQueue.sync { writeError = writeError ?? error }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            guard writeError == nil else {
                try? FileManager.default.removeItem(at: folder)
                completion(nil)
                return
            }
            let resources = Resources(folderName: folderName, photoFilename: photoURL.lastPathComponent, videoFilename: videoURL.lastPathComponent)
            completion(try? JSONEncoder().encode(resources))
        }
    }

    private static func fileExtension(for resource: PHAssetResource, fallback: String) -> String {
        let ext = URL(fileURLWithPath: resource.originalFilename).pathExtension
        return ext.isEmpty ? fallback : ext
    }
}

private struct LivePhotoPlayer: UIViewRepresentable {
    let livePhoto: PHLivePhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        view.isOpaque = false
        view.livePhoto = livePhoto
        DispatchQueue.main.async { view.startPlayback(with: .full) }
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        guard uiView.livePhoto != livePhoto else { return }
        uiView.livePhoto = livePhoto
        DispatchQueue.main.async { uiView.startPlayback(with: .full) }
    }

    static func dismantleUIView(_ uiView: PHLivePhotoView, coordinator: ()) {
        uiView.stopPlayback()
    }
}

struct FloatingTabBar: View {
    @Namespace private var selectionAnimation
    let tab: AppTab; let select: (AppTab) -> Void; let add: () -> Void
    var body: some View { ZStack { HStack(spacing: 0) { tabItem(.home); tabItem(.recipes); Spacer().frame(width: 58); tabItem(.analysis); tabItem(.history) }.padding(.horizontal, 8).frame(height: 62).background(AppTheme.surface).clipShape(Capsule()).apricotElevation(.primary).animation(.snappy(duration: 0.24, extraBounce: 0.08), value: tab); Button(action: add) { Image(systemName: "plus").font(.system(size: 26, weight: .medium)).foregroundStyle(.white).frame(width: 54, height: 54).background(LinearGradient(colors: [Color(red: 1, green: 0.60, blue: 0.36), Color(red: 1, green: 0.42, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)).overlay { Circle().stroke(.white.opacity(0.42), lineWidth: 1).padding(1) }.clipShape(Circle()).shadow(color: AppTheme.primary.opacity(0.50), radius: 8, y: 8).shadow(color: AppTheme.ink.opacity(0.14), radius: 3, y: 2) }.offset(y: -7) }.padding(.horizontal, 18).padding(.bottom, 12) }
    private func tabItem(_ item: AppTab) -> some View { Button { select(item) } label: { VStack(spacing: 3) { tabIcon(item); Text(item.title).font(.caption2.weight(.bold)) }.foregroundStyle(tab == item ? AppTheme.primary : AppTheme.secondaryInk).frame(maxWidth: .infinity) } }

    private func tabIcon(_ item: AppTab) -> some View {
        Image(systemName: item.symbol)
            .font(.system(size: 18, weight: .semibold))
            .frame(width: 42, height: 28)
            .background {
                if tab == item {
                    Capsule()
                        .fill(AppTheme.warmSurface)
                        .matchedGeometryEffect(id: "selectedTab", in: selectionAnimation)
                }
            }
            .clipShape(Capsule())
            .scaleEffect(tab == item ? 1.10 : 1)
    }
}

struct MealRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DiaryStore.self) private var store
    let form: MealRecordForm

    @State private var date: Date
    @State private var meal: String
    @State private var reaction: Reaction
    @State private var note: String
    @State private var photoData: Data?
    @State private var livePhotoData: Data?
    @State private var livePhotoAssetIdentifier: String?
    @State private var livePhotoResourcesData: Data?
    @State private var dishes: [DishSnapshot]
    @State private var editingID: UUID?

    @State private var showDatePicker = false
    @State private var showRecipePicker = false
    @State private var showValidation = false
    @State private var showPhotoPicker = false
    @State private var iconEditTarget: IconEditTarget?

    private let recipeTypes = ["主食", "肉食", "蔬菜", "水果"]

    init(form: MealRecordForm) {
        self.form = form
        _date = State(initialValue: form.date)
        _meal = State(initialValue: form.meal)
        _reaction = State(initialValue: form.reaction)
        _note = State(initialValue: form.note)
        _photoData = State(initialValue: form.photoData)
        _livePhotoData = State(initialValue: form.livePhotoData)
        _livePhotoAssetIdentifier = State(initialValue: form.livePhotoAssetIdentifier)
        _livePhotoResourcesData = State(initialValue: form.livePhotoResourcesData)
        _dishes = State(initialValue: form.dishes)
        _editingID = State(initialValue: form.editingID)
    }

    private var dateString: String { Self.dateFormatter.string(from: date) }

    var body: some View {
        NavigationStack { ScrollView(showsIndicators: false) { VStack(spacing: 14) {
            HStack { Button { dismiss() } label: { Image(systemName: "chevron.left").font(.headline).frame(width: 40, height: 40).background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 14)).apricotElevation(.control) }; Spacer(); Text(editingID == nil ? "记录一餐" : "编辑记录").font(.title3.bold()); Spacer(); Button { clearAll() } label: { Text("清空").font(.caption.weight(.bold)).foregroundStyle(AppTheme.secondaryInk) }.buttonStyle(.plain) }
            Button { showDatePicker = true } label: { ApricotCard { HStack(spacing: 8) { Text("日期").font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk); Text(dateString).font(.headline).foregroundStyle(AppTheme.ink); Spacer(); Image(systemName: "chevron.right").foregroundStyle(AppTheme.primary) } } }.buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 8) { Text("选择餐次").font(.subheadline.bold()); HStack(spacing: 7) { ForEach(MealPeriod.allCases) { option in Button { meal = option.rawValue } label: { MealOption(meal: option, isSelected: option.rawValue == meal) }.buttonStyle(.plain) } } }
            VStack(alignment: .leading, spacing: 8) {
                Text("选择菜谱").font(.subheadline.bold())
                ApricotCard { VStack(spacing: 0) {
                    if dishes.isEmpty {
                        Text("还没有添加食物").font(.subheadline).foregroundStyle(AppTheme.secondaryInk).frame(maxWidth: .infinity).padding(.vertical, 14)
                    } else {
                        ForEach(Array(dishes.enumerated()), id: \.element.id) { index, dish in
                            VStack(spacing: 0) {
                                HStack(spacing: 10) {
                                    Button {
                                        iconEditTarget = IconEditTarget(dishID: dish.id, recipeID: dish.recipeID)
                                    } label: {
                                        MealDishThumbnail(dish: MealDish(snapshot: dish), size: 38)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("修改\(dish.name)图标")

                                    VStack(alignment: .leading, spacing: 7) {
                                        Text(dish.name).font(.subheadline.bold()).lineLimit(1)
                                        HStack(spacing: 7) {
                                            Menu {
                                                ForEach(recipeTypes, id: \.self) { type in
                                                    Button { selectRecipeType(type, for: dish) } label: {
                                                        Label(type, systemImage: currentType(for: dish) == type ? "checkmark" : "")
                                                    }
                                                }
                                            } label: {
                                                Pill(text: recipeTypeLabel(for: dish), color: recipeTypeColor(for: dish)).contentShape(Capsule())
                                            }
                                            .accessibilityHint("点击选择菜谱类型")

                                            Menu {
                                                ForEach(Reaction.allCases) { option in
                                                    Button { dishes[index].reactionRaw = option.rawValue } label: {
                                                        Label(option.title, systemImage: dish.reaction == option ? "checkmark" : "")
                                                    }
                                                }
                                            } label: {
                                                Pill(text: dish.reaction.title, color: dish.reaction.color).contentShape(Capsule())
                                            }
                                            .accessibilityHint("点击选择这道菜谱的喜欢程度")
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    Button { dishes.remove(at: index) } label: {
                                        Image(systemName: "xmark").font(.caption).foregroundStyle(AppTheme.secondaryInk)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 8)
                                if index < dishes.count - 1 { Divider().overlay(AppTheme.warmSurface) }
                            }
                        }
                    }
                } }
                addButton(title: "添加菜谱", systemImage: "plus.circle") { showRecipePicker = true }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("上传照片（选填）").font(.subheadline.bold())
                Button { showPhotoPicker = true } label: {
                    Group {
                        if let data = photoData, let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else {
                            Image(systemName: "camera").foregroundStyle(AppTheme.secondaryInk)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(photoData == nil ? AppTheme.warmSurface.opacity(0.6) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
                if photoData != nil {
                    Button("移除照片") {
                        photoData = nil
                        livePhotoData = nil
                        livePhotoAssetIdentifier = nil
                        livePhotoResourcesData = nil
                    }
                    .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.danger).frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            VStack(alignment: .leading, spacing: 8) { Text("接受度").font(.subheadline.bold()); HStack(spacing: 7) { ForEach(Reaction.allCases) { option in Button { reaction = option } label: { ReactionOption(reaction: option, isSelected: option == reaction) }.buttonStyle(.plain) } } }
            VStack(alignment: .leading, spacing: 8) {
                Text("备注（选填）").font(.subheadline.bold())
                ZStack(alignment: .topLeading) {
                    if note.isEmpty { Text("记录食量、反应或饮食情况…").font(.subheadline).foregroundStyle(AppTheme.secondaryInk.opacity(0.6)).padding(.horizontal, 12).padding(.top, 12) }
                    TextEditor(text: $note).font(.subheadline).foregroundStyle(AppTheme.ink).frame(minHeight: 72).padding(.horizontal, 6).padding(.vertical, 2).scrollContentBackground(.hidden).background(Color.clear)
                }
                .frame(minHeight: 72)
                .background(AppTheme.warmSurface.opacity(0.58))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(AppTheme.warmSurface, lineWidth: 1) }
            }
            Button { save() } label: { Text("保存").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15).background(LinearGradient(colors: [.orange.opacity(0.72), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 17)).apricotElevation(.primary) }.buttonStyle(.plain)
        }.padding(17) }.background(AppTheme.background) }
        .presentationDetents([.large])
        .sheet(isPresented: $showDatePicker) { datePickerSheet }
        .sheet(isPresented: $showRecipePicker) {
            RecipePickerSheet(initialDishes: dishes) { selected in
                reconcileDishes(with: selected)
                showRecipePicker = false
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { selection in
                photoData = selection?.photoData
                livePhotoData = selection?.livePhotoData
                livePhotoAssetIdentifier = selection?.livePhotoAssetIdentifier
                livePhotoResourcesData = selection?.livePhotoResourcesData
            }
        }
        .sheet(item: $iconEditTarget) { target in
            FoodIconPickerSheet(selectedID: dishes.first(where: { $0.id == target.dishID })?.iconID ?? FoodIconCatalog.defaultID) { icon in
                guard let index = dishes.firstIndex(where: { $0.id == target.dishID }) else { return }
                dishes[index].iconID = icon.id
                if let recipeID = target.recipeID { store.updateRecipeIcon(id: recipeID, iconID: icon.id) }
            }
        }
        .alert("至少添加一道宝宝尝过的食物", isPresented: $showValidation) { Button("好的", role: .cancel) {} }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker("日期", selection: $date, displayedComponents: .date).datePickerStyle(.graphical).labelsHidden().padding()
                Spacer()
            }
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showDatePicker = false } } }
        }
        .presentationDetents([.medium])
    }

    private func clearAll() {
        date = .now; meal = DiaryStore.inferredMeal(); reaction = .like; note = ""; photoData = nil; livePhotoData = nil; livePhotoAssetIdentifier = nil; livePhotoResourcesData = nil; dishes = []
    }

    /// Current dish type: from the backing recipe, or from the ad-hoc dish's own `type`.
    private func currentType(for dish: DishSnapshot) -> String? {
        if let recipeID = dish.recipeID {
            return store.recipes.first(where: { $0.id == recipeID })?.categories.first
        }
        return dish.type
    }

    private func recipeTypeLabel(for dish: DishSnapshot) -> String {
        currentType(for: dish) ?? "选择类型"
    }

    private func recipeTypeColor(for dish: DishSnapshot) -> Color {
        switch recipeTypeLabel(for: dish) {
        case "肉食": return .pink
        case "蔬菜": return AppTheme.success
        case "水果": return .purple
        default: return AppTheme.warning
        }
    }

    private func selectRecipeType(_ type: String, for dish: DishSnapshot) {
        if let recipeID = dish.recipeID {
            store.updateRecipeCategories(id: recipeID, categories: [type])
        } else if let index = dishes.firstIndex(where: { $0.id == dish.id }) {
            dishes[index].type = type
        }
    }

    private func reconcileDishes(with selected: [DishSnapshot]) {
        let selectedIDs = Set(selected.map { $0.id })
        // Keep existing dishes that remain selected (preserves their reaction/type/icon edits).
        var kept = dishes.filter { selectedIDs.contains($0.id) }
        let keptIDs = Set(kept.map { $0.id })
        // Append newly selected dishes (existing recipes or ad-hoc new ones).
        for snap in selected where !keptIDs.contains(snap.id) {
            kept.append(snap)
        }
        dishes = kept
    }

    @ViewBuilder
    private func addButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppTheme.warmSurface.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }.buttonStyle(.plain)
    }

    private func save() {
        guard !dishes.isEmpty else { showValidation = true; return }
        store.saveMealRecord(MealRecordForm(editingID: editingID, date: date, meal: meal, reaction: reaction, note: note, photoData: photoData, livePhotoData: livePhotoData, livePhotoAssetIdentifier: livePhotoAssetIdentifier, livePhotoResourcesData: livePhotoResourcesData, dishes: dishes))
        dismiss()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
}

struct MealOption: View {
    let meal: MealPeriod
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: meal.symbol).font(.system(size: 17, weight: .semibold))
            Text(meal.rawValue).font(.caption.weight(.bold))
        }
        .foregroundStyle(isSelected ? .white : meal.color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(isSelected ? LinearGradient(colors: [.orange.opacity(0.72), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [AppTheme.surface, AppTheme.surface], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .apricotElevation(isSelected ? .primary : .control)
        .accessibilityLabel(meal.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ReactionOption: View { let reaction: Reaction; let isSelected: Bool; var body: some View { VStack(spacing: 3) { Image(systemName: reaction.symbol).font(.system(size: 19, weight: .medium)); Text(reaction.title).font(.caption2.weight(isSelected ? .bold : .semibold)) }.foregroundStyle(reaction.color).frame(maxWidth: .infinity).padding(.vertical, 8).background(isSelected ? reaction.color.opacity(0.15) : .white).clipShape(RoundedRectangle(cornerRadius: 14)).shadow(color: isSelected ? reaction.color.opacity(0.28) : AppTheme.primary.opacity(0.08), radius: isSelected ? 2 : 6, y: isSelected ? 4 : 3) } }

struct RecipePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DiaryStore.self) private var store
    let onConfirm: ([DishSnapshot]) -> Void
    @State private var selected: [DishSnapshot]
    @State private var search = ""
    @FocusState private var searchFocused: Bool

    init(initialDishes: [DishSnapshot], onConfirm: @escaping ([DishSnapshot]) -> Void) {
        self.onConfirm = onConfirm
        _selected = State(initialValue: initialDishes)
    }

    private var trimmedSearch: String { search.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var results: [Recipe] { store.libraryRecipes(search: search, category: "全部") }
    private var canCreateNew: Bool {
        !trimmedSearch.isEmpty
            && !store.recipes.contains { $0.name == trimmedSearch }
            && !selected.contains { $0.name == trimmedSearch }
    }

    private func recipeSelected(_ recipe: Recipe) -> Bool { selected.contains { $0.recipeID == recipe.id } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.secondaryInk)
                    TextField("搜索菜名，没找到可直接新建", text: $search)
                        .focused($searchFocused)
                        .font(.subheadline)
                        .submitLabel(.done)
                    if !search.isEmpty {
                        Button { search = ""; searchFocused = true } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.secondaryInk)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .apricotElevation(.control)
                .padding(.horizontal, 17)
                .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if !selected.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selected) { dish in
                                        Button { remove(dish) } label: {
                                            HStack(spacing: 4) {
                                                Text(dish.name).font(.caption.weight(.bold))
                                                Image(systemName: "checkmark.circle.fill").font(.caption2)
                                            }
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(AppTheme.primary)
                                            .clipShape(Capsule())
                                        }.buttonStyle(.plain)
                                    }
                                }.padding(.horizontal, 2).padding(.vertical, 2)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if canCreateNew {
                            Button { createNew() } label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("新建菜谱").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.secondaryInk)
                                        Text("「\(trimmedSearch)」").font(.subheadline.bold()).foregroundStyle(AppTheme.ink).lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(AppTheme.primary)
                                }
                                .padding(12)
                                .background(AppTheme.warmSurface.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay { RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primary.opacity(0.3), lineWidth: 1) }
                            }.buttonStyle(.plain)
                        }
                        ForEach(results) { recipe in
                            Button { toggleRecipe(recipe) } label: {
                                HStack(spacing: 12) {
                                    FoodThumbnail(recipe: recipe, size: 44)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(recipe.name).font(.subheadline.bold()).foregroundStyle(AppTheme.ink)
                                        HStack { ForEach(recipe.categories.prefix(2), id: \.self) { Pill(text: $0, color: AppTheme.warning) } }
                                        Text("已记录 \(recipe.count) 次").font(.caption2).foregroundStyle(AppTheme.secondaryInk)
                                    }
                                    Spacer()
                                    Image(systemName: recipeSelected(recipe) ? "checkmark.circle.fill" : "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(recipeSelected(recipe) ? AppTheme.success : AppTheme.primary)
                                }
                                .padding(12)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .apricotElevation(.card)
                                .overlay { RoundedRectangle(cornerRadius: 16).stroke(recipeSelected(recipe) ? AppTheme.success.opacity(0.4) : .clear, lineWidth: 1) }
                            }.buttonStyle(.plain)
                        }
                        if results.isEmpty && trimmedSearch.isEmpty {
                            Text("输入菜名搜索，没找到可直接新建").font(.subheadline).foregroundStyle(AppTheme.secondaryInk).padding(.top, 30)
                        }
                    }.padding(.horizontal, 17).padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .background(AppTheme.background)
            .navigationTitle("添加菜谱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(selected.isEmpty ? "完成" : "完成 (\(selected.count))") { onConfirm(selected); dismiss() } }
            }
        }
    }

    private func toggleRecipe(_ recipe: Recipe) {
        if let index = selected.firstIndex(where: { $0.recipeID == recipe.id }) {
            selected.remove(at: index)
        } else {
            selected.append(DishSnapshot(recipe: recipe, reaction: .like))
        }
    }

    private func remove(_ dish: DishSnapshot) {
        selected.removeAll { $0.id == dish.id }
    }

    /// Creates a draft dish for this meal. It is promoted into the recipe library when the meal is saved.
    private func createNew() {
        let snap = DishSnapshot(
            id: UUID(),
            recipeID: nil,
            name: trimmedSearch,
            symbol: "circle.fill",
            iconID: FoodIconCatalog.matchingIconID(for: trimmedSearch),
            colorHexA: "FFB366",
            colorHexB: "FF8A3D",
            reactionRaw: Reaction.like.rawValue
        )
        selected.append(snap)
        search = ""
    }
}

struct FoodIconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let selectedID: String
    let onPick: (FoodIconCatalog.Icon) -> Void
    @State private var search = ""
    @State private var category = "全部"

    private var icons: [FoodIconCatalog.Icon] { FoodIconCatalog.filtered(search: search, category: category) }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FoodIconCatalog.categories, id: \.self) { item in
                            Button(item) { category = item }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(category == item ? .white : AppTheme.secondaryInk)
                                .padding(.horizontal, 12).padding(.vertical, 9)
                                .background(category == item ? AppTheme.primary : AppTheme.warmSurface)
                                .clipShape(Capsule())
                        }
                    }.padding(.horizontal, 17)
                }
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(icons) { icon in
                            Button {
                                onPick(icon)
                                dismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    FoodIconThumbnail(iconID: icon.id, symbol: "fork.knife", colors: [AppTheme.warmSurface, .white], size: 56)
                                        .overlay { if icon.id == selectedID { RoundedRectangle(cornerRadius: 13).stroke(AppTheme.primary, lineWidth: 2) } }
                                    Text(icon.name).font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.ink).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, minHeight: 82)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("选择\(icon.name)图标")
                        }
                    }.padding(17)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("选择食材图标")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "搜索食材")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

struct PickedMealPhoto {
    let photoData: Data
    let livePhotoData: Data?
    let livePhotoAssetIdentifier: String?
    let livePhotoResourcesData: Data?
}

struct PhotoPicker: UIViewControllerRepresentable {
    let onPick: (PickedMealPhoto?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (PickedMealPhoto?) -> Void
        init(onPick: @escaping (PickedMealPhoto?) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first,
                  result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
                onPick(nil); return
            }
            let provider = result.itemProvider
            let isLivePhoto = provider.canLoadObject(ofClass: PHLivePhoto.self)

            loadLivePhotoData(from: provider) { livePhotoData in
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    guard let photoData = (object as? UIImage)?.jpegData(compressionQuality: 0.8) else {
                        DispatchQueue.main.async { self.onPick(nil) }
                        return
                    }
                    let selection = PickedMealPhoto(
                        photoData: photoData,
                        livePhotoData: livePhotoData,
                        livePhotoAssetIdentifier: result.assetIdentifier,
                        livePhotoResourcesData: nil
                    )
                    guard isLivePhoto else {
                        DispatchQueue.main.async { self.onPick(selection) }
                        return
                    }
                    self.copyLivePhotoResources(assetIdentifier: result.assetIdentifier) { resourcesData in
                        let copiedSelection = PickedMealPhoto(
                            photoData: selection.photoData,
                            livePhotoData: selection.livePhotoData,
                            livePhotoAssetIdentifier: selection.livePhotoAssetIdentifier,
                            livePhotoResourcesData: resourcesData
                        )
                        DispatchQueue.main.async { self.onPick(copiedSelection) }
                    }
                }
            }
        }

        private func copyLivePhotoResources(assetIdentifier: String?, completion: @escaping (Data?) -> Void) {
            guard let assetIdentifier else { completion(nil); return }

            let copyIfAllowed: (PHAuthorizationStatus) -> Void = { status in
                guard status == .authorized || status == .limited else { completion(nil); return }
                LivePhotoSandbox.copy(assetIdentifier: assetIdentifier, completion: completion)
            }

            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if status == .notDetermined {
                PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: copyIfAllowed)
            } else {
                copyIfAllowed(status)
            }
        }

        private func loadLivePhotoData(from provider: NSItemProvider, completion: @escaping (Data?) -> Void) {
            guard provider.canLoadObject(ofClass: PHLivePhoto.self) else {
                completion(nil)
                return
            }
            provider.loadObject(ofClass: PHLivePhoto.self) { object, _ in
                guard let livePhoto = object as? PHLivePhoto else {
                    completion(nil)
                    return
                }
                let data = try? NSKeyedArchiver.archivedData(withRootObject: livePhoto, requiringSecureCoding: true)
                completion(data)
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}

struct FormCard: View { let title: String; let value: String; let symbol: String; var body: some View { ApricotCard { HStack { Image(systemName: symbol).foregroundStyle(AppTheme.primary).frame(width: 26); Text(title).font(.subheadline.bold()); Spacer(); Text(value).font(.subheadline).foregroundStyle(AppTheme.secondaryInk); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(AppTheme.secondaryInk) } }.padding(0) } }

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DiaryStore.self) private var store
    @State private var nickname = "泡泡"
    @State private var birthDate: Date = .now
    @State private var gender = "男宝"
    @State private var exportError: String?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showAvatarPicker = false
    @State private var showBirthDatePicker = false
    @State private var importError: String?
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var showDocumentPicker = false
    @State private var showImportConfirmation = false
    @State private var pendingImportURL: URL?
    @State private var importSuccessMessage: String?

    private var birthDateString: String { Self.birthDateFormatter.string(from: birthDate) }

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
                    importButton
                    if let importError {
                        Label(importError, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    if let importSuccessMessage {
                        Label(importSuccessMessage, systemImage: "checkmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    privacyCard
                }
                .padding(.horizontal, 17)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .background(AppTheme.background)
            .onAppear {
                nickname = store.baby.name
                birthDate = store.baby.birthDate
                gender = store.baby.gender
            }
            .onDisappear { store.updateBaby(name: nickname, birthDate: birthDate, gender: gender) }
            .sheet(isPresented: $showAvatarPicker) {
                PhotoPicker { selection in
                    store.updateAvatar(selection?.photoData)
                    showAvatarPicker = false
                }
            }
            .sheet(isPresented: $showBirthDatePicker) {
                NavigationStack {
                    VStack {
                        DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("选择出生日期")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showBirthDatePicker = false } } }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { url in
                    showDocumentPicker = false
                    guard let url else { return }
                    handlePickedImport(url: url)
                }
            }
            .alert("确认导入", isPresented: $showImportConfirmation) {
                Button("取消", role: .cancel) { pendingImportURL = nil }
                Button("导入") { performImport() }
            } message: {
                if let url = pendingImportURL {
                    Text("将从 \"\(url.lastPathComponent)\" 导入数据。\n已有菜谱将跳过，用餐记录将追加。")
                }
            }
        }
    }

    private static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Label("关闭", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.surface)
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
                Button { showAvatarPicker = true } label: {
                    BabyAvatar(data: store.baby.avatarData, size: 88, cornerRadius: 44, fallbackSymbol: "face.smiling.fill")
                        .apricotElevation(.primary)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(AppTheme.primary)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                }.buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 12) {
                    SettingsTextField(title: "宝宝昵称", text: $nickname, symbol: "heart.fill")
                    VStack(alignment: .leading, spacing: 8) {
                        Label("出生日期", systemImage: "calendar")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                        Button { showBirthDatePicker = true } label: {
                            HStack {
                                Text(birthDateString).font(.subheadline).foregroundStyle(AppTheme.ink)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(AppTheme.secondaryInk)
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .background(AppTheme.warmSurface.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay { RoundedRectangle(cornerRadius: 14).stroke(AppTheme.warmSurface, lineWidth: 1) }
                        }.buttonStyle(.plain)
                    }
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
                Text("导出包含宝宝资料、菜谱、用餐记录及照片的备份包（.zip），便于自行备份或迁移。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var privacyCard: some View {
        NavigationLink {
            PrivacyPolicyView()
        } label: {
            ApricotCard {
                HStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("隐私政策")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        Text("了解资料如何保存在设备上")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryInk)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("查看宝宝尝鲜记隐私政策")
    }

    private var exportButton: some View {
        VStack(spacing: 10) {
            if isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: exportProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primary))
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                        .padding(.horizontal, 4)
                    Text("正在导出…")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                }
            } else {
                Button(action: exportBackup) {
                    Label("导出备份", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(LinearGradient(colors: [.orange.opacity(0.70), AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .apricotElevation(.primary)
                }
                .accessibilityHint("生成并分享含照片的备份包")
            }
        }
    }

    private func exportBackup() {
        isExporting = true
        exportError = nil
        exportProgress = 0

        DispatchQueue.global(qos: .userInitiated).async {
            let bundle = store.buildBackup()
            DispatchQueue.main.async { exportProgress = 0.3 }

            do {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("baby-food-diary-backup.zip")
                try? FileManager.default.removeItem(at: url)
                try BackupArchive.writeZip(bundle, to: url)
                DispatchQueue.main.async {
                    exportProgress = 0.7
                    // Brief pause so user sees the progress bar fill
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        exportProgress = 1.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            isExporting = false
                            exportProgress = 0
                            presentActivitySheet(with: url)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    exportProgress = 0
                    exportError = "导出失败，请稍后重试。"
                }
            }
        }
    }

    private func presentActivitySheet(with url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            exportError = "无法打开分享面板。"
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true)
    }

    // MARK: Import

    private var importButton: some View {
        VStack(spacing: 10) {
            if isImporting {
                VStack(spacing: 8) {
                    ProgressView(value: importProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.success))
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                        .padding(.horizontal, 4)
                    Text("正在导入…")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.success.opacity(0.25), lineWidth: 1)
                }
            } else {
                Button { showDocumentPicker = true } label: {
                    Label("导入备份", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.primary, lineWidth: 1.5)
                        }
                }
                .accessibilityHint("从备份包恢复宝宝辅食数据")
            }
        }
    }

    private func handlePickedImport(url: URL) {
        importError = nil
        importSuccessMessage = nil

        guard url.startAccessingSecurityScopedResource() else {
            importError = "无法读取文件，请重试。"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let bundle = try BackupArchive.readZip(at: url)
            guard bundle.payload["baby"] != nil else {
                importError = "文件格式不正确，请选择导出的备份包（.zip）。"
                return
            }
        } catch {
            importError = "文件格式不正确，请选择导出的备份包（.zip）。"
            return
        }

        pendingImportURL = url
        showImportConfirmation = true
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }
        pendingImportURL = nil
        isImporting = true
        importError = nil
        importSuccessMessage = nil
        importProgress = 0

        DispatchQueue.global(qos: .userInitiated).async {
            guard url.startAccessingSecurityScopedResource() else {
                DispatchQueue.main.async { isImporting = false; importError = "无法读取文件，请重试。" }
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            DispatchQueue.main.async { importProgress = 0.15 }

            do {
                let bundle = try BackupArchive.readZip(at: url)
                let summary = try store.importBackup(bundle)
                DispatchQueue.main.async {
                    importProgress = 0.6
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        importProgress = 1.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isImporting = false
                            importProgress = 0
                            var parts: [String] = []
                            if summary.totalRecords > 0 { parts.append("\(summary.totalRecords) 条用餐记录") }
                            if summary.newRecipes > 0 { parts.append("\(summary.newRecipes) 种新菜谱") }
                            if summary.photos > 0 { parts.append("\(summary.photos) 张照片") }
                            let detail = parts.isEmpty ? "已更新宝宝资料" : parts.joined(separator: "、")
                            importSuccessMessage = "导入完成：\(detail)。"
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    importProgress = 0
                    importError = "导入失败，请稍后重试。"
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    private let sections: [(title: String, body: String)] = [
        ("我们收集哪些信息", "宝宝尝鲜记不会将个人信息或使用数据发送给开发者。宝宝昵称、出生日期、头像、辅食记录、备注与照片仅保存在你的设备上。"),
        ("照片权限", "只有当你主动选择照片时，App 才会通过 Apple 提供的系统照片选择器读取所选内容，用于添加头像或用餐照片。App 不会浏览或上传你的完整照片图库。"),
        ("数据存储与备份", "记录由系统提供的 SwiftData 保存在本机。你可以在设置中主动导出 ZIP 备份，并自行选择保存或分享位置；导出后的文件由你负责保管。导入操作只读取你主动选择的备份文件。"),
        ("数据共享与追踪", "App 不包含广告、第三方分析工具或跨 App 追踪，也不会向开发者或第三方出售、共享你的数据。"),
        ("删除数据", "你可以在 App 内删除相关记录，或通过 iPhone 的系统设置删除 App 及其全部本地数据。删除 App 前如需保留资料，请先导出备份。"),
        ("儿童隐私", "本 App 供家长或监护人记录宝宝的饮食信息，不面向儿童创建账号或直接收集儿童信息。请由家长或监护人管理设备中的资料。"),
        ("政策更新", "如果未来版本的数据处理方式发生变化，我们会更新本政策，并在需要时重新征求你的授权。")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("隐私政策")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.ink)
                Text("更新日期：2026年7月14日")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)

                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(AppTheme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("如对隐私政策有疑问，请通过 App Store 产品页面中的支持链接联系我们。")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .padding(.top, 4)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background)
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
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
    static func makeURL(payload: [String: Any]) throws -> URL {
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("baby-food-diary-export.json")
        try data.write(to: url, options: .atomic)
        return url
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
