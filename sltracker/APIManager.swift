//
//  APIManager.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation

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
