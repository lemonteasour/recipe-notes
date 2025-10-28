//
//  PreviewData.swift
//  RecipeNotes
//
//  Created by Jay Hui on 28/09/2025.
//


import SwiftData

@MainActor
enum PreviewData {

    static let sampleRecipeEnglish = Recipe(
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
    )


    static let sampleRecipeJapanese: Recipe = Recipe(
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
    )

    static let samplePantryItemEnglish: PantryItem = PantryItem(name: "Onion", quantity: "2", sortOrder: -1)


    /// Returns a ModelContainer with seeded sample data
    static func containerWithSamples() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Recipe.self, PantryItem.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Seed if empty
            if try context.fetch(FetchDescriptor<Recipe>()).isEmpty {
                context.insert(sampleRecipeEnglish)
            }
            if try context.fetch(FetchDescriptor<PantryItem>()).isEmpty {
                context.insert(samplePantryItemEnglish)
            }

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
