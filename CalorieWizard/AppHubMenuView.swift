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

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    var previous: AppDestination? {
        let i = index
        guard i > 0 else { return nil }
        return Self.allCases[i - 1]
    }

    var next: AppDestination? {
        let i = index
        guard i < Self.allCases.count - 1 else { return nil }
        return Self.allCases[i + 1]
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

            if selectedDestination != nil {
                DestinationPager(
                    selection: Binding(
                        get: { selectedDestination ?? .today },
                        set: { selectedDestination = $0 }
                    ),
                    onBackToMenu: {
                        withAnimation(BrandTransitions.cover) {
                            selectedDestination = nil
                        }
                    }
                )
                .transition(BrandTransitions.destinationCover)
                .zIndex(2)
            }
        }
        .animation(BrandTransitions.cover, value: selectedDestination == nil)
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
        Text("Open any section, then swipe or use the arrows to move between features. Tap Menu to return here.")
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

private struct DestinationPager: View {
    @Binding var selection: AppDestination
    var onBackToMenu: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground)
                .ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(AppDestination.allCases) { destination in
                    destinationRoot(destination)
                        .tag(destination)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(BrandTransitions.cover, value: selection)

            VStack(spacing: 0) {
                topChrome
                Spacer()
                bottomChrome
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(BrandTransitions.cover) {
                appeared = true
            }
        }
    }

    private var topChrome: some View {
        HStack(spacing: 12) {
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
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Image(systemName: selection.symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(
                        LinearGradient(colors: selection.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )

                Text(selection.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(BrandTheme.plum.opacity(0.2), lineWidth: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var bottomChrome: some View {
        VStack(spacing: 12) {
            pageDots

            HStack(spacing: 18) {
                navArrow(
                    systemName: "chevron.left",
                    enabled: selection.previous != nil
                ) {
                    guard let previous = selection.previous else { return }
                    withAnimation(BrandTransitions.cover) {
                        selection = previous
                    }
                }

                Text("\(selection.index + 1) / \(AppDestination.allCases.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 48)

                navArrow(
                    systemName: "chevron.right",
                    enabled: selection.next != nil
                ) {
                    guard let next = selection.next else { return }
                    withAnimation(BrandTransitions.cover) {
                        selection = next
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BrandTheme.plum.opacity(0.12))
                .frame(height: 1)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(AppDestination.allCases) { destination in
                Capsule()
                    .fill(destination == selection ? BrandTheme.plum : BrandTheme.plum.opacity(0.25))
                    .frame(width: destination == selection ? 18 : 7, height: 7)
                    .animation(BrandTransitions.quick, value: selection)
            }
        }
        .accessibilityHidden(true)
    }

    private func navArrow(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.bold))
                .foregroundStyle(enabled ? .white : .white.opacity(0.45))
                .frame(width: 48, height: 48)
                .background(
                    enabled
                        ? AnyShapeStyle(BrandTheme.primaryGradient(for: colorScheme))
                        : AnyShapeStyle(BrandTheme.plum.opacity(0.25)),
                    in: Circle()
                )
                .shadow(color: BrandTheme.plum.opacity(enabled ? 0.28 : 0), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(systemName.contains("left") ? "Previous section" : "Next section")
    }

    @ViewBuilder
    private func destinationRoot(_ destination: AppDestination) -> some View {
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
        // Leave room for top title chrome + bottom arrows.
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 56)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 108)
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
