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
            for await (event, session) in SupabaseManager.client.auth.authStateChanges {
                if Task.isCancelled { break }

                switch event {
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                    if let session, !session.isExpired {
                        apply(session: session)
                    } else if session?.isExpired == true {
                        // Keep showing signed-out until refresh succeeds or signOut fires.
                        userId = nil
                        email = nil
                    } else {
                        userId = nil
                        email = nil
                    }
                case .signedOut:
                    userId = nil
                    email = nil
                default:
                    if let session, !session.isExpired {
                        apply(session: session)
                    }
                }
            }
        }
    }

    func signUp(email: String, password: String) async throws {
        configureIfNeeded()
        guard isConfigured else { throw AuthServiceError.notConfigured }
        lastError = nil
        let response = try await SupabaseManager.client.auth.signUp(email: email, password: password)

        if let session = response.session {
            apply(session: session)
        } else {
            // User row can exist without a session (e.g. confirm-email). Sign in to get a JWT for sync.
            let session = try await SupabaseManager.client.auth.signIn(email: email, password: password)
            apply(session: session)
        }

        try await SupabaseSyncService.ensureProfileStub(email: email)
    }

    func signIn(email: String, password: String) async throws {
        configureIfNeeded()
        guard isConfigured else { throw AuthServiceError.notConfigured }
        lastError = nil
        let session = try await SupabaseManager.client.auth.signIn(email: email, password: password)
        apply(session: session)
        try await SupabaseSyncService.ensureProfileStub(email: email)
    }

    func signOut() async throws {
        try await SupabaseManager.client.auth.signOut()
        userId = nil
        email = nil
    }

    private func apply(session: Session) {
        userId = session.user.id.uuidString
        email = session.user.email
    }
}

enum AuthServiceError: LocalizedError {
    case notConfigured
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY first."
        case .notSignedIn:
            return "You need an active session before syncing. Sign in again."
        }
    }
}
