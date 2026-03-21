//
//  SLTrackerWidget.swift
//  SLTrackerWidget
//
//  Created by Erik on 2025-01-27.
//

import WidgetKit
import SwiftUI
import Intents

/// The data structure for widget entries
struct SLTrackerWidgetEntry: TimelineEntry, Codable {
    let date: Date
    let stationName: String?
    let departures: [Departure]?
    let errorMessage: String?
    let lastUpdated: Date
    
    init(date: Date, stationName: String?, departures: [Departure]?, errorMessage: String?) {
        self.date = date
        self.stationName = stationName
        self.departures = departures
        self.errorMessage = errorMessage
        self.lastUpdated = Date()
    }
}

/// The main widget view that displays departures for the first pinned station
struct SLTrackerWidgetEntryView: View {
    var entry: SLTrackerWidgetEntry
    
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
        .widgetURL(URL(string: "sltracker://station/\(entry.stationName?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"))
        .contentShape(Rectangle()) // Makes the entire widget tappable
    }
    
    /// View showing the departures list
    private func departuresView(departures: [Departure], stationName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with station name and refresh info
            HStack {
                Image(systemName: widgetIcon(for: departures))
                    .foregroundStyle(widgetIconColor(for: departures))
                    .font(.footnote.weight(.medium))
                
                Text(stationName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Refresh icon and timestamp
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    Text(timeString(from: entry.lastUpdated))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
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
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 20)
                .background(lineColor(for: departure))
                .clipShape(.rect(cornerRadius: 4))
            
            // Destination
            Text(departure.destination)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Time - show actual time instead of relative time
            Text(formatDepartureTime(departure.expected))
                .font(.caption.bold())
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
    
    /// View when no departures are found
    private func noDeparturesView(stationName: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tram")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("No departures")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)
            
            Text(stationName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// View when no stations are pinned
    private var noPinnedStationsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "pin")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Pin a station")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)
            
            Text("Add a favorite station in the app")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                .font(.title2)
                .foregroundStyle(.red)
            
            Text("Error: \(errorMessage)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
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
    
    /// Returns the appropriate icon based on the departures' transport modes
    private func widgetIcon(for departures: [Departure]) -> String {
        let modes = Set(departures.map { $0.line.transportMode })
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

    /// Returns the appropriate icon color based on the departures' transport modes
    private func widgetIconColor(for departures: [Departure]) -> Color {
        let modes = Set(departures.map { $0.line.transportMode })
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

    /// Converts a date to a time string for display (respects user's time format preference)
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        // Use current locale to respect user's 12/24 hour preference
        formatter.locale = Locale.current
        let timeString = formatter.string(from: date)
        return timeString
    }
    
    /// Formats departure time from API string to display time (e.g., "13:32")
    private func formatDepartureTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Stockholm")
        
        if let date = formatter.date(from: timeString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            displayFormatter.timeZone = TimeZone(identifier: "Europe/Stockholm")
            return displayFormatter.string(from: date)
        }
        
        // Fallback to original display if parsing fails
        return timeString
    }
}

/// The widget provider that supplies timeline entries
struct SLTrackerWidgetProvider: TimelineProvider {
    typealias Entry = SLTrackerWidgetEntry
    
    /// Provides a placeholder entry for when the widget is first added
    func placeholder(in context: Context) -> SLTrackerWidgetEntry {
        return SLTrackerWidgetEntry(
            date: Date(),
            stationName: "Loading...",
            departures: nil,
            errorMessage: nil
        )
    }
    
    /// Provides a snapshot entry for the widget gallery
    func getSnapshot(in context: Context, completion: @escaping (SLTrackerWidgetEntry) -> Void) {
        Task {
            let entry = await fetchWidgetData()
            completion(entry)
        }
    }
    
    /// Provides timeline entries for the widget
    func getTimeline(in context: Context, completion: @escaping (Timeline<SLTrackerWidgetEntry>) -> Void) {
        Task {
            // Fetch current data
            let entry = await fetchWidgetData()
            
            // Create a more aggressive update strategy
            var entries: [SLTrackerWidgetEntry] = [entry]
            
            // Create multiple future entries with shorter intervals
            // This helps iOS understand we want frequent updates
            let currentDate = Date()
            
            // Add entries for the next 5 minutes with 30-second intervals
            for i in 1...10 {
                if let futureDate = Calendar.current.date(byAdding: .second, value: i * 30, to: currentDate) {
                    // Create a placeholder entry that will be refreshed
                    let futureEntry = SLTrackerWidgetEntry(
                        date: futureDate,
                        stationName: entry.stationName,
                        departures: entry.departures,
                        errorMessage: entry.errorMessage
                    )
                    entries.append(futureEntry)
                }
            }
            
            // Use a very aggressive update policy for real-time feel
            // Request updates every 30 seconds, but iOS may not honor this
            let nextUpdate = Calendar.current.date(byAdding: .second, value: 30, to: currentDate) ?? currentDate
            
            let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    /// Fetches the widget data by getting the first pinned station and its departures
    private func fetchWidgetData() async -> SLTrackerWidgetEntry {
        // Use App Groups to access shared data
        let sharedDefaults = UserDefaults(suiteName: "group.com.erik.sltracker") ?? UserDefaults.standard
        
        // Check if we have cached data that's recent enough
        let lastCacheTime = sharedDefaults.double(forKey: "widgetDataLastUpdated")
        let currentTime = Date().timeIntervalSince1970
        let cacheAge = currentTime - lastCacheTime
        
        // Use cached data if it's less than 30 seconds old
        if cacheAge < 30, 
           let cachedData = sharedDefaults.data(forKey: "widgetCachedData"),
           let cachedEntry = try? JSONDecoder().decode(SLTrackerWidgetEntry.self, from: cachedData) {
            return cachedEntry
        }
        
        // Try to get pinned stations from shared UserDefaults
        var pinnedStations: [PinnedStation] = []
        
        if let data = sharedDefaults.data(forKey: "pinnedStations"),
           let stations = try? JSONDecoder().decode([PinnedStation].self, from: data) {
            pinnedStations = stations.sorted { $0.pinnedAt > $1.pinnedAt }
        }
        
        // Get the first pinned station
        guard let firstStation = pinnedStations.first else {
            let entry = SLTrackerWidgetEntry(
                date: Date(),
                stationName: nil,
                departures: nil,
                errorMessage: "No pinned stations found"
            )
            cacheWidgetData(entry)
            return entry
        }
        
        // Fetch departures for the first station
        do {
            let apiManager = APIManager.shared
            let allDepartures = try await apiManager.fetchDepartures(for: firstStation.id)
            // Sort by expected time (ISO 8601 strings sort chronologically)
            let departures = allDepartures.sorted { $0.expected < $1.expected }

            let entry = SLTrackerWidgetEntry(
                date: Date(),
                stationName: firstStation.name,
                departures: departures,
                errorMessage: nil
            )
            
            // Cache the successful result
            cacheWidgetData(entry)
            return entry
            
        } catch {
            let entry = SLTrackerWidgetEntry(
                date: Date(),
                stationName: firstStation.name,
                departures: nil,
                errorMessage: "Error loading departures"
            )
            cacheWidgetData(entry)
            return entry
        }
    }
    
    /// Caches widget data to reduce API calls
    private func cacheWidgetData(_ entry: SLTrackerWidgetEntry) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.erik.sltracker") ?? UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(entry) {
            sharedDefaults.set(data, forKey: "widgetCachedData")
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "widgetDataLastUpdated")
        }
    }
}

/// The widget bundle that contains all widget sizes
struct SLTrackerWidget: Widget {
    let kind: String = "SLTrackerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SLTrackerWidgetProvider()) { entry in
            SLTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SL Tracker")
        .description("Shows departures for your pinned stations.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
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
