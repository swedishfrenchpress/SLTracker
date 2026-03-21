//
//  ContentView.swift
//  sltracker
//
//  Created by Erik on 2025-08-18.
//

import SwiftUI

// MARK: - Preference Keys for Dynamic Layout

struct HeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SearchBarHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    
    /// Whether to show the station suggestions dropdown
    @State private var showingSuggestions = false
    
    /// The filtered list of station suggestions
    @State private var filteredStations: [Site] = []

    /// Whether the search field is focused
    @FocusState private var isSearchFocused: Bool
    
    /// Whether we're in search mode (station selected)
    @State private var isSearchMode = false

    /// Animation state for smooth transitions
    @State private var searchBarOffset: CGFloat = 0
    
    /// Dynamic layout measurements for responsive positioning
    @State private var headerHeight: CGFloat = 0
    @State private var searchBarHeight: CGFloat = 0
    
    /// Easter egg state variables
    @State private var showingThankYou = false
    @State private var easterEggTapCount = 0

    /// Empty state animation flag
    @State private var isEmptyStatePulsing = false

    /// Selected transport mode filter (nil = show all)
    @State private var selectedTransportFilter: String? = nil

    // Station data is now loaded from all_sites.json via SiteStore
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background - consistent throughout app
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Main content layers with iOS-standard navigation animations
            switch isSearchMode {
            case false:
                // Home screen - always present, no insertion animation
                homeScreenView
                    .zIndex(0)
                    
            case true:
                // Search results screen - slides in from right, out to right
                searchResultsView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(1)
            }
            
            // No more overlay - dropdown is now part of natural flow
        }
        .animation(.easeInOut(duration: 0.35), value: isSearchMode)
        .animation(.easeInOut(duration: 0.25), value: showingSuggestions)
        
        // Easter egg overlay
        .overlay(
            ThankYouView(isVisible: $showingThankYou)
        )
        .onChange(of: navigationState.shouldNavigateToStation) { _, shouldNavigate in
            if shouldNavigate, let name = navigationState.targetStation {
                let siteID = SiteStore.shared.getSiteID(for: name) ?? ""
                selectStation(name: name, siteID: siteID)
                navigationState.clearNavigationTarget()
            }
        }

    }
    
    // MARK: - View Components
    
    /// Home screen view with tap-to-dismiss functionality
    private var homeScreenView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Main content
                VStack(spacing: 0) {
                    // Custom header (instead of NavigationView)
                    homeScreenHeader
                        .background(
                            GeometryReader { headerGeometry in
                                Color.clear.preference(key: HeaderHeightPreferenceKey.self, value: headerGeometry.size.height)
                            }
                        )
                    
                    // Search Section
                    searchBarSection
                        .background(
                            GeometryReader { searchGeometry in
                                Color.clear.preference(key: SearchBarHeightPreferenceKey.self, value: searchGeometry.size.height)
                            }
                        )
                    
                    // Content Section
                    VStack {
                        if !viewModel.departures.isEmpty {
                            departuresList
                        } else {
                            initialView
                        }
                    }
                    .padding(.top, 32)
                    
                    Spacer()
                    
                    // Footer
                    footerSection
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // Make entire area tappable
                .onTapGesture {
                    // Dismiss dropdown and keyboard when tapping outside
                    if showingSuggestions {
                        dismissDropdownAndKeyboard()
                    }
                }
                
                // Dynamic dropdown overlay
                if showingSuggestions && !filteredStations.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 0) {
                        // Dynamic positioning with fallback values for initial state
                        let calculatedHeight = max(headerHeight + searchBarHeight + 16, 140) // Increased spacing after moving search bar
                        Spacer()
                            .frame(height: calculatedHeight)
                        
                        dropdownView
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.25)))
                            .allowsHitTesting(true) // Ensure dropdown can receive taps
                        
                        Spacer()
                    }
                    .zIndex(1)
                }
            }
        }
        .onPreferenceChange(HeaderHeightPreferenceKey.self) { height in
            headerHeight = height
        }
        .onPreferenceChange(SearchBarHeightPreferenceKey.self) { height in
            searchBarHeight = height
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    /// Search results view with tap-to-dismiss functionality
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Custom navigation bar
            customNavigationBar
            
            // Search Section
            searchBarSection
            
            // Dropdown appears in flow (pushes results down)
            if showingSuggestions && !filteredStations.isEmpty && !viewModel.isLoading {
                dropdownView
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)).animation(.easeInOut(duration: 0.2)))
                    .allowsHitTesting(true)
            }
            
            // Content Section
            contentSection
            
            Spacer()
        }
        .padding(.horizontal)
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            // Dismiss dropdown and keyboard when tapping outside
            if showingSuggestions {
                dismissDropdownAndKeyboard()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    /// Custom header for home screen (replaces NavigationView)
    private var homeScreenHeader: some View {
        HStack {
            Text("SL Tracker")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Refresh button for home screen
            if !viewModel.departures.isEmpty {
                Group {
                    if #available(iOS 26, *) {
                        Button(action: refreshDepartures) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body.weight(.medium))
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("Refresh departures")
                    } else {
                        Button(action: refreshDepartures) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body.weight(.medium))
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                        .tint(.primary)
                        .accessibilityLabel("Refresh departures")
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    /// Custom navigation bar for search mode
    private var customNavigationBar: some View {
        HStack {
            Group {
                if #available(iOS 26, *) {
                    Button(action: resetSearch) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                            Text("Back")
                                .font(.body)
                        }
                    }
                    .buttonStyle(.glass)
                } else {
                    Button(action: resetSearch) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                            Text("Back")
                                .font(.body)
                        }
                    }
                    .tint(.primary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Pin/Unpin button
                Group {
                    if #available(iOS 26, *) {
                        Button(action: {
                            let modes = Array(Set(viewModel.departures.map { $0.line.transportMode }))
                            pinnedManager.togglePin(id: getCurrentSiteID(), name: stationName, transportModes: modes)
                        }) {
                            Image(systemName: pinnedManager.isStationPinned(id: getCurrentSiteID()) ? "pin.fill" : "pin")
                                .font(.body.weight(.medium))
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel(pinnedManager.isStationPinned(id: getCurrentSiteID()) ? "Unpin station" : "Pin station")
                    } else {
                        Button(action: {
                            let modes = Array(Set(viewModel.departures.map { $0.line.transportMode }))
                            pinnedManager.togglePin(id: getCurrentSiteID(), name: stationName, transportModes: modes)
                        }) {
                            Image(systemName: pinnedManager.isStationPinned(id: getCurrentSiteID()) ? "pin.fill" : "pin")
                                .font(.body.weight(.medium))
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .tint(.primary)
                        .accessibilityLabel(pinnedManager.isStationPinned(id: getCurrentSiteID()) ? "Unpin station" : "Pin station")
                    }
                }
                
                // Refresh button with rotation animation
                Group {
                    if #available(iOS 26, *) {
                        Button(action: refreshDepartures) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body.weight(.medium))
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("Refresh departures")
                    } else {
                        Button(action: refreshDepartures) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body.weight(.medium))
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                        .tint(.primary)
                        .accessibilityLabel("Refresh departures")
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    /// The search bar section (without dropdown)
    private var searchBarSection: some View {
        VStack(spacing: 12) {
            // Standard iOS search field with proper styling
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                
                TextField("Search for a station", text: $stationName)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onChange(of: stationName) { _, newValue in
                        updateSuggestions(for: newValue)
                    }
                    .onSubmit {
                        if let firstSite = filteredStations.first {
                            selectStation(name: firstSite.name, siteID: String(firstSite.id))
                        }
                    }
                
                if !stationName.isEmpty {
                    Button {
                        // Clear text and dismiss keyboard (standard iOS behavior)
                        stationName = ""
                        filteredStations = []
                        showingSuggestions = false
                        isSearchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
        }
        .padding(.horizontal)
        .padding(.top, isSearchMode ? 8 : 0)
    }
    
    /// The main content section showing departures or status
    private var contentSection: some View {
        VStack {
            if viewModel.isLoading {
                // Loading state - always show when loading in search mode
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                // Error state
                errorView(message: errorMessage)
            } else if !viewModel.departures.isEmpty {
                // Departures list
                departuresList
            } else if !viewModel.currentStation.isEmpty {
                // No departures found
                noDeparturesView
            } else if !isSearchMode {
                // Initial state - only show on home screen, not in search mode
                initialView
            } else {
                // Empty space in search mode when no station selected yet
                Spacer()
            }
        }
        .padding(.top, isSearchMode ? 16 : 32)
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
        .transition(.opacity.combined(with: .scale(scale: 0.9)).animation(.easeInOut(duration: 0.3)))
    }
    
    /// Error message display
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text("Error")
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
    
    /// Filter pills for transport modes (only shown when 2+ modes available)
    @ViewBuilder
    private var transportFilterPills: some View {
        let modes = availableTransportModes
        if modes.count >= 2 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPillButton(
                        label: "All",
                        icon: nil,
                        color: .primary,
                        isSelected: selectedTransportFilter == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTransportFilter = nil
                        }
                    }

                    ForEach(modes, id: \.self) { mode in
                        FilterPillButton(
                            label: transportModeName(for: mode),
                            icon: transportModeIcon(for: mode),
                            color: transportModeColor(for: mode),
                            isSelected: selectedTransportFilter == mode
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTransportFilter = mode
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
        }
    }

    /// Flat chronological list of departures with optional filter pills
    private var departuresList: some View {
        VStack(spacing: 0) {
            transportFilterPills

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredDepartures.enumerated()), id: \.element.id) { index, departure in
                            DepartureRowView(departure: departure)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .id(departure.id)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing))
                                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05)),
                                    removal: .opacity.animation(.easeInOut(duration: 0.2))
                                ))
                                .modifier(ScrollFadeModifier(index: index))

                            if index < filteredDepartures.count - 1 {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.35)))
    }
    
    /// No departures found message
    private var noDeparturesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No departures found")
                .font(.headline)
            
            Text("No departures found for \(viewModel.currentStation). Try a different station or check the station name.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Initial state when app first loads with smooth transitions
    private var initialView: some View {
        Group {
            if pinnedManager.pinnedStations.isEmpty {
                // Empty state with subtle animation
                VStack(spacing: 24) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                        .scaleEffect(isEmptyStatePulsing ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isEmptyStatePulsing)
                        .onAppear {
                            isEmptyStatePulsing = true
                        }
                        .onDisappear {
                            isEmptyStatePulsing = false
                        }
                    
                    Text("Ready to roll?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.9)).animation(.easeInOut(duration: 0.5)))
            } else {
                // Pinned stations
                pinnedStationsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.4)))
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
            .background {
                if #available(iOS 26, *) {
                    // Use Liquid Glass effect on iOS 26+
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.clear)
                        .glassEffect(.regular, in: .rect(cornerRadius: 12))
                } else {
                    // Fallback for older iOS versions
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
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
    
    /// Dropdown view using ScrollView + LazyVStack for stability
    private var dropdownView: some View {
        ZStack {
            // Background that matches app background
            Color(.systemBackground)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredStations) { site in
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            selectStation(name: site.name, siteID: String(site.id))
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tram.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline.weight(.medium))

                                Text(site.name)
                                    .foregroundStyle(.primary)
                                    .font(.body)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        if site.id != filteredStations.last?.id {
                            Divider()
                                .background(Color(.separator))
                        }
                    }
                }
            }
        }
        // Keep dropdown height consistent with row padding
        .frame(height: min(CGFloat(filteredStations.count) * 52, 416)) // Max 8 items at 52pt each
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
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

    /// Updates the station suggestions based on user input
    private func updateSuggestions(for input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedInput.isEmpty {
            filteredStations = []
            showingSuggestions = false
        } else {
            filteredStations = SiteStore.shared.search(query: trimmedInput)
            showingSuggestions = !filteredStations.isEmpty
        }
    }
    
    /// Selects a station and transitions to search mode
    private func selectStation(name: String, siteID: String) {
        isSearchFocused = false
        clearDropdownState()
        selectedTransportFilter = nil
        stationName = name
        viewModel.currentSiteID = siteID

        withAnimation(.easeInOut(duration: 0.35)) {
            isSearchMode = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            searchDepartures()
        }
    }

    /// Selects a pinned station
    private func selectPinnedStation(_ station: PinnedStation) {
        selectStation(name: station.name, siteID: station.id)
    }
    
    /// Completely clears all dropdown-related state
    private func clearDropdownState() {
        isSearchFocused = false
        showingSuggestions = false
        filteredStations = []
    }
    
    /// Dismisses dropdown and keyboard when tapping outside
    private func dismissDropdownAndKeyboard() {
        // Dismiss keyboard first, before animation
        isSearchFocused = false
        
        withAnimation(.easeInOut(duration: 0.25)) {
            showingSuggestions = false
        }
        
        // Clear filtered stations
        filteredStations = []
    }
    
    /// Gets the current site ID for the selected station
    private func getCurrentSiteID() -> String {
        return viewModel.currentSiteID
    }

    /// Searches for departures using the current site ID
    private func searchDepartures() {
        let trimmedName = stationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !viewModel.currentSiteID.isEmpty else { return }

        clearDropdownState()
        viewModel.fetchDepartures(for: viewModel.currentSiteID, stationName: trimmedName)
    }
    
    /// Resets the search and returns to initial state
    private func resetSearch() {
        // Dismiss keyboard first
        isSearchFocused = false
        
        clearDropdownState()
        
        withAnimation(.easeInOut(duration: 0.35)) {
            isSearchMode = false
            stationName = ""
            selectedTransportFilter = nil
            viewModel.clearDepartures()
        }
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
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if easterEggTapCount < 3 {
                easterEggTapCount = 0
            }
        }
        
        // Show easter egg after 3 taps
        if easterEggTapCount >= 3 {
            easterEggTapCount = 0 // Reset for next time
            
            // Show thank you screen
            withAnimation(.easeInOut(duration: 0.3)) {
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
                    .rotationEffect(.degrees(isPressed ? 5 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.15)) {
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
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Line number and direction
            VStack(alignment: .leading, spacing: 6) {
                // Colored line number box with subtle animation
                Text(departure.line.designation)
                    .font(.callout.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 28)
                    .background(lineColor(for: departure))
                    .clipShape(.rect(cornerRadius: 8))
                    .shadow(color: lineColor(for: departure).opacity(0.3), radius: 4, x: 0, y: 2)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                
                Text(departure.destination)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .opacity(isVisible ? 1.0 : 0.0)
            }
            
            Spacer()
            
            // Departure time with pulse animation for urgent departures
            VStack(alignment: .trailing, spacing: 4) {
                Text(departure.display)
                    .font(.headline)
                    .foregroundStyle(departure.display.contains("Nu") || departure.display.contains("min") ? .orange : .blue)
                    .scaleEffect(departure.display.contains("Nu") ? (isVisible ? 1.1 : 1.0) : 1.0)
                    .opacity(isVisible ? 1.0 : 0.0)
                
                if let platform = departure.stopPoint.designation {
                    Text("Platform \(platform)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .opacity(isVisible ? 1.0 : 0.0)
                }
            }
        }
        .onAppear {
            // Snappier initial animation to work with scroll-based animations
            withAnimation(.easeOut(duration: 0.2)) {
                isVisible = true
            }
            
            // Add pulse animation for urgent departures
            if departure.display.contains("Nu") {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isVisible = true
                }
            }
        }
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

// MARK: - Filter Pill Button

struct FilterPillButton: View {
    let label: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
            .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? color : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
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
                    
                    VStack(spacing: 16) {
                        // Simple title
                        Text("Dedication")
                            .font(.title)
                            .foregroundStyle(.primary)
                        
                        // Simple subtitle
                        Text("This app is dedicated to my friends Alex, Nick, and Elin from Katerina Ol Cafe. The best bar in Stockholm.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // Simple close text
                    Button("Close") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isVisible = false
                        }
                    }
                    .tint(.primary)
                }
                .padding(.vertical, 80)
            }
            .overlay(ConfettiView().allowsHitTesting(false).ignoresSafeArea())
            .transition(.opacity)
        }
    }
}

