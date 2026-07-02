//
//  DeparturesViewModel.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation
import WidgetKit

/// Manages the state and business logic for metro departures
@MainActor
@Observable
final class DeparturesViewModel {
    
    // MARK: - Properties
    
    /// The list of metro departures to display
    var departures: [Departure] = []
    
    /// Whether the app is currently loading data
    var isLoading = false
    
    /// Any error message to display to the user
    var errorMessage: String?
    
    /// The current station name being displayed
    var currentStation = ""

    /// The current site ID being displayed
    var currentSiteID = ""

    /// When departures were last successfully refreshed
    var lastUpdated: Date?

    // MARK: - Private Properties

    /// The API manager for making network requests
    private let apiManager = APIManager()

    // MARK: - Public Methods

    /// Fetches all departures for a station and its related sub-stations
    func fetchDepartures(for siteID: String, stationName: String) {
        Task { await performFetch(for: siteID, stationName: stationName) }
    }

    /// Awaitable variant for pull-to-refresh — the caller's spinner stays until the
    /// fetch actually completes.
    func fetchDepartures(for siteID: String, stationName: String) async {
        await performFetch(for: siteID, stationName: stationName)
    }

    /// Shared fetch implementation used by both the fire-and-forget and awaitable entry points.
    private func performFetch(for siteID: String, stationName: String) async {
        errorMessage = nil
        isLoading = true
        currentStation = stationName
        currentSiteID = siteID

        // Get all related site IDs (e.g., Slussen, Slussen/Stadsgården, etc.)
        let allIDs = SiteStore.shared.relatedSiteIDs(for: stationName)
        let idsToFetch = allIDs.isEmpty ? [siteID] : allIDs

        do {
            // Fetch departures from all related stations in parallel
            let allDepartures = try await withThrowingTaskGroup(of: [Departure].self) { group in
                for id in idsToFetch {
                    group.addTask { [apiManager] in
                        try await apiManager.fetchDepartures(for: id)
                    }
                }

                var merged: [Departure] = []
                for try await batch in group {
                    merged.append(contentsOf: batch)
                }
                return merged
            }

            // Filter out past departures and deduplicate by journey ID
            let now = Date()
            var seenJourneys = Set<Int>()
            let futureDepartures = allDepartures.filter { dep in
                guard parseDate(from: dep.expected) >= now else { return false }
                guard seenJourneys.insert(dep.journey.id).inserted else { return false }
                return true
            }

            // Sort by expected time
            departures = futureDepartures.sorted {
                parseDate(from: $0.expected) < parseDate(from: $1.expected)
            }

            lastUpdated = Date()
            WidgetCenter.shared.reloadAllTimelines()

        } catch {
            handleError(error)
        }

        isLoading = false
    }
    
    /// Clears all departures and resets the state
    func clearDepartures() {
        departures = []
        currentStation = ""
        errorMessage = nil
        lastUpdated = nil
    }
    
    // MARK: - Private Methods
    
    /// Handles errors by converting them to user-friendly messages
    /// - Parameter error: The error that occurred
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        // Keep existing departures so user still sees previous data with error banner
    }
    
    /// Reusable date formatter for API date strings
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Stockholm")
        return formatter
    }()

    /// Converts a date string from the API to a Date object
    /// - Parameter dateString: The date string from the API (format: "2024-01-01T12:00:00")
    /// - Returns: A Date object, or current date if parsing fails
    private func parseDate(from dateString: String) -> Date {
        Self.dateFormatter.date(from: dateString) ?? Date()
    }
}
