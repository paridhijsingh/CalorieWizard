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
    }
}

#Preview {
    WizardMainTabView()
        .modelContainer(for: MealEntry.self, inMemory: true)
}
