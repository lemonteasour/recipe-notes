//
//  PreviewData.swift
//  RecipeBB
//
//  Created by Jay Hui on 28/09/2025.
//


import Foundation
import SwiftData

@MainActor
enum PreviewData {

    // Computed so every access returns a fresh instance — seeding must never
    // re-insert an object that a previous wipe deleted.
    static var sampleRecipeEnglish: Recipe { Recipe(
        name: "Spaghetti Bolognese",
        desc: "Classic Italian pasta with rich meat sauce, serves 2–3 people",
        ingredients: [
            Ingredient(name: "Spaghetti", quantity: "200g", sortOrder: 0),
            Ingredient(name: "Parmesan cheese", quantity: "For serving", sortOrder: 1),
            // Sauce
            Ingredient(name: "Ground beef", quantity: "250g", sortOrder: 3),
            Ingredient(name: "Onion", quantity: "1 small", sortOrder: 4),
            Ingredient(name: "Garlic cloves", quantity: "2", sortOrder: 5),
            Ingredient(name: "Carrot", quantity: "1 small", sortOrder: 6),
            Ingredient(name: "Celery", quantity: "1 stick", sortOrder: 7),
            Ingredient(name: "Olive oil", quantity: "2 tbsp", sortOrder: 8),
            Ingredient(name: "Tomato paste", quantity: "2 tbsp", sortOrder: 9),
            Ingredient(name: "Canned tomatoes", quantity: "400g", sortOrder: 10),
            Ingredient(name: "Beef stock", quantity: "100ml", sortOrder: 11),
            Ingredient(name: "Dried oregano", quantity: "1 tsp", sortOrder: 12),
            Ingredient(name: "Salt & pepper", quantity: "To taste", sortOrder: 13),
        ],
        ingredientHeadings: [
            IngredientHeading(name: "Sauce", sortOrder: 2)
        ],
        steps: [
            Step(value: "Finely chop the onion, garlic, carrot, and celery.", sortOrder: 0),
            Step(value: "Heat olive oil in a pan. Add onion, garlic, carrot, and celery, and sauté until softened.", sortOrder: 1),
            Step(value: "Add ground beef and cook until browned.", sortOrder: 2),
            Step(value: "Stir in tomato paste and cook briefly, then add canned tomatoes and beef stock.", sortOrder: 3),
            Step(value: "Season with oregano, salt, and pepper. Simmer on low heat for 20–30 minutes.", sortOrder: 4),
            Step(value: "Meanwhile, cook spaghetti in salted boiling water until al dente. Drain well.", sortOrder: 5),
            Step(value: "Serve spaghetti topped with the sauce. Garnish with parmesan cheese.", sortOrder: 6),
        ]
    ) }


    static var sampleRecipeJapanese: Recipe { Recipe(
        name: "親子丼",
        desc: "2人分",
        ingredients: [
            Ingredient(name: "鶏肉", quantity: "200g", sortOrder: 0),
            Ingredient(name: "玉ねぎ", quantity: "半玉", sortOrder: 1),
            Ingredient(name: "卵", quantity: "3個", sortOrder: 2),
            Ingredient(name: "ご飯", quantity: "250g", sortOrder: 3),
            // Condiments
            Ingredient(name: "麺つゆ", quantity: "大さじ4", sortOrder: 5),
            Ingredient(name: "水", quantity: "200ml", sortOrder: 6),
            Ingredient(name: "水溶き片栗粉", quantity: "適量", sortOrder: 7),
        ],
        ingredientHeadings: [
            IngredientHeading(name: "調味料", sortOrder: 4)
        ],
        steps: [
            Step(value: "鶏肉を一口大に切り、玉ねぎを0.5mm幅にスライスする。", sortOrder: 0),
            Step(value: "片栗粉以外の調味料を鍋に入れ、1の具材を加える。", sortOrder: 1),
            Step(value: "加熱し、鶏肉に完全に火が通ったら水溶き片栗粉でとろみをつける。", sortOrder: 2),
            Step(value: "卵はかけ混ぜすぎないように解き、半分加えて8割くらい火を通す。", sortOrder: 3),
            Step(value: "残り半分の卵も加え、火を止めて蓋をして10分待つ。", sortOrder: 4),
            Step(value: "ご飯の上に盛り付けて完成。", sortOrder: 5)
        ]
    ) }

    // MARK: - Seeding

