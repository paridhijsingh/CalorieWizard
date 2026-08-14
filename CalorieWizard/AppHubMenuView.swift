//
//  AppHubMenuView.swift
//  CalorieWizard
//

import SwiftUI

enum AppDestination: String, CaseIterable, Identifiable, Hashable {
    case today
    case analyze
    case recipes
    case water
    case history
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Dashboard"
        case .analyze: "Analyze Meal"
        case .recipes: "Recipe Wizard"
        case .water: "Water Tracker"
        case .history: "Meal History"
        case .profile: "Profile & Goals"
        }
    }

    var subtitle: String {
        switch self {
        case .today: "Calories, macros, and weekly charts"
        case .analyze: "Snap a meal for AI nutrition insights"
        case .recipes: "Craft recipes and save favorites"
        case .water: "Log hydration and set reminders"
        case .history: "Review past meals and photos"
        case .profile: "Personal details and daily targets"
        }
    }

    var symbol: String {
        switch self {
        case .today: "sun.max.fill"
        case .analyze: "camera.viewfinder"
        case .recipes: "wand.and.stars"
        case .water: "drop.fill"
        case .history: "clock.arrow.circlepath"
        case .profile: "person.crop.circle.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .today: [.purple, .indigo]
        case .analyze: [.indigo, .blue]
        case .recipes: [.pink, .purple]
        case .water: [.cyan, .blue]
        case .history: [.orange, .pink]
        case .profile: [.mint, .teal]
        }
    }
}

struct AppHubMenuView: View {
    @AppStorage(UserProfileKey.firstName) private var firstName = ""
    @Environment(\.colorScheme) private var colorScheme
    @State private var isMenuExpanded = true
    @State private var appeared = false
    @State private var selectedDestination: AppDestination?

    var body: some View {
        ZStack {
            hubBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    aestheticMenuCard
                    quickHint
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 36)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
            }
        }
        .calorieLimitMonitoring()
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.86)) {
                appeared = true
            }
        }
        .fullScreenCover(item: $selectedDestination) { destination in
            DestinationContainer(destination: destination) {
                selectedDestination = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("CalorieWizard")
                    .font(.title2.weight(.bold))
            }

            Text(greeting)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Text("Choose where you’d like to go.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var aestheticMenuCard: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    isMenuExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.9), .indigo.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Explore menu")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(isMenuExpanded ? "Tap to collapse" : "Tap to open destinations")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isMenuExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isMenuExpanded {
                Divider().padding(.horizontal, 16)

                VStack(spacing: 10) {
                    ForEach(Array(AppDestination.allCases.enumerated()), id: \.element.id) { index, destination in
                        Button {
                            selectedDestination = destination
                        } label: {
                            menuRow(destination)
                        }
                        .buttonStyle(HubMenuRowButtonStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.84).delay(Double(index) * 0.04),
                            value: isMenuExpanded
                        )
                    }
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(colorScheme == .dark ? 0.45 : 0.25),
                            Color.indigo.opacity(0.15),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.purple.opacity(colorScheme == .dark ? 0.28 : 0.12), radius: 24, y: 12)
    }

    private func menuRow(_ destination: AppDestination) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: destination.colors.map { $0.opacity(colorScheme == .dark ? 0.55 : 0.9) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                Image(systemName: destination.symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(destination.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(destination.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var quickHint: some View {
        Text("Open any section, then tap Menu in the corner to return here.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let name = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return "Welcome"
        }
        return "Welcome, \(name)"
    }

    private var hubBackground: some View {
        ZStack {
            Color(.systemBackground)

            LinearGradient(
                colors: [
                    Color.purple.opacity(colorScheme == .dark ? 0.34 : 0.16),
                    Color(.systemBackground),
                    Color.indigo.opacity(colorScheme == .dark ? 0.24 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.purple.opacity(colorScheme == .dark ? 0.28 : 0.14))
                .blur(radius: 90)
                .frame(width: 260, height: 260)
                .offset(x: -130, y: -240)

            Circle()
                .fill(Color.cyan.opacity(colorScheme == .dark ? 0.18 : 0.1))
                .blur(radius: 90)
                .frame(width: 220, height: 220)
                .offset(x: 140, y: 260)
        }
    }
}

private struct DestinationContainer: View {
    let destination: AppDestination
    var onBackToMenu: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch destination {
                case .today: DashboardView()
                case .analyze: FoodScannerView()
                case .recipes: RecipeGeneratorView()
                case .water: WaterTrackerView()
                case .history: HistoryView()
                case .profile: ProfileView()
                }
            }

            Button(action: onBackToMenu) {
                Label("Menu", systemImage: "square.grid.2x2.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
    }
}

private struct HubMenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    AppHubMenuView()
}
