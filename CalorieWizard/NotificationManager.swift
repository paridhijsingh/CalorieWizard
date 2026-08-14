//
//  NotificationManager.swift
//  CalorieWizard
//

import Foundation
import SwiftData
import UserNotifications

enum ReminderSoundOption: String, CaseIterable, Identifiable {
    case `default`
    case silent
    case alert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: "Default"
        case .silent: "Silent"
        case .alert: "Alert"
        }
    }

    var detail: String {
        switch self {
        case .default: "Standard iOS notification sound"
        case .silent: "Banner only — no sound"
        case .alert: "Louder attention-style alert"
        }
    }

    var notificationSound: UNNotificationSound? {
        switch self {
        case .default: .default
        case .silent: nil
        case .alert: .defaultCritical
        }
    }
}

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let waterPrefix = "water-reminder-"
    private let calorieLimitID = "calorie-limit-reached"
    private let maxPendingWaterReminders = 60

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleWaterReminders(
        enabled: Bool,
        intervalMinutes: Int,
        startHour: Int,
        endHour: Int,
        sound: ReminderSoundOption,
        modelContext: ModelContext?,
        logScheduleEvent: Bool = false
    ) async {
        let pending = await center.pendingNotificationRequests()
        for request in pending where request.identifier.hasPrefix(waterPrefix) {
            center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
        }

        guard enabled else { return }
        _ = await requestAuthorization()

        let interval = max(intervalMinutes, 10)
        let start = min(max(startHour, 0), 23)
        var end = min(max(endHour, 0), 23)
        if end < start { end = start }

        let slots = Self.reminderSlots(
            startHour: start,
            endHour: end,
            intervalMinutes: interval,
            limit: maxPendingWaterReminders
        )

        for (index, slot) in slots.enumerated() {
            var components = DateComponents()
            components.hour = slot.hour
            components.minute = slot.minute

            let content = UNMutableNotificationContent()
            content.title = "Hydration reminder"
            content.body = "Time to drink some water and log it in CalorieWizard."
            content.sound = sound.notificationSound
            content.userInfo = ["kind": ReminderKind.water.rawValue]

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let id = "\(waterPrefix)\(index)-\(slot.hour)-\(slot.minute)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }

        if logScheduleEvent, let modelContext, !slots.isEmpty {
            let rangeText = "\(Self.hourLabel(start))–\(Self.hourLabel(end))"
            let event = ReminderEvent(
                kind: .water,
                title: "Water reminders updated",
                message: "Every \(Self.intervalLabel(interval)) from \(rangeText) · Sound: \(sound.title) · \(slots.count) daily alerts"
            )
            modelContext.insert(event)
            try? modelContext.save()
        }
    }

    func notifyCalorieLimitIfNeeded(
        consumed: Double,
        goal: Double,
        sound: ReminderSoundOption,
        modelContext: ModelContext
    ) async {
        guard goal > 0, consumed >= goal else { return }

        let defaults = UserDefaults.standard
        let key = UserProfileKey.lastCalorieLimitNotifyDay
        let today = Self.dayStamp(for: .now)
        if defaults.string(forKey: key) == today {
            return
        }

        _ = await requestAuthorization()

        let content = UNMutableNotificationContent()
        content.title = "Daily calorie limit reached"
        content.body = "You've hit \(Int(goal.rounded())) kcal today. Consider pausing extra snacks."
        content.sound = sound.notificationSound
        content.userInfo = ["kind": ReminderKind.calorieLimit.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(calorieLimitID)-\(today)",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)

        defaults.set(today, forKey: key)

        let event = ReminderEvent(
            kind: .calorieLimit,
            title: "Calorie limit reached",
            message: "Logged \(Int(consumed.rounded())) / \(Int(goal.rounded())) kcal · Sound: \(sound.title)"
        )
        modelContext.insert(event)
        try? modelContext.save()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    static func reminderSlots(
        startHour: Int,
        endHour: Int,
        intervalMinutes: Int,
        limit: Int
    ) -> [(hour: Int, minute: Int)] {
        let startMinutes = startHour * 60
        let endMinutes = endHour * 60
        guard endMinutes >= startMinutes else { return [] }

        var slots: [(hour: Int, minute: Int)] = []
        var cursor = startMinutes
        while cursor <= endMinutes && slots.count < limit {
            slots.append((cursor / 60, cursor % 60))
            cursor += max(intervalMinutes, 10)
        }
        return slots
    }

    static func intervalLabel(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let rem = minutes % 60
        if rem == 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        return "\(hours)h \(rem)m"
    }

    static func hourLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let calendar = Calendar.current
        let date = calendar.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }

    private static func dayStamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