    /// Seeds sample data into `context` if it holds no recipes / pantry items.
    /// Used by preview containers and by the developer reset button in MoreView.
    ///
    /// The sample set is chosen from the app's resolved localization, so running
    /// with App Language set to 日本語 or 繁體中文 seeds data in that language.
    static func seedIfEmpty(context: ModelContext) {
        let recipeCount = (try? context.fetchCount(FetchDescriptor<Recipe>())) ?? 0
        let pantryCount = (try? context.fetchCount(FetchDescriptor<PantryItem>())) ?? 0
        guard recipeCount == 0 || pantryCount == 0 else { return }

        let language = Bundle.main.preferredLocalizations.first ?? "en"
        let samples: SampleSet
        if language.hasPrefix("ja") {
            samples = japaneseSamples()
        } else if language.hasPrefix("zh") {
            samples = traditionalChineseSamples()
        } else {
            samples = englishSamples()
        }

        if recipeCount == 0 {
            var tagsByName: [String: RecipeTag] = [:]
            for entry in samples.recipes {
                context.insert(entry.recipe)
                entry.recipe.isFavorite = entry.isFavorite
                entry.recipe.createdAt = entry.createdAt
                entry.recipe.tags = entry.tags.map { name in
                    if let existing = tagsByName[name] { return existing }
                    let tag = RecipeTag(name: name)
                    context.insert(tag)
                    tagsByName[name] = tag
                    return tag
                }
            }

            // Title-only filler recipes with randomly spread dates, enough to
            // exercise the index scrubber.
            for title in samples.extraTitles {
                let recipe = Recipe(name: title, desc: "")
                context.insert(recipe)
                recipe.createdAt = daysAgo(Int.random(in: 0...900))
            }
        }

        if pantryCount == 0 {
            for (categoryIndex, category) in samples.pantryCategories.enumerated() {
                let pantryCategory = PantryCategory(name: category.name, sortOrder: categoryIndex)
                context.insert(pantryCategory)
                for (itemIndex, item) in category.items.enumerated() {
                    context.insert(PantryItem(name: item.name, quantity: item.quantity, sortOrder: itemIndex, category: pantryCategory))
                }
            }
            for (itemIndex, item) in samples.loosePantryItems.enumerated() {
                context.insert(PantryItem(name: item.name, quantity: item.quantity, sortOrder: itemIndex))
            }
        }

        try? context.save()
    }

    /// Deletes all user data and reseeds the sample set for the current app
    /// language. Backs the developer-only reset button in MoreView.
    static func wipeAndReseed(context: ModelContext) {
        // Delete through the context (not a batch delete) so cascade rules
        // clean up ingredients, headings, and steps.
        for recipe in (try? context.fetch(FetchDescriptor<Recipe>())) ?? [] { context.delete(recipe) }
        for tag in (try? context.fetch(FetchDescriptor<RecipeTag>())) ?? [] { context.delete(tag) }
        for item in (try? context.fetch(FetchDescriptor<PantryItem>())) ?? [] { context.delete(item) }
        for category in (try? context.fetch(FetchDescriptor<PantryCategory>())) ?? [] { context.delete(category) }
        try? context.save()

        seedIfEmpty(context: context)
    }

    /// Returns a ModelContainer with seeded sample data
    static func containerWithSamples() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self, MealPlanEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            seedIfEmpty(context: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }

    // MARK: - Sample sets

    private struct SampleSet {
        var recipes: [(recipe: Recipe, tags: [String], createdAt: Date, isFavorite: Bool)]
        var extraTitles: [String]
        var pantryCategories: [(name: String, items: [(name: String, quantity: String)])]
        var loosePantryItems: [(name: String, quantity: String)]
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    private static func makeRecipe(
        _ name: String,
        _ desc: String,
        ingredients: [(String, String)],
        steps: [String]
    ) -> Recipe {
        Recipe(
            name: name,
            desc: desc,
            ingredients: ingredients.enumerated().map { Ingredient(name: $0.element.0, quantity: $0.element.1, sortOrder: $0.offset) },
            steps: steps.enumerated().map { Step(value: $0.element, sortOrder: $0.offset) }
        )
    }

