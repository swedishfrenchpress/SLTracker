//
//  SharedModels.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation
import WidgetKit

// MARK: - API Response Models (Shared between app and widget)

/// The main response structure from the SL Transport API
struct DeparturesResponse: Codable {
    let departures: [Departure]
    let stopDeviations: [StopDeviation]?
    
    enum CodingKeys: String, CodingKey {
        case departures
        case stopDeviations = "stop_deviations"
    }
}

/// Represents a single departure
struct Departure: Codable, Identifiable {
    let id = UUID() // Unique identifier for SwiftUI lists
    let direction: String
    let directionCode: Int
    let destination: String
    let state: String
    let scheduled: String
    let expected: String
    let display: String
    let journey: Journey
    let stopArea: StopArea
    let stopPoint: StopPoint
    let line: Line
    let deviations: [Deviation]?
    
    enum CodingKeys: String, CodingKey {
        case direction
        case directionCode = "direction_code"
        case destination
        case state
        case scheduled
        case expected
        case display
        case journey
        case stopArea = "stop_area"
        case stopPoint = "stop_point"
        case line
        case deviations
    }
}

/// Journey information
struct Journey: Codable {
    let id: Int
    let state: String
    let predictionState: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case state
        case predictionState = "prediction_state"
    }
}

/// Stop area information
struct StopArea: Codable {
    let id: Int
    let name: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
    }
}

/// Stop point information
struct StopPoint: Codable {
    let id: Int
    let name: String
    let designation: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case designation
    }
}

/// Line information
struct Line: Codable {
    let id: Int
    let designation: String
    let transportAuthorityId: Int
    let transportMode: String
    let groupOfLines: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case designation
        case transportAuthorityId = "transport_authority_id"
        case transportMode = "transport_mode"
        case groupOfLines = "group_of_lines"
    }
}

/// Deviation information
struct Deviation: Codable {
    let importanceLevel: Int
    let consequence: String?
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case importanceLevel = "importance_level"
        case consequence
        case message
    }
}

/// Stop deviation information
struct StopDeviation: Codable {
    let id: Int?
    let importanceLevel: Int
    let message: String
    let scope: DeviationScope?
    
    enum CodingKeys: String, CodingKey {
        case id
        case importanceLevel = "importance_level"
        case message
        case scope
    }
}

/// Deviation scope information
struct DeviationScope: Codable {
    let lines: [Line]?
    let stopAreas: [StopArea]?
    let stopPoints: [StopPoint]?
    
    enum CodingKeys: String, CodingKey {
        case lines
        case stopAreas = "stop_areas"
        case stopPoints = "stop_points"
    }
}

// MARK: - Pinned Station Models (Shared between app and widget)

/// Represents a pinned/favorited station
struct PinnedStation: Codable, Identifiable, Equatable {
    let id: String // Site ID from API
    let name: String
    let pinnedAt: Date
    var transportModes: [String]

    init(id: String, name: String, transportModes: [String] = ["METRO"]) {
        self.id = id
        self.name = name
        self.pinnedAt = Date()
        self.transportModes = transportModes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        pinnedAt = try container.decode(Date.self, forKey: .pinnedAt)
        transportModes = try container.decodeIfPresent([String].self, forKey: .transportModes) ?? ["METRO"]
    }
}

/// Manager for handling pinned stations with persistence
@MainActor
@Observable
final class PinnedStationsManager {
    var pinnedStations: [PinnedStation] = []
    
    private let maxPinnedStations = 8
    private let storageKey = "pinnedStations"
    
    // Use App Groups to share data between app and widget
    private var userDefaults: UserDefaults {
        // Try to use App Group first, fallback to standard UserDefaults
        if let groupDefaults = UserDefaults(suiteName: "group.com.erik.sltracker") {
            return groupDefaults
        }
        return UserDefaults.standard
    }
    
    init() {
        loadPinnedStations()
    }
    
    /// Load pinned stations from UserDefaults
    private func loadPinnedStations() {
        if let data = userDefaults.data(forKey: storageKey),
           let stations = try? JSONDecoder().decode([PinnedStation].self, from: data) {
            pinnedStations = stations.sorted { $0.pinnedAt > $1.pinnedAt }
        }
    }
    
    /// Save pinned stations to UserDefaults
    private func savePinnedStations() {
        if let data = try? JSONEncoder().encode(pinnedStations) {
            userDefaults.set(data, forKey: storageKey)
            
            // Add a timestamp to force widget refresh
            userDefaults.set(Date().timeIntervalSince1970, forKey: "pinnedStationsLastUpdated")
            
            // Trigger widget refresh when pinned stations change
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// Check if a station is pinned
    func isStationPinned(id: String) -> Bool {
        pinnedStations.contains { $0.id == id }
    }
    
    /// Pin a station
    func pinStation(id: String, name: String, transportModes: [String] = ["METRO"]) {
        // Don't pin if already pinned
        guard !isStationPinned(id: id) else { return }

        let newStation = PinnedStation(id: id, name: name, transportModes: transportModes)
        pinnedStations.insert(newStation, at: 0)
        
        // Remove oldest if over limit
        if pinnedStations.count > maxPinnedStations {
            pinnedStations.removeLast()
        }
        
        savePinnedStations()
    }
    
    /// Unpin a station
    func unpinStation(id: String) {
        pinnedStations.removeAll { $0.id == id }
        savePinnedStations()
    }
    
    /// Toggle pin status
    func togglePin(id: String, name: String, transportModes: [String] = ["METRO"]) {
        if isStationPinned(id: id) {
            unpinStation(id: id)
        } else {
            pinStation(id: id, name: name, transportModes: transportModes)
        }
    }
}

// MARK: - API Manager (Shared between app and widget)

/// Manages all API calls to the Stockholm Transport API
final class APIManager {
    
    /// Shared singleton instance
    static let shared = APIManager()
    
    // MARK: - Properties
    
    /// The base URL for the SL Transport API
    private let baseURL = "https://transport.integration.sl.se/v1"
    

    /// Fetches all departures for a specific site
    func fetchDepartures(for siteID: String) async throws -> [Departure] {
        let urlString = "\(baseURL)/sites/\(siteID)/departures"
        var components = URLComponents(string: urlString)
        components?.queryItems = [
            URLQueryItem(name: "forecast", value: "480")
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let departuresResponse = try JSONDecoder().decode(DeparturesResponse.self, from: data)
        return departuresResponse.departures
    }
}

// MARK: - Error Types

/// Custom error types for API-related errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError
    case apiError(message: String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network connection failed"
        case .apiError(let message):
            return "API Error: \(message)"
        case .decodingError:
            return "Failed to process server response"
        }
    }
}
