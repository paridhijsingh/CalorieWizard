//
//  RecipeGeneratorView.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/13/26.
//

import SwiftData
import SwiftUI

struct RecipeGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab = 0
    @State private var ingredientsInput = ""
    @State private var targetCalories: Double = 500
    @State private var mealType = "Main Course"
    @State private var dietaryPreference = "Balanced"
    @State private var selectedHealthCondition = "None"
    @State private var generatedText = "Enter your available ingredients to craft a healthy, preservative-free gourmet recipe..."
    @State private var parsedRecipe: GeneratedRecipePayload?
    @State private var isLoading = false
    @State private var toastMessage: String?

    private let mealTypes = ["Main Course", "Snack", "Dessert"]
    private let dietaryOptions = ["Balanced", "High-Protein", "Low-Carb", "Vegetarian", "Keto"]
    private let healthConditions = ["None", "Celiac / Gluten-Free", "Diabetic / Low-Glycemic", "High Cholesterol / Heart-Healthy", "Low-Sodium"]
    private var apiKey: String { APIKeys.gemini }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    Text("Create").tag(0)
                    Text("Favorites").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                if selectedTab == 0 {
                    createForm
                } else {
                    FavoritesListView()
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Recipes")
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    Text(toastMessage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.95), in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var createForm: some View {
        Form {
            Section("Available Ingredients / Pantry Items") {
                TextField("e.g., oats, almond milk, banana, eggs", text: $ingredientsInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Category") {
                Picker("Meal Type", selection: $mealType) {
                    ForEach(mealTypes, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Dietary Focus & Health Needs") {
                Picker("Diet", selection: $dietaryPreference) {
                    ForEach(dietaryOptions, id: \.self) { Text($0).tag($0) }
                }
                Picker("Health Focus", selection: $selectedHealthCondition) {
                    ForEach(healthConditions, id: \.self) { Text($0).tag($0) }
                }
            }

            Section("Calorie Target: \(Int(targetCalories)) kcal") {
                Slider(value: $targetCalories, in: 150...1000, step: 25)
            }

            Section {
                Button {
                    Task { await generateGourmetRecipe() }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Label("Craft Gourmet Recipe", systemImage: "wand.and.stars")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(isLoading || ingredientsInput.trimmingCharacters(in: .whitespaces).isEmpty || !APIKeys.hasGemini)
            }

            Section("Culinary Result") {
                if isLoading {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Designing safe, restaurant-quality creation...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if let parsedRecipe {
                    RecipeResultCard(
                        recipe: parsedRecipe,
                        onSave: { saveFavorite(parsedRecipe) },
                        onLog: { logToTracker(parsedRecipe) }
                    )
                } else {
                    Text(generatedText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation {
            toastMessage = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { toastMessage = nil }
            }
        }
    }

    private func saveFavorite(_ recipe: GeneratedRecipePayload) {
        let favorite = FavoriteRecipe(
            title: recipe.title,
            bodyText: recipe.formattedBody,
            calories: recipe.calories,
            proteinG: recipe.proteinG,
            carbsG: recipe.carbsG,
            fatsG: recipe.fatsG,
            mealType: mealType,
            dietaryPreference: dietaryPreference,
            ingredients: ingredientsInput
        )
        modelContext.insert(favorite)
        try? modelContext.save()
        showToast("Saved to Favorites")
        selectedTab = 1
    }

    private func logToTracker(_ recipe: GeneratedRecipePayload) {
        let entry = MealEntry(
            foodName: recipe.title,
            calories: recipe.calories,
            proteinG: recipe.proteinG,
            carbsG: recipe.carbsG,
            fatsG: recipe.fatsG,
            insights: recipe.insights.isEmpty ? "Logged from Recipe Wizard" : recipe.insights,
            imageFileName: "",
            mealKind: mealType == "Snack" ? .snack : .meal
        )
        modelContext.insert(entry)
        try? modelContext.save()
        showToast("Logged to Today’s tracker")
    }

    func generateGourmetRecipe() async {
        guard APIKeys.hasGemini else {
            generatedText = "Add your Gemini API key in Config/Secrets.xcconfig first."
            parsedRecipe = nil
            return
        }

        isLoading = true
        parsedRecipe = nil
        defer { isLoading = false }

        let ingredientsList = ingredientsInput
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }

        let prompt = """
        You are an elite clinical nutritionist and Michelin-trained private chef.
        Create a preservative-free, budget-friendly '\(mealType)' for:
        - Health/Medical Need: \(selectedHealthCondition)
        - Core Diet Style: \(dietaryPreference)
        - Ingredients Available: \(ingredientsList.joined(separator: ", "))
        - Calorie Target: Around \(Int(targetCalories)) calories

        Maximize flavor with natural spices, herbs, and marinades without empty calories.

        Respond with ONLY compact JSON (no markdown fences):
        {
          "title":"Recipe name",
          "cooking_time":"25 min",
          "ingredients":["1 cup oats","..."],
          "instructions":["Step 1","Step 2"],
          "calories":0,
          "protein_g":0,
          "carbs_g":0,
          "fats_g":0,
          "insights":"1-2 sentences on nutrition and flavor"
        }
        Use numbers for calories and grams. Quantities must be exact.
        """

        let payload: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                if let recipe = GeneratedRecipePayload.parse(from: text) {
                    parsedRecipe = recipe
                    generatedText = recipe.formattedBody
                } else {
                    parsedRecipe = nil
                    generatedText = text
                }
            } else {
                generatedText = "Failed to generate recipe. Please try again."
            }
        } catch {
            generatedText = "Error connecting to Gemini: \(error.localizedDescription)"
        }
    }
}

private struct RecipeResultCard: View {
    let recipe: GeneratedRecipePayload
    var onSave: () -> Void
    var onLog: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(recipe.title)
                .font(.title3.weight(.bold))

            if !recipe.cookingTime.isEmpty {
                Label(recipe.cookingTime, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                macroPill("\(Int(recipe.calories.rounded())) kcal", color: .purple)
                macroPill("P \(Int(recipe.proteinG.rounded()))g", color: .purple)
                macroPill("C \(Int(recipe.carbsG.rounded()))g", color: .orange)
                macroPill("F \(Int(recipe.fatsG.rounded()))g", color: .green)
            }

            if !recipe.insights.isEmpty {
                Text(recipe.insights)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !recipe.ingredients.isEmpty {
                Text("Ingredients")
                    .font(.headline)
                ForEach(recipe.ingredients, id: \.self) { item in
                    Text("• \(item)")
                        .font(.subheadline)
                }
            }

            if !recipe.instructions.isEmpty {
                Text("Instructions")
                    .font(.headline)
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .font(.subheadline)
                }
            }

            HStack(spacing: 10) {
                Button(action: onSave) {
                    Label("Save to Favorites", systemImage: "heart.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)

                Button(action: onLog) {
                    Label("Log to Today", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    private func macroPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

struct FavoritesListView: View {
    @Query(sort: \FavoriteRecipe.createdAt, order: .reverse) private var favorites: [FavoriteRecipe]
    @Environment(\.modelContext) private var modelContext
    @State private var toastMessage: String?

    var body: some View {
        Group {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "No favorites yet",
                    systemImage: "heart",
                    description: Text("Generate a recipe and tap Save to Favorites.")
                )
            } else {
                List {
                    ForEach(favorites) { recipe in
                        NavigationLink {
                            FavoriteRecipeDetailView(recipe: recipe)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(recipe.title)
                                    .font(.headline)
                                Text("\(recipe.mealType) · \(Int(recipe.calories.rounded())) kcal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("P \(Int(recipe.proteinG.rounded()))g · C \(Int(recipe.carbsG.rounded()))g · F \(Int(recipe.fatsG.rounded()))g")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(recipe)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                logFavorite(recipe)
                            } label: {
                                Label("Log", systemImage: "plus.circle")
                            }
                            .tint(.purple)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.95), in: Capsule())
                    .padding(.bottom, 24)
            }
        }
    }

    private func logFavorite(_ recipe: FavoriteRecipe) {
        let entry = MealEntry(
            foodName: recipe.title,
            calories: recipe.calories,
            proteinG: recipe.proteinG,
            carbsG: recipe.carbsG,
            fatsG: recipe.fatsG,
            insights: "Logged from Favorites",
            imageFileName: "",
            mealKind: recipe.mealType == "Snack" ? .snack : .meal
        )
        modelContext.insert(entry)
        try? modelContext.save()
        toastMessage = "Logged to Today"
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { toastMessage = nil }
        }
    }
}

struct FavoriteRecipeDetailView: View {
    let recipe: FavoriteRecipe
    @Environment(\.modelContext) private var modelContext
    @State private var didLog = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.title)
                    .font(.largeTitle.weight(.bold))

                Text("\(recipe.mealType) · \(recipe.dietaryPreference)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Text("\(Int(recipe.calories.rounded())) kcal")
                    Text("P \(Int(recipe.proteinG.rounded()))g")
                    Text("C \(Int(recipe.carbsG.rounded()))g")
                    Text("F \(Int(recipe.fatsG.rounded()))g")
                }
                .font(.subheadline.weight(.semibold).monospacedDigit())

                Text(recipe.bodyText)
                    .font(.body)

                Button {
                    let entry = MealEntry(
                        foodName: recipe.title,
                        calories: recipe.calories,
                        proteinG: recipe.proteinG,
                        carbsG: recipe.carbsG,
                        fatsG: recipe.fatsG,
                        insights: "Logged from Favorites",
                        imageFileName: "",
                        mealKind: recipe.mealType == "Snack" ? .snack : .meal
                    )
                    modelContext.insert(entry)
                    try? modelContext.save()
                    didLog = true
                } label: {
                    Label(didLog ? "Logged to Today" : "Log to Daily Tracker", systemImage: didLog ? "checkmark.circle.fill" : "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(didLog)
            }
            .padding()
        }
        .navigationTitle("Favorite")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    RecipeGeneratorView()
        .modelContainer(for: [MealEntry.self, FavoriteRecipe.self], inMemory: true)
}
