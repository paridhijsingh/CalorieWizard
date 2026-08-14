//
//  BrandTheme.swift
//  CalorieWizard
//
//  Colors sampled from the CalorieWizard logo (muted plum / mauve).
//

import SwiftUI

enum BrandTheme {
    /// Primary logo plum — RGB(112, 72, 96)
    static let plum = Color(red: 112 / 255, green: 72 / 255, blue: 96 / 255)

    /// Slightly deeper for dark-mode fills / gradients
    static let plumDeep = Color(red: 86 / 255, green: 52 / 255, blue: 74 / 255)

    /// Soft wash for light backgrounds
    static let plumSoft = Color(red: 168 / 255, green: 132 / 255, blue: 154 / 255)

    /// Warm cream related to logo line contrast
    static let cream = Color(red: 248 / 255, green: 242 / 255, blue: 246 / 255)

    static func pageBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 18 / 255, green: 12 / 255, blue: 16 / 255) : cream
    }

    static func cardFill(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.78)
    }

    static func primaryGradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: scheme == .dark
                ? [plumSoft, plum]
                : [plum, plumDeep],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func aura(for scheme: ColorScheme) -> some View {
        ZStack {
            pageBackground(for: scheme)

            LinearGradient(
                colors: [
                    plum.opacity(scheme == .dark ? 0.42 : 0.18),
                    pageBackground(for: scheme),
                    plumDeep.opacity(scheme == .dark ? 0.32 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(plum.opacity(scheme == .dark ? 0.34 : 0.16))
                .blur(radius: 90)
                .frame(width: 280, height: 280)
                .offset(x: -120, y: -220)

            Circle()
                .fill(plumSoft.opacity(scheme == .dark ? 0.22 : 0.14))
                .blur(radius: 90)
                .frame(width: 240, height: 240)
                .offset(x: 140, y: 200)
        }
    }
}
