//
//  RNHeadlessManager.swift
//  Hyperswitch
//
//  Hosts the SDK's headless React Native runtime (the "HyperHeadless" module)
//  that drives headless payment sessions without any visible UI.
//
//  New Architecture note:
//  ----------------------
//  Mirrors RNViewManager: uses the full RCTReactNativeFactory rather than the
//  legacy RCTBridge(delegate:launchOptions:) + RCTRootView(bridge:…) pair.
//  The raw bridge init is incompatible with RCTSetNewArchEnabled(YES) (set
//  globally by the host app's RN runtime), which caused EXC_BAD_ACCESS at
//  offset 0x69f when accessing the bridge's C++ internals via RCTRootView.
//
//  reinvalidateBridge() is preserved for callers (PaymentSession+UIKit) that
//  need to reset the headless runtime between sessions; it now tears down and
//  lazily recreates the RCTReactNativeFactory instead of the bare bridge.
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

internal class RNHeadlessManager: RCTDefaultReactNativeFactoryDelegate {

    internal var responseHandler: RNResponseHandler?
    internal var rootView: UIView?

    private var reactNativeFactory: RCTReactNativeFactory?

    internal static let sharedInstance = RNHeadlessManager()

    // MARK: - Factory lifecycle

    /// Lazily creates the RCTReactNativeFactory (and its bridge) on first use.
    private func factory() -> RCTReactNativeFactory {
        if let existing = reactNativeFactory {
            return existing
        }
        self.dependencyProvider = RCTAppDependencyProvider()
        let created = RCTReactNativeFactory(delegate: self)
        reactNativeFactory = created
        return created
    }

    // MARK: - View creation

    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        let view = factory().rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
        self.rootView = view
        return view
    }

    /// Tear down the current factory (and its bridge) so the next call to
    /// viewForModule starts a fresh JS runtime for the new headless session.
    internal func reinvalidateBridge() {
        reactNativeFactory = nil
        rootView = nil
    }

    // MARK: - RCTDefaultReactNativeFactoryDelegate

    /// Use bridge mode (not bridgeless) so the headless module can use the
    /// legacy RCTBridge event / callback APIs.
    public override func bridgelessEnabled() -> Bool {
        return false
    }

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    public override func bundleURL() -> URL? {
        return Bundle(for: RNHeadlessManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
    }
}
