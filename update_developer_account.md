# Updating Xcode Project for New Developer Account

## After enrolling in Apple Developer Program:

### 1. Update Bundle Identifier (if needed)
- Open Xcode project
- Select project in navigator
- Under "General" tab, verify Bundle Identifier is `com.erik.sltracker`
- If you want to change it, update it here and in all targets

### 2. Update Team Settings
- In Xcode, select your project
- Under "Signing & Capabilities":
  - **Team**: Select your new personal team
  - **Bundle Identifier**: Verify it matches App Store Connect
  - **Automatically manage signing**: ✅ Check this

### 3. Update App Groups
- Ensure App Groups are configured for your new team
- Group identifier: `group.com.erik.sltracker`
- This should work with your personal account

### 4. Verify Entitlements
- Check that `sltracker.entitlements` contains:
  ```xml
  <key>com.apple.security.application-groups</key>
  <array>
      <string>group.com.erik.sltracker</string>
  </array>
  ```

### 5. Archive and Upload
- Select "Any iOS Device (arm64)" as target
- Product → Archive
- Distribute → App Store Connect → Upload

## Important Notes:
- Your app will have a new App Store Connect record
- TestFlight builds will be separate from any organization builds
- You'll have full control over pricing, metadata, and distribution
