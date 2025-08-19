//
//  DeparturesViewModel.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation

/// Manages the state and business logic for metro departures
@MainActor
class DeparturesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The list of metro departures to display
    @Published var departures: [Departure] = []
    
    /// Whether the app is currently loading data
    @Published var isLoading = false
    
    /// Any error message to display to the user
    @Published var errorMessage: String?
    
    /// The current station name being displayed
    @Published var currentStation = ""
    
    // MARK: - Private Properties
    
    /// The API manager for making network requests
    private let apiManager = APIManager()
    
    // MARK: - Public Methods
    
    /// Fetches metro departures for a specific station
    /// - Parameter stationName: The name of the station to get departures for
    func fetchDepartures(for stationName: String) {
        // Clear any previous errors
        errorMessage = nil
        
        // Set loading state
        isLoading = true
        
        // Update the current station
        currentStation = stationName
        
        // Use Task to handle the async API call
        Task {
            do {
                // Fetch departures from the API
                let fetchedDepartures = try await apiManager.fetchMetroDepartures(for: stationName)
                
                // Filter out departures that are already in the past
                let now = Date()
                let futureDepartures = fetchedDepartures.filter { dep in
                    parseDate(from: dep.expected) >= now
                }

                // Sort departures by expected time (earliest first)
                let sortedDepartures = futureDepartures.sorted { departure1, departure2 in
                    // Convert string dates to Date objects for comparison
                    let date1 = parseDate(from: departure1.expected)
                    let date2 = parseDate(from: departure2.expected)
                    return date1 < date2
                }
                
                // Update the departures on the main thread
                departures = sortedDepartures
                
            } catch {
                // Handle any errors that occurred
                handleError(error)
            }
            
            // Stop loading
            isLoading = false
        }
    }
    
    /// Clears all departures and resets the state
    func clearDepartures() {
        departures = []
        currentStation = ""
        errorMessage = nil
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
        
        // Clear departures when there's an error
        departures = []
    }
    
    /// Converts a date string from the API to a Date object
    /// - Parameter dateString: The date string from the API (format: "2024-01-01T12:00:00")
    /// - Returns: A Date object, or current date if parsing fails
    private func parseDate(from dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Stockholm")
        
        return formatter.date(from: dateString) ?? Date()
    }
}