    private static func englishSamples() -> SampleSet {
        SampleSet(
            recipes: [
                (sampleRecipeEnglish, tags: ["Dinner", "Italian"], createdAt: date(2026, 1, 21), isFavorite: true),
                (makeRecipe(
                    "Fluffy Pancakes",
                    "Weekend breakfast stack, serves 2",
                    ingredients: [
                        ("Plain flour", "150g"),
                        ("Milk", "180ml"),
                        ("Egg", "1"),
                        ("Baking powder", "2 tsp"),
                        ("Sugar", "2 tbsp"),
                        ("Butter", "A knob"),
                        ("Maple syrup", "To serve"),
                    ],
                    steps: [
                        "Whisk the flour, baking powder, and sugar together in a bowl.",
                        "Whisk the milk and egg together, then fold into the dry ingredients until just combined.",
                        "Melt butter in a pan over medium heat. Pour in a ladle of batter and cook until bubbles appear, then flip.",
                        "Repeat with the remaining batter. Serve with maple syrup.",
                    ]
                ), tags: ["Breakfast", "Quick"], createdAt: daysAgo(3), isFavorite: false),
                (makeRecipe(
                    "Chicken Caesar Salad",
                    "Crisp lunch salad with grilled chicken, serves 2",
                    ingredients: [
                        ("Chicken breast", "1 large"),
                        ("Romaine lettuce", "1 head"),
                        ("Parmesan cheese", "30g"),
                        ("Croutons", "1 cup"),
                        ("Caesar dressing", "4 tbsp"),
                        ("Olive oil", "1 tbsp"),
                    ],
                    steps: [
                        "Season the chicken and grill in olive oil until cooked through. Rest, then slice.",
                        "Chop the lettuce and toss with the dressing.",
                        "Top with chicken, croutons, and shaved parmesan.",
                    ]
                ), tags: ["Quick"], createdAt: daysAgo(9), isFavorite: false),
                (makeRecipe(
                    "Beef Tacos",
                    "Weeknight tacos with spiced ground beef, serves 3–4",
                    ingredients: [
                        ("Ground beef", "400g"),
                        ("Taco shells", "8"),
                        ("Taco seasoning", "2 tbsp"),
                        ("Cheddar cheese", "100g"),
                        ("Lettuce & tomato", "For topping"),
                        ("Sour cream", "To serve"),
                    ],
                    steps: [
                        "Brown the beef in a pan, then stir in the seasoning with a splash of water.",
                        "Warm the taco shells in the oven.",
                        "Fill the shells with beef and top with cheese, lettuce, tomato, and sour cream.",
                    ]
                ), tags: ["Dinner", "Mexican"], createdAt: date(2025, 12, 8), isFavorite: true),
                (makeRecipe(
                    "Roasted Tomato Soup",
                    "Comforting soup with roasted tomatoes and basil, serves 4",
                    ingredients: [
                        ("Tomatoes", "1kg"),
                        ("Onion", "1"),
                        ("Garlic cloves", "3"),
                        ("Olive oil", "3 tbsp"),
                        ("Vegetable stock", "500ml"),
                        ("Fresh basil", "A handful"),
                        ("Cream", "50ml (optional)"),
                    ],
                    steps: [
                        "Roast the tomatoes, onion, and garlic with olive oil at 200°C for 30 minutes.",
                        "Blend with the stock until smooth.",
                        "Simmer for 10 minutes, stir in the basil, and season to taste.",
                        "Serve with a swirl of cream.",
                    ]
                ), tags: ["Dinner"], createdAt: date(2025, 11, 12), isFavorite: false),
            ],
            extraTitles: [
                "Garlic Butter Shrimp",
                "Mushroom Risotto",
                "Greek Salad",
                "BBQ Pulled Pork",
                "Lemon Drizzle Cake",
                "French Onion Soup",
                "Chicken Tikka Masala",
                "Avocado Toast",
                "Beef Stroganoff",
                "Ratatouille",
                "Fish and Chips",
                "Banana Bread",
                "Shepherd's Pie",
                "Pad Thai",
                "Clam Chowder",
            ],
            pantryCategories: [
                (name: "Vegetables", items: [
                    (name: "Onion", quantity: "2"),
                    (name: "Garlic", quantity: "1 bulb"),
                    (name: "Carrots", quantity: "3"),
                ]),
                (name: "Condiments", items: [
                    (name: "Olive oil", quantity: "1 bottle"),
                    (name: "Soy sauce", quantity: "500ml"),
                ]),
            ],
            loosePantryItems: [
                (name: "Eggs", quantity: "6"),
                (name: "Plain flour", quantity: "1kg"),
            ]
        )
    }

