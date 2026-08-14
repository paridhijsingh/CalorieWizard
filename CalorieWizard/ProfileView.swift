//
//  ProfileView.swift
//  CalorieWizard
//

import SwiftUI

struct ProfileView: View {
    @AppStorage(UserProfileKey.firstName) private var firstName = ""
    @AppStorage(UserProfileKey.lastName) private var lastName = ""
    @AppStorage(UserProfileKey.email) private var email = ""
    @AppStorage(UserProfileKey.phone) private var phone = ""
    @AppStorage(UserProfileKey.dailyCalorieGoal) private var dailyCalorieGoal = 2000.0

    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    LabeledContent("First Name", value: firstName.isEmpty ? "—" : firstName)
                    LabeledContent("Last Name", value: lastName.isEmpty ? "—" : lastName)
                    LabeledContent("Email ID", value: email.isEmpty ? "—" : email)
                    LabeledContent("Phone Number", value: phone.isEmpty ? "Not added" : phone)
                }

                Section("Daily goal") {
                    Stepper(value: $dailyCalorieGoal, in: 1000...4000, step: 50) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calories Consumed Today target")
                                .font(.subheadline)
                            Text("\(Int(dailyCalorieGoal.rounded())) kcal")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.purple)
                        }
                    }
                }

                Section {
                    Button("Edit profile") {
                        isEditing = true
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isEditing) {
                ProfileSetupView(onComplete: { isEditing = false })
            }
        }
    }
}

#Preview {
    ProfileView()
}
