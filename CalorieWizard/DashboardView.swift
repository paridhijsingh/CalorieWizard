//
//  DashboardView.swift
//  CalorieWizard
//

import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    @AppStorage(UserProfileKey.firstName) private var firstName = ""
    @AppStorage(UserProfileKey.dailyCalorieGoal) private var dailyCalorieGoal = 2000.0
    @AppStorage(UserProfileKey.dailyProteinGoal) private var dailyProteinGoal = 150.0
    @AppStorage(UserProfileKey.dailyCarbsGoal) private var dailyCarbsGoal = 200.0
    @AppStorage(UserProfileKey.dailyFatGoal) private var dailyFatGoal = 65.0

    @Query(sort: \MealEntry.createdAt, order: .reverse) private var meals: [MealEntry]
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPeriod: DashboardPeriod = .day

    private var periodMeals: [MealEntry] {
        meals.filter { meal in
            guard let interval = periodInterval else { return false }
            return interval.contains(meal.createdAt)
        }
    }

    private var periodInterval: DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case .day:
            let start = calendar.startOfDay(for: now)
            return DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: start) ?? now)
        case .week:
            guard let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return nil }
            return DateInterval(start: start, end: calendar.date(byAdding: .day, value: 7, to: start) ?? now)
        case .month:
            return calendar.dateInterval(of: .month, for: now)
        case .year:
            return calendar.dateInterval(of: .year, for: now)
        }
    }

    private var dayCount: Double {
        switch selectedPeriod {
        case .day:
            return 1
        case .week:
            return 7
        case .month:
            let days = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
            return Double(days)
        case .year:
            return 365
        }
    }

    private var totals: NutritionTotals {
        periodMeals.reduce(.zero) { partial, meal in
            NutritionTotals(
                calories: partial.calories + meal.calories,
                protein: partial.protein + meal.proteinG,
                carbs: partial.carbs + meal.carbsG,
                fats: partial.fats + meal.fatsG
            )
        }
    }

    private var calorieGoal: Double { max(dailyCalorieGoal, 1) * dayCount }
    private var proteinGoal: Double { max(dailyProteinGoal, 1) * dayCount }
    private var carbsGoal: Double { max(dailyCarbsGoal, 1) * dayCount }
    private var fatGoal: Double { max(dailyFatGoal, 1) * dayCount }

    private var chartPoints: [ChartDayPoint] {
        let calendar = Calendar.current
        guard let interval = periodInterval else { return [] }

        let formatter = DateFormatter()
        switch selectedPeriod {
        case .day, .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d"
        case .year:
            formatter.dateFormat = "MMM"
        }

        if selectedPeriod == .year {
            return (0..<12).compactMap { offset -> ChartDayPoint? in
                guard let monthDate = calendar.date(byAdding: .month, value: offset, to: interval.start) else { return nil }
                let monthInterval = calendar.dateInterval(of: .month, for: monthDate)
                let monthMeals = periodMeals.filter { meal in
                    guard let monthInterval else { return false }
                    return monthInterval.contains(meal.createdAt)
                }
                let calories = monthMeals.reduce(0) { $0 + $1.calories }
                let protein = monthMeals.reduce(0) { $0 + $1.proteinG }
                let carbs = monthMeals.reduce(0) { $0 + $1.carbsG }
                let fats = monthMeals.reduce(0) { $0 + $1.fatsG }
                return ChartDayPoint(
                    date: monthDate,
                    label: formatter.string(from: monthDate),
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fats: fats
                )
            }
        }

        let days = Int(dayCount)
        return (0..<days).compactMap { offset -> ChartDayPoint? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            let dayMeals = periodMeals.filter { $0.createdAt >= start && $0.createdAt < end }
            return ChartDayPoint(
                date: start,
                label: formatter.string(from: start),
                calories: dayMeals.reduce(0) { $0 + $1.calories },
                protein: dayMeals.reduce(0) { $0 + $1.proteinG },
                carbs: dayMeals.reduce(0) { $0 + $1.carbsG },
                fats: dayMeals.reduce(0) { $0 + $1.fatsG }
            )
        }
    }

    private var todayMeals: [MealEntry] {
        meals.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greetingText)
                            .font(.title2.weight(.bold))
                        Text("Track calories and macros across today, week, month, and year.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(DashboardPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    summaryCard
                    macroRow
                    calorieChartCard
                    macroChartCard

                    if selectedPeriod == .day, !todayMeals.isEmpty {
                        todayLogSection
                    }

                    Spacer(minLength: 12)
                }
                .padding(.top)
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Calories · \(selectedPeriod.title)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(max(calorieGoal - totals.calories, 0).rounded())) left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.purple)
            }

            ProgressView(value: min(totals.calories / calorieGoal, 1))
                .tint(.purple)
                .scaleEffect(x: 1, y: 2.5, anchor: .center)
                .padding(.vertical, 4)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text("\(Int(totals.calories.rounded()))")
                        .font(.system(size: 32, weight: .bold))
                    Text("Consumed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(Int(calorieGoal.rounded()))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text("\(selectedPeriod.title) goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(averageLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.06), radius: 8, y: 4)
        .padding(.horizontal)
    }

    private var averageLine: String {
        let avg = totals.calories / max(dayCount, 1)
        return "Avg \(Int(avg.rounded())) kcal/day · Daily target \(Int(dailyCalorieGoal.rounded())) kcal"
    }

    private var macroRow: some View {
        HStack(spacing: 12) {
            MacroBox(title: "Protein", current: Int(totals.protein.rounded()), target: Int(proteinGoal.rounded()), unit: "g", color: .purple)
            MacroBox(title: "Carbs", current: Int(totals.carbs.rounded()), target: Int(carbsGoal.rounded()), unit: "g", color: .orange)
            MacroBox(title: "Fat", current: Int(totals.fats.rounded()), target: Int(fatGoal.rounded()), unit: "g", color: .green)
        }
        .padding(.horizontal)
    }

    private var calorieChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calorie trend")
                .font(.headline)

            if chartPoints.allSatisfy({ $0.calories == 0 }) {
                Text("Log meals to see your \(selectedPeriod.title.lowercased()) calorie chart.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
            } else {
                Chart(chartPoints) { point in
                    BarMark(
                        x: .value("Period", point.label),
                        y: .value("Calories", point.calories)
                    )
                    .foregroundStyle(Color.purple.gradient)
                }
                .frame(height: 180)
                .chartYAxisLabel("kcal")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private var macroChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition trend")
                .font(.headline)

            if chartPoints.allSatisfy({ $0.protein + $0.carbs + $0.fats == 0 }) {
                Text("Protein, carbs, and fats will chart here as you log food.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
            } else {
                Chart {
                    ForEach(chartPoints) { point in
                        LineMark(
                            x: .value("Period", point.label),
                            y: .value("Grams", point.protein)
                        )
                        .foregroundStyle(by: .value("Macro", "Protein"))

                        LineMark(
                            x: .value("Period", point.label),
                            y: .value("Grams", point.carbs)
                        )
                        .foregroundStyle(by: .value("Macro", "Carbs"))

                        LineMark(
                            x: .value("Period", point.label),
                            y: .value("Grams", point.fats)
                        )
                        .foregroundStyle(by: .value("Macro", "Fats"))
                    }
                }
                .chartForegroundStyleScale([
                    "Protein": Color.purple,
                    "Carbs": Color.orange,
                    "Fats": Color.green
                ])
                .frame(height: 180)
                .chartYAxisLabel("g")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private var todayLogSection: some View {
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

            Text("\(current)/\(max(target, 1))\(unit)")
                .font(.system(size: 13, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            ProgressView(value: Double(min(current, max(target, 1))), total: Double(max(target, 1)))
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
