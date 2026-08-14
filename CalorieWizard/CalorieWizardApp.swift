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
    var body: some Scene {
        WindowGroup {
            RootContainerView()
        }
        .modelContainer(for: [MealEntry.self, FavoriteRecipe.self, WaterEntry.self, ReminderEvent.self])
    }
}

struct RootContainerView: View {
    /// Session-only: landing shows each launch; profile stays in AppStorage.
    @State private var hasLaunched = false
    @AppStorage(UserProfileKey.hasCompletedProfile) private var hasCompletedProfile = false
    @State private var showProfileSetup = false

    var body: some View {
        Group {
            if !hasLaunched {
                LandingView {
                    withAnimation(.spring(response: 0.52, dampingFraction: 0.78)) {
                        if hasCompletedProfile {
                            // Returning user — profile already saved
                            hasLaunched = true
                        } else {
                            // New user — collect profile (or allow skip)
                            showProfileSetup = true
                        }
                    }
                }
                .sheet(isPresented: $showProfileSetup) {
                    ProfileSetupView(
                        onComplete: {
                            enterHub(fromProfileSheet: true)
                        },
                        onSkip: {
                            enterHub(fromProfileSheet: true)
                        }
                    )
                    .interactiveDismissDisabled(false)
                }
            } else {
                AppHubMenuView()
            }
        }
        .animation(.spring(response: 0.52, dampingFraction: 0.78), value: hasLaunched)
    }

    private func enterHub(fromProfileSheet: Bool) {
        if fromProfileSheet {
            showProfileSetup = false
        }
        withAnimation(.spring(response: 0.52, dampingFraction: 0.78)) {
            hasLaunched = true
        }
    }
}
