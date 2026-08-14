//
//  NotificationManager.swift
//  CalorieWizard
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let waterPrefix = "water-reminder-"
    private let calorieLimitID = "calorie-limit-reached"

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
        intervalHours: Int,
        modelContext: ModelContext?,
        logScheduleEvent: Bool = false
    ) async {
        let pending = await center.pendingNotificationRequests()
        for request in pending where request.identifier.hasPrefix(waterPrefix) {
            center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
        }

        guard enabled else { return }
        _ = await requestAuthorization()

        let hours = max(intervalHours, 1)
        let startHour = 8
        let endHour = 22
        var scheduled = 0

        for hour in stride(from: startHour, through: endHour, by: hours) {
            var components = DateComponents()
            components.hour = hour
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Hydration reminder"
            content.body = "Time to drink some water and log it in CalorieWizard."
            content.sound = .default
            content.userInfo = ["kind": ReminderKind.water.rawValue]

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let id = "\(waterPrefix)\(hour)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
            scheduled += 1
        }

        if logScheduleEvent, let modelContext, scheduled > 0 {
            let event = ReminderEvent(
                kind: .water,
                title: "Water reminders scheduled",
                message: "Reminding you every \(hours) hour(s) from 8 AM to 10 PM."
            )
            modelContext.insert(event)
            try? modelContext.save()
        }
    }

    func notifyCalorieLimitIfNeeded(
        consumed: Double,
        goal: Double,
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
        content.sound = .default
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
            message: "Logged \(Int(consumed.rounded())) / \(Int(goal.rounded())) kcal for today."
        )
        modelContext.insert(event)
        try? modelContext.save()
    }

    func logDeliveredNotification(_ notification: UNNotification, modelContext: ModelContext?) {
        guard let modelContext else { return }
        let info = notification.request.content.userInfo
        let kind = ReminderKind(rawValue: info["kind"] as? String ?? "") ?? .water
        let event = ReminderEvent(
            kind: kind,
            title: notification.request.content.title,
            message: notification.request.content.body
        )
        modelContext.insert(event)
        try? modelContext.save()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await MainActor.run {
            // Foreground delivery is captured in the reminder log when possible.
        }
        return [.banner, .sound]
    }

    private static func dayStamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
