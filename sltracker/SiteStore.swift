//
//  SiteStore.swift
//  sltracker
//

import Foundation

/// Represents a transit stop/site from the SL transport system
struct Site: Codable, Identifiable {
    let id: Int
    let name: String
}

/// Loads and queries all SL transit stops from the bundled JSON data
class SiteStore {

    static let shared = SiteStore()

    private var sites: [Site] = []
    private var nameToID: [String: Int] = [:]
    private var idToName: [Int: String] = [:]

    init() {
        loadSites()
    }

    private func loadSites() {
        guard let url = Bundle.main.url(forResource: "all_sites", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let loadedSites = try? JSONDecoder().decode([Site].self, from: data) else {
            return
        }

        sites = loadedSites

        // Build lookup dictionaries, preferring 9xxx IDs for duplicate names
        for site in sites {
            let existing = nameToID[site.name]
            if existing == nil || (site.id >= 9000 && (existing ?? 0) < 9000) {
                nameToID[site.name] = site.id
            }
            idToName[site.id] = site.name
        }
    }

    /// Search for stops matching the query, returns up to 8 results
    func search(query: String) -> [Site] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var seen = Set<String>()
        var results: [Site] = []

        for site in sites {
            guard site.name.localizedStandardContains(trimmed) else { continue }

            let preferredID = nameToID[site.name] ?? site.id
            guard !seen.contains(site.name) else { continue }
            seen.insert(site.name)

            results.append(Site(id: preferredID, name: site.name))
            if results.count >= 8 { break }
        }

        return results
    }

    /// Get the site ID for a station name
    func getSiteID(for name: String) -> String? {
        if let id = nameToID[name] {
            return String(id)
        }
        return nil
    }

    /// Get the station name for a site ID
    func getStationName(for id: String) -> String? {
        if let intID = Int(id) {
            return idToName[intID]
        }
        return nil
    }
}
