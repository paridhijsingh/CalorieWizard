//
//  DashboardView.swift
//  CalorieWizard
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @AppStorage(UserProfileKey.firstName) private var firstName = ""
    @AppStorage(UserProfileKey.dailyCalorieGoal) private var calorieGoal = 2000.0
    @Query(sort: \MealEntry.createdAt, order: .reverse) private var meals: [MealEntry]
    @Environment(\.colorScheme) private var colorScheme

    private var todayMeals: [MealEntry] {
        meals.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var totalCaloriesConsumed: Double {
        todayMeals.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        todayMeals.reduce(0) { $0 + $1.proteinG }
    }

    private var totalCarbs: Double {
        todayMeals.reduce(0) { $0 + $1.carbsG }
    }

    private var totalFat: Double {
        todayMeals.reduce(0) { $0 + $1.fatsG }
    }

    private var goal: Double {
        calorieGoal > 0 ? calorieGoal : 2000
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greetingText)
                            .font(.title2.weight(.bold))
                        Text("Here’s how your day is tracking.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Calories Consumed Today")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(max(goal - totalCaloriesConsumed, 0).rounded())) kcal left")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.purple)
                        }

                        ProgressView(value: min(totalCaloriesConsumed / goal, 1))
                            .tint(.purple)
                            .scaleEffect(x: 1, y: 2.5, anchor: .center)
                            .padding(.vertical, 4)

                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading) {
                                Text("\(Int(totalCaloriesConsumed.rounded()))")
                                    .font(.system(size: 32, weight: .bold))
                                Text("Consumed")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("\(Int(goal.rounded()))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Text("Goal")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.06), radius: 8, y: 4)
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        MacroBox(title: "Protein", current: Int(totalProtein.rounded()), target: 150, unit: "g", color: .purple)
                        MacroBox(title: "Carbs", current: Int(totalCarbs.rounded()), target: 200, unit: "g", color: .orange)
                        MacroBox(title: "Fat", current: Int(totalFat.rounded()), target: 65, unit: "g", color: .green)
                    }
                    .padding(.horizontal)

                    if !todayMeals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today’s log")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(todayMeals) { meal in
                                HStack(spacing: 12) {
                                    MealThumbnail(filename: meal.imageFileName, size: 48)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(meal.foodName)
                                            .font(.subheadline.weight(.semibold))
                                            .lineLimit(1)
                                        Text("\(Int(meal.calories.rounded())) kcal")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.horizontal)
                            }
                        }
                    }

                    Spacer(minLength: 12)
                }
                .padding(.top)
            }
            .navigationTitle("Today")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    private var greetingText: String {
        let name = firstName.isEmpty ? "there" : firstName
        let hour = Calendar.current.component(.hour, from: .now)
        let hello: String
        switch hour {
        case 5..<12: hello = "Good morning"
        case 12..<17: hello = "Good afternoon"
        default: hello = "Good evening"
        }
        return "\(hello), \(name)"
    }
}

struct MacroBox: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(current)\(unit)")
                .font(.system(size: 16, weight: .bold))

            ProgressView(value: Double(min(current, target)), total: Double(max(target, 1)))
                .tint(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: MealEntry.self, inMemory: true)
}
