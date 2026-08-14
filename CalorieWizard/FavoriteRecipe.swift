//
//  FavoriteRecipe.swift
//  CalorieWizard
//

import Foundation
import SwiftData

@Model
final class FavoriteRecipe {
    var id: UUID
    var title: String
    var bodyText: String
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatsG: Double
    var mealType: String
    var dietaryPreference: String
    var ingredients: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        bodyText: String,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatsG: Double,
        mealType: String,
        dietaryPreference: String,
        ingredients: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.bodyText = bodyText
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatsG = fatsG
        self.mealType = mealType
        self.dietaryPreference = dietaryPreference
        self.ingredients = ingredients
        self.createdAt = createdAt
    }
}

struct GeneratedRecipePayload: Codable, Equatable {
    var title: String
    var cookingTime: String
    var ingredients: [String]
    var instructions: [String]
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatsG: Double
    var insights: String

    enum CodingKeys: String, CodingKey {
        case title
        case cookingTime = "cooking_time"
        case ingredients
        case instructions
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatsG = "fats_g"
        case insights
    }

    var formattedBody: String {
        var lines: [String] = []
        lines.append(title)
        if !cookingTime.isEmpty {
            lines.append("⏱ \(cookingTime)")
        }
        if !insights.isEmpty {
            lines.append("")
            lines.append(insights)
        }
        if !ingredients.isEmpty {
            lines.append("")
            lines.append("Ingredients")
            for item in ingredients {
                lines.append("• \(item)")
            }
        }
        if !instructions.isEmpty {
            lines.append("")
            lines.append("Instructions")
            for (index, step) in instructions.enumerated() {
                lines.append("\(index + 1). \(step)")
            }
        }
        lines.append("")
        lines.append("Macros: \(Int(calories.rounded())) kcal · P \(Int(proteinG.rounded()))g · C \(Int(carbsG.rounded()))g · F \(Int(fatsG.rounded()))g")
        return lines.joined(separator: "\n")
    }

    static func parse(from text: String) -> GeneratedRecipePayload? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let data = cleaned.data(using: .utf8),
           let payload = try? JSONDecoder().decode(GeneratedRecipePayload.self, from: data) {
            return payload
        }
        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}"),
           start < end,
           let data = String(cleaned[start...end]).data(using: .utf8),
           let payload = try? JSONDecoder().decode(GeneratedRecipePayload.self, from: data) {
            return payload
        }
        return nil
    }
}

enum DashboardPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "Today"
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }
}

struct NutritionTotals {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double

    static let zero = NutritionTotals(calories: 0, protein: 0, carbs: 0, fats: 0)
}

struct ChartDayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
}
