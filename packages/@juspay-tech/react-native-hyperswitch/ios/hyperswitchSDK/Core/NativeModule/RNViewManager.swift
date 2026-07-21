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
//  We keep the *bridge* alive by overriding `bridgelessEnabled` → false, because
//  the SDK's widget commands still use `bridge.enqueueJSCall` / `bridge.uiManager`.
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

    /// Captured when the embedded bridge loads its JS source (see `sourceURL(for:)`).
    /// The host app is bridgeless, so this embedded bridge is the SDK's only bridge.
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

    /// Keep the legacy bridge alive (Fabric-on-bridge) so the SDK's
    /// `bridge.enqueueJSCall` / `bridge.uiManager` widget commands keep working.
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

    public override func bundleURL() -> URL? {
//        switch Helper.getInfoPlist("HyperswitchSource") {
//        case "LocalHosted":
//            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
//        case "LocalBundle":
//            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
//        default:
//            #if canImport(HyperOTA)
//            return OTAServices.shared.getBundleURL()
//            #else
            return Bundle(for: RNViewManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
//            #endif
//        }
    }
}

