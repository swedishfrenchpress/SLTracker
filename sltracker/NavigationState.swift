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
class NavigationState: ObservableObject {
    @Published var targetStation: String?
    @Published var shouldNavigateToStation = false
    
    /// Navigate to a specific station (called from widget tap)
    func navigateToStation(stationName: String) {
        targetStation = stationName
        shouldNavigateToStation = true
        
        // Reset after a short delay to allow navigation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldNavigateToStation = false
        }
    }
    
    /// Clear the navigation target
    func clearNavigationTarget() {
        targetStation = nil
        shouldNavigateToStation = false
    }
}
