# Setting Up App Groups for SL Tracker Widget

## Problem
Your widget is showing "Pin a station" even after you've pinned stations in the main app. This happens because the main app and widget extension run in separate processes and can't share data by default.

## Solution: App Groups
We need to set up App Groups to allow data sharing between the main app and widget extension.

## Step-by-Step Instructions

### 1. Open Xcode Project
1. Open your `sltracker.xcodeproj` file in Xcode
2. Select the project in the navigator (the blue project icon at the top)

### 2. Configure App Groups for Main App
1. Select the **sltracker** target (main app)
2. Go to the **Signing & Capabilities** tab
3. Click the **+ Capability** button
4. Search for and add **App Groups**
5. Click the **+** button under App Groups
6. Add the group: `group.com.erik.sltracker`
7. Make sure it's checked/enabled

### 3. Configure App Groups for Widget Extension
1. Select the **SLTrackerWidgetExtension** target
2. Go to the **Signing & Capabilities** tab
3. Click the **+ Capability** button
4. Search for and add **App Groups**
5. Click the **+** button under App Groups
6. Add the same group: `group.com.erik.sltracker`
7. Make sure it's checked/enabled

### 4. Verify Configuration
Both targets should now have:
- App Groups capability enabled
- The same group ID: `group.com.erik.sltracker`

### 5. Build and Test
1. Clean the build folder (Product → Clean Build Folder)
2. Build the project (⌘+B)
3. Run the app on your device
4. Pin a station in the main app
5. Add the widget to your home screen
6. The widget should now show your pinned station's departures

## What This Fixes

### ✅ Container Background API Error
The widget now uses the modern `containerBackground` API for iOS 17+, which eliminates the "Please adopt containerBackground API" error.

### ✅ Data Sharing Between App and Widget
App Groups allow the main app and widget extension to share the same UserDefaults storage, so pinned stations will be visible in the widget.

## Troubleshooting

If you still see issues:

1. **Widget shows "Pin a station"**: 
   - Make sure both targets have the same App Group ID
   - Clean and rebuild the project
   - Delete and re-add the widget

2. **Container Background error persists**:
   - Make sure you're running iOS 17+ on your device
   - The code includes a fallback for older iOS versions

3. **Build errors**:
   - Check that both targets have the App Groups capability
   - Verify the group ID is exactly the same in both targets

## Code Changes Made

1. **SLTrackerWidget.swift**: Updated to use `containerBackground` API
2. **SharedModels.swift**: Updated `PinnedStationsManager` to use App Groups

The widget should now work correctly on both your mobile phone and simulator!
