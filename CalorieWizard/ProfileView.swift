//
//  ProfileView.swift
//  CalorieWizard
//

import SwiftUI

struct CalorieGoalSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let calories: Double
}

struct ProfileView: View {
    @AppStorage(UserProfileKey.firstName) private var firstName = ""
    @AppStorage(UserProfileKey.lastName) private var lastName = ""
    @AppStorage(UserProfileKey.email) private var email = ""
    @AppStorage(UserProfileKey.phone) private var phone = ""
    @AppStorage(UserProfileKey.dailyCalorieGoal) private var dailyCalorieGoal = 2000.0
    @AppStorage(UserProfileKey.dailyProteinGoal) private var dailyProteinGoal = 150.0
    @AppStorage(UserProfileKey.dailyCarbsGoal) private var dailyCarbsGoal = 200.0
    @AppStorage(UserProfileKey.dailyFatGoal) private var dailyFatGoal = 65.0
    @AppStorage(UserProfileKey.calorieLimitRemindersEnabled) private var calorieLimitRemindersEnabled = true
    @State private var authManager = AuthManager.shared

    @State private var isEditing = false

    private let suggestions: [CalorieGoalSuggestion] = [
        .init(title: "Gentle cut", detail: "Lower intake for gradual fat loss", calories: 1600),
        .init(title: "Maintain", detail: "Steady everyday energy", calories: 2000),
        .init(title: "Active days", detail: "More fuel for workouts", calories: 2400),
        .init(title: "Muscle gain", detail: "Surplus for strength training", calories: 2800)
    ]

    private var weeklyGoal: Int { Int((dailyCalorieGoal * 7).rounded()) }
    private var monthlyGoal: Int {
        let days = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        return Int((dailyCalorieGoal * Double(days)).rounded())
    }
    private var yearlyGoal: Int { Int((dailyCalorieGoal * 365).rounded()) }

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    LabeledContent("First Name", value: firstName.isEmpty ? "—" : firstName)
                    LabeledContent("Last Name", value: lastName.isEmpty ? "—" : lastName)
                    LabeledContent("Email ID", value: email.isEmpty ? "—" : email)
                    LabeledContent("Phone Number", value: phone.isEmpty ? "Not added" : phone)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Daily calorie goal")
                            Spacer()
                            Text("\(Int(dailyCalorieGoal.rounded())) kcal")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.purple)
                        }

                        Slider(value: $dailyCalorieGoal, in: 1200...3500, step: 50)
                            .tint(.purple)

                        Text(suggestionHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggestions")
                            .font(.subheadline.weight(.semibold))
                        ForEach(suggestions) { suggestion in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    dailyCalorieGoal = suggestion.calories
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(suggestion.detail)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(Int(suggestion.calories))")
                                        .font(.subheadline.monospacedDigit().weight(.bold))
                                        .foregroundStyle(.purple)
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(dailyCalorieGoal == suggestion.calories ? Color.purple.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Daily Goal")
                } footer: {
                    Text("Week \(weeklyGoal) · Month \(monthlyGoal) · Year \(yearlyGoal) kcal (based on your daily target).")
                }

                Section("Daily macro targets") {
                    macroSlider(title: "Protein", value: $dailyProteinGoal, range: 50...250, color: .purple, unit: "g")
                    macroSlider(title: "Carbs", value: $dailyCarbsGoal, range: 50...400, color: .orange, unit: "g")
                    macroSlider(title: "Fat", value: $dailyFatGoal, range: 20...150, color: .green, unit: "g")
                }

                Section {
                    Toggle("Calorie limit alerts", isOn: $calorieLimitRemindersEnabled)
                    Text("Get notified once per day when you reach your calorie goal. Water reminders are managed in the Water tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Notifications")
                }

                Section("Account") {
                    LabeledContent("Signed in as", value: authManager.email ?? email.ifEmpty("—"))
                    LabeledContent("User ID", value: authManager.userId ?? "Not signed in")
                    Button("Sync profile to cloud") {
                        Task { await syncProfile() }
                    }
                    if authManager.isSignedIn {
                        Button("Sign out", role: .destructive) {
                            Task {
                                try? await authManager.signOut()
                            }
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
                ProfileSetupView(onComplete: {
                    isEditing = false
                    Task { await syncProfile() }
                })
            }
            .onChange(of: dailyCalorieGoal) { _, _ in Task { await syncProfile() } }
            .onChange(of: dailyProteinGoal) { _, _ in Task { await syncProfile() } }
            .onChange(of: dailyCarbsGoal) { _, _ in Task { await syncProfile() } }
            .onChange(of: dailyFatGoal) { _, _ in Task { await syncProfile() } }
        }
    }

    private func syncProfile() async {
        try? await SupabaseSyncService.upsertProfile(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            dailyCalorieGoal: dailyCalorieGoal,
            dailyProteinGoal: dailyProteinGoal,
            dailyCarbsGoal: dailyCarbsGoal,
            dailyFatGoal: dailyFatGoal,
            dailyWaterGoalMl: UserDefaults.standard.object(forKey: UserProfileKey.dailyWaterGoalMl) as? Double ?? 2000
        )
    }

    private var suggestionHint: String {
        switch dailyCalorieGoal {
        case ..<1800: return "Lower range — useful for a careful deficit."
        case 1800..<2200: return "Balanced maintenance range for many adults."
        case 2200..<2600: return "Higher fuel for active training days."
        default: return "Surplus range — helpful when building muscle."
        }
    }

    private func macroSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        color: Color,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))\(unit)")
                    .foregroundStyle(color)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }
            Slider(value: value, in: range, step: 5)
                .tint(color)
        }
        .padding(.vertical, 2)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

#Preview {
    ProfileView()
}
