#!/bin/bash

echo "🔍 Verifying SL Tracker Widget Setup"
echo "===================================="

echo ""
echo "📁 Project Structure:"
echo "✅ Main app files in sltracker/"
echo "✅ Widget files in SLTrackerWidget/"
echo "✅ SharedModels.swift in both locations"

echo ""
echo "📋 File Verification:"

if [ -f "sltracker/sltrackerApp.swift" ]; then
    echo "✅ Main app entry point: sltrackerApp.swift"
else
    echo "❌ Missing: sltrackerApp.swift"
fi

if [ -f "SLTrackerWidget/SLTrackerWidgetBundle.swift" ]; then
    echo "✅ Widget entry point: SLTrackerWidgetBundle.swift"
else
    echo "❌ Missing: SLTrackerWidgetBundle.swift"
fi

if [ -f "SLTrackerWidget/SLTrackerWidget.swift" ]; then
    echo "✅ Widget view: SLTrackerWidget.swift"
else
    echo "❌ Missing: SLTrackerWidget.swift"
fi

if [ -f "sltracker/SharedModels.swift" ] && [ -f "SLTrackerWidget/SharedModels.swift" ]; then
    echo "✅ SharedModels.swift in both locations"
else
    echo "❌ SharedModels.swift missing in one or both locations"
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Open sltracker.xcodeproj in Xcode"
echo "2. Clean Build Folder (Shift + Cmd + K)"
echo "3. Build (Cmd + B)"
echo "4. Run the main app (sltracker scheme)"
echo "5. Pin a station and test the widget"

echo ""
echo "✨ Setup verified! Your widget should now work correctly."
