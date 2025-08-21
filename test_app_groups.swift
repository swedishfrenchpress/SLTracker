//
//  test_app_groups.swift
//  sltracker
//
//  Created by Erik on 2025-01-27.
//

import Foundation

/// Test utility to verify App Groups functionality
class AppGroupsTest {
    
    static func testAppGroupsAccess() {
        print("🔍 Testing App Groups Access...")
        
        // Test 1: Can we access the shared UserDefaults?
        if let sharedDefaults = UserDefaults(suiteName: "group.com.erik.sltracker") {
            print("✅ Shared UserDefaults accessible")
            
            // Test 2: Can we write to it?
            sharedDefaults.set("test_value", forKey: "test_key")
            if let testValue = sharedDefaults.string(forKey: "test_key") {
                print("✅ Can write and read from shared UserDefaults: \(testValue)")
            } else {
                print("❌ Cannot read from shared UserDefaults")
            }
            
            // Test 3: Check if we have any existing pinned stations
            if let data = sharedDefaults.data(forKey: "pinnedStations") {
                print("✅ Found existing pinnedStations data in shared UserDefaults")
                if let stations = try? JSONDecoder().decode([PinnedStation].self, from: data) {
                    print("✅ Successfully decoded \(stations.count) pinned stations:")
                    for station in stations {
                        print("   - \(station.name) (ID: \(station.id))")
                    }
                } else {
                    print("❌ Failed to decode pinned stations data")
                }
            } else {
                print("❌ No pinnedStations data found in shared UserDefaults")
            }
            
        } else {
            print("❌ Shared UserDefaults not accessible - App Groups may not be configured")
        }
        
        // Test 4: Compare with standard UserDefaults
        let standardDefaults = UserDefaults.standard
        if let data = standardDefaults.data(forKey: "pinnedStations") {
            print("✅ Found pinnedStations data in standard UserDefaults")
            if let stations = try? JSONDecoder().decode([PinnedStation].self, from: data) {
                print("✅ Standard UserDefaults has \(stations.count) pinned stations:")
                for station in stations {
                    print("   - \(station.name) (ID: \(station.id))")
                }
            }
        } else {
            print("❌ No pinnedStations data found in standard UserDefaults")
        }
        
        print("🔍 App Groups Test Complete")
    }
    
    static func createTestData() {
        print("💾 Creating test data...")
        
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

// Usage:
// 1. Add this file to your main app target
// 2. Call AppGroupsTest.testAppGroupsAccess() in your app
// 3. Call AppGroupsTest.createTestData() to create test data
// 4. Check Xcode console for output
