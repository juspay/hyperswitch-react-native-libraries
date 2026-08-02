# Hyperswitch Bundle Resources

This directory contains version-specific React Native bundles for the embedded Hyperswitch payment UI.

## Bundle Files

### `hyperswitch-rn76-81.bundle`
**Target:** React Native versions 0.76 through 0.81
- Built from: `../hyperswitch-client-core` (NEW-ARCH-2026 or turbo branch)
- Compatible with: RN 0.76, 0.79, 0.81
- Architecture: New Architecture (Turbo Modules)

### `hyperswitch-rn82plus.bundle`
**Target:** React Native versions 0.82 and above (including 0.85+)
- Built from: `../hyperswitch-client-core` (latest turbo branch)
- Compatible with: RN 0.82, 0.85, and future versions
- Architecture: New Architecture (Turbo Modules)

### `hyperswitch.bundle` (Legacy)
**Target:** Fallback for any version detection issues
- Kept for backward compatibility
- Used when version-specific bundles are not found

## Version Selection Logic

The SDK automatically detects the merchant app's React Native version at runtime using `RCTGetReactNativeVersion()` and loads the appropriate bundle:

```swift
RN 0.76 - 0.81  →  hyperswitch-rn76-81.bundle
RN 0.82+        →  hyperswitch-rn82plus.bundle
Fallback        →  hyperswitch.bundle
```

See `RNViewManager.swift` `bundleURL()` method for implementation details.

## Building Bundles

To generate these bundles, run the following commands from the SDK root:

```bash
# For RN 0.76-0.81
yarn bundle:ios:rn76-81

# For RN 0.82+
yarn bundle:ios:rn82plus
```

The build scripts should:
1. Navigate to `../hyperswitch-client-core`
2. Switch to the appropriate branch (NEW-ARCH-2026 or turbo)
3. Run Metro bundler with correct RN version
4. Copy the output to this directory

## File Size

Bundle files should be approximately 3-4 MB each (minified JavaScript).

## OTA Updates

When HyperOTA is enabled (via conditional import), the SDK will attempt to fetch bundles from the OTA server instead of using these embedded bundles. These files serve as the initial/fallback bundles.

## Notes

- **DO NOT** commit placeholder/empty bundle files to production
- Bundles must be generated from the actual `hyperswitch-client-core` codebase
- Version detection happens at runtime, so the same SDK binary works across all RN versions
- The merchant app's RN version is detected, NOT the SDK's internal dependency version
