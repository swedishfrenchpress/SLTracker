//
//  Models.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation

// MARK: - API Response Models

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
