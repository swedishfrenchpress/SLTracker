//
//  SharedModels.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation

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
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
        self.pinnedAt = Date()
    }
}

/// Manager for handling pinned stations with persistence
@MainActor
class PinnedStationsManager: ObservableObject {
    @Published var pinnedStations: [PinnedStation] = []
    
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
        }
    }
    
    /// Check if a station is pinned
    func isStationPinned(id: String) -> Bool {
        pinnedStations.contains { $0.id == id }
    }
    
    /// Pin a station
    func pinStation(id: String, name: String) {
        print("📌 PinnedStationsManager: Attempting to pin station '\(name)' (ID: \(id))")
        
        // Don't pin if already pinned
        guard !isStationPinned(id: id) else { 
            print("⚠️ PinnedStationsManager: Station '\(name)' is already pinned")
            return 
        }
        
        let newStation = PinnedStation(id: id, name: name)
        pinnedStations.insert(newStation, at: 0)
        
        // Remove oldest if over limit
        if pinnedStations.count > maxPinnedStations {
            pinnedStations.removeLast()
        }
        
        print("✅ PinnedStationsManager: Successfully pinned '\(name)'. Total stations: \(pinnedStations.count)")
        savePinnedStations()
    }
    
    /// Unpin a station
    func unpinStation(id: String) {
        print("📌 PinnedStationsManager: Attempting to unpin station with ID: \(id)")
        
        let beforeCount = pinnedStations.count
        pinnedStations.removeAll { $0.id == id }
        let afterCount = pinnedStations.count
        
        if beforeCount != afterCount {
            print("✅ PinnedStationsManager: Successfully unpinned station. Stations: \(beforeCount) → \(afterCount)")
        } else {
            print("⚠️ PinnedStationsManager: Station with ID \(id) was not found to unpin")
        }
        
        savePinnedStations()
    }
    
    /// Toggle pin status
    func togglePin(id: String, name: String) {
        if isStationPinned(id: id) {
            unpinStation(id: id)
        } else {
            pinStation(id: id, name: name)
        }
    }
}

// MARK: - API Manager (Shared between app and widget)

/// Manages all API calls to the Stockholm Transport API
class APIManager {
    
    /// Shared singleton instance
    static let shared = APIManager()
    
    // MARK: - Properties
    
    /// The base URL for the SL Transport API
    private let baseURL = "https://transport.integration.sl.se/v1"
    
    /// Your API key for accessing the SL Transport API
    /// Note: You'll need to get this from https://www.trafiklab.se/
    private let apiKey = "b890520205904723b2fd61a42c46b332"
    
    // MARK: - Public Methods
    
    /// Fetches metro departures for a specific station
    /// - Parameter stationName: The name of the station to get departures for
    /// - Returns: An array of departures
    /// - Throws: Network errors or API errors
    func fetchMetroDepartures(for stationName: String) async throws -> [Departure] {
        
        // Step 1: Build the URL with query parameters
        guard let url = buildURL(for: stationName) else {
            throw APIError.invalidURL
        }
        
        // Step 2: Make the network request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Step 3: Check if the HTTP response is successful
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        // Step 4: Decode the JSON response into our Swift objects
        let departuresResponse = try JSONDecoder().decode(DeparturesResponse.self, from: data)
        
        // Step 5: Filter for metro departures only
        let metroDepartures = departuresResponse.departures.filter { departure in
            departure.line.transportMode == "METRO"
        }
        
        // Step 6: Return the filtered metro departures
        return metroDepartures
    }
    
    // MARK: - Private Methods
    
    /// Builds the complete URL with query parameters for the API request
    /// - Parameter stationName: The name of the station
    /// - Returns: The complete URL, or nil if it can't be built
    private func buildURL(for stationName: String) -> URL? {
        let siteID = getSiteID(for: stationName)
        let urlString = "\(baseURL)/sites/\(siteID)/departures"
        var components = URLComponents(string: urlString)
        
        // Add query parameters - get all departures and filter for metros in code
        components?.queryItems = [
            URLQueryItem(name: "forecast", value: "480") // Get departures for the next 8 hours to find next metro
        ]
        
        return components?.url
    }
    