// MARK: - Scroll Fade Modifier

/// A custom modifier that applies beautiful fade animations based on scroll position
/// This creates the same fade effect when scrolling up as when scrolling down
/// 
/// How it works:
/// 1. Tracks scroll position using GeometryReader and preference keys
/// 2. Determines scroll direction by comparing current vs previous scroll offset
/// 3. Applies fade-in animations when items come into view (both up and down scrolling)
/// 4. Uses staggered delays for a beautiful cascading effect
struct ScrollFadeModifier: ViewModifier {
    let index: Int
    
    @State private var isVisible = false
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollDirection: ScrollDirection = .none
    
    // Animation timing for smooth fade effects - optimized for snappier response
    private let fadeInDuration: Double = 0.2
    private let fadeOutDuration: Double = 0.15
    private let staggerDelay: Double = 0.01
    
    enum ScrollDirection {
        case up, down, none
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.98)
            .offset(y: isVisible ? 0 : (scrollDirection == .up ? 5 : -5))
            .animation(
                .easeOut(duration: isVisible ? fadeInDuration : fadeOutDuration)
                .delay(Double(index) * staggerDelay),
                value: isVisible
            )
            .onAppear {
                // Initial fade in with minimal delay for snappier response
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(Double(index) * staggerDelay * 1_000_000_000))
                    withAnimation(.easeOut(duration: fadeInDuration)) {
                        isVisible = true
                    }
                }
            }
            .onDisappear {
                // Fade out when disappearing
                withAnimation(.easeOut(duration: fadeOutDuration)) {
                    isVisible = false
                }
            }
            // Add scroll detection using GeometryReader
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = value
                            
                            // Determine scroll direction with much lower threshold for snappier response
                            if abs(scrollOffset - lastScrollOffset) > 2 { // Reduced threshold for immediate response
                                scrollDirection = scrollOffset > lastScrollOffset ? .up : .down
                                
                                // Apply fade animation based on scroll direction - immediate response
                                if scrollDirection == .up {
                                    // Fade in when scrolling up (items coming into view from bottom)
                                    withAnimation(.easeOut(duration: fadeInDuration).delay(Double(index) * staggerDelay)) {
                                        isVisible = true
                                    }
                                } else if scrollDirection == .down {
                                    // Fade in when scrolling down (items coming into view from top)
                                    withAnimation(.easeOut(duration: fadeInDuration).delay(Double(index) * staggerDelay)) {
                                        isVisible = true
                                    }
                                }
                            }
                            
                            lastScrollOffset = scrollOffset
                        }
                }
            )
    }
}

// MARK: - Scroll Offset Preference Key

/// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
