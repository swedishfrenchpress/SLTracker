//
//  OnboardingView.swift
//  sltracker
//
//  Created by Erik on 2026-07-02.
//

import SwiftUI

/// First-launch onboarding explaining the app, station pinning, and the widget.
/// Presented as a full-screen overlay from ContentView until completed.
struct OnboardingView: View {

    // MARK: - Properties

    /// Persisted flag — flipping this dismisses the onboarding in ContentView
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// Accessibility: reduce or disable animations for motion-sensitive users
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The currently visible page
    @State private var currentPage = 0

    private let pageCount = 3

    private var isLastPage: Bool { currentPage == pageCount - 1 }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - consistent with the home screen
            Color(.systemBackground)
                .ignoresSafeArea()

            GeometryReader { geo in
                Image("BackgroundMap")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.3)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                skipButton

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    pinPage.tag(1)
                    widgetPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator
                    .padding(.bottom, 24)

                continueButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        OnboardingPage(
            title: "Welcome to SL Tracker",
            subtitle: "Real-time departures for Stockholm's metro, buses, trams, trains, and ferries. Nothing more, nothing less.",
            isActive: currentPage == 0
        ) {
            Image("OnboardingAppIcon")
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 4)
        }
    }

    private var pinPage: some View {
        OnboardingPage(
            title: "Pin your stations",
            subtitle: "Search for any station and tap the pin. Pinned stations are front and center every time you open the app.",
            isActive: currentPage == 1
        ) {
            MockPinnedStationsCard(isActive: currentPage == 1)
        }
    }

    private var widgetPage: some View {
        OnboardingPage(
            title: "Add the widget",
            subtitle: "The widget shows live departures for your latest pin — no app-opening required. Touch and hold your Home Screen, tap +, and add SL Tracker.",
            isActive: currentPage == 2
        ) {
            MockWidgetCard(isActive: currentPage == 2)
        }
    }

    // MARK: - View Components

    private var skipButton: some View {
        HStack {
            Spacer()

            Button(action: completeOnboarding) {
                if #available(iOS 26, *) {
                    skipLabel
                        .glassEffect(.regular.interactive(), in: .capsule)
                } else {
                    skipLabel
                        .background(Capsule().fill(Color(.systemGray6)))
                }
            }
            .buttonStyle(.plain)
            .opacity(isLastPage ? 0 : 1)
            .disabled(isLastPage)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .animation(reduceMotion ? nil : .default, value: isLastPage)
    }

    private var skipLabel: some View {
        Text("Skip")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.primary : Color(.systemGray4))
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
            }
        }
        .animation(reduceMotion ? nil : .default, value: currentPage)
        .accessibilityHidden(true)
    }

    private var continueButton: some View {
        Group {
            if #available(iOS 26, *) {
                Button(action: advance) { continueLabel }
                    .buttonStyle(.glassProminent)
            } else {
                Button(action: advance) { continueLabel }
                    .buttonStyle(.borderedProminent)
            }
        }
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(.blue)
        .frame(maxWidth: 360)
    }

    private var continueLabel: some View {
        Text(isLastPage ? "Get Started" : "Continue")
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func advance() {
        if isLastPage {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            completeOnboarding()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(reduceMotion ? nil : .default) {
                currentPage += 1
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Page Layout

/// Shared layout for a single onboarding page: illustration above title and subtitle.
/// Content reveals with a gentle stagger when the page becomes active.
private struct OnboardingPage<Illustration: View>: View {
    let title: String
    let subtitle: String
    let isActive: Bool
    @ViewBuilder let illustration: Illustration

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 32) {
            illustration
                .accessibilityHidden(true)
                .opacity(revealed ? 1 : 0)
                .scaleEffect(revealed || reduceMotion ? 1 : 0.92)
                .animation(reduceMotion ? nil : .default, value: revealed)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed || reduceMotion ? 0 : 12)
                    .animation(reduceMotion ? nil : .default.delay(0.08), value: revealed)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed || reduceMotion ? 0 : 12)
                    .animation(reduceMotion ? nil : .default.delay(0.16), value: revealed)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { revealed = isActive }
        .onChange(of: isActive) { _, active in
            revealed = active
        }
    }
}

// MARK: - Mock Illustrations

/// Miniature of the home screen's pinned stations list, with a pin badge
private struct MockPinnedStationsCard: View {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pinBounce = false

    var body: some View {
        VStack(spacing: 0) {
            MockPinnedRow(icon: "tram.fill", color: .blue, name: "T-Centralen")

            Divider()
                .padding(.leading, 60)

            MockPinnedRow(icon: "bus.fill", color: .indigo, name: "Cityterminalen")
        }
        .modifier(GlassOrFillModifier(cornerRadius: 16))
        .frame(maxWidth: 320)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "pin.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.blue))
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                .offset(x: 10, y: -10)
                .symbolEffect(.bounce, value: pinBounce)
        }
        .onChange(of: isActive) { _, active in
            guard active, !reduceMotion else { return }
            Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                pinBounce.toggle()
            }
        }
    }
}

/// A single row matching PinnedStationRow's layout
private struct MockPinnedRow: View {
    let icon: String
    let color: Color
    let name: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.body.weight(.medium))
                .frame(width: 28, height: 28)
                .background(Color(.systemGray5))
                .clipShape(.rect(cornerRadius: 6))

            Text(name)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// A single mock departure for the widget miniature
private struct MockDeparture {
    let line: String
    let color: Color
    let destination: String
    let time: String
}

/// Miniature of the home screen widget; rows stagger in when the page becomes active
private struct MockWidgetCard: View {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    private static let departures: [MockDeparture] = [
        MockDeparture(line: "14", color: .red, destination: "Fruängen", time: "12:04"),
        MockDeparture(line: "17", color: .green, destination: "Skarpnäck", time: "12:07"),
        MockDeparture(line: "10", color: .blue, destination: "Hjulsta", time: "12:09")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tram.fill")
                    .foregroundStyle(.blue)
                    .font(.footnote.weight(.medium))

                Text("T-Centralen")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            VStack(spacing: 4) {
                ForEach(Array(Self.departures.enumerated()), id: \.element.line) { index, departure in
                    Group {
                        MockWidgetRow(
                            line: departure.line,
                            color: departure.color,
                            destination: departure.destination,
                            time: departure.time
                        )

                        if index < Self.departures.count - 1 {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed || reduceMotion ? 0 : 8)
                    .animation(reduceMotion ? nil : .default.delay(0.2 + 0.1 * Double(index)), value: revealed)
                }
            }
            .padding(.bottom, 12)
        }
        .frame(width: 190)
        .modifier(GlassOrFillModifier(cornerRadius: 22))
        .onAppear { revealed = isActive }
        .onChange(of: isActive) { _, active in
            revealed = active
        }
    }
}

/// A single departure row matching the widget's layout
private struct MockWidgetRow: View {
    let line: String
    let color: Color
    let destination: String
    let time: String

    var body: some View {
        HStack(spacing: 8) {
            Text(line)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 20)
                .background(color)
                .clipShape(.rect(cornerRadius: 4))

            Text(destination)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Text(time)
                .font(.caption.bold())
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
