//
//  ContentView.swift
//  sltracker
//
//  Created by Erik on 2025-08-18.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Properties

    /// The view model that manages our departure data
    @State private var viewModel = DeparturesViewModel()

    /// The pinned stations manager
    @State private var pinnedManager = PinnedStationsManager()

    /// Navigation state for deep linking
    @Environment(NavigationState.self) private var navigationState

    /// The text the user enters for the station name
    @State private var stationName = ""

    /// The filtered list of station suggestions
    @State private var filteredStations: [Site] = []

    /// Whether we're in search mode (station selected)
    @State private var isSearchMode = false

    /// Easter egg state variables
    @State private var showingThankYou = false
    @State private var easterEggTapCount = 0

    /// First-launch onboarding — persisted so it only shows once
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// Focus state for search bar
    @FocusState private var isSearchFieldFocused: Bool


    /// Selected transport mode filter (nil = show all)
    @State private var selectedTransportFilter: String? = nil

    /// Accessibility: reduce or disable animations for motion-sensitive users
    @Environment(\.accessibilityReduceMotion) private var reduceMotion


    /// Tracked task for proper cancellation of the easter-egg reset timer
    @State private var easterEggResetTask: Task<Void, Never>?

    // Station data is now loaded from all_sites.json via SiteStore

    // MARK: - Body

    var body: some View {
        ZStack {
        NavigationStack {
            ZStack {
                // Background - consistent throughout app
                Color(.systemBackground)
                    .ignoresSafeArea()

                // Subtle Stockholm map background on home screen
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

                homeScreenView
            }
            .navigationTitle("SL Tracker")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $isSearchMode) {
                searchResultsView
                    .navigationTitle(stationName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 16) {
                                Button(action: {
                                    let modes = Array(Set(viewModel.departures.map { $0.line.transportMode }))
                                    let relatedIDs = SiteStore.shared.relatedSiteIDs(for: stationName)
                                    pinnedManager.togglePin(id: getCurrentSiteID(), name: stationName, transportModes: modes, relatedSiteIDs: relatedIDs)
                                }) {
                                    Image(systemName: pinnedManager.isStationPinned(id: getCurrentSiteID()) ? "pin.fill" : "pin")
                                        .font(.body.weight(.medium))
                                        .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                                }
                                .tint(.primary)
                                .accessibilityLabel(pinnedManager.isStationPinned(id: getCurrentSiteID()) ? "Unpin station" : "Pin station")

                                Button(action: refreshDepartures) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.body.weight(.medium))
                                        .rotationEffect(.degrees(viewModel.isLoading && !reduceMotion ? 360 : 0))
                                        .animation(viewModel.isLoading && !reduceMotion ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                                }
                                .tint(.primary)
                                .accessibilityLabel("Refresh departures")
                                .disabled(viewModel.isLoading)
                            }
                        }
                    }
            }
        }
        .onChange(of: navigationState.shouldNavigateToStation) { _, shouldNavigate in
            if shouldNavigate, let name = navigationState.targetStation {
                let siteID = SiteStore.shared.getSiteID(for: name) ?? ""
                selectStation(name: name, siteID: siteID)
                navigationState.clearNavigationTarget()
            }
        }
        .onChange(of: isSearchMode) { _, newValue in
            if !newValue {
                // Clean up when navigating back (system back button or swipe)
                stationName = ""
                selectedTransportFilter = nil
                viewModel.clearDepartures()
            }
        }
        .blur(radius: showingThankYou ? 8 : 0)
        .opacity(showingThankYou ? 0.3 : 1)

        // Easter egg overlay — above NavigationStack, covers nav bar
        ThankYouView(isVisible: $showingThankYou)

        // First-launch onboarding — topmost overlay, covers nav bar
        if !hasCompletedOnboarding {
            OnboardingView()
                .zIndex(1)
                .transition(.opacity)
        }
        }
        .animation(reduceMotion ? .none : .default, value: showingThankYou)
        .animation(reduceMotion ? .none : .default, value: hasCompletedOnboarding)
    }

    // MARK: - View Components

    /// Custom search bar with full hit area
    @ViewBuilder
    private var customSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search for a station", text: $stationName)
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .onSubmit {
                    if let firstSite = filteredStations.first {
                        selectStation(name: firstSite.name, siteID: String(firstSite.id))
                    }
                }

            if !stationName.isEmpty {
                Button {
                    stationName = ""
                    filteredStations = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .padding(.vertical, -10)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(10)
        .contentShape(Rectangle())
        .onTapGesture { isSearchFieldFocused = true }
        .modifier(GlassOrFillModifier(cornerRadius: .infinity))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    /// Search suggestions shown below the custom search bar
    private var searchSuggestionsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(filteredStations.prefix(8)) { site in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectStation(name: site.name, siteID: String(site.id))
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "tram.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text(site.name)
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if site.id != filteredStations.prefix(8).last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .modifier(GlassOrFillModifier(cornerRadius: 16))
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    /// Shown when the typed query matches no stations.
    private var noSearchResultsView: some View {
        VStack(spacing: 8) {
            Text("No stations found")
                .font(.headline)

            Text("Check the spelling, or try the Swedish name.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal)
    }

    /// Home screen view
    private var homeScreenView: some View {
        VStack(spacing: 0) {
            customSearchBar

            if isSearchFieldFocused && !filteredStations.isEmpty {
                searchSuggestionsView
                    .padding(.top, 8)
                    .transition(.opacity)
            } else if isSearchFieldFocused && !stationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                noSearchResultsView
                    .transition(.opacity)
            } else if !isSearchFieldFocused {
                Group {
                    initialView
                        .padding(.top, 32)

                    Spacer()

                    footerSection
                }
                .transition(.opacity)
            } else {
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(reduceMotion ? .none : .default) {
                isSearchFieldFocused = false
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(reduceMotion ? .none : .default, value: isSearchFieldFocused)
        .onChange(of: stationName) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            withAnimation(reduceMotion ? .none : .default) {
                if trimmed.isEmpty {
                    filteredStations = []
                } else {
                    filteredStations = SiteStore.shared.search(query: trimmed)
                }
            }
        }
    }

    /// Search results view
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Content Section
            contentSection

            Spacer()
        }
        .padding(.horizontal)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    /// The main content section showing departures or status
    private var contentSection: some View {
        VStack {
            if !viewModel.departures.isEmpty {
                // Keep the last-known list visible while refreshing or after a failed
                // refresh — surface any error as a calm inline banner, never a wall.
                VStack(spacing: 0) {
                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(message: errorMessage)
                    }
                    departuresList
                }
                .transition(.opacity)
            } else if viewModel.isLoading {
                loadingView
                    .transition(.opacity)
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
                    .transition(.opacity)
            } else if !viewModel.currentStation.isEmpty {
                noDeparturesView
                    .transition(.opacity)
            } else {
                Spacer()
            }
        }
        .animation(reduceMotion ? .none : .default, value: viewModel.isLoading)
        .animation(reduceMotion ? .none : .default, value: viewModel.departures.isEmpty)
        .animation(reduceMotion ? .none : .default, value: viewModel.errorMessage)
        .padding(.top, 16)
    }

    /// Loading indicator with beautiful animations
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(.blue)

            Text("Loading departures...")
                .font(.headline)
                .foregroundStyle(.secondary)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Full-screen state shown only when there's nothing else to display.
    /// Kept calm — a transient signal blip shouldn't read as a system failure.
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Couldn't load departures")
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                searchDepartures()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Calm inline banner shown above still-visible departures when a refresh fails,
    /// so the rider keeps the times already on screen.
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button("Retry") {
                refreshDepartures()
            }
            .font(.footnote.weight(.semibold))
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }

    /// Filter pills for transport modes (only shown when 2+ modes available)
    @ViewBuilder
    private var transportFilterPills: some View {
        let modes = availableTransportModes
        if modes.count >= 2 {
            ScrollView(.horizontal, showsIndicators: false) {
                filterPillsContent
            }
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var filterPillsContent: some View {
        let pills = HStack(spacing: 8) {
            FilterPillButton(
                label: "All",
                icon: nil,
                color: .primary,
                isSelected: selectedTransportFilter == nil,
                invertSelection: true
            ) {
                withAnimation(reduceMotion ? .none : .default) {
                    selectedTransportFilter = nil
                }
            }

            ForEach(availableTransportModes, id: \.self) { mode in
                FilterPillButton(
                    label: transportModeName(for: mode),
                    icon: transportModeIcon(for: mode),
                    color: transportModeColor(for: mode),
                    isSelected: selectedTransportFilter == mode
                ) {
                    withAnimation(reduceMotion ? .none : .default) {
                        selectedTransportFilter = mode
                    }
                }
            }
        }
        .padding(.horizontal)

        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 8) {
                pills
            }
        } else {
            pills
        }
    }

    /// Flat chronological list of departures with optional filter pills
    private var departuresList: some View {
        VStack(spacing: 0) {
            transportFilterPills

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredDepartures, id: \.id) { departure in
                        DepartureRowView(departure: departure)
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                        if departure.id != filteredDepartures.last?.id {
                            Divider()
                                .padding(.leading)
                        }
                    }

                    if let updated = viewModel.lastUpdated {
                        Text("Updated \(updated, format: .dateTime.hour().minute())")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                    }
                }
            }
            .refreshable {
                await viewModel.fetchDepartures(for: viewModel.currentSiteID, stationName: viewModel.currentStation)
            }
        }
    }

    /// No departures found message
    private var noDeparturesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No departures found")
                .font(.headline)

            Text("No departures found for \(viewModel.currentStation). Try a different station or check the station name.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Initial state when app first loads
    private var initialView: some View {
        Group {
            if pinnedManager.pinnedStations.isEmpty {
                VStack(spacing: 12) {
                    Text("Ready to roll?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary.opacity(0.8))

                    Text("Search for a station to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                pinnedStationsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// Pinned stations section
    private var pinnedStationsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pinned Stations")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)

            pinnedStationsListContent
                .padding(.horizontal)

            Spacer()
        }
    }

    private var pinnedStationsListContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(pinnedManager.pinnedStations, id: \.id) { station in
                PinnedStationRow(
                    station: station,
                    onTap: { selectPinnedStation(station) },
                    onUnpin: { pinnedManager.unpinStation(id: station.id) }
                )

                if station.id != pinnedManager.pinnedStations.last?.id {
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .modifier(GlassOrFillModifier(cornerRadius: 16))
    }

    /// Footer section
    private var footerSection: some View {
        Button {
            triggerEasterEgg()
        } label: {
            Text("Lovingly made by Erik in Stockholm ❤️‍🔥")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 20)
    }

    // MARK: - Transport Mode Helpers

    private func transportModeIcon(for mode: String) -> String {
        switch mode {
        case "METRO": return "tram.fill"
        case "TRAM": return "cablecar"
        case "BUS": return "bus.fill"
        case "TRAIN": return "train.side.front.car"
        case "SHIP": return "ferry.fill"
        default: return "questionmark.circle"
        }
    }

    private func transportModeName(for mode: String) -> String {
        switch mode {
        case "METRO": return "Metro"
        case "TRAM": return "Tram"
        case "BUS": return "Bus"
        case "TRAIN": return "Train"
        case "SHIP": return "Ferry"
        default: return mode
        }
    }

    private func transportModeColor(for mode: String) -> Color {
        switch mode {
        case "METRO": return .blue
        case "TRAM": return .orange
        case "BUS": return .indigo
        case "TRAIN": return .purple
        case "SHIP": return .teal
        default: return .gray
        }
    }

    /// Ordered list of transport modes present in current departures
    private var availableTransportModes: [String] {
        let modeOrder = ["METRO", "TRAM", "BUS", "TRAIN", "SHIP"]
        let presentModes = Set(viewModel.departures.map { $0.line.transportMode })
        return modeOrder.filter { presentModes.contains($0) }
    }

    /// Departures filtered by the selected transport mode
    private var filteredDepartures: [Departure] {
        guard let filter = selectedTransportFilter else {
            return viewModel.departures
        }
        return viewModel.departures.filter { $0.line.transportMode == filter }
    }

    // MARK: - Actions

    /// Selects a station and transitions to search mode
    private func selectStation(name: String, siteID: String) {
        isSearchFieldFocused = false
        filteredStations = []
        selectedTransportFilter = nil
        viewModel.currentSiteID = siteID
        stationName = name
        isSearchMode = true

        searchDepartures()
    }

    /// Selects a pinned station
    private func selectPinnedStation(_ station: PinnedStation) {
        selectStation(name: station.name, siteID: station.id)
    }

    /// Gets the current site ID for the selected station
    private func getCurrentSiteID() -> String {
        return viewModel.currentSiteID
    }

    /// Searches for departures using the current site ID
    private func searchDepartures() {
        let trimmedName = stationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !viewModel.currentSiteID.isEmpty else { return }

        filteredStations = []
        viewModel.fetchDepartures(for: viewModel.currentSiteID, stationName: trimmedName)
    }

    /// Refreshes the current departures by calling the API again
    private func refreshDepartures() {
        selectedTransportFilter = nil
        guard !viewModel.currentSiteID.isEmpty else { return }
        viewModel.fetchDepartures(for: viewModel.currentSiteID, stationName: viewModel.currentStation)
    }

    /// Triggers the easter egg (requires 3 taps)
    private func triggerEasterEgg() {
        easterEggTapCount += 1

        // Reset tap count after 3 seconds if not completed
        easterEggResetTask?.cancel()
        easterEggResetTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            guard !Task.isCancelled else { return }
            if easterEggTapCount < 3 {
                easterEggTapCount = 0
            }
        }

        // Show easter egg after 3 taps
        if easterEggTapCount >= 3 {
            easterEggTapCount = 0 // Reset for next time

            // Show thank you screen
            withAnimation(reduceMotion ? .none : .default) {
                showingThankYou = true
            }
        }
    }


}

// MARK: - Pinned Station Row View

/// A row view for displaying a pinned station with enhanced interactions
struct PinnedStationRow: View {
    let station: PinnedStation
    let onTap: () -> Void
    let onUnpin: () -> Void

    @State private var isPressed = false

    /// Accessibility: reduce or disable animations for motion-sensitive users
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Station icon based on transport modes
                Image(systemName: stationIcon)
                    .foregroundStyle(stationIconColor)
                    .font(.body.weight(.medium))
                    .frame(width: 28, height: 28)
                    .background(Color(.systemGray5))
                    .clipShape(.rect(cornerRadius: 6))
                    .scaleEffect(isPressed ? 0.95 : 1.0)

                // Station name
                Text(station.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(reduceMotion ? .none : .default) {
                isPressed = isPressing
            }
        }, perform: {})
        .swipeActions(edge: .trailing) {
            Button("Unpin") {
                onUnpin()
            }
            .tint(.red)
        }
        .contextMenu {
            Button("Unpin", role: .destructive) {
                onUnpin()
            }
        }
    }

    private var stationIcon: String {
        let modes = station.transportModes
        if modes.contains("METRO") || modes.isEmpty { return "tram.fill" }
        if modes.count == 1, let mode = modes.first {
            switch mode {
            case "TRAM": return "cablecar"
            case "BUS": return "bus.fill"
            case "TRAIN": return "train.side.front.car"
            case "SHIP": return "ferry.fill"
            default: return "tram.fill"
            }
        }
        let priority = ["TRAIN", "TRAM", "BUS", "SHIP"]
        for mode in priority {
            if modes.contains(mode) {
                switch mode {
                case "TRAM": return "cablecar"
                case "BUS": return "bus.fill"
                case "TRAIN": return "train.side.front.car"
                case "SHIP": return "ferry.fill"
                default: break
                }
            }
        }
        return "tram.fill"
    }

    private var stationIconColor: Color {
        let modes = station.transportModes
        if modes.contains("METRO") || modes.isEmpty { return .blue }
        if modes.count == 1, let mode = modes.first {
            switch mode {
            case "TRAM": return .orange
            case "BUS": return .indigo
            case "TRAIN": return .purple
            case "SHIP": return .teal
            default: return .blue
            }
        }
        let priority = ["TRAIN", "TRAM", "BUS", "SHIP"]
        for mode in priority {
            if modes.contains(mode) {
                switch mode {
                case "TRAM": return .orange
                case "BUS": return .indigo
                case "TRAIN": return .purple
                case "SHIP": return .teal
                default: break
                }
            }
        }
        return .blue
    }
}

// MARK: - Departure Row View

/// A single row view for displaying a metro departure with enhanced animations
struct DepartureRowView: View {
    let departure: Departure

    var body: some View {
        HStack(spacing: 16) {
            // Line number and direction
            VStack(alignment: .leading, spacing: 6) {
                Text(departure.line.designation)
                    .font(.callout.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 28)
                    .background(lineColor(for: departure))
                    .clipShape(.rect(cornerRadius: 8))
                    .shadow(color: lineColor(for: departure).opacity(0.3), radius: 4, x: 0, y: 2)

                Text(departure.destination)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(departure.display)
                    .font(.headline)
                    .foregroundStyle(isImminent ? .orange : .blue)

                if let platform = departure.stopPoint.designation {
                    Text("Platform \(platform)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        // Merge the fragments into one spoken sentence for VoiceOver, and keep
        // urgency legible without relying on colour alone.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Whether this departure is imminent (leaving "Nu"/now or within minutes).
    private var isImminent: Bool {
        departure.display.contains("Nu") || departure.display.contains("min")
    }

    /// A single, VoiceOver-friendly description of the whole row.
    private var accessibilityDescription: String {
        let time = departure.display == "Nu" ? "now" : departure.display
        var parts = ["Line \(departure.line.designation) to \(departure.destination)", time]
        if let platform = departure.stopPoint.designation {
            parts.append("platform \(platform)")
        }
        return parts.joined(separator: ", ")
    }

    /// Returns the appropriate color based on transport mode and line
    private func lineColor(for departure: Departure) -> Color {
        switch departure.line.transportMode {
        case "METRO":
            switch departure.line.designation {
            case "13", "14": return .red
            case "17", "18", "19": return .green
            case "10", "11": return .blue
            default: return .gray
            }
        case "TRAM": return .orange
        case "BUS": return .indigo
        case "TRAIN": return .purple
        case "SHIP": return .teal
        default: return .gray
        }
    }

}

// MARK: - Glass or Fill Modifier

/// Applies liquid glass on iOS 26+, falls back to systemGray6 fill.
/// Pass `.infinity` for cornerRadius to get a capsule shape.
struct GlassOrFillModifier: ViewModifier {
    let cornerRadius: CGFloat

    private var isCapsule: Bool { cornerRadius == .infinity }

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if isCapsule {
                content.glassEffect(.regular, in: .capsule)
            } else {
                content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            if isCapsule {
                content
                    .background(Capsule().fill(Color(.systemGray6)))
            } else {
                content
                    .background(RoundedRectangle(cornerRadius: cornerRadius).fill(Color(.systemGray6)))
            }
        }
    }
}

// MARK: - Filter Pill Button

struct FilterPillButton: View {
    let label: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    var invertSelection: Bool = false
    let action: () -> Void

    private var pillContent: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.medium))
            }
            Text(label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .fixedSize()
        .foregroundStyle(isSelected ? (invertSelection ? Color(.systemBackground) : color) : .primary)
    }

    var body: some View {
        Button(action: action) {
            if #available(iOS 26, *) {
                pillContent
                    .glassEffect(
                        isSelected ? .regular.interactive().tint(invertSelection ? Color(.label) : color) : .regular.interactive(),
                        in: .capsule
                    )
            } else {
                pillContent
                    .background(isSelected ? (invertSelection ? Color(.label) : color.opacity(0.15)) : Color(.systemGray6))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(isSelected ? (invertSelection ? Color.clear : color.opacity(0.3)) : Color.clear, lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

// MARK: - Easter Egg Views

/// Native confetti effect using Core Animation's particle emitter
struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> ConfettiUIView {
        ConfettiUIView()
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {}

    class ConfettiUIView: UIView {
        private let emitter = CAEmitterLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isUserInteractionEnabled = false
            emitter.emitterShape = .line

            let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPink, .systemYellow, .systemPurple]
            emitter.emitterCells = colors.flatMap { color in
                [ConfettiView.makeCell(color: color, size: 8), ConfettiView.makeCell(color: color, size: 5)]
            }

            layer.addSublayer(emitter)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.emitter.birthRate = 0
            }
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
            emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        }
    }

    static func makeCell(color: UIColor, size: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 12
        cell.lifetime = 5
        cell.velocity = 180
        cell.velocityRange = 80
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 4
        cell.spin = 4
        cell.spinRange = 8
        cell.scale = 0.06 * size / 8
        cell.scaleRange = 0.03
        cell.color = color.cgColor
        cell.alphaSpeed = -0.2
        cell.contents = Self.makeConfettiImage(size: size)
        return cell
    }

    static func makeConfettiImage(size: CGFloat) -> CGImage? {
        let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        UIColor.white.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: size > 6 ? 1 : size / 2).fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.cgImage
    }
}

/// Thank you screen with dedication message
struct ThankYouView: View {
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            ZStack {
                // Clean background
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    VStack(spacing: 8) {
                        Text("Dedicated to my friend Adam.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Thank you for testing this app early and helping me build it.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Simple close text
                    Button("Close") {
                        withAnimation(UIAccessibility.isReduceMotionEnabled ? .none : .default) {
                            isVisible = false
                        }
                    }
                    .tint(.primary)
                }
                .padding(.vertical, 80)
            }
            .overlay {
                if !UIAccessibility.isReduceMotionEnabled {
                    ConfettiView().allowsHitTesting(false).ignoresSafeArea()
                }
            }
            .transition(.opacity)
        }
    }
}

