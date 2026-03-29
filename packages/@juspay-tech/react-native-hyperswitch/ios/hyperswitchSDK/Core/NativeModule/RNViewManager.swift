//
//  RNViewManager.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React

internal class RNViewManager: NSObject {

    internal var responseHandler: RNResponseHandler?
    internal var rootView: RCTRootView?

    // Promise storage for confirmPayment feature
    internal var confirmPromises: [String: RCTPromiseResolveBlock] = [:]
    internal var confirmRejectors: [String: RCTPromiseRejectBlock] = [:]

    internal lazy var bridge: RCTBridge = {
        RCTBridge.init(delegate: self, launchOptions: nil)
    }()

    internal static let sharedInstance = RNViewManager()

    internal func viewForModule(_ moduleName: String, initialProperties: [String : Any]?) -> RCTRootView {
        let rootView: RCTRootView = RCTRootView(
            bridge: self.bridge,
            moduleName: moduleName,
            initialProperties: initialProperties)
        self.rootView = rootView
        return rootView
    }

    // Confirm Payment Promise Helpers
    internal func setConfirmPromise(widgetId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        confirmPromises[widgetId] = resolve
        confirmRejectors[widgetId] = reject
    }

    internal func resolveConfirmPromise(widgetId: String, result: Any?) {
        if let resolve = confirmPromises[widgetId] {
            resolve(result)
            confirmPromises.removeValue(forKey: widgetId)
            confirmRejectors.removeValue(forKey: widgetId)
        }
    }

    internal func rejectConfirmPromise(widgetId: String, error: NSError) {
        if let reject = confirmRejectors[widgetId] {
            reject(error.domain, error.localizedDescription, error)
            confirmPromises.removeValue(forKey: widgetId)
            confirmRejectors.removeValue(forKey: widgetId)
        }
    }
}

extension RNViewManager: RCTBridgeDelegate {
    func sourceURL(for bridge: RCTBridge) -> URL? {
        switch Helper.getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        case "LocalBundle":
            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
        default:
#if canImport(HyperOTA)
            return OTAServices.shared.getBundleURL()
#else
            return Bundle(for: RNViewManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
#endif
        }
    }
}