    private static func japaneseSamples() -> SampleSet {
        SampleSet(
            recipes: [
                (sampleRecipeJapanese, tags: ["夕食", "和食"], createdAt: date(2026, 1, 10), isFavorite: false),
                (makeRecipe(
                    "味噌汁",
                    "定番の朝食、2人分",
                    ingredients: [
                        ("豆腐", "1/4丁"),
                        ("乾燥わかめ", "大さじ1"),
                        ("味噌", "大さじ2"),
                        ("だしの素", "小さじ1"),
                        ("水", "400ml"),
                        ("長ねぎ", "適量"),
                    ],
                    steps: [
                        "鍋に水とだしの素を入れて沸かす。",
                        "さいの目に切った豆腐とわかめを加えて2分煮る。",
                        "火を止めて味噌を溶き入れる。",
                        "小口切りにした長ねぎを散らして完成。",
                    ]
                ), tags: ["朝食", "和食"], createdAt: daysAgo(2), isFavorite: false),
                (makeRecipe(
                    "カレーライス",
                    "みんな大好き、4人分",
                    ingredients: [
                        ("カレールー", "1/2箱"),
                        ("豚こま肉", "300g"),
                        ("玉ねぎ", "2個"),
                        ("にんじん", "1本"),
                        ("じゃがいも", "2個"),
                        ("水", "700ml"),
                        ("ご飯", "4人分"),
                    ],
                    steps: [
                        "野菜と肉を一口大に切る。",
                        "鍋に油を熱し、肉と野菜を炒める。",
                        "水を加えて沸騰したらアクを取り、15分煮込む。",
                        "火を止めてルーを溶かし、とろみが付くまで弱火で煮る。",
                        "ご飯にかけて完成。",
                    ]
                ), tags: ["夕食"], createdAt: date(2025, 12, 14), isFavorite: true),
                (makeRecipe(
                    "鶏の唐揚げ",
                    "外はカリッと中はジューシー、2〜3人分",
                    ingredients: [
                        ("鶏もも肉", "400g"),
                        ("醤油", "大さじ2"),
                        ("酒", "大さじ1"),
                        ("にんにく", "1片"),
                        ("生姜", "1片"),
                        ("片栗粉", "適量"),
                        ("揚げ油", "適量"),
                    ],
                    steps: [
                        "鶏肉を一口大に切り、すりおろしたにんにく・生姜と調味料に30分漬ける。",
                        "汁気を切って片栗粉をまぶす。",
                        "170℃の油で4〜5分揚げて一度取り出す。",
                        "180℃に上げて1分二度揚げする。",
                    ]
                ), tags: ["夕食", "揚げ物"], createdAt: date(2025, 11, 20), isFavorite: false),
                (makeRecipe(
                    "卵焼き",
                    "お弁当の定番、卵3個分",
                    ingredients: [
                        ("卵", "3個"),
                        ("砂糖", "大さじ1"),
                        ("みりん", "大さじ1"),
                        ("塩", "少々"),
                        ("サラダ油", "適量"),
                    ],
                    steps: [
                        "卵と調味料をよく混ぜる。",
                        "卵焼き器に油をひき、卵液の1/3を流し入れる。",
                        "半熟のうちに手前に巻き、奥に寄せる。",
                        "残りの卵液も同様に繰り返し、形を整えて完成。",
                    ]
                ), tags: ["朝食", "和食"], createdAt: daysAgo(6), isFavorite: false),
            ],
            extraTitles: [
                "肉じゃが",
                "生姜焼き",
                "天ぷら",
                "おでん",
                "冷やし中華",
                "ハンバーグ",
                "焼きそば",
                "お好み焼き",
                "茶碗蒸し",
                "ぶり大根",
                "グラタン",
                "オムライス",
                "豚汁",
                "ナポリタン",
                "餃子",
            ],
            pantryCategories: [
                (name: "野菜", items: [
                    (name: "玉ねぎ", quantity: "3個"),
                    (name: "にんじん", quantity: "2本"),
                    (name: "じゃがいも", quantity: "4個"),
                ]),
                (name: "調味料", items: [
                    (name: "醤油", quantity: "1本"),
                    (name: "みりん", quantity: "500ml"),
                    (name: "味噌", quantity: "1パック"),
                ]),
            ],
            loosePantryItems: [
                (name: "卵", quantity: "6個"),
                (name: "米", quantity: "2kg"),
            ]
        )
    }

