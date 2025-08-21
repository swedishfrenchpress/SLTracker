#!/bin/bash

# Check Target Configuration Script
# This script helps verify that files are in the correct targets

echo "🔍 Checking Target Configuration"
echo "================================"

# Check if widget files exist
if [ -f "sltracker/SLTrackerWidget/SLTrackerWidget.swift" ]; then
    echo "✅ SLTrackerWidget.swift exists"
else
    echo "❌ SLTrackerWidget.swift missing"
fi

if [ -f "sltracker/SLTrackerWidget/SLTrackerWidgetBundle.swift" ]; then
    echo "✅ SLTrackerWidgetBundle.swift exists"
else
    echo "❌ SLTrackerWidgetBundle.swift missing"
fi

if [ -f "sltracker/SharedModels.swift" ]; then
    echo "✅ SharedModels.swift exists"
else
    echo "❌ SharedModels.swift missing"
fi

if [ -f "sltracker/sltrackerApp.swift" ]; then
    echo "✅ sltrackerApp.swift exists"
else
    echo "❌ sltrackerApp.swift missing"
fi

echo ""
echo "🎯 Target Membership Check Required:"
echo ""
echo "In Xcode, verify these target memberships:"
echo ""
echo "📱 Main App Target (sltracker):"
echo "   ✅ sltrackerApp.swift"
echo "   ✅ ContentView.swift"
echo "   ✅ SharedModels.swift"
echo "   ❌ SLTrackerWidget.swift (should NOT be here)"
echo "   ❌ SLTrackerWidgetBundle.swift (should NOT be here)"
echo ""
echo "📦 Widget Target (SLTrackerWidget):"
echo "   ✅ SLTrackerWidget.swift"
echo "   ✅ SLTrackerWidgetBundle.swift"
echo "   ✅ SharedModels.swift"
echo "   ❌ sltrackerApp.swift (should NOT be here)"
echo ""
echo "🔧 How to fix:"
echo "   1. Select each widget file in Xcode"
echo "   2. Open File Inspector (right panel)"
echo "   3. Under 'Target Membership':"
echo "      - Uncheck main app target"
echo "      - Check only widget target"
echo ""
echo "✨ This will resolve the @main conflict!"
