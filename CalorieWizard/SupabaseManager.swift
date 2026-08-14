//
//  SupabaseManager.swift
//  CalorieWizard
//

import Foundation
import Supabase

enum SupabaseConfig {
    static var urlString: String {
        value(for: "SUPABASE_URL")
    }

    static var anonKey: String {
        value(for: "SUPABASE_ANON_KEY")
    }

    static var isConfigured: Bool {
        guard let url = URL(string: urlString),
              url.scheme == "https",
              !anonKey.isEmpty,
              anonKey != "your_supabase_anon_key_here" else {
            return false
        }
        return true
    }

    private static func value(for key: String) -> String {
        if let env = ProcessInfo.processInfo.environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = plist.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }
        return ""
    }
}

enum SupabaseManager {
    static let client: SupabaseClient = {
        let url = URL(string: SupabaseConfig.urlString) ?? URL(string: "https://example.supabase.co")!
        return SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
    }()
}
