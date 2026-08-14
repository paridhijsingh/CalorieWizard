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
        GeometryReader { geo in
            let logoWidth = min(geo.size.width * 0.78, 320)

            ZStack {
                BrandTheme.plum
                    .ignoresSafeArea()

                // Soft oversized wash so the page still feels branded edge-to-edge
                Image("CalorieWizardMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 1.35)
                    .opacity(0.12)
                    .blur(radius: 1)
                    .offset(y: -geo.size.height * 0.06)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.12)

                    Image("CalorieWizardLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoWidth)
                        .scaleEffect(logoPulse ? 1.02 : 1.0)
                        .opacity(logoPulse ? 1 : 0.94)
                        .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
                        .accessibilityLabel("CalorieWizard")

                    Spacer()

                    Text("Snap, Track, and Transform")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.92))
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
        }
        .background(BrandTheme.plum.ignoresSafeArea())
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
