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

    /// Derives an entry at a new timeline `date` while preserving the original
    /// `lastUpdated` — used to fan one fetch into several boundary entries and to
    /// keep the true "updated" time when serving stale data after a failure.
    init(date: Date, stationName: String?, departures: [Departure]?, errorMessage: String?, lastUpdated: Date) {
        self.date = date
        self.stationName = stationName
        self.departures = departures
        self.errorMessage = errorMessage
        self.lastUpdated = lastUpdated
    }
}

extension SLTrackerWidgetEntry {
    /// Static sample for the placeholder and the widget gallery — renders instantly,
    /// no network round-trip.
    static var sample: SLTrackerWidgetEntry {
        SLTrackerWidgetEntry(
            date: Date(),
            stationName: "T-Centralen",
            departures: [
                Departure(
                    direction: "North", directionCode: 1, destination: "Mörby centrum",
                    state: "EXPECTED", scheduled: "2025-01-27T10:00:00", expected: "2025-01-27T10:00:00",
                    display: "2 min", journey: Journey(id: 1, state: "EXPECTED", predictionState: "NORMAL"),
                    stopArea: StopArea(id: 1, name: "T-Centralen", type: "METROSTN"),
                    stopPoint: StopPoint(id: 1, name: "T-Centralen", designation: "1"),
                    line: Line(id: 1, designation: "14", transportAuthorityId: 1, transportMode: "METRO", groupOfLines: "Röda linjen"),
                    deviations: nil
                ),
                Departure(
                    direction: "South", directionCode: 2, destination: "Fruängen",
                    state: "EXPECTED", scheduled: "2025-01-27T10:05:00", expected: "2025-01-27T10:05:00",
                    display: "7 min", journey: Journey(id: 2, state: "EXPECTED", predictionState: "NORMAL"),
                    stopArea: StopArea(id: 1, name: "T-Centralen", type: "METROSTN"),
                    stopPoint: StopPoint(id: 2, name: "T-Centralen", designation: "2"),
                    line: Line(id: 2, designation: "14", transportAuthorityId: 1, transportMode: "METRO", groupOfLines: "Röda linjen"),
                    deviations: nil
                )
            ],
            errorMessage: nil
        )
    }
}

/// The main widget view that displays departures for the first pinned station
struct SLTrackerWidgetEntryView: View {
    var entry: SLTrackerWidgetEntry

