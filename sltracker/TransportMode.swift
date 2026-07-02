//
//  TransportMode.swift
//  sltracker
//
//  Single source for transport-mode → icon / name / color mapping, shared by the
//  home screen, pinned list, and departure rows.
//
//  NOTE: SLTrackerWidget/TransportMode.swift is a hand-maintained copy of this
//  file (the widget target compiles its own copy, mirroring SharedModels.swift).
//  Keep the two in sync.
//

import SwiftUI

/// A Stockholm transit mode. Raw values match the SL API's `transport_mode`.
enum TransportMode: String {
    case metro = "METRO"
    case tram = "TRAM"
    case bus = "BUS"
    case train = "TRAIN"
    case ship = "SHIP"

    /// Maps an API mode code to a case, defaulting to `.metro` for anything unknown.
    init(code: String) {
        self = TransportMode(rawValue: code) ?? .metro
    }

    /// Human-readable name shown in filter pills.
    var displayName: String {
        switch self {
        case .metro: return "Metro"
        case .tram:  return "Tram"
        case .bus:   return "Bus"
        case .train: return "Pendeltåg"
        case .ship:  return "Ferry"
        }
    }

    /// SF Symbol for the mode (station icons, filter pills, widget header).
    var icon: String {
        switch self {
        case .metro: return "tram.tunnel.fill"
        case .tram:  return "tram.fill"
        case .bus:   return "bus.fill"
        case .train: return "train.side.front.car"
        case .ship:  return "ferry.fill"
        }
    }

    /// Foreground tint for icons and filter pills. System colors are correct here —
    /// they sit on light chips / surfaces, never behind white text.
    var tint: Color {
        switch self {
        case .metro: return .blue
        case .tram:  return .orange
        case .bus:   return .indigo
        case .train: return .purple
        case .ship:  return .teal
        }
    }
}

/// The representative mode for a station serving several — picks one icon + tint.
/// Metro wins if present; otherwise the highest-priority mode; falls back to metro.
func slPrimaryMode(from modes: Set<String>) -> TransportMode {
    if modes.contains("METRO") || modes.isEmpty { return .metro }
    if modes.count == 1, let only = modes.first { return TransportMode(code: only) }
    for code in ["TRAIN", "TRAM", "BUS", "SHIP"] where modes.contains(code) {
        return TransportMode(code: code)
    }
    return .metro
}

/// Background color for a line badge. White text sits on top, so these are the
/// accessible, brand-accurate SL line colors (all ≥4.5:1 with white) rather than
/// the lighter system palette. Metro is colored per line; other modes use their
/// own badge color.
func slLineBadgeColor(mode: String, designation: String) -> Color {
    switch TransportMode(code: mode) {
    case .metro:
        switch designation {
        case "13", "14":       return Color(red: 0.757, green: 0.153, blue: 0.176) // #C1272D red line
        case "17", "18", "19": return Color(red: 0.082, green: 0.498, blue: 0.235) // #157F3C green line
        case "10", "11":       return Color(red: 0.000, green: 0.412, blue: 0.647) // #0069A5 blue line
        default:               return .gray
        }
    case .tram:  return Color(red: 0.722, green: 0.361, blue: 0.000) // #B85C00
    case .bus:   return .indigo
    case .train: return Color(red: 0.416, green: 0.298, blue: 0.647) // #6A4CA5
    case .ship:  return Color(red: 0.039, green: 0.431, blue: 0.486) // #0A6E7C
    }
}

// MARK: - Accent

extension Color {
    /// The app's single accent — departure times, primary buttons, the loading
    /// spinner, the pin badge. One source instead of scattered `.blue`.
    static let slAccent = Color.blue
}

// MARK: - Imminence

/// Seconds-to-departure under which a departure is treated as "leaving now" and
/// its time is tinted urgent instead of accent.
let slImminentThreshold: TimeInterval = 120

private let slImminenceDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    f.timeZone = TimeZone(identifier: "Europe/Stockholm")
    return f
}()

/// Whether a departure's API `expected` timestamp is imminent relative to `now`.
/// Shared so the app and the widget agree on urgency, regardless of how each one
/// formats the clock. Unparseable timestamps are never imminent.
func slIsImminent(expected: String, now: Date = Date()) -> Bool {
    guard let date = slImminenceDateFormatter.date(from: expected) else { return false }
    return date.timeIntervalSince(now) <= slImminentThreshold
}
