//
//  RecipeGeneratorView.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/13/26.
//

import SwiftUI

struct RecipeGeneratorView: View {
    @State private var ingredientsInput: String = ""
    @State private var targetCalories: Double = 500
    @State private var mealType: String = "Main Course"
    @State private var dietaryPreference: String = "Balanced"
    @State private var selectedHealthCondition: String = "None"
    @State private var generatedRecipe: String = "Enter your available ingredients to craft a healthy, preservative-free gourmet recipe..."
    @State private var isLoading: Bool = false
    
    let mealTypes = ["Main Course", "Snack", "Dessert"]
    let dietaryOptions = ["Balanced", "High-Protein", "Low-Carb", "Vegetarian", "Keto"]
    let healthConditions = ["None", "Celiac / Gluten-Free", "Diabetic / Low-Glycemic", "High Cholesterol / Heart-Healthy", "Low-Sodium"]
    
    // Gemini API Configuration
    private let apiKey = "YOUR_GEMINI_API_KEY"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Available Ingredients / Pantry Items")) {
                    TextField("e.g., oats, almond milk, banana, eggs", text: $ingredientsInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Category")) {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Dietary Focus & Health Needs")) {
                    Picker("Diet", selection: $dietaryPreference) {
                        ForEach(dietaryOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    Picker("Health Focus", selection: $selectedHealthCondition) {
                        ForEach(healthConditions, id: \.self) { condition in
                            Text(condition).tag(condition)
                        }
                    }
                }
                
                Section(header: Text("Calorie Target: \(Int(targetCalories)) kcal")) {
                    Slider(value: $targetCalories, in: 150...1000, step: 25)
                }
                
                Section {
                    Button(action: {
                        Task {
                            await generateGourmetRecipe()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Label("Craft Gourmet Recipe", systemImage: "wand.and.stars")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(isLoading || ingredientsInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                
                Section(header: Text("Culinary Result")) {
                    if isLoading {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Designing safe, restaurant-quality creation...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else {
                        ScrollView {
                            Text(generatedRecipe)
                                .font(.body)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("CalorieWizard Chef")
        }
    }

    // MARK: - Gemini Clinical Nutrition & Culinary Persona Logic
    func generateGourmetRecipe() async {
        isLoading = true
        defer { isLoading = false }
        
        let ingredientsList = ingredientsInput.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        let prompt = """
        You are an elite clinical nutritionist and Michelin-trained private chef. 
        Create a preservative-free, budget-friendly '\(mealType)' tailored precisely for a person with the following profile:
        - Health/Medical Need: \(selectedHealthCondition)
        - Core Diet Style: \(dietaryPreference)
        - Ingredients Available: \(ingredientsList.joined(separator: ", "))
        - Calorie Target: Around \(Int(targetCalories)) calories
        
        CRITICAL CONSTRAINTS:
        1. Medical Safety: If Celiac, strictly avoid all gluten cross-contamination sources. If Diabetic, focus on low-glycemic, blood-sugar-friendly choices. If High Cholesterol, prioritize heart-healthy fats and avoid saturated fats.
        2. Budget-Friendly: Rely on everyday, affordable grocery staples.
        3. Preservative-Free: Emphasize fresh, whole-food execution.
        4. Taste Elevation: Ensure healthy food doesn't taste boring. Use intelligent spice layering, herbs, natural acids, and chef techniques to deliver a gourmet restaurant experience.
        
        Format clearly with:
        - Gourmet Recipe Title
        - Prep & Cook Time
        - Health & Safety Note (Addressing the medical/dietary need)
        - Chef's Flavor Secret (How to maximize flavor)
        - Step-by-Step Instructions
        - Estimated Macros (Calories, Protein, Carbs, Sugars, Fiber, Fats)
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
                generatedRecipe = text
            } else {
                generatedRecipe = "Failed to generate recipe. Please try again."
            }
        } catch {
            generatedRecipe = "Error connecting to Gemini: \(error.localizedDescription)"
        }
    }
}

#Preview {
    RecipeGeneratorView()
}
