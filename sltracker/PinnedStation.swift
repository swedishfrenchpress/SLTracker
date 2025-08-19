//
//  PinnedStation.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation

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
    
    init() {
        loadPinnedStations()
    }
    
    /// Load pinned stations from UserDefaults
    private func loadPinnedStations() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let stations = try? JSONDecoder().decode([PinnedStation].self, from: data) {
            pinnedStations = stations.sorted { $0.pinnedAt > $1.pinnedAt }
        }
    }
    
    /// Save pinned stations to UserDefaults
    private func savePinnedStations() {
        if let data = try? JSONEncoder().encode(pinnedStations) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    /// Check if a station is pinned
    func isStationPinned(id: String) -> Bool {
        pinnedStations.contains { $0.id == id }
    }
    
    /// Pin a station
    func pinStation(id: String, name: String) {
        // Don't pin if already pinned
        guard !isStationPinned(id: id) else { return }
        
        let newStation = PinnedStation(id: id, name: name)
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
    func togglePin(id: String, name: String) {
        if isStationPinned(id: id) {
            unpinStation(id: id)
        } else {
            pinStation(id: id, name: name)
        }
    }
}