    private static func traditionalChineseSamples() -> SampleSet {
        SampleSet(
            recipes: [
                (makeRecipe(
                    "蕃茄炒蛋",
                    "簡單快手的住家菜，2人份",
                    ingredients: [
                        ("蕃茄", "2個"),
                        ("雞蛋", "3隻"),
                        ("蔥", "1條"),
                        ("糖", "1茶匙"),
                        ("鹽", "適量"),
                        ("油", "2湯匙"),
                    ],
                    steps: [
                        "蕃茄切件、蔥切段、雞蛋打勻。",
                        "燒熱油將蛋炒至半熟後盛起。",
                        "下蕃茄炒軟，加入糖和鹽調味。",
                        "回鑊與炒蛋拌勻，灑上蔥段即成。",
                    ]
                ), tags: ["家常", "快速"], createdAt: daysAgo(1), isFavorite: false),
                (makeRecipe(
                    "豉油雞",
                    "皮滑肉嫩的經典粵菜，4人份",
                    ingredients: [
                        ("光雞", "1隻（約1.2kg）"),
                        ("生抽", "200ml"),
                        ("老抽", "3湯匙"),
                        ("冰糖", "60g"),
                        ("薑", "4片"),
                        ("蔥", "2條"),
                        ("八角", "2粒"),
                        ("紹興酒", "2湯匙"),
                        ("水", "600ml"),
                    ],
                    steps: [
                        "將生抽、老抽、冰糖、薑蔥、八角、紹興酒和水煮滾成豉油汁。",
                        "放入全雞，小火浸煮約30分鐘，中途翻面。",
                        "熄火加蓋焗15分鐘至熟透。",
                        "取出放涼後斬件，淋上豉油汁即成。",
                    ]
                ), tags: ["晚餐", "港式"], createdAt: date(2025, 12, 6), isFavorite: true),
                (makeRecipe(
                    "西多士",
                    "港式茶餐廳經典，1人份",
                    ingredients: [
                        ("方包", "2片"),
                        ("花生醬", "適量"),
                        ("雞蛋", "2隻"),
                        ("牛油", "1小塊"),
                        ("糖漿", "適量"),
                        ("油", "適量"),
                    ],
                    steps: [
                        "方包塗上花生醬夾好。",
                        "雞蛋打勻，將多士兩面沾滿蛋液。",
                        "中火半煎炸至兩面金黃。",
                        "放上牛油、淋上糖漿趁熱享用。",
                    ]
                ), tags: ["早餐", "港式"], createdAt: daysAgo(7), isFavorite: false),
                (makeRecipe(
                    "咕嚕肉",
                    "酸甜開胃的經典粵菜，3人份",
                    ingredients: [
                        ("梅頭豬肉", "400g"),
                        ("青椒", "1個"),
                        ("菠蘿", "4片"),
                        ("雞蛋", "1隻"),
                        ("生粉", "適量"),
                        ("茄汁", "4湯匙"),
                        ("白醋", "3湯匙"),
                        ("糖", "3湯匙"),
                    ],
                    steps: [
                        "豬肉切件醃味，沾上蛋液和生粉。",
                        "落油鑊炸至金黃酥脆，撈起備用。",
                        "茄汁、白醋、糖煮成甜酸汁。",
                        "加入青椒、菠蘿和炸豬肉炒勻上碟。",
                    ]
                ), tags: ["晚餐", "家常"], createdAt: date(2026, 1, 18), isFavorite: false),
                (makeRecipe(
                    "臘味煲仔飯",
                    "秋冬暖胃之選，2人份",
                    ingredients: [
                        ("白米", "1.5杯"),
                        ("臘腸", "2條"),
                        ("膶腸", "1條"),
                        ("菜心", "適量"),
                        ("生抽", "2湯匙"),
                        ("老抽", "1湯匙"),
                        ("糖", "1茶匙"),
                        ("熟油", "1湯匙"),
                    ],
                    steps: [
                        "白米洗淨放入瓦煲，加水煮至水分收乾。",
                        "放上切片的臘腸膶腸，加蓋小火焗15分鐘。",
                        "菜心灼熟排在飯面。",
                        "生抽、老抽、糖和熟油拌勻成豉油，食前淋上撈勻即成。",
                    ]
                ), tags: ["晚餐", "港式"], createdAt: date(2025, 11, 16), isFavorite: false),
            ],
            extraTitles: [
                "雲吞麵",
                "菠蘿包",
                "蛋撻",
                "楊枝甘露",
                "白切雞",
                "蒸水蛋",
                "豉椒排骨",
                "乾炒牛河",
                "魚香茄子",
                "蝦餃",
                "奶黃包",
                "煎釀三寶",
                "皮蛋瘦肉粥",
                "港式奶茶",
                "薑汁撞奶",
            ],
            pantryCategories: [
                (name: "蔬菜", items: [
                    (name: "蔥", quantity: "1紮"),
                    (name: "蒜頭", quantity: "2個"),
                    (name: "蕃茄", quantity: "3個"),
                ]),
                (name: "調味料", items: [
                    (name: "生抽", quantity: "1樽"),
                    (name: "老抽", quantity: "1樽"),
                    (name: "麻油", quantity: "1樽"),
                ]),
            ],
            loosePantryItems: [
                (name: "雞蛋", quantity: "1打"),
                (name: "白米", quantity: "5kg"),
            ]
        )
    }
}
