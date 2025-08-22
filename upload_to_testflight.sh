#!/bin/bash

# SLTracker TestFlight Upload Script
# This script helps you upload your app to TestFlight using altool

echo "🚀 SLTracker TestFlight Upload Script"
echo "======================================"

# Configuration - Update these values
APP_NAME="SLTracker"
BUNDLE_ID="com.erik.sltracker"
VERSION="1.0"  # Update this to match your app version
BUILD_NUMBER="1"  # Update this to match your build number
APPLE_ID=""  # You'll need to get this from App Store Connect
ASC_PUBLIC_ID=""  # You'll need to get this from App Store Connect

# Check if required tools are available
if ! command -v xcrun &> /dev/null; then
    echo "❌ Error: xcrun not found. Make sure Xcode is installed."
    exit 1
fi

# Function to get archive path
get_archive_path() {
    # Look for the most recent archive
    ARCHIVE_PATH=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d | head -1)
    
    if [ -z "$ARCHIVE_PATH" ]; then
        echo "❌ No archive found. Please archive your app in Xcode first:"
        echo "   1. Open Xcode"
        echo "   2. Select 'Any iOS Device (arm64)' as target"
        echo "   3. Go to Product → Archive"
        exit 1
    fi
    
    echo "📦 Found archive: $ARCHIVE_PATH"
}

# Function to validate the app
validate_app() {
    echo "🔍 Validating app..."
    
    # Create IPA from archive
    IPA_PATH="/tmp/${APP_NAME}.ipa"
    
    echo "📱 Creating IPA file..."
    xcrun -sdk iphoneos PackageApplication \
        -v "$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app" \
        -o "$IPA_PATH" \
        --sign "iPhone Distribution" \
        --embed "$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app/embedded.mobileprovision"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create IPA file"
        exit 1
    fi
    
    echo "✅ IPA created successfully: $IPA_PATH"
    
    # Validate the app
    echo "🔍 Validating app with App Store Connect..."
    xcrun altool --validate-app \
        -f "$IPA_PATH" \
        -t ios \
        -u "$APPLE_ID" \
        --output-format xml
    
    if [ $? -eq 0 ]; then
        echo "✅ App validation successful!"
    else
        echo "❌ App validation failed. Please check the errors above."
        exit 1
    fi
}

# Function to upload the app
upload_app() {
    echo "📤 Uploading app to App Store Connect..."
    
    if [ -z "$APPLE_ID" ] || [ -z "$ASC_PUBLIC_ID" ]; then
        echo "⚠️  Warning: APPLE_ID or ASC_PUBLIC_ID not set."
        echo "   You'll need to provide these values:"
        echo "   - APPLE_ID: Get this from your App Store Connect app page"
        echo "   - ASC_PUBLIC_ID: Get this by running: xcrun altool --list-providers -u YOUR_APPLE_ID"
        echo ""
        echo "   Then run this script again with the correct values."
        exit 1
    fi
    
    xcrun altool --upload-package "$IPA_PATH" \
        -t ios \
        --asc-public-id "$ASC_PUBLIC_ID" \
        --apple-id "$APPLE_ID" \
        --bundle-id "$BUNDLE_ID" \
        --bundle-short-version-string "$VERSION" \
        --bundle-version "$BUILD_NUMBER" \
        -u "$APPLE_ID" \
        --output-format xml
    
    if [ $? -eq 0 ]; then
        echo "✅ App uploaded successfully!"
        echo "🎉 Your app is now being processed by App Store Connect."
        echo "   Check App Store Connect in a few minutes to see your build."
    else
        echo "❌ App upload failed. Please check the errors above."
        exit 1
    fi
}

# Main execution
echo "📋 Configuration:"
echo "   App Name: $APP_NAME"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Version: $VERSION"
echo "   Build: $BUILD_NUMBER"
echo ""

get_archive_path
validate_app
upload_app

echo ""
echo "🎯 Next Steps:"
echo "   1. Go to App Store Connect (https://appstoreconnect.apple.com)"
echo "   2. Select your app"
echo "   3. Go to 'TestFlight' tab"
echo "   4. Wait for processing to complete (usually 5-15 minutes)"
echo "   5. Add test information and submit for review"
echo "   6. Once approved, you can invite testers!"
