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
}

extension UserDefaults {
    static var dailyCalorieGoal: Double {
        let stored = UserDefaults.standard.double(forKey: UserProfileKey.dailyCalorieGoal)
        return stored > 0 ? stored : 2000
    }
}
