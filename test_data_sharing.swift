//
//  test_data_sharing.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation

/// Test utility to verify data sharing between app and widget
class DataSharingTest {
    
    static func testDataSharing() {
        print("🔍 Testing Data Sharing...")
        
        // Test shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.erik.sltracker") {
            print("✅ Shared UserDefaults accessible")
            
            // Check if we have pinned stations
            if let data = sharedDefaults.data(forKey: "pinnedStations"),
               let stations = try? JSONDecoder().decode([PinnedStation].self, from: data) {
                print("✅ Found \(stations.count) pinned stations in shared UserDefaults:")
                for station in stations {
                    print("   - \(station.name) (ID: \(station.id))")
                }
            } else {
                print("❌ No pinned stations found in shared UserDefaults")
            }
        } else {
            print("❌ Shared UserDefaults not accessible")
        }
        
        // Test standard UserDefaults
        let standardDefaults = UserDefaults.standard
        if let data = standardDefaults.data(forKey: "pinnedStations"),
           let stations = try? JSONDecoder().decode([PinnedStation].self, from: data) {
            print("✅ Found \(stations.count) pinned stations in standard UserDefaults:")
            for station in stations {
                print("   - \(station.name) (ID: \(station.id))")
            }
        } else {
            print("❌ No pinned stations found in standard UserDefaults")
        }
        
        print("🔍 Data Sharing Test Complete")
    }
    
    static func saveTestData() {
        print("💾 Saving test data...")
        
        // Create a test pinned station
        let testStation = PinnedStation(id: "9001", name: "T-Centralen")
        let testStations = [testStation]
        
        // Try to save to shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.erik.sltracker"),
           let data = try? JSONEncoder().encode(testStations) {
            sharedDefaults.set(data, forKey: "pinnedStations")
            print("✅ Test data saved to shared UserDefaults")
        } else {
            print("❌ Failed to save test data to shared UserDefaults")
        }
        
        // Also save to standard UserDefaults
        if let data = try? JSONEncoder().encode(testStations) {
            UserDefaults.standard.set(data, forKey: "pinnedStations")
            print("✅ Test data saved to standard UserDefaults")
        } else {
            print("❌ Failed to save test data to standard UserDefaults")
        }
    }
}

// Usage instructions:
// 1. Add this file to your main app target
// 2. Call DataSharingTest.testDataSharing() in your app to see what data is available
// 3. Call DataSharingTest.saveTestData() to create test data
// 4. Check the Xcode console for output
