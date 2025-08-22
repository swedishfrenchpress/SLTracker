//
//  sltrackerApp.swift
//  sltracker
//
//  Created by Erik on 2025-08-18.
//

import SwiftUI

@main
struct sltrackerApp: App {
    
    // Shared state for navigation
    @StateObject private var navigationState = NavigationState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationState)
                .onOpenURL { url in
                    // Handle widget station URL
                    if url.scheme == "sltracker" && url.host == "station" {
                        let stationName = url.lastPathComponent.removingPercentEncoding ?? ""
                        if !stationName.isEmpty {
                            // Navigate to the station's departure page
                            navigationState.navigateToStation(stationName: stationName)
                        }
                    }
                }
        }
    }
}
