//
//  WidgetSettings.swift
//  sltracker
//
//  Widget-level preferences shared with the widget extension via App Group.
//

import Foundation
import WidgetKit

/// Manages user-configurable settings for the Home Screen widget.
///
/// Currently exposes which transit modes the widget should display. Stored in the
/// shared App Group so the widget extension can read it, mirroring the persistence
/// pattern used by `PinnedStationsManager`.
@MainActor
@Observable
final class WidgetSettingsManager {

    /// The transit modes the widget should show. `nil` means "show all modes".
    var enabledModes: [String]?

    /// UserDefaults key for the enabled modes array.
    static let enabledModesKey = "widgetTransportModes"

    // Use App Groups to share data between app and widget
    private var userDefaults: UserDefaults {
        if let groupDefaults = UserDefaults(suiteName: "group.com.erik.sltracker") {
            return groupDefaults
        }
        return UserDefaults.standard
    }

    init() {
        enabledModes = userDefaults.stringArray(forKey: Self.enabledModesKey)
    }

    /// Updates which transit modes the widget shows and refreshes the widget.
    ///
    /// Passing `nil` (or an empty array) clears the filter so the widget shows all modes.
    func setEnabledModes(_ modes: [String]?) {
        enabledModes = modes

        if let modes, !modes.isEmpty {
            userDefaults.set(modes, forKey: Self.enabledModesKey)
        } else {
            userDefaults.removeObject(forKey: Self.enabledModesKey)
        }

        // Bust the widget's 30s data cache so the new filter is reflected immediately
        userDefaults.removeObject(forKey: "widgetDataLastUpdated")

        WidgetCenter.shared.reloadAllTimelines()
    }
}
