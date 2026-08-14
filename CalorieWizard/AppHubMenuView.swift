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

    /// Harmonious plum-family accents so rows match the logo (not a rainbow).
    var colors: [Color] {
        switch self {
        case .today: [BrandTheme.plum, BrandTheme.plumDeep]
        case .analyze: [BrandTheme.plumDeep, BrandTheme.plum]
        case .recipes: [BrandTheme.plumSoft, BrandTheme.plum]
        case .water: [BrandTheme.plum, BrandTheme.plumSoft]
        case .history: [BrandTheme.plumDeep, BrandTheme.plumSoft]
        case .profile: [BrandTheme.plumSoft, BrandTheme.plumDeep]
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
            BrandTheme.aura(for: colorScheme)
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
            .scaleEffect(selectedDestination == nil ? 1 : 0.96)
            .opacity(selectedDestination == nil ? 1 : 0.55)
            .blur(radius: selectedDestination == nil ? 0 : 2)
            .allowsHitTesting(selectedDestination == nil)

            if let destination = selectedDestination {
                DestinationContainer(destination: destination) {
                    withAnimation(BrandTransitions.cover) {
                        selectedDestination = nil
                    }
                }
                .transition(BrandTransitions.destinationCover)
                .zIndex(2)
            }
        }
        .animation(BrandTransitions.cover, value: selectedDestination)
        .calorieLimitMonitoring()
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.86)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image("CalorieWizardMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(BrandTheme.plum.opacity(0.35), lineWidth: 1)
                    }
                    .shadow(color: BrandTheme.plum.opacity(0.25), radius: 8, y: 3)

                Text("CalorieWizard")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(colorScheme == .dark ? .white : BrandTheme.plumDeep)
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
                            .fill(BrandTheme.primaryGradient(for: colorScheme))
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
                            withAnimation(BrandTransitions.cover) {
                                selectedDestination = destination
                            }
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
        .background(BrandTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(BrandTheme.plum.opacity(colorScheme == .dark ? 0.35 : 0.18), lineWidth: 1)
        }
        .shadow(color: BrandTheme.plum.opacity(colorScheme == .dark ? 0.28 : 0.12), radius: 24, y: 12)
    }

    private func menuRow(_ destination: AppDestination) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: destination.colors,
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
        .background(
            (colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
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
}

private struct DestinationContainer: View {
    let destination: AppDestination
    var onBackToMenu: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

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
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : 24)

            Button(action: onBackToMenu) {
                Label("Menu", systemImage: "square.grid.2x2.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : BrandTheme.plumDeep)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(BrandTheme.plum.opacity(0.28), lineWidth: 1)
                    }
                    .shadow(color: BrandTheme.plum.opacity(0.16), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.trailing, 16)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.9)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(BrandTransitions.cover) {
                appeared = true
            }
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
