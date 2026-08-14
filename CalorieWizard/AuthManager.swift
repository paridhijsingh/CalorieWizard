//
//  AuthManager.swift
//  CalorieWizard
//

import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class AuthManager {
    static let shared = AuthManager()

    private(set) var userId: String?
    private(set) var email: String?
    private(set) var isConfigured = false
    private(set) var lastError: String?

    var isSignedIn: Bool { userId != nil }

    private var authTask: Task<Void, Never>?

    private init() {}

    func configureIfNeeded() {
        guard !isConfigured else { return }

        guard SupabaseConfig.isConfigured else {
            lastError = "Add SUPABASE_URL and SUPABASE_ANON_KEY in Config/Secrets.xcconfig."
            isConfigured = false
            return
        }

        isConfigured = true
        authTask?.cancel()
        authTask = Task {
            do {
                let session = try await SupabaseManager.client.auth.session
                userId = session.user.id.uuidString
                email = session.user.email
            } catch {
                userId = nil
                email = nil
            }

            for await (_, session) in SupabaseManager.client.auth.authStateChanges {
                if Task.isCancelled { break }
                userId = session?.user.id.uuidString
                email = session?.user.email
            }
        }
    }

    func signUp(email: String, password: String) async throws {
        configureIfNeeded()
        guard isConfigured else { throw AuthServiceError.notConfigured }
        lastError = nil
        let response = try await SupabaseManager.client.auth.signUp(email: email, password: password)
        userId = response.user.id.uuidString
        self.email = response.user.email
    }

    func signIn(email: String, password: String) async throws {
        configureIfNeeded()
        guard isConfigured else { throw AuthServiceError.notConfigured }
        lastError = nil
        let session = try await SupabaseManager.client.auth.signIn(email: email, password: password)
        userId = session.user.id.uuidString
        self.email = session.user.email
    }

    func signOut() async throws {
        try await SupabaseManager.client.auth.signOut()
        userId = nil
        email = nil
    }
}

enum AuthServiceError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY first."
        }
    }
}
