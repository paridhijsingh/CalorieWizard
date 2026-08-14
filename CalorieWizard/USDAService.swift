//
//  USDAService.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/13/26.
//

import Foundation

struct USDAService {
    private var apiKey: String { APIKeys.usda }
    
    func searchFood(query: String) async throws -> [USDAFoodItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(encodedQuery)&api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        return response.foods
    }
}

// MARK: - Models for Decoding USDA JSON
struct USDASearchResponse: Codable {
    let foods: [USDAFoodItem]
}

struct USDAFoodItem: Codable, Identifiable {
    var id: Int { fdcId }
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]?
    
    // Helper to extract specific macros (Calories, Protein, Fat, Carbs)
    func getNutrient(number: String) -> Double {
        return foodNutrients?.first(where: { $0.nutrientNumber == number })?.value ?? 0.0
    }
    
    var calories: Double { getNutrient(number: "1008") } // USDA code for Energy (kcal)
    var protein: Double { getNutrient(number: "1003") }  // USDA code for Protein
    var fat: Double { getNutrient(number: "1004") }      // USDA code for Total lipid (fat)
    var carbs: Double { getNutrient(number: "1005") }    // USDA code for Carbohydrate
}

struct USDANutrient: Codable {
    let nutrientId: Int?
    let nutrientName: String?
    let nutrientNumber: String?
    let value: Double?
}
