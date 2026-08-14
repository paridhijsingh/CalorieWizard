//
//  ProfileSetupView.swift
//  CalorieWizard
//

import SwiftUI

struct ProfileSetupView: View {
    var onComplete: () -> Void
    var onSkip: (() -> Void)? = nil

    @AppStorage(UserProfileKey.firstName) private var firstName = ""
    @AppStorage(UserProfileKey.lastName) private var lastName = ""
    @AppStorage(UserProfileKey.email) private var email = ""
    @AppStorage(UserProfileKey.phone) private var phone = ""
    @AppStorage(UserProfileKey.hasCompletedProfile) private var hasCompletedProfile = false

    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email ID", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone Number (Optional)", text: $phone)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Personal Information")
                } footer: {
                    Text("Save your details to personalize CalorieWizard, or skip and set them up later in Profile.")
                }

                Section {
                    Button {
                        hasCompletedProfile = true
                        onComplete()
                    } label: {
                        Text("Save & Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canSave)

                    if onSkip != nil {
                        Button("Skip for now") {
                            onSkip?()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if onSkip != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip for now") {
                            onSkip?()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileSetupView(onComplete: {}, onSkip: {})
}
