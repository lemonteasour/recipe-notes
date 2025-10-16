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
            Ingredient(name: "Spaghetti", quantity: "200g", index: 0),
            Ingredient(name: "Parmesan cheese", quantity: "For serving", index: 1),
            // Sauce
            Ingredient(name: "Ground beef", quantity: "250g", index: 3),
            Ingredient(name: "Onion", quantity: "1 small", index: 4),
            Ingredient(name: "Garlic cloves", quantity: "2", index: 5),
            Ingredient(name: "Carrot", quantity: "1 small", index: 6),
            Ingredient(name: "Celery", quantity: "1 stick", index: 7),
            Ingredient(name: "Olive oil", quantity: "2 tbsp", index: 8),
            Ingredient(name: "Tomato paste", quantity: "2 tbsp", index: 9),
            Ingredient(name: "Canned tomatoes", quantity: "400g", index: 10),
            Ingredient(name: "Beef stock", quantity: "100ml", index: 11),
            Ingredient(name: "Dried oregano", quantity: "1 tsp", index: 12),
            Ingredient(name: "Salt & pepper", quantity: "To taste", index: 13),
        ],
        ingredientHeadings: [
            IngredientHeading(name: "Sauce", index: 2)
        ],
        steps: [
            Step(value: "Finely chop the onion, garlic, carrot, and celery.", index: 0),
            Step(value: "Heat olive oil in a pan. Add onion, garlic, carrot, and celery, and sauté until softened.", index: 1),
            Step(value: "Add ground beef and cook until browned.", index: 2),
            Step(value: "Stir in tomato paste and cook briefly, then add canned tomatoes and beef stock.", index: 3),
            Step(value: "Season with oregano, salt, and pepper. Simmer on low heat for 20–30 minutes.", index: 4),
            Step(value: "Meanwhile, cook spaghetti in salted boiling water until al dente. Drain well.", index: 5),
            Step(value: "Serve spaghetti topped with the sauce. Garnish with parmesan cheese.", index: 6),
        ]
    )


    static let sampleRecipeJapanese: Recipe = Recipe(
        name: "親子丼",
        desc: "2人分",
        ingredients: [
            Ingredient(name: "鶏肉", quantity: "200g", index: 0),
            Ingredient(name: "玉ねぎ", quantity: "半玉", index: 1),
            Ingredient(name: "卵", quantity: "3個", index: 2),
            Ingredient(name: "ご飯", quantity: "250g", index: 3),
            // Condiments
            Ingredient(name: "麺つゆ", quantity: "大さじ4", index: 5),
            Ingredient(name: "水", quantity: "200ml", index: 6),
            Ingredient(name: "水溶き片栗粉", quantity: "適量", index: 7),
        ],
        ingredientHeadings: [
            IngredientHeading(name: "調味料", index: 4)
        ],
        steps: [
            Step(value: "鶏肉を一口大に切り、玉ねぎを0.5mm幅にスライスする。", index: 0),
            Step(value: "片栗粉以外の調味料を鍋に入れ、1の具材を加える。", index: 1),
            Step(value: "加熱し、鶏肉に完全に火が通ったら水溶き片栗粉でとろみをつける。", index: 2),
            Step(value: "卵はかけ混ぜすぎないように解き、半分加えて8割くらい火を通す。", index: 3),
            Step(value: "残り半分の卵も加え、火を止めて蓋をして10分待つ。", index: 4),
            Step(value: "ご飯の上に盛り付けて完成。", index: 5)
        ]
    )

    static let samplePantryItemEnglish: PantryItem = PantryItem(name: "Onion", quantity: "2")


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
