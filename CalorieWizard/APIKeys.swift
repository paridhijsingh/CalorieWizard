//
//  APIKeys.swift
//  CalorieWizard
//

import Foundation

/// Reads API keys from process environment variables first, then Info.plist
/// values injected from `Config/Secrets.xcconfig` at build time.
enum APIKeys {
    static var gemini: String {
        value(for: "GEMINI_API_KEY")
    }

    static var usda: String {
        value(for: "USDA_API_KEY")
    }

    static var hasGemini: Bool {
        !gemini.isEmpty && gemini != "your_gemini_api_key_here"
    }

    static var hasUSDA: Bool {
        !usda.isEmpty && usda != "your_usda_api_key_here"
    }

    private static func value(for key: String) -> String {
        if let env = ProcessInfo.processInfo.environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty {
            return env
        }

        if let plist = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = plist.trimmingCharacters(in: .whitespacesAndNewlines)
            // Unexpanded build settings look like "$(GEMINI_API_KEY)"
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }

        return ""
    }
}
