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

    private static func requireUserId() async throws -> UUID {
        do {
            return try await client.auth.session.user.id
        } catch {
            throw AuthServiceError.notSignedIn
        }
    }

    /// Creates a profile row right after auth so Table Editor isn't empty.
    static func ensureProfileStub(email: String) async throws {
        let defaults = UserDefaults.standard
        try await upsertProfile(
            firstName: defaults.string(forKey: UserProfileKey.firstName) ?? "",
            lastName: defaults.string(forKey: UserProfileKey.lastName) ?? "",
            email: email,
            phone: defaults.string(forKey: UserProfileKey.phone) ?? "",
            dailyCalorieGoal: defaults.object(forKey: UserProfileKey.dailyCalorieGoal) as? Double ?? 2000,
            dailyProteinGoal: defaults.object(forKey: UserProfileKey.dailyProteinGoal) as? Double ?? 150,
            dailyCarbsGoal: defaults.object(forKey: UserProfileKey.dailyCarbsGoal) as? Double ?? 200,
            dailyFatGoal: defaults.object(forKey: UserProfileKey.dailyFatGoal) as? Double ?? 65,
            dailyWaterGoalMl: defaults.object(forKey: UserProfileKey.dailyWaterGoalMl) as? Double ?? 2000
        )
    }

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
        let uid = try await requireUserId()
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
        let uid = try await requireUserId()
        let rows: [ProfileRecord] = try await client
            .from("profiles")
            .select()
            .eq("id", value: uid)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    static func upsertMeal(
        id: UUID,
        foodName: String,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatsG: Double,
        insights: String,
        createdAt: Date,
        imageFileName: String,
        mealKind: String
    ) async throws {
        let uid = try await requireUserId()
        let record = MealRecord(
            id: id,
            userId: uid,
            foodName: foodName,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatsG: fatsG,
            insights: insights,
            createdAt: createdAt,
            imageFileName: imageFileName,
            mealKind: mealKind
        )
        try await client.from("meals").upsert(record).execute()
    }

    static func upsertWater(
        id: UUID,
        amountMl: Double,
        createdAt: Date,
        note: String
    ) async throws {
        let uid = try await requireUserId()
        let record = WaterRecord(
            id: id,
            userId: uid,
            amountMl: amountMl,
            createdAt: createdAt,
            note: note
        )
        try await client.from("water_logs").upsert(record).execute()
    }

    static func upsertFavorite(
        id: UUID,
        title: String,
        bodyText: String,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatsG: Double,
        mealType: String,
        dietaryPreference: String,
        ingredients: String,
        createdAt: Date
    ) async throws {
        let uid = try await requireUserId()
        let record = FavoriteRecord(
            id: id,
            userId: uid,
            title: title,
            bodyText: bodyText,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatsG: fatsG,
            mealType: mealType,
            dietaryPreference: dietaryPreference,
            ingredients: ingredients,
            createdAt: createdAt
        )
        try await client.from("favorite_recipes").upsert(record).execute()
    }
}
