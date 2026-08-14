//
//  WaterTrackerView.swift
//  CalorieWizard
//

import SwiftData
import SwiftUI

struct WaterTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage(UserProfileKey.dailyWaterGoalMl) private var dailyWaterGoalMl = 2000.0
    @AppStorage(UserProfileKey.waterRemindersEnabled) private var waterRemindersEnabled = true
    @AppStorage(UserProfileKey.waterReminderIntervalHours) private var waterReminderIntervalHours = 2

    @Query(sort: \WaterEntry.createdAt, order: .reverse) private var allWater: [WaterEntry]
    @Query(sort: \ReminderEvent.createdAt, order: .reverse) private var reminderEvents: [ReminderEvent]

    @State private var customAmount: Double = 250
    @State private var permissionMessage: String?

    private var todayEntries: [WaterEntry] {
        allWater.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var todayTotal: Double {
        todayEntries.reduce(0) { $0 + $1.amountMl }
    }

    private var progress: Double {
        guard dailyWaterGoalMl > 0 else { return 0 }
        return min(todayTotal / dailyWaterGoalMl, 1)
    }

    private var glasses: Int {
        Int((todayTotal / 250.0).rounded())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    quickAddRow
                    customAddCard
                    reminderSettingsCard
                    todayLogCard
                    reminderLogCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Water")
            .task {
                await refreshWaterSchedule(logEvent: false)
            }
            .onChange(of: waterRemindersEnabled) {
                Task { await refreshWaterSchedule(logEvent: true) }
            }
            .onChange(of: waterReminderIntervalHours) {
                Task { await refreshWaterSchedule(logEvent: true) }
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Today’s hydration", systemImage: "drop.fill")
                    .font(.headline)
                    .foregroundStyle(.cyan)
                Spacer()
                Text("\(glasses) glasses")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [.cyan, .blue], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: progress)

                VStack(spacing: 4) {
                    Text("\(Int(todayTotal.rounded()))")
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    Text("/ \(Int(dailyWaterGoalMl.rounded())) ml")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)
            .padding(.vertical, 8)

            Text("\(Int(max(dailyWaterGoalMl - todayTotal, 0).rounded())) ml remaining")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.06), radius: 8, y: 4)
    }

    private var quickAddRow: some View {
        HStack(spacing: 10) {
            quickAddButton(100, label: "100 ml")
            quickAddButton(250, label: "Glass")
            quickAddButton(500, label: "Bottle")
        }
    }

    private func quickAddButton(_ amount: Double, label: String) -> some View {
        Button {
            addWater(amount)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var customAddCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Custom amount")
                    .font(.headline)
                Spacer()
                Text("\(Int(customAmount)) ml")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.cyan)
            }
            Slider(value: $customAmount, in: 50...1000, step: 50)
                .tint(.cyan)
            Button {
                addWater(customAmount)
            } label: {
                Label("Log \(Int(customAmount)) ml", systemImage: "drop.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var reminderSettingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.headline)

            Toggle("Water drink reminders", isOn: $waterRemindersEnabled)
                .tint(.cyan)

            if waterRemindersEnabled {
                Stepper(value: $waterReminderIntervalHours, in: 1...4) {
                    Text("Every \(waterReminderIntervalHours) hour\(waterReminderIntervalHours == 1 ? "" : "s") (8 AM–10 PM)")
                        .font(.subheadline)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Daily water goal")
                    .font(.subheadline.weight(.semibold))
                Slider(value: $dailyWaterGoalMl, in: 1000...4000, step: 100)
                    .tint(.cyan)
                Text("\(Int(dailyWaterGoalMl.rounded())) ml / day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let permissionMessage {
                Text(permissionMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var todayLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s water log")
                .font(.headline)

            if todayEntries.isEmpty {
                Text("No water logged yet. Tap a quick-add button to start.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayEntries) { entry in
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.cyan)
                        Text("\(Int(entry.amountMl.rounded())) ml")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var reminderLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder log")
                .font(.headline)

            if reminderEvents.isEmpty {
                Text("Water and calorie-limit reminders will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(reminderEvents.prefix(20)) { event in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: event.kind.symbol)
                            .foregroundStyle(event.kind == .water ? .cyan : .orange)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline.weight(.semibold))
                            Text(event.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func addWater(_ amount: Double) {
        let entry = WaterEntry(amountMl: amount)
        modelContext.insert(entry)
        try? modelContext.save()
    }

    private func refreshWaterSchedule(logEvent: Bool) async {
        let granted = await NotificationManager.shared.requestAuthorization()
        if !granted {
            permissionMessage = "Enable notifications in Settings to receive water and calorie reminders."
        } else {
            permissionMessage = waterRemindersEnabled
                ? "Reminders are on for this device."
                : "Water reminders are paused."
        }
        await NotificationManager.shared.scheduleWaterReminders(
            enabled: waterRemindersEnabled,
            intervalHours: waterReminderIntervalHours,
            modelContext: modelContext,
            logScheduleEvent: logEvent
        )
    }
}

/// Watches today's calorie total and fires a one-per-day limit notification.
struct CalorieLimitMonitor: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(UserProfileKey.dailyCalorieGoal) private var dailyCalorieGoal = 2000.0
    @AppStorage(UserProfileKey.calorieLimitRemindersEnabled) private var calorieLimitRemindersEnabled = true
    @Query(sort: \MealEntry.createdAt, order: .reverse) private var meals: [MealEntry]

    private var todayCalories: Double {
        meals
            .filter { Calendar.current.isDateInToday($0.createdAt) }
            .reduce(0) { $0 + $1.calories }
    }

    func body(content: Content) -> some View {
        content
            .task(id: todayCalories) {
                guard calorieLimitRemindersEnabled else { return }
                await NotificationManager.shared.notifyCalorieLimitIfNeeded(
                    consumed: todayCalories,
                    goal: dailyCalorieGoal > 0 ? dailyCalorieGoal : 2000,
                    modelContext: modelContext
                )
            }
    }
}

extension View {
    func calorieLimitMonitoring() -> some View {
        modifier(CalorieLimitMonitor())
    }
}

#Preview {
    WaterTrackerView()
        .modelContainer(for: [WaterEntry.self, ReminderEvent.self, MealEntry.self], inMemory: true)
}
