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
            landingBackground
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(colorScheme == .dark ? 0.45 : 0.22),
                                        Color.indigo.opacity(colorScheme == .dark ? 0.28 : 0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 148, height: 148)
                            .scaleEffect(logoPulse ? 1.08 : 0.94)
                            .opacity(logoPulse ? 0.95 : 0.55)

                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 58, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(logoPulse ? 1.08 : 0.94)
                            .opacity(logoPulse ? 1 : 0.62)
                    }
                    .accessibilityHidden(true)

                    Text("CalorieWizard")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)

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
                        LinearGradient(
                            colors: [Color.purple, Color.indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .shadow(color: Color.purple.opacity(colorScheme == .dark ? 0.5 : 0.35), radius: 16, y: 8)
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

    private var landingBackground: some View {
        ZStack {
            Color(.systemBackground)

            LinearGradient(
                colors: [
                    Color.purple.opacity(colorScheme == .dark ? 0.32 : 0.14),
                    Color(.systemBackground),
                    Color.indigo.opacity(colorScheme == .dark ? 0.22 : 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.purple.opacity(colorScheme == .dark ? 0.28 : 0.16))
                .blur(radius: 90)
                .frame(width: 260, height: 260)
                .offset(x: -120, y: -220)

            Circle()
                .fill(Color.indigo.opacity(colorScheme == .dark ? 0.24 : 0.12))
                .blur(radius: 90)
                .frame(width: 240, height: 240)
                .offset(x: 140, y: 180)
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
