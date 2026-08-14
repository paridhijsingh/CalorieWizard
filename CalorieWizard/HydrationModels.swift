//
//  HydrationModels.swift
//  CalorieWizard
//

import Foundation
import SwiftData

@Model
final class WaterEntry {
    var id: UUID
    var amountMl: Double
    var createdAt: Date
    var note: String

    init(
        id: UUID = UUID(),
        amountMl: Double,
        createdAt: Date = .now,
        note: String = ""
    ) {
        self.id = id
        self.amountMl = amountMl
        self.createdAt = createdAt
        self.note = note
    }
}

enum ReminderKind: String, Codable, CaseIterable, Identifiable {
    case water
    case calorieLimit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .water: "Water"
        case .calorieLimit: "Calorie Limit"
        }
    }

    var symbol: String {
        switch self {
        case .water: "drop.fill"
        case .calorieLimit: "flame.fill"
        }
    }
}

@Model
final class ReminderEvent {
    var id: UUID
    var kindRaw: String
    var title: String
    var message: String
    var createdAt: Date

    var kind: ReminderKind {
        get { ReminderKind(rawValue: kindRaw) ?? .water }
        set { kindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: ReminderKind,
        title: String,
        message: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.title = title
        self.message = message
        self.createdAt = createdAt
    }
}