    /// Departures still in the future relative to this entry's date. Because the
    /// timeline carries one entry per departure boundary, trains that have already
    /// left drop off as the clock advances — without waiting for a network reload.
    private var upcomingDepartures: [Departure]? {
        guard let departures = entry.departures else { return nil }
        // Strict `>` so a train drops off exactly at its departure time and the next
        // fetched departure slides up into view, rather than lingering until the
        // following train's boundary.
        return departures.filter { widgetParseDate($0.expected) > entry.date }
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
            
            if let departures = upcomingDepartures, !departures.isEmpty, let stationName = entry.stationName {
                // Show departures still ahead of this entry's moment
                departuresView(departures: departures, stationName: stationName)
            } else if entry.errorMessage != nil {
                // Load failed with no cached departures to fall back on. Check this
                // BEFORE the station branch so a network blip reads as "couldn't
                // refresh", not a misleading "no departures".
                errorView(stationName: entry.stationName)
            } else if let stationName = entry.stationName {
                // Station loaded, but genuinely nothing upcoming
                noDeparturesView(stationName: stationName)
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
        let primaryMode = slPrimaryMode(from: Set(departures.map { $0.line.transportMode }))
        return VStack(alignment: .leading, spacing: 8) {
            // Header with station name and refresh info
            HStack {
                Image(systemName: primaryMode.icon)
                    .foregroundStyle(primaryMode.tint)
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 24, height: 20)
                .background(slLineBadgeColor(mode: departure.line.transportMode, designation: departure.line.designation))
                .clipShape(.rect(cornerRadius: 4))

            // Destination
            Text(departure.destination)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            // Time - show actual clock time; tint urgent when leaving now
            Text(formatDepartureTime(departure.expected))
                .font(.caption.bold())
                .foregroundStyle(slIsImminent(expected: departure.expected, now: entry.date) ? .orange : .slAccent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Line \(departure.line.designation) to \(departure.destination), departs \(formatDepartureTime(departure.expected))")
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
    
    /// Calm fallback shown when a load fails with no cached departures to fall
    /// back on. Mirrors the app's calm error tone — secondary, no red, no "Error:".
    private func errorView(stationName: String?) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Couldn't refresh")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)

            if let stationName {
                Text(stationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
    }
    
    // MARK: - Static Formatters

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        f.locale = Locale.current
        return f
    }()

    private static let apiDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.timeZone = TimeZone(identifier: "Europe/Stockholm")
        return f
    }()

    private static let displayTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Europe/Stockholm")
        return f
    }()

    private func timeString(from date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    private func formatDepartureTime(_ timeString: String) -> String {
        if let date = Self.apiDateFormatter.date(from: timeString) {
            return Self.displayTimeFormatter.string(from: date)
        }
        return timeString
    }
}

/// Shared, read-only formatter for the provider's date math. Safe to read across tasks.
private let widgetAPIDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.timeZone = TimeZone(identifier: "Europe/Stockholm")
    return formatter
}()

private func widgetParseDate(_ dateString: String) -> Date {
    // Unparseable times sort to the past so a malformed departure is dropped by the
    // `>= now` / `>= entry.date` filters, rather than shown with a garbage clock
    // value or jumping to the front as if imminent.
    widgetAPIDateFormatter.date(from: dateString) ?? .distantPast
}

/// The widget provider that supplies timeline entries
struct SLTrackerWidgetProvider: TimelineProvider {
    typealias Entry = SLTrackerWidgetEntry
    
    /// Provides a placeholder entry for when the widget is first added
    func placeholder(in context: Context) -> SLTrackerWidgetEntry {
        return .sample
    }

    /// Provides a snapshot entry for the widget gallery
    func getSnapshot(in context: Context, completion: @escaping (SLTrackerWidgetEntry) -> Void) {
        // The gallery/preview should render instantly without a network round-trip.
        if context.isPreview {
            completion(.sample)
            return
        }
        Task {
            let entry = await fetchWidgetData()
            completion(entry)
        }
    }
    
    /// Provides timeline entries for the widget
    func getTimeline(in context: Context, completion: @escaping (Timeline<SLTrackerWidgetEntry>) -> Void) {
        Task {
            let base = await fetchWidgetData()

            // Fan the single fetch into one entry per upcoming departure boundary so
            // a train drops off exactly when it leaves — even before iOS grants the
            // next network reload.
            let entries = timelineEntries(from: base)

            // Request a data refresh in ~15 min; iOS throttles the real cadence.
            // The app also calls WidgetCenter.shared.reloadAllTimelines() on changes.
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    /// Builds timeline entries at each upcoming departure boundary (capped) so the
    /// view can re-filter departed trains as the clock advances, without a reload.
    /// Preserves the base entry's `lastUpdated` so the "updated" time stays truthful.
    private func timelineEntries(from base: SLTrackerWidgetEntry) -> [SLTrackerWidgetEntry] {
        guard let departures = base.departures, !departures.isEmpty else {
            return [base]
        }
        let now = Date()
        var boundaries: [Date] = [now]
        for departure in departures {
            let time = widgetParseDate(departure.expected)
            if time > now, time != boundaries.last {
                boundaries.append(time)
            }
        }
        return boundaries.prefix(30).map { boundary in
            SLTrackerWidgetEntry(
                date: boundary,
                stationName: base.stationName,
                departures: base.departures,
                errorMessage: base.errorMessage,
                lastUpdated: base.lastUpdated
            )
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
            // Leave stationName and errorMessage nil so the view routes to the
            // friendly "Pin a station" empty state rather than a dev-facing error.
            let entry = SLTrackerWidgetEntry(
                date: Date(),
                stationName: nil,
                departures: nil,
                errorMessage: nil
            )
            cacheWidgetData(entry)
            return entry
        }
        
        // Fetch departures for the first station and all related sub-stations
        do {
            let apiManager = APIManager.shared
            let idsToFetch = firstStation.relatedSiteIDs.isEmpty ? [firstStation.id] : firstStation.relatedSiteIDs

            let allDepartures = try await withThrowingTaskGroup(of: [Departure].self) { group in
                for id in idsToFetch {
                    group.addTask {
                        try await apiManager.fetchDepartures(for: id)
                    }
                }
                var merged: [Departure] = []
                for try await batch in group {
                    merged.append(contentsOf: batch)
                }
                return merged
            }

            // Drop past departures, deduplicate by journey ID, and sort
            // chronologically — mirroring the app so the widget never shows
            // trains that have already left.
            let now = Date()
            var seenJourneys = Set<Int>()
            let departures = allDepartures
                .filter { widgetParseDate($0.expected) >= now }
                .filter { seenJourneys.insert($0.journey.id).inserted }
                .sorted { widgetParseDate($0.expected) < widgetParseDate($1.expected) }

            // Apply the user's widget transit-mode filter (nil/empty = show all)
            let enabledModes = sharedDefaults.stringArray(forKey: "widgetTransportModes")
            let visibleDepartures: [Departure]
            if let enabledModes, !enabledModes.isEmpty {
                visibleDepartures = departures.filter { enabledModes.contains($0.line.transportMode) }
            } else {
                visibleDepartures = departures
            }

            let entry = SLTrackerWidgetEntry(
                date: Date(),
                stationName: firstStation.name,
                departures: visibleDepartures,
                errorMessage: nil
            )
            
            // Cache the successful result
            cacheWidgetData(entry)
            return entry
            
        } catch {
            // Don't let one network blip wipe the widget: keep serving the last good
            // departures (their original "updated" time stays as a staleness cue) and
            // do NOT overwrite the good cache with this failure.
            if let cachedData = sharedDefaults.data(forKey: "widgetCachedData"),
               let cachedEntry = try? JSONDecoder().decode(SLTrackerWidgetEntry.self, from: cachedData),
               let cachedDepartures = cachedEntry.departures, !cachedDepartures.isEmpty {
                return cachedEntry
            }
            return SLTrackerWidgetEntry(
                date: Date(),
                stationName: firstStation.name,
                departures: nil,
                errorMessage: "Error loading departures"
            )
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
