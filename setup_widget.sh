#!/bin/bash

# SL Tracker Widget Setup Script
# This script helps organize the widget files for your Xcode project

echo "🚇 SL Tracker Widget Setup"
echo "=========================="

# Check if we're in the right directory
if [ ! -f "sltracker.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the root of your SL Tracker project"
    echo "   (where sltracker.xcodeproj is located)"
    exit 1
fi

echo "✅ Found SL Tracker project"

# Create widget directory if it doesn't exist
if [ ! -d "sltracker/SLTrackerWidget" ]; then
    echo "📁 Creating widget directory..."
    mkdir -p sltracker/SLTrackerWidget
fi

echo "📋 Files ready for widget setup:"
echo "   • sltracker/SharedModels.swift"
echo "   • sltracker/SLTrackerWidget/SLTrackerWidget.swift"
echo "   • sltracker/SLTrackerWidget/SLTrackerWidgetBundle.swift"
echo "   • WIDGET_SETUP.md"
echo ""
echo "ℹ️  Note: Your project uses auto-generated Info.plist files"
echo "   No manual Info.plist is needed for the widget"

echo ""
echo "🎯 Next steps:"
echo "   1. Open sltracker.xcodeproj in Xcode"
echo "   2. Follow the instructions in WIDGET_SETUP.md"
echo "   3. Add the widget extension target"
echo "   4. Replace generated files with our custom ones"
echo "   5. Add SharedModels.swift to both targets"
echo ""
echo "📖 Read WIDGET_SETUP.md for detailed instructions"
echo ""
echo "✨ Good luck with your widget!"
