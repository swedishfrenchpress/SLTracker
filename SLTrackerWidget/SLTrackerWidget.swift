//
//  SLTrackerWidget.swift
//  SLTrackerWidget
//
//  Created by Erik on 2025-01-27.
//

import WidgetKit
import SwiftUI

/// The data structure for widget entries
struct SLTrackerWidgetEntry: TimelineEntry {
    let date: Date
    let stationName: String?
    let departures: [Departure]?
    let errorMessage: String?
    
    init(date: Date, stationName: String?, departures: [Departure]?, errorMessage: String?) {
        self.date = date
        self.stationName = stationName
        self.departures = departures
        self.errorMessage = errorMessage
        print("🔍 Widget: SLTrackerWidgetEntry created - station: \(stationName ?? "nil"), departures: \(departures?.count ?? 0), error: \(errorMessage ?? "nil")")
    }
}

/// The main widget view that displays departures for the first pinned station
struct SLTrackerWidgetEntryView: View {
    var entry: SLTrackerWidgetEntry
    
    init(entry: SLTrackerWidgetEntry) {
        self.entry = entry
        print("🔍 Widget: SLTrackerWidgetEntryView initialized with entry: \(entry)")
    }
    
    var body: some View {
        ZStack {
            // Use the modern containerBackground API for iOS 17+
            if #available(iOS 17.0, *) {
                // Modern background approach
                Color.clear
                    .containerBackground(.background, for: .widget)
            } else {
                // Fallback for older iOS versions
                Color(.systemBackground)
            }
            
            if let departures = entry.departures, !departures.isEmpty, let stationName = entry.stationName {
                // Show departures
                departuresView(departures: departures, stationName: stationName)
            } else if let stationName = entry.stationName {
                // Station exists but no departures
                noDeparturesView(stationName: stationName)
            } else if let errorMessage = entry.errorMessage {
                // Show error message for debugging
                errorView(errorMessage: errorMessage)
            } else {
                // No pinned stations
                noPinnedStationsView
            }
        }
        .onAppear {
            print("🔍 Widget: SLTrackerWidgetEntryView appeared")
        }
    }
    
    /// View showing the departures list
    private func departuresView(departures: [Departure], stationName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with station name
            HStack {
                Image(systemName: "tram.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14, weight: .medium))
                
                Text(stationName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Departures list
            VStack(spacing: 4) {
                ForEach(Array(departures.prefix(3).enumerated()), id: \.element.id) { index, departure in
                    departureRow(departure: departure)
                    
                    if index < min(departures.count, 3) - 1 {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    /// Individual departure row
    private func departureRow(departure: Departure) -> some View {
        HStack(spacing: 8) {
            // Line number
            Text(departure.line.designation)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 20)
                .background(lineColor(for: departure.line.designation))
                .cornerRadius(4)
            
            // Destination
            Text(departure.destination)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Time
            Text(departure.display)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(departure.display.contains("Nu") || departure.display.contains("min") ? .orange : .blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
    
    /// View when no departures are found
    private func noDeparturesView(stationName: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tram")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text("No departures")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Text(stationName)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// View when no stations are pinned
    private var noPinnedStationsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "pin")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text("Pin a station")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Add a favorite station in the app")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
    }
    
    /// View for displaying error messages
    private func errorView(errorMessage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)
            
            Text("Error: \(errorMessage)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
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
}

/// The widget provider that supplies timeline entries
struct SLTrackerWidgetProvider: TimelineProvider {
    typealias Entry = SLTrackerWidgetEntry
    
    init() {
        print("🔍 Widget: SLTrackerWidgetProvider initialized")
    }
    
    /// Provides a placeholder entry for when the widget is first added
    func placeholder(in context: Context) -> SLTrackerWidgetEntry {
        print("🔍 Widget: Providing placeholder entry")
        return SLTrackerWidgetEntry(
            date: Date(),
            stationName: "Loading...",
            departures: nil,
            errorMessage: nil
        )
    }
    
    /// Provides a snapshot entry for the widget gallery
    func getSnapshot(in context: Context, completion: @escaping (SLTrackerWidgetEntry) -> Void) {
        print("🔍 Widget: Getting snapshot entry")
        Task {
            let entry = await fetchWidgetData()
            completion(entry)
        }
    }
    
    /// Provides timeline entries for the widget
    func getTimeline(in context: Context, completion: @escaping (Timeline<SLTrackerWidgetEntry>) -> Void) {
        print("🔍 Widget: Getting timeline entries")
        Task {
            let entry = await fetchWidgetData()
            
            // Update every 5 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            print("🔍 Widget: Timeline created with next update at \(nextUpdate)")
            completion(timeline)
        }
    }
    
    /// Fetches the widget data by getting the first pinned station and its departures
    private func fetchWidgetData() async -> SLTrackerWidgetEntry {
        print("🔍 Widget: Starting to fetch widget data...")
        
        // Use App Groups to access shared data
        let sharedDefaults = UserDefaults(suiteName: "group.com.erik.sltracker") ?? UserDefaults.standard
        
        // Try to get pinned stations from shared UserDefaults
        var pinnedStations: [PinnedStation] = []
        
        if let data = sharedDefaults.data(forKey: "pinnedStations"),
           let stations = try? JSONDecoder().decode([PinnedStation].self, from: data) {
            pinnedStations = stations.sorted { $0.pinnedAt > $1.pinnedAt }
            print("✅ Widget: Found \(pinnedStations.count) pinned stations in UserDefaults")
            for station in pinnedStations {
                print("   - \(station.name) (ID: \(station.id))")
            }
        } else {
            print("❌ Widget: No pinned stations found in UserDefaults")
        }
        
        // Get the first pinned station
        guard let firstStation = pinnedStations.first else {
            print("❌ Widget: No pinned stations available")
            return SLTrackerWidgetEntry(
                date: Date(),
                stationName: nil,
                departures: nil,
                errorMessage: "No pinned stations found"
            )
        }
        
        print("✅ Widget: Using first pinned station: \(firstStation.name)")
        
        // Fetch departures for the first station
        do {
            let apiManager = APIManager.shared
            let departures = try await apiManager.fetchMetroDepartures(for: firstStation.name)
            
            print("✅ Widget: Fetched \(departures.count) departures for \(firstStation.name)")
            
            return SLTrackerWidgetEntry(
                date: Date(),
                stationName: firstStation.name,
                departures: departures,
                errorMessage: nil
            )
        } catch {
            print("❌ Widget: Error fetching departures: \(error)")
            return SLTrackerWidgetEntry(
                date: Date(),
                stationName: firstStation.name,
                departures: nil,
                errorMessage: "Error loading departures"
            )
        }
    }
}

/// The widget bundle that contains all widget sizes
struct SLTrackerWidget: Widget {
    let kind: String = "SLTrackerWidget"
    
    init() {
        print("🔍 Widget: SLTrackerWidget initialized")
    }
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SLTrackerWidgetProvider()) { entry in
            SLTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SL Tracker")
        .description("Shows departures for your pinned stations.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Preview provider for the widget
struct SLTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        SLTrackerWidgetEntryView(entry: SLTrackerWidgetEntry(
            date: Date(),
            stationName: "T-Centralen",
            departures: [
                // Sample departure data for preview
                Departure(
                    direction: "North",
                    directionCode: 1,
                    destination: "T-Centralen",
                    state: "ON_TIME",
                    scheduled: "2025-01-27T10:00:00",
                    expected: "2025-01-27T10:00:00",
                    display: "2 min",
                    journey: Journey(id: 1, state: "ON_TIME", predictionState: "ON_TIME"),
                    stopArea: StopArea(id: 1, name: "T-Centralen", type: "METRO"),
                    stopPoint: StopPoint(id: 1, name: "T-Centralen", designation: "1"),
                    line: Line(id: 1, designation: "13", transportAuthorityId: 1, transportMode: "METRO", groupOfLines: "Red"),
                    deviations: nil
                )
            ],
            errorMessage: nil
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
