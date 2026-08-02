//
//  RNViewManager.swift
//  Hyperswitch
//
//  Hosts the SDK's embedded React Native runtime that renders the payment sheet
//  from the packaged `hyperswitch.bundle`.
//
//  New Architecture note:
//  ----------------------
//  The embedded runtime MUST be created through the full `RCTReactNativeFactory`.
//  That initializer performs the essential RN setup — feature flags,
//  `RCTSetNewArchEnabled`, `RCTEnableTurboModule`, the Fabric component provider —
//  and wires a TurboModule manager that can resolve RN's own CORE modules
//  (`DeviceInfo`, `ExceptionsManager`, `RedBox`, …). Building the low-level
//  `RCTRootViewFactory` directly (as the old `RNBridgeFactory` did) leaves the
//  runtime under-initialised, so `getEnforcing('DeviceInfo')` fails and the bundle
//  can't boot — the sheet renders blank.
//
//  The bridge is intentionally kept alive (Fabric-on-bridge) for now because the
//  legacy widget code still uses `bridge.enqueueJSCall` / `bridge.uiManager`.
//  For the payment-sheet-only build we do not capture or expose the bridge here.
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

internal class RNViewManager: RCTDefaultReactNativeFactoryDelegate {

    internal var responseHandler: RNResponseHandler?
    internal var rootView: UIView?

    private var reactNativeFactory: RCTReactNativeFactory?

    // Bridge capture for widget operations (enqueueJSCall / uiManager).
    private weak var capturedBridge: RCTBridge?

    internal static let sharedInstance = RNViewManager()

    /// Lazily create the standard RN factory (does the full runtime setup).
    private func factory() -> RCTReactNativeFactory {
        if let existing = reactNativeFactory {
            return existing
        }
        self.dependencyProvider = RCTAppDependencyProvider()
        let created = RCTReactNativeFactory(delegate: self)
        reactNativeFactory = created
        return created
    }

    /// The bridge backing the embedded runtime. Kept for the SDK's widget commands
    /// (`bridge.enqueueJSCall` / `bridge.uiManager`). Available after the first view
    /// is created.
    internal var bridge: RCTBridge? {
        return capturedBridge
    }

    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        let view = factory().rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
        self.rootView = view
        return view
    }

    internal func widgetViewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        return factory().rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
    }

    // MARK: - Arch configuration

    /// Keep a bridge-backed Fabric runtime so the bundled payment sheet can boot.
    /// (The bridge itself is not exposed here; only the factory/rootView is used.)
    public override func bridgelessEnabled() -> Bool {
        return false
    }

    // MARK: - Bundle source
    // Both are required in bridge mode: the default implementations throw.

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        // Called while the embedded bridge loads its JS — capture it for the SDK's
        // bridge-dependent widget commands.
        self.capturedBridge = bridge
        return bundleURL()
    }

    /// Detects the merchant app's React Native version and returns the appropriate bundle.
    /// Version selection:
    ///   - RN 0.76 - 0.81: hyperswitch-rn76-81.bundle
    ///   - RN 0.82+:       hyperswitch-rn82plus.bundle
    ///   - Fallback:       hyperswitch.bundle (legacy)
    public override func bundleURL() -> URL? {
        #if canImport(HyperOTA)
            return OTAServices.shared.getBundleURL()
        #else
            // Detect merchant app's React Native version
            guard let rnVersion = RCTGetReactNativeVersion() else {
                return Bundle(for: RNViewManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
            }
            
            let majorVersion = (rnVersion["major"] as? Int) ?? 0
            let minorVersion = (rnVersion["minor"] as? Int) ?? 0
            
            let bundleName: String
            
            // Version selection logic
            if majorVersion == 0 {
                // RN 0.x versions
                if minorVersion >= 76 && minorVersion <= 81 {
                    bundleName = "hyperswitch-rn76-81"
                } else if minorVersion >= 82 {
                    bundleName = "hyperswitch-rn82plus"
                } else {
                    // Legacy fallback for versions < 0.76
                    bundleName = "hyperswitch"
                }
            } else {
                // Future RN 1.x+ versions - use latest bundle
                bundleName = "hyperswitch-rn82plus"
            }
            
            let bundleURL = Bundle(for: RNViewManager.self).url(forResource: bundleName, withExtension: "bundle")

            if bundleURL == nil {
                return Bundle(for: RNViewManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
            }
            
            return bundleURL
        #endif
    }
}