    /// Converts a station name to its corresponding site ID
    /// Complete Stockholm Metro station mapping with correct site IDs
    /// - Parameter stationName: The name of the station
    /// - Returns: The site ID for the station
    func getSiteID(for stationName: String) -> String {
        // Complete Stockholm Metro station site IDs from the SL integration API
        // Each station appears only once, with correct site IDs
        let stationMapping = [
            // Core Metro Stations (served by multiple lines)
            "T-Centralen": "9001",
            "T-centralen": "9001",
            "Tcentralen": "9001",
            
            // RED LINE (Röda linjen) - Lines 13 & 14
            // Line 13: Norsborg ↔ Ropsten
            // Line 14: Fruängen ↔ Mörby centrum
            
            // Southbound from T-Centralen (Line 13/14)
            "Gamla stan": "9193",
            "Slussen": "9192",
            "Mariatorget": "9297",
            "Medborgarplatsen": "9191",
            "Skanstull": "9190",
            "Gullmarsplan": "9189",
            "Skärmarbrink": "9188",
            "Blåsut": "9187",
            "Sandsborg": "9186",
            "Skogskyrkogården": "9185",
            "Tallkrogen": "9184",
            "Gubbängen": "9183",
            "Hökarängen": "9182",
            "Farsta": "9181",
            "Farsta strand": "9180",
            "Hammarbyhöjden": "9179",
            "Björkhagen": "9178",
            "Kärrtorp": "9177",
            "Bagarmossen": "9176",
            "Skarpnäck": "9140",
            
            // Northbound from T-Centralen (Line 13/14)
            "Östermalmstorg": "9194",
            "Stadion": "9195",
            "Tekniska högskolan": "9196",
            "Universitetet": "9197",
            "Bergshamra": "9198",
            "Danderyds sjukhus": "9199",
            "Mörby centrum": "9200",
            "Ropsten": "9201",
            "Gärdet": "9202",
            "Karlaplan": "9203",
            
            // Line 13 specific stations (Norsborg branch)
            "Norsborg": "9204",
            "Hallunda": "9205",
            "Alby": "9206",
            "Fittja": "9207",
            "Masmo": "9208",
            "Vårberg": "9209",
            "Vårby gård": "9210",
            "Aspudden": "9211",
            "Örnsberg": "9212",
            "Axelsberg": "9213",
            "Mälarhöjden": "9214",
            "Bredäng": "9215",
            "Sätra": "9216",
            "Skärholmen": "9217",
            "Vårby": "9218",
            
            // Line 14 specific stations (Fruängen branch)
            "Fruängen": "9219",
            "Västertorp": "9220",
            "Hägerstensåsen": "9262",
            "Telefonplan": "9221",
            "Midsommarkransen": "9222",
            "Globen": "9223",
            "Enskede gård": "9224",
            
            // GREEN LINE (Gröna linjen) - Lines 17, 18 & 19
            // Line 17: Åkeshov ↔ Skarpnäck
            // Line 18: Alvik ↔ Farsta strand  
            // Line 19: Hässelby strand ↔ Hagsätra
            
            // Westbound from T-Centralen (Line 17/18/19)
            "Hässelby strand": "9100",
            "Hässelby gård": "9101",
            "Johannelund": "9102",
            "Vällingby": "9103",
            "Råcksta": "9104",
            "Blackeberg": "9105",
            "Islandstorget": "9106",
            "Ängbyplan": "9107",
            "Åkeshov": "9108",
            "Brommaplan": "9109",
            "Abrahamsberg": "9110",
            "Stora mossen": "9111",
            "Alvik": "9112",
            "Kristineberg": "9113",
            "Thorildsplan": "9114",
            "Fridhemsplan": "9115",
            "Odenplan": "9117",
            "Rådmansgatan": "9118",
            "Hötorget": "9119",
            
            // Line 19 specific stations (Hagsätra branch)
            "Hagsätra": "9225",
            "Rågsved": "9226",
            "Huddinge": "9227",
            "Flemingsberg": "9228",
            "Tullinge": "9229",
            "Tumba": "9230",
            "Rönninge": "9231",
            "Österhaninge": "9232",
            "Handen": "9233",
            "Vendelsö": "9234",
            "Trångsund": "9235",
            "Skogås": "9236",
            
            // BLUE LINE (Blåa linjen) - Lines 10 & 11
            // Line 10: Kungsträdgården ↔ Hjulsta
            // Line 11: Kungsträdgården ↔ Akalla
            
            // Northbound from Kungsträdgården (Line 10/11)
            "Kungsträdgården": "9237",
            "Rådhuset": "9238",
            "Stadshagen": "9239",
            "S:t Eriksplan": "9240",
            "Solnacentrum": "9241",
            "Västra skogen": "9242",
            "Huvudsta": "9243",
            "Solna strand": "9244",
            "Sundbybergs centrum": "9245",
            "Duvbo": "9246",
            "Sollentuna": "9247",
            "Rösersberg": "9248",
            
            // Line 10 specific stations (Hjulsta branch)
            "Hjulsta": "9249",
            "Tensta": "9250",
            "Rinkeby": "9251",
            "Spånga": "9252",
            "Sollentuna centrum": "9253",
            
            // Line 11 specific stations (Akalla branch)
            "Akalla": "9254",
            "Kista": "9255",
            "Husby": "9256",
            "Kungens kurva": "9257"
        ]
        
        return stationMapping[stationName] ?? "9001" // Default to T-Centralen if not found
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
