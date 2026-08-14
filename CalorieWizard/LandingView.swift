//
//  LandingView.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/13/26.
//

import SwiftUI

struct LandingView: View {
    var onGetStarted: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoPulse = false

    var body: some View {
        ZStack {
            BrandTheme.aura(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 22) {
                    Image("CalorieWizardLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 48, style: .continuous)
                                .stroke(BrandTheme.plum.opacity(0.22), lineWidth: 1)
                        }
                        .shadow(color: BrandTheme.plum.opacity(colorScheme == .dark ? 0.55 : 0.28), radius: 18, y: 10)
                        .scaleEffect(logoPulse ? 1.03 : 0.97)
                        .opacity(logoPulse ? 1 : 0.9)
                        .accessibilityLabel("CalorieWizard logo")

                    Text("Snap, Track, and Transform")
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button(action: onGetStarted) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        BrandTheme.primaryGradient(for: colorScheme),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .shadow(color: BrandTheme.plum.opacity(colorScheme == .dark ? 0.5 : 0.32), radius: 16, y: 8)
                }
                .buttonStyle(LandingCTAButtonStyle())
                .padding(.horizontal, 22)
                .padding(.bottom, 36)
                .accessibilityHint("Continues to profile setup or your dashboard")
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                logoPulse = true
            }
        }
    }
}

private struct LandingCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    LandingView(onGetStarted: {})
}
