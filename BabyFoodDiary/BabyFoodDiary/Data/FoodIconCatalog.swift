import Foundation

/// The built-in, offline ingredient icon directory. IDs are also the image-set names.
enum FoodIconCatalog {
    struct Icon: Identifiable, Hashable {
        let id: String
        let name: String
        let category: String
        let aliases: [String]
    }

    static let defaultID = "meal-bowl"
    static let categories = ["全部", "谷薯", "蔬菜", "水果", "豆菌", "肉蛋奶", "水产", "油调味"]

    static let icons: [Icon] = [Icon(id: "meal-bowl", name: "餐盘", category: "全部", aliases: ["餐", "菜", "饭", "粥", "泥", "饼"])]
        + group("谷薯", "rice:大米,白米", "millet:小米", "oats:燕麦", "corn:玉米", "glutinous-rice:糯米", "black-rice:黑米", "quinoa:藜麦", "flour:面粉,小麦", "buckwheat:荞麦", "pasta:意面,面条", "sweet-potato:红薯,地瓜", "potato:土豆,马铃薯", "yam:山药,淮山", "taro:芋头", "lotus-root:莲藕")
        + group("蔬菜", "broccoli:西兰花,绿花菜", "cauliflower:菜花,花椰菜", "carrot:胡萝卜,红萝卜", "pumpkin:南瓜", "tomato:番茄,西红柿", "cucumber:黄瓜", "winter-melon:冬瓜", "loofah:丝瓜", "eggplant:茄子", "pepper:青椒,彩椒", "lettuce:生菜", "spinach:菠菜", "bok-choy:油菜,青菜", "cabbage:小白菜,大白菜,娃娃菜", "celery:芹菜", "asparagus:芦笋", "peas:豌豆", "snow-peas:荷兰豆", "green-beans:四季豆,豆角", "baby-corn:玉米笋", "onion:洋葱", "garlic:大蒜,蒜", "ginger:生姜,姜", "mushroom:香菇", "enoki:金针菇", "button-mushroom:口蘑,白蘑菇", "wood-ear:木耳", "kelp:海带")
        + group("水果", "apple:苹果", "banana:香蕉", "pear:梨", "orange:橙子,橙", "grapefruit:柚子", "strawberry:草莓", "blueberry:蓝莓", "grape:葡萄", "watermelon:西瓜", "melon:哈密瓜,甜瓜", "kiwi:猕猴桃,奇异果", "peach:桃子,桃", "cherry:樱桃", "dragon-fruit:火龙果", "avocado:牛油果", "mango:芒果", "pineapple:菠萝,凤梨", "papaya:木瓜", "jujube:红枣,枣", "longan:桂圆,龙眼")
        + group("豆菌", "soybean:黄豆,大豆", "black-bean:黑豆", "mung-bean:绿豆", "red-bean:红豆", "chickpea:鹰嘴豆", "tofu:豆腐", "dried-tofu:豆腐干,豆干", "yuba:腐竹", "soy-milk:豆浆", "sesame:芝麻", "peanut:花生")
        + group("肉蛋奶", "pork:猪肉,猪,排骨", "beef:牛肉,牛", "lamb:羊肉,羊", "chicken:鸡肉,鸡", "duck:鸭肉,鸭", "pigeon:鸽子,鸽", "liver:猪肝,鸡肝,肝", "egg:鸡蛋,蛋黄,蛋白,蒸蛋", "quail-egg:鹌鹑蛋", "milk:牛奶,鲜奶", "yogurt:酸奶", "cheese:奶酪,芝士", "butter:黄油")
        + group("水产", "salmon:三文鱼", "cod:鳕鱼", "bass:鲈鱼", "hairtail:带鱼", "yellow-croaker:黄花鱼", "shrimp:虾仁,虾", "crab:螃蟹,蟹", "clam:蛤蜊,花蛤", "scallop:扇贝", "oyster:生蚝,牡蛎", "sea-cucumber:海参", "cuttlefish:墨鱼", "squid:鱿鱼", "fish-roe:鱼籽")
        + group("油调味", "olive-oil:橄榄油", "walnut-oil:核桃油", "sesame-oil:芝麻油,香油", "flaxseed-oil:亚麻籽油", "rapeseed-oil:菜籽油", "salt:盐", "soy-sauce:酱油", "vinegar:醋", "white-sesame:白芝麻", "black-sesame:黑芝麻")

    static func matchingIconID(for recipeName: String) -> String {
        let normalized = normalize(recipeName)
        let candidates = icons.filter { $0.id != defaultID }.flatMap { icon in
            ([icon.name] + icon.aliases).map { (icon, normalize($0)) }
        }.filter { !$0.1.isEmpty }

        let match = candidates.compactMap { icon, alias -> (Icon, Int, Int)? in
            guard let range = normalized.range(of: alias) else { return nil }
            return (icon, normalized.distance(from: normalized.startIndex, to: range.lowerBound), alias.count)
        }.sorted {
            $0.1 == $1.1 ? ($0.2 == $1.2 ? $0.0.id < $1.0.id : $0.2 > $1.2) : $0.1 < $1.1
        }.first
        return match?.0.id ?? defaultID
    }

    static func icon(id: String?) -> Icon {
        icons.first(where: { $0.id == id }) ?? icons[0]
    }

    static func filtered(search: String, category: String) -> [Icon] {
        let term = normalize(search)
        return icons.filter { icon in
            (category == "全部" || icon.category == category || icon.id == defaultID) &&
            (term.isEmpty || normalize(icon.name).contains(term) || icon.aliases.contains { normalize($0).contains(term) })
        }
    }

    private static func normalize(_ value: String) -> String {
        value.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || CharacterSet.letters.contains($0) }.map(String.init).joined()
    }

    private static func group(_ category: String, _ definitions: String...) -> [Icon] {
        definitions.map { definition in
            let pair = definition.split(separator: ":", maxSplits: 1).map(String.init)
            let names = pair[1].split(separator: ",").map(String.init)
            return Icon(id: pair[0], name: names[0], category: category, aliases: Array(names.dropFirst()))
        }
    }
}
