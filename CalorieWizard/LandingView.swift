//
//  LandingView.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/13/26.
//

import SwiftUI

struct LandingView: View {
    var onGetStarted: () -> Void
    @State private var logoPulse = false

    var body: some View {
        ZStack {
            // Full-bleed brand mark as the page itself
            BrandTheme.plum
                .ignoresSafeArea()

            Image("CalorieWizardLogo")
                .resizable()
                .scaledToFill()
                .scaleEffect(logoPulse ? 1.04 : 1.0)
                .opacity(logoPulse ? 1 : 0.92)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            // Soft veil so tagline + CTA stay readable over the artwork
            LinearGradient(
                colors: [
                    Color.clear,
                    BrandTheme.plumDeep.opacity(0.15),
                    BrandTheme.plumDeep.opacity(0.72)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                Text("Snap, Track, and Transform")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: BrandTheme.plumDeep.opacity(0.45), radius: 8, y: 2)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 22)

                Button(action: onGetStarted) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(BrandTheme.plumDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        Color.white.opacity(0.94),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .shadow(color: .black.opacity(0.22), radius: 16, y: 8)
                }
                .buttonStyle(LandingCTAButtonStyle())
                .padding(.horizontal, 22)
                .padding(.bottom, 36)
                .accessibilityHint("Continues to profile setup or your dashboard")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("CalorieWizard")
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
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
