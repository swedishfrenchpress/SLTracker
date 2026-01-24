//
//  NavigationState.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation
import SwiftUI

/// Manages navigation state for deep linking from widgets
@MainActor
@Observable
final class NavigationState {
    var targetStation: String?
    var shouldNavigateToStation = false
    
    /// Navigate to a specific station (called from widget tap)
    func navigateToStation(stationName: String) {
        targetStation = stationName
        shouldNavigateToStation = true
        
        // Reset after a short delay to allow navigation to complete
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            self.shouldNavigateToStation = false
        }
    }
    
    /// Clear the navigation target
    func clearNavigationTarget() {
        targetStation = nil
        shouldNavigateToStation = false
    }
}
