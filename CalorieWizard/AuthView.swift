//
//  AuthView.swift
//  CalorieWizard
//

import SwiftUI

struct AuthView: View {
    var onAuthenticated: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.largeTitle.weight(.bold))
                        Text("Each family member signs in on their own device. Your meals and water stay private to your account.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Mode", selection: $isSignUp) {
                        Text("Sign Up").tag(true)
                        Text("Sign In").tag(false)
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        TextField("you@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        SecureField("At least 6 characters", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .background(
                            canSubmit && !isLoading ? Color.purple : Color.gray,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .disabled(!canSubmit || isLoading)

                    Text("After signup, each family member can create their own Supabase account and sync privately.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(22)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if isSignUp {
                try await AuthManager.shared.signUp(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            } else {
                try await AuthManager.shared.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            }
            UserDefaults.standard.set(email.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserProfileKey.email)
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AuthView(onAuthenticated: {})
}
