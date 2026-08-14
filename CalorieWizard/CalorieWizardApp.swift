//
//  CalorieWizardApp.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/13/26.
//

import SwiftData
import SwiftUI

@main
struct CalorieWizardApp: App {
    init() {
        AuthManager.shared.configureIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
        }
        .modelContainer(for: [MealEntry.self, FavoriteRecipe.self, WaterEntry.self, ReminderEvent.self])
    }
}

struct RootContainerView: View {
    @State private var hasLaunched = false
    @State private var showAuth = false
    @State private var showProfileSetup = false
    @AppStorage(UserProfileKey.hasCompletedProfile) private var hasCompletedProfile = false
    @State private var authManager = AuthManager.shared

    var body: some View {
        ZStack {
            if !hasLaunched {
                LandingView {
                    withAnimation(BrandTransitions.page) {
                        if authManager.isSignedIn {
                            continueAfterAuth()
                        } else {
                            showAuth = true
                        }
                    }
                }
                .transition(BrandTransitions.landingExit)
                .zIndex(1)
            } else {
                AppHubMenuView()
                    .transition(BrandTransitions.hubEnter)
                    .zIndex(0)
            }
        }
        .animation(BrandTransitions.page, value: hasLaunched)
        .sheet(isPresented: $showAuth) {
            AuthView {
                withAnimation(BrandTransitions.quick) {
                    showAuth = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    continueAfterAuth()
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showProfileSetup) {
            ProfileSetupView(
                onComplete: {
                    Task { await syncProfileToCloud() }
                    enterHub(fromProfileSheet: true)
                },
                onSkip: {
                    enterHub(fromProfileSheet: true)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .task {
            authManager.configureIfNeeded()
            if authManager.isSignedIn {
                await pullProfileFromCloud()
            }
        }
    }

    private func continueAfterAuth() {
        if hasCompletedProfile {
            Task { await pullProfileFromCloud() }
            enterHub(fromProfileSheet: false)
        } else {
            showProfileSetup = true
        }
    }

    private func enterHub(fromProfileSheet: Bool) {
        if fromProfileSheet {
            showProfileSetup = false
        }
        withAnimation(BrandTransitions.page) {
            hasLaunched = true
        }
    }

    private func syncProfileToCloud() async {
        let defaults = UserDefaults.standard
        try? await SupabaseSyncService.upsertProfile(
            firstName: defaults.string(forKey: UserProfileKey.firstName) ?? "",
            lastName: defaults.string(forKey: UserProfileKey.lastName) ?? "",
            email: defaults.string(forKey: UserProfileKey.email) ?? "",
            phone: defaults.string(forKey: UserProfileKey.phone) ?? "",
            dailyCalorieGoal: defaults.object(forKey: UserProfileKey.dailyCalorieGoal) as? Double ?? 2000,
            dailyProteinGoal: defaults.object(forKey: UserProfileKey.dailyProteinGoal) as? Double ?? 150,
            dailyCarbsGoal: defaults.object(forKey: UserProfileKey.dailyCarbsGoal) as? Double ?? 200,
            dailyFatGoal: defaults.object(forKey: UserProfileKey.dailyFatGoal) as? Double ?? 65,
            dailyWaterGoalMl: defaults.object(forKey: UserProfileKey.dailyWaterGoalMl) as? Double ?? 2000
        )
    }

    private func pullProfileFromCloud() async {
        guard let data = try? await SupabaseSyncService.fetchProfile() else { return }
        let defaults = UserDefaults.standard
        if !data.firstName.isEmpty {
            defaults.set(data.firstName, forKey: UserProfileKey.firstName)
        }
        defaults.set(data.lastName, forKey: UserProfileKey.lastName)
        defaults.set(data.email, forKey: UserProfileKey.email)
        defaults.set(data.phone, forKey: UserProfileKey.phone)
        defaults.set(data.dailyCalorieGoal, forKey: UserProfileKey.dailyCalorieGoal)
        defaults.set(data.dailyProteinGoal, forKey: UserProfileKey.dailyProteinGoal)
        defaults.set(data.dailyCarbsGoal, forKey: UserProfileKey.dailyCarbsGoal)
        defaults.set(data.dailyFatGoal, forKey: UserProfileKey.dailyFatGoal)
        defaults.set(data.dailyWaterGoalMl, forKey: UserProfileKey.dailyWaterGoalMl)
        if !data.firstName.isEmpty {
            defaults.set(true, forKey: UserProfileKey.hasCompletedProfile)
        }
    }
}
