//
//  UserProfileStore.swift
//  CalorieWizard
//

import Foundation
import SwiftUI

enum UserProfileKey {
    static let firstName = "userFirstName"
    static let lastName = "userLastName"
    static let email = "userEmail"
    static let phone = "userPhone"
    static let hasCompletedProfile = "hasCompletedProfile"
    static let dailyCalorieGoal = "dailyCalorieGoal"
    static let dailyProteinGoal = "dailyProteinGoal"
    static let dailyCarbsGoal = "dailyCarbsGoal"
    static let dailyFatGoal = "dailyFatGoal"
    static let dailyWaterGoalMl = "dailyWaterGoalMl"
    static let waterRemindersEnabled = "waterRemindersEnabled"
    static let waterReminderIntervalHours = "waterReminderIntervalHours"
    static let calorieLimitRemindersEnabled = "calorieLimitRemindersEnabled"
    static let lastCalorieLimitNotifyDay = "lastCalorieLimitNotifyDay"
}

extension UserDefaults {
    static var dailyCalorieGoal: Double {
        let stored = UserDefaults.standard.double(forKey: UserProfileKey.dailyCalorieGoal)
        return stored > 0 ? stored : 2000
    }
}
