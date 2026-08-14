//
//  SupabaseSyncService.swift
//  CalorieWizard
//

import Foundation
import Supabase

struct ProfileRecord: Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var dailyCalorieGoal: Double
    var dailyProteinGoal: Double
    var dailyCarbsGoal: Double
    var dailyFatGoal: Double
    var dailyWaterGoalMl: Double

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case dailyCalorieGoal = "daily_calorie_goal"
        case dailyProteinGoal = "daily_protein_goal"
        case dailyCarbsGoal = "daily_carbs_goal"
        case dailyFatGoal = "daily_fat_goal"
        case dailyWaterGoalMl = "daily_water_goal_ml"
    }
}

struct MealRecord: Codable {
    let id: UUID
    let userId: UUID
    var foodName: String
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatsG: Double
    var insights: String
    var createdAt: Date
    var imageFileName: String
    var mealKind: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case foodName = "food_name"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatsG = "fats_g"
        case insights
        case createdAt = "created_at"
        case imageFileName = "image_file_name"
        case mealKind = "meal_kind"
    }
}

struct WaterRecord: Codable {
    let id: UUID
    let userId: UUID
    var amountMl: Double
    var createdAt: Date
    var note: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amountMl = "amount_ml"
        case createdAt = "created_at"
        case note
    }
}

struct FavoriteRecord: Codable {
    let id: UUID
    let userId: UUID
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

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case bodyText = "body_text"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatsG = "fats_g"
        case mealType = "meal_type"
        case dietaryPreference = "dietary_preference"
        case ingredients
        case createdAt = "created_at"
    }
}

@MainActor
enum SupabaseSyncService {
    private static var client: SupabaseClient { SupabaseManager.client }

    static func upsertProfile(
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        dailyCalorieGoal: Double,
        dailyProteinGoal: Double,
        dailyCarbsGoal: Double,
        dailyFatGoal: Double,
        dailyWaterGoalMl: Double
    ) async throws {
        guard let uid = try? await client.auth.session.user.id else { return }
        let record = ProfileRecord(
            id: uid,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            dailyCalorieGoal: dailyCalorieGoal,
            dailyProteinGoal: dailyProteinGoal,
            dailyCarbsGoal: dailyCarbsGoal,
            dailyFatGoal: dailyFatGoal,
            dailyWaterGoalMl: dailyWaterGoalMl
        )
        try await client.from("profiles").upsert(record).execute()
    }

    static func fetchProfile() async throws -> ProfileRecord? {
        guard let uid = try? await client.auth.session.user.id else { return nil }
        let rows: [ProfileRecord] = try await client
            .from("profiles")
            .select()
            .eq("id", value: uid)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    static func upsertMeal(_ meal: MealEntry) async throws {
        guard let uid = try? await client.auth.session.user.id else { return }
        let record = MealRecord(
            id: meal.id,
            userId: uid,
            foodName: meal.foodName,
            calories: meal.calories,
            proteinG: meal.proteinG,
            carbsG: meal.carbsG,
            fatsG: meal.fatsG,
            insights: meal.insights,
            createdAt: meal.createdAt,
            imageFileName: meal.imageFileName,
            mealKind: meal.mealKind.rawValue
        )
        try await client.from("meals").upsert(record).execute()
    }

    static func upsertWater(_ entry: WaterEntry) async throws {
        guard let uid = try? await client.auth.session.user.id else { return }
        let record = WaterRecord(
            id: entry.id,
            userId: uid,
            amountMl: entry.amountMl,
            createdAt: entry.createdAt,
            note: entry.note
        )
        try await client.from("water_logs").upsert(record).execute()
    }

    static func upsertFavorite(_ recipe: FavoriteRecipe) async throws {
        guard let uid = try? await client.auth.session.user.id else { return }
        let record = FavoriteRecord(
            id: recipe.id,
            userId: uid,
            title: recipe.title,
            bodyText: recipe.bodyText,
            calories: recipe.calories,
            proteinG: recipe.proteinG,
            carbsG: recipe.carbsG,
            fatsG: recipe.fatsG,
            mealType: recipe.mealType,
            dietaryPreference: recipe.dietaryPreference,
            ingredients: recipe.ingredients,
            createdAt: recipe.createdAt
        )
        try await client.from("favorite_recipes").upsert(record).execute()
    }
}
