//
//  MainTabView.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/13/26.
//

import SwiftData
import SwiftUI

struct WizardMainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            FoodScannerView()
                .tabItem {
                    Label("Analyze", systemImage: "camera.viewfinder")
                }

            RecipeGeneratorView()
                .tabItem {
                    Label("Recipes", systemImage: "wand.and.stars")
                }

            WaterTrackerView()
                .tabItem {
                    Label("Water", systemImage: "drop.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.purple)
        .calorieLimitMonitoring()
    }
}

#Preview {
    WizardMainTabView()
        .modelContainer(
            for: [MealEntry.self, FavoriteRecipe.self, WaterEntry.self, ReminderEvent.self],
            inMemory: true
        )
}
