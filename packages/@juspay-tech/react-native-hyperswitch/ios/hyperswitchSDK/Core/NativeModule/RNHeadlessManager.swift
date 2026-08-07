//
//  RNHeadlessManager.swift
//  Hyperswitch
//
//  Hosts the SDK's headless React Native runtime (the "HyperHeadless" module)
//  that drives headless payment sessions without any visible UI.
//

import Foundation
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

internal class RNHeadlessManagerDelegate: RNFactoryDelegate {

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    public override func bundleURL() -> URL? {
        return HyperBundleResolver.bundleURL(for: RNHeadlessManager.self)
    }
}

internal class RNHeadlessManager: RCTDefaultReactNativeFactoryDelegate {

    internal var responseHandler: RNResponseHandler?
    internal var rootView: UIView?

    private var factory: RCTReactNativeFactory?

    internal let hyperModule = HyperModuleImpl()

    internal static let sharedInstance = RNHeadlessManager()

    private let delegate = RNHeadlessManagerDelegate()

    // MARK: - Factory lifecycle

    private func factoryOrCreate() -> RCTReactNativeFactory {
        if let existing = factory {
            return existing
        }
        delegate.dependencyProvider = RCTAppDependencyProvider()
        let created = RCTReactNativeFactory(delegate: delegate)
        factory = created
        return created
    }

    // MARK: - View creation
    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        let makeView = {
            self.factoryOrCreate().rootViewFactory.view(
                withModuleName: moduleName,
                initialProperties: initialProperties
            )
        }
        let view: UIView
        if Thread.isMainThread {
            view = makeView()
        } else {
            view = DispatchQueue.main.sync(execute: makeView)
        }
        self.rootView = view
        return view
    }

    internal func reinvalidateBridge() {
        rootView = nil
    }

    // MARK: - RCTTurboModuleManagerDelegate

    @objc public func getModuleInstanceFromClass(_ moduleClass: AnyClass) -> AnyObject? {
        if String(describing: moduleClass) == "HyperModule",
           let shim = (moduleClass as? NSObject.Type)?.init() as? HyperModuleShim {
            hyperModule.attach(to: shim)
            return shim as AnyObject
        }
        return nil
    }

    public override func bridgelessEnabled() -> Bool {
        return true
    }

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    public override func bundleURL() -> URL? {
        return HyperBundleResolver.bundleURL(for: RNHeadlessManager.self)
    }
}
