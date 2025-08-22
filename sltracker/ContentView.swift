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
    @StateObject private var viewModel = DeparturesViewModel()
    
    /// The pinned stations manager
    @StateObject private var pinnedManager = PinnedStationsManager()
    
    /// Navigation state for deep linking
    @EnvironmentObject var navigationState: NavigationState
    
    /// The text the user enters for the station name
    @State private var stationName = ""
    
    /// Whether to show the station suggestions dropdown
    @State private var showingSuggestions = false
    
    /// The filtered list of station suggestions
    @State private var filteredStations: [String] = []
    
    /// Whether the search field is focused
    @FocusState private var isSearchFocused: Bool
    
    /// Whether we're in search mode (station selected)
    @State private var isSearchMode = false
    
    /// Show action sheet for pinning
    @State private var showingPinActionSheet = false
    
    /// Animation state for smooth transitions
    @State private var searchBarOffset: CGFloat = 0
    
    /// Dynamic layout measurements for responsive positioning
    @State private var headerHeight: CGFloat = 0
    @State private var searchBarHeight: CGFloat = 0
    
    /// Easter egg state variables
    @State private var showingThankYou = false
    @State private var easterEggTapCount = 0
    
    /// All available Stockholm Metro stations
    private let allStations = [
        // Core Metro Stations (served by multiple lines)
        "T-Centralen",
        
        // RED LINE (Röda linjen) - Lines 13 & 14
        // Line 13: Norsborg ↔ Ropsten
        // Line 14: Fruängen ↔ Mörby centrum
        
        // Southbound from T-Centralen (Line 13/14)
        "Gamla stan", "Slussen", "Mariatorget", "Medborgarplatsen", "Skanstull",
        "Gullmarsplan", "Skärmarbrink", "Blåsut", "Sandsborg", "Skogskyrkogården",
        "Tallkrogen", "Gubbängen", "Hökarängen", "Farsta", "Farsta strand",
        "Hammarbyhöjden", "Björkhagen", "Kärrtorp", "Bagarmossen", "Skarpnäck",
        
        // Northbound from T-Centralen (Line 13/14)
        "Östermalmstorg", "Stadion", "Tekniska högskolan", "Universitetet", "Bergshamra",
        "Danderyds sjukhus", "Mörby centrum", "Ropsten", "Gärdet", "Karlaplan",
        
        // Line 13 specific stations (Norsborg branch)
        "Norsborg", "Hallunda", "Alby", "Fittja", "Masmo", "Vårberg", "Vårby gård",
        "Aspudden", "Örnsberg", "Axelsberg", "Mälarhöjden", "Bredäng", "Sätra",
        "Skärholmen", "Vårby",
        
        // Line 14 specific stations (Fruängen branch)
        "Fruängen", "Västertorp", "Hägerstensåsen", "Telefonplan", "Midsommarkransen",
        "Globen", "Enskede gård",
        
        // GREEN LINE (Gröna linjen) - Lines 17, 18 & 19
        // Line 17: Åkeshov ↔ Skarpnäck
        // Line 18: Alvik ↔ Farsta strand
        // Line 19: Hässelby strand ↔ Hagsätra
        
        // Westbound from T-Centralen (Line 17/18/19)
        "Hässelby strand", "Hässelby gård", "Johannelund", "Vällingby", "Råcksta",
        "Blackeberg", "Islandstorget", "Ängbyplan", "Åkeshov", "Brommaplan",
        "Abrahamsberg", "Stora mossen", "Alvik", "Kristineberg", "Thorildsplan",
        "Fridhemsplan", "Odenplan", "Rådmansgatan", "Hötorget",
        
        // Line 19 specific stations (Hagsätra branch)
        "Hagsätra", "Rågsved", "Huddinge", "Flemingsberg", "Tullinge", "Tumba",
        "Rönninge", "Österhaninge", "Handen", "Vendelsö", "Trångsund", "Skogås",
        
        // BLUE LINE (Blåa linjen) - Lines 10 & 11
        // Line 10: Kungsträdgården ↔ Hjulsta
        // Line 11: Kungsträdgården ↔ Akalla
        
        // Northbound from Kungsträdgården (Line 10/11)
        "Kungsträdgården", "Rådhuset", "Stadshagen", "S:t Eriksplan", "Solnacentrum",
        "Västra skogen", "Huvudsta", "Solna strand", "Sundbybergs centrum", "Duvbo",
        "Sollentuna", "Rösersberg",
        
        // Line 10 specific stations (Hjulsta branch)
        "Hjulsta", "Tensta", "Rinkeby", "Spånga", "Sollentuna centrum",
        
        // Line 11 specific stations (Akalla branch)
        "Akalla", "Kista", "Husby", "Kungens kurva"
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background - consistent throughout app
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Main content layers with smooth transitions (iOS-standard navigation)
            switch isSearchMode {
            case false:
                // Home screen
                homeScreenView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .zIndex(0)
                    
            case true:
                // Search results screen
                searchResultsView
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
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
            if shouldNavigate, let stationName = navigationState.targetStation {
                // Navigate to the station from widget
                selectStation(stationName)
                navigationState.clearNavigationTarget()
            }
        }
        .actionSheet(isPresented: $showingPinActionSheet) {
            let currentSiteID = getCurrentSiteID()
            let isPinned = pinnedManager.isStationPinned(id: currentSiteID)
            
            return ActionSheet(
                title: Text(stationName),
                buttons: [
                    isPinned 
                        ? .destructive(Text("Unpin this station")) {
                            pinnedManager.unpinStation(id: currentSiteID)
                        }
                        : .default(Text("Pin this station")) {
                            pinnedManager.pinStation(id: currentSiteID, name: stationName)
                        },
                    .cancel()
                ]
            )
        }

    }
    
    // MARK: - View Components
    
    /// Home screen view with custom header and dynamic dropdown positioning
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
                
                // Dynamic dropdown overlay
                if showingSuggestions && !filteredStations.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 0) {
                        // Dynamic positioning with fallback values for initial state
                        let calculatedHeight = max(headerHeight + searchBarHeight + 16, 140) // Increased spacing after moving search bar
                        Spacer()
                            .frame(height: calculatedHeight)
                        
                        dropdownView
                            .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.25)))
                        
                        Spacer()
                    }
                    .zIndex(1000)
                }
            }
        }
        .onPreferenceChange(HeaderHeightPreferenceKey.self) { height in
            print("Header height measured: \(height)")
            headerHeight = height
        }
        .onPreferenceChange(SearchBarHeightPreferenceKey.self) { height in
            print("Search bar height measured: \(height)")
            searchBarHeight = height
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    /// Search results view with custom navigation
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Custom navigation bar
            customNavigationBar
            
            // Search Section with integrated dropdown
            VStack(spacing: 0) {
                searchBarSection
                
                // Dropdown appears naturally in the flow when typing
                if showingSuggestions && !filteredStations.isEmpty && !viewModel.isLoading {
                    dropdownView
                        .padding(.top, 8) // Natural spacing
                        .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.25)))
                }
            }
            
            // Content Section  
            contentSection
            
            Spacer()
        }
        .padding(.horizontal)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    /// Custom header for home screen (replaces NavigationView)
    private var homeScreenHeader: some View {
        HStack {
            Text("SL Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Refresh button for home screen
            if !viewModel.departures.isEmpty {
                Button(action: refreshDepartures) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(viewModel.isLoading ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
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
            Button(action: resetSearch) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Pin/Unpin button
                Button(action: { showingPinActionSheet = true }) {
                    Image(systemName: pinnedManager.isStationPinned(id: getCurrentSiteID()) ? "pin.fill" : "pin")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                // Refresh button with rotation animation
                Button(action: refreshDepartures) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(viewModel.isLoading ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
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
            Button(action: {
                isSearchFocused = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Search for a station", text: $stationName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isSearchFocused)
                        .onChange(of: stationName) { _, newValue in
                            updateSuggestions(for: newValue)
                        }
                        .onSubmit {
                            if let firstSuggestion = filteredStations.first {
                                selectStation(firstSuggestion)
                            }
                        }
                        .allowsHitTesting(true)
                    
                    if !stationName.isEmpty {
                        Button(action: {
                            stationName = ""
                            filteredStations = []
                            showingSuggestions = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                        .allowsHitTesting(true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSearchMode ? Color(.systemGray5) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSearchFocused ? Color.blue : (isSearchMode ? Color(.systemGray4) : Color.clear), lineWidth: isSearchMode ? 1 : 1.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Helper text removed - redundant with search field placeholder
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
                .foregroundColor(.secondary)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.9)).animation(.easeInOut(duration: 0.3)))
    }
    
    /// Error message display
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                searchDepartures()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// List of departures with smooth animations
    private var departuresList: some View {
        VStack(spacing: 0) {
            // Departures list with scroll-based animations
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.departures.enumerated()), id: \.element.id) { index, departure in
                            DepartureRowView(departure: departure)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .id(departure.id) // Ensure unique ID for scroll tracking
                                // Enhanced scroll-based fade animation
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing))
                                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05)),
                                    removal: .opacity.animation(.easeInOut(duration: 0.2))
                                ))
                                // Add scroll-based fade effect
                                .modifier(ScrollFadeModifier(index: index))
                            
                            if index < viewModel.departures.count - 1 {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                }
                .coordinateSpace(name: "scroll") // Add coordinate space for scroll tracking
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.35)))
    }
    
    /// No departures found message
    private var noDeparturesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No departures found")
                .font(.headline)
            
            Text("No metro departures found for \(viewModel.currentStation). Try a different station or check the station name.")
                .font(.body)
                .foregroundColor(.secondary)
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
                        .foregroundColor(.blue)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: UUID())
                    
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
                ForEach(Array(pinnedManager.pinnedStations.enumerated()), id: \.element.id) { index, station in
                    PinnedStationRow(
                        station: station,
                        onTap: { selectPinnedStation(station) },
                        onUnpin: { pinnedManager.unpinStation(id: station.id) }
                    )
                    
                    if index < pinnedManager.pinnedStations.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    /// Footer section
    private var footerSection: some View {
        Text("Lovingly made by Erik in Stockholm ❤️‍🔥")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.bottom, 20)
            .contentShape(Rectangle())
            .onTapGesture {
                triggerEasterEgg()
            }
    }
    
    /// Dropdown view that follows SwiftUI's natural layout
    private var dropdownView: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredStations.enumerated()), id: \.element) { index, station in
                Button(action: {
                    // Add haptic feedback for better UX
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    selectStation(station)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "tram.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(station)
                            .foregroundColor(.primary)
                            .font(.system(size: 16))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                            .animation(.easeInOut(duration: 0.15), value: isSearchFocused)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                // Staggered animation for each item
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).animation(.easeInOut(duration: 0.2).delay(Double(index) * 0.03)),
                    removal: .opacity.animation(.easeInOut(duration: 0.15))
                ))
                
                if station != filteredStations.last {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 32) // Match search bar's total padding (16 + 16)
        .scaleEffect(showingSuggestions ? 1.0 : 0.95)
        }
    
    // MARK: - Actions
    
    /// Updates the station suggestions based on user input
    private func updateSuggestions(for input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if trimmedInput.isEmpty {
            filteredStations = []
            showingSuggestions = false
        } else {
            // Filter stations that contain the input (case-insensitive)
            filteredStations = allStations.filter { station in
                station.lowercased().contains(trimmedInput)
            }
            
            // Limit to first 8 suggestions for better UX
            filteredStations = Array(filteredStations.prefix(8))
            
            // Show suggestions if we have matches
            showingSuggestions = !filteredStations.isEmpty
        }
    }
    
    /// Selects a station and transitions to search mode
    private func selectStation(_ station: String) {
        // COMPLETELY clear all dropdown state
        clearDropdownState()
        
        // Set the station name
        stationName = station
        
        // Animate to search mode with beautiful Macadamia-style transition
        withAnimation(.easeInOut(duration: 0.35)) {
            isSearchMode = true
        }
        
        // Search for departures with slight delay for smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            searchDepartures()
        }
    }
    
    /// Selects a pinned station
    private func selectPinnedStation(_ station: PinnedStation) {
        clearDropdownState()
        stationName = station.name
        
        withAnimation(.easeInOut(duration: 0.35)) {
            isSearchMode = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            searchDepartures()
        }
    }
    
    /// Completely clears all dropdown-related state
    private func clearDropdownState() {
        isSearchFocused = false
        showingSuggestions = false
        filteredStations = []
    }
    
    /// Gets the current site ID for the selected station
    private func getCurrentSiteID() -> String {
        return APIManager.shared.getSiteID(for: stationName)
    }
    
    /// Searches for departures using the entered station name
    private func searchDepartures() {
        let trimmedName = stationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Ensure dropdown is completely cleared
        clearDropdownState()
        
        viewModel.fetchDepartures(for: trimmedName)
    }
    
    /// Resets the search and returns to initial state
    private func resetSearch() {
        clearDropdownState()
        
        withAnimation(.easeInOut(duration: 0.35)) {
            isSearchMode = false
            stationName = ""
            viewModel.clearDepartures()
        }
    }
    
    /// Refreshes the current departures by calling the API again
    private func refreshDepartures() {
        guard !viewModel.currentStation.isEmpty else { return }
        viewModel.fetchDepartures(for: viewModel.currentStation)
    }
    
    /// Triggers the easter egg (requires 3 taps)
    private func triggerEasterEgg() {
        easterEggTapCount += 1
        
        // Reset tap count after 3 seconds if not completed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
                // Station icon with line color if available
                Image(systemName: "tram.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                // Station name
                Text(station.name)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 28)
                    .background(lineColor(for: departure.line.designation))
                    .cornerRadius(8)
                    .shadow(color: lineColor(for: departure.line.designation).opacity(0.3), radius: 4, x: 0, y: 2)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                
                Text(departure.destination)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .opacity(isVisible ? 1.0 : 0.0)
            }
            
            Spacer()
            
            // Departure time with pulse animation for urgent departures
            VStack(alignment: .trailing, spacing: 4) {
                Text(departure.display)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(departure.display.contains("Nu") || departure.display.contains("min") ? .orange : .blue)
                    .scaleEffect(departure.display.contains("Nu") ? (isVisible ? 1.1 : 1.0) : 1.0)
                    .opacity(isVisible ? 1.0 : 0.0)
                
                Text("Platform \(departure.stopPoint.designation ?? "N/A")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(isVisible ? 1.0 : 0.0)
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
    
    /// Returns the appropriate color for each metro line
    private func lineColor(for lineNumber: String) -> Color {
        switch lineNumber {
        case "13", "14":
            return Color.red // Red line
        case "17", "18", "19":
            return Color.green // Green line
        case "10", "11":
            return Color.blue // Blue line
        default:
            return Color.gray // Default for unknown lines
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        // Convert ISO time string to readable format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: timeString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            return displayFormatter.string(from: date)
        }
        
        return timeString
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

// MARK: - Easter Egg Views

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
                            .foregroundColor(.primary)
                        
                        // Simple subtitle
                        Text("This app is dedicated to Johanna, and my friends Alex, Nick, and Elin from Katerina Ol Cafe. The best bar in Stockholm.")
                            .font(.body)
                            .foregroundColor(.secondary)
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
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 80)
            }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * staggerDelay) {
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
