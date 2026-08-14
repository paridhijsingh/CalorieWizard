//
//  HistoryView.swift
//  CalorieWizard
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \MealEntry.createdAt, order: .reverse) private var meals: [MealEntry]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            Group {
                if meals.isEmpty {
                    ContentUnavailableView(
                        "No meals yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Analyzed meals and snacks will appear here with photos and macros.")
                    )
                } else {
                    List {
                        ForEach(meals) { meal in
                            NavigationLink(destination: MealDetailView(meal: meal)) {
                                HistoryRow(meal: meal)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteMeals)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("History")
        }
    }

    private func deleteMeals(at offsets: IndexSet) {
        for index in offsets {
            let meal = meals[index]
            MealImageStore.delete(meal.imageFileName)
            modelContext.delete(meal)
        }
        try? modelContext.save()
    }
}

private struct HistoryRow: View {
    let meal: MealEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MealThumbnail(filename: meal.imageFileName, size: 72)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(meal.foodName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Spacer()
                    Text(meal.mealKind.displayName)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.15), in: Capsule())
                }

                Text(meal.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(Int(meal.calories.rounded())) kcal")
                    .font(.subheadline.weight(.semibold).monospacedDigit())

                HStack(spacing: 10) {
                    macroChip("P", value: meal.proteinG, color: .purple)
                    macroChip("C", value: meal.carbsG, color: .orange)
                    macroChip("F", value: meal.fatsG, color: .green)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.06), radius: 8, y: 3)
    }

    private func macroChip(_ label: String, value: Double, color: Color) -> some View {
        Text("\(label) \(Int(value.rounded()))g")
            .font(.caption2.weight(.medium).monospacedDigit())
            .foregroundStyle(color)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: MealEntry.self, inMemory: true)
}

// MARK: - Meal Thumbnail Helper
struct MealThumbnail: View {
    let filename: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let filename, let uiImage = MealImageStore.load(filename) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                fallbackImageView
            }
        }
    }

    private var fallbackImageView: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            )
    }
}
