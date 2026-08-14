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
    @AppStorage(UserProfileKey.waterReminderIntervalMinutes) private var waterReminderIntervalMinutes = 60.0
    @AppStorage(UserProfileKey.waterReminderStartHour) private var waterReminderStartHour = 8.0
    @AppStorage(UserProfileKey.waterReminderEndHour) private var waterReminderEndHour = 22.0
    @AppStorage(UserProfileKey.reminderSoundOption) private var reminderSoundRaw = ReminderSoundOption.default.rawValue

    @Query(sort: \WaterEntry.createdAt, order: .reverse) private var allWater: [WaterEntry]
    @Query(sort: \ReminderEvent.createdAt, order: .reverse) private var reminderEvents: [ReminderEvent]

    @State private var customAmount: Double = 250
    @State private var permissionMessage: String?

    private var reminderSound: ReminderSoundOption {
        get { ReminderSoundOption(rawValue: reminderSoundRaw) ?? .default }
        nonmutating set { reminderSoundRaw = newValue.rawValue }
    }

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

    private var scheduledCount: Int {
        NotificationManager.reminderSlots(
            startHour: Int(waterReminderStartHour.rounded()),
            endHour: Int(max(waterReminderEndHour, waterReminderStartHour).rounded()),
            intervalMinutes: Int(waterReminderIntervalMinutes.rounded()),
            limit: 60
        ).count
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
                normalizeRange()
                await refreshWaterSchedule(logEvent: false)
            }
            .onChange(of: waterRemindersEnabled) { _, _ in
                Task { await refreshWaterSchedule(logEvent: true) }
            }
            .onChange(of: waterReminderIntervalMinutes) { _, _ in
                Task { await refreshWaterSchedule(logEvent: true) }
            }
            .onChange(of: waterReminderStartHour) { _, _ in
                normalizeRange()
                Task { await refreshWaterSchedule(logEvent: true) }
            }
            .onChange(of: waterReminderEndHour) { _, _ in
                normalizeRange()
                Task { await refreshWaterSchedule(logEvent: true) }
            }
            .onChange(of: reminderSoundRaw) { _, _ in
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
        VStack(alignment: .leading, spacing: 14) {
            Text("Reminders")
                .font(.headline)

            Toggle("Water drink reminders", isOn: $waterRemindersEnabled)
                .tint(.cyan)

            if waterRemindersEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Remind every")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(NotificationManager.intervalLabel(Int(waterReminderIntervalMinutes.rounded())))
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.cyan)
                    }
                    Slider(value: $waterReminderIntervalMinutes, in: 10...180, step: 10)
                        .tint(.cyan)
                    Text("From 10 minutes up to 3 hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Active from")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(NotificationManager.hourLabel(Int(waterReminderStartHour.rounded())))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.cyan)
                    }
                    Slider(value: $waterReminderStartHour, in: 0...23, step: 1)
                    .tint(.cyan)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Active until")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(NotificationManager.hourLabel(Int(waterReminderEndHour.rounded())))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.cyan)
                    }
                    Slider(value: $waterReminderEndHour, in: 0...23, step: 1)
                    .tint(.cyan)
                }

                Text("\(scheduledCount) reminder\(scheduledCount == 1 ? "" : "s") scheduled daily in this window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notification sound")
                        .font(.subheadline.weight(.semibold))

                    ForEach(ReminderSoundOption.allCases) { option in
                        Button {
                            reminderSound = option
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: soundSymbol(for: option))
                                    .foregroundStyle(.cyan)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(option.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if reminderSound == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.cyan)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(reminderSound == option ? Color.cyan.opacity(0.12) : Color(.tertiarySystemFill))
                            )
                        }
                        .buttonStyle(.plain)
                    }
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

    private func soundSymbol(for option: ReminderSoundOption) -> String {
        switch option {
        case .default: "speaker.wave.2.fill"
        case .silent: "speaker.slash.fill"
        case .alert: "bell.and.waves.left.and.right.fill"
        }
    }

    private func normalizeRange() {
        if waterReminderEndHour < waterReminderStartHour {
            waterReminderEndHour = waterReminderStartHour
        }
    }

    private func addWater(_ amount: Double) {
        let entry = WaterEntry(amountMl: amount)
        modelContext.insert(entry)
        try? modelContext.save()
        Task {
            try? await SupabaseSyncService.upsertWater(entry)
        }
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
            intervalMinutes: Int(waterReminderIntervalMinutes.rounded()),
            startHour: Int(waterReminderStartHour.rounded()),
            endHour: Int(waterReminderEndHour.rounded()),
            sound: reminderSound,
            modelContext: modelContext,
            logScheduleEvent: logEvent
        )
    }
}

struct CalorieLimitMonitor: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(UserProfileKey.dailyCalorieGoal) private var dailyCalorieGoal = 2000.0
    @AppStorage(UserProfileKey.calorieLimitRemindersEnabled) private var calorieLimitRemindersEnabled = true
    @AppStorage(UserProfileKey.reminderSoundOption) private var reminderSoundRaw = ReminderSoundOption.default.rawValue
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
                let sound = ReminderSoundOption(rawValue: reminderSoundRaw) ?? .default
                await NotificationManager.shared.notifyCalorieLimitIfNeeded(
                    consumed: todayCalories,
                    goal: dailyCalorieGoal > 0 ? dailyCalorieGoal : 2000,
                    sound: sound,
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
