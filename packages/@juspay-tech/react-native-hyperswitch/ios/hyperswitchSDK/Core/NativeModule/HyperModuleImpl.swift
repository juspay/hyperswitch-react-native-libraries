//
//  HyperModuleImpl.swift
//  Pods
//
//  Created by Kuntimaddi Manideep on 22/07/26.
//

import Foundation
import React
import React_RCTAppDelegate

@objc(HyperModuleImpl)
public class HyperModuleImpl: NSObject {

    @objc public static let shared = HyperModuleImpl()

    /// The RN-registered event emitter (the ObjC++ `HyperModule` TurboModule) through
    /// which JS-facing events are dispatched and the bridge / uiManager is reached.
    @objc public weak var eventEmitter: RCTEventEmitter?

    private let applePayPaymentHandler = ApplePayHandler()
    private let expressCheckoutHandler = ExpressCheckoutLauncher()
    private var presentCallback: RCTResponseSenderBlock? = nil

    /// Direct reference to the currently-presented PaymentSheet.
    /// Set by PaymentSheetView+UIKit when the sheet is presented; cleared in exitPaymentsheet.
    /// Avoids relying on bridge.uiManager.addUIBlock (which doesn't find Fabric views).
    private var activePaymentSheet: PaymentSheet?
    private weak var activePaymentSheetVC: HyperUIViewController?

    private override init() {
        super.init()
    }

    // MARK: - Payment sheet registration (called from PaymentSheetView+UIKit)

    internal func registerPaymentSheet(_ sheet: PaymentSheet, vc: HyperUIViewController) {
        activePaymentSheet = sheet
        activePaymentSheetVC = vc
    }

    // Bridge-backed widget helpers available when bridge is re-exposed.
    private var bridge: RCTBridge? { eventEmitter?.bridge }

    // MARK: - Events

    @objc public func confirm(data: [String: Any]) {
        eventEmitter?.sendEvent(withName: "confirm", body: data)
    }
    // MARK: WIP
    //    @objc public func confirmEC(data: [String: Any]) {
    //        eventEmitter?.sendEvent(withName: "confirmEC", body: data)
    //    }

    // MARK: - Generic message passing

    @objc public func sendMessageToNative(_ rnMessage: String) {}

    // MARK: - Apple Pay

    @objc public func launchApplePay(_ rnMessage: String, callback: @escaping RCTResponseSenderBlock) {
        applePayPaymentHandler.startPayment(rnMessage: rnMessage, rnCallback: callback, presentCallback: self.presentCallback)
    }

    @objc public func startApplePay(_ rnMessage: String, callback: @escaping RCTResponseSenderBlock) {
        callback([])
    }

    @objc public func presentApplePay(_ rnMessage: String, callback: @escaping RCTResponseSenderBlock) {
        self.presentCallback = callback
    }

    // MARK: - Widget (commented out — relies on RCTBridge/uiManager)

       @objc public func launchWidgetPaymentSheet(_ requestObj: String, callback: @escaping RCTResponseSenderBlock) {
        //    let request = HyperModuleImpl.jsonObject(from: requestObj)
        //    expressCheckoutHandler.launchPaymentSheet(paymentResult: request, callBack: callback)
       }
    //
       @objc public func onAddPaymentMethod(_ rnMessage: String) {
        //    PaymentMethodManagementWidget.onAddPaymentMethod?()
       }

    // MARK: - Payment sheet exits

    @objc public func exitPaymentsheet(_ reactTag: NSNumber, result rnMessage: String, reset: Bool) {
        // Consume and clear so they can't be called a second time.
        let sheet = activePaymentSheet
        let vc    = activePaymentSheetVC
        activePaymentSheet   = nil
        activePaymentSheetVC = nil

        // Pass the raw JS result string directly — no PaymentResult conversion.
        // PaymentSheet.completion is (String) -> Void, so this goes straight to
        // the promise resolve in HyperswitchModule.presentPaymentSheet.
        sheet?.completion?(rnMessage)

        // Dismiss the VC, then release the rootView so the Fabric surface is torn down.
        vc?.dismiss(animated: false) {
            RNViewManager.sharedInstance.rootView?.removeFromSuperview()
            RNViewManager.sharedInstance.rootView = nil
        }
    }

    @objc public func exitWidgetPaymentsheet(_ reactTag: NSNumber, result rnMessage: String, reset: Bool) {
        // Final result - send to callback/event and trigger exit
        withNativePaymentWidgetView(reactTag) { view in
            view.handlePaymentResult(rnMessage, triggerExit: true)
        }
    }

    @objc public func exitPaymentMethodManagement(_ reactTag: NSNumber, result rnMessage: String, reset: Bool) {
        exitSheet(rnMessage)
    }

    @objc public func exitCardForm(_ rnMessage: String) {
        exitCardFormInternal(rnMessage)
    }

    // MARK: - Payment result / events (commented out — rely on RCTBridge/uiManager)

    @objc public func notifyWidgetPaymentResult(_ rootTag: NSNumber, result rnMessage: String) {
        // Intermediate result (e.g. validation errors) - send to callback only, don't exit
        withNativePaymentWidgetView(rootTag) { view in
            view.handleConfirmPaymentNotification(rnMessage)
        }
    }

    @objc public func onUpdateIntentEvent(_ rootTag: NSNumber, type: String, result: String) {
        // Notify the widget for Combine publishers (optional)
        withWidget(rootTag) { widget in
            widget.handleUpdateIntentEvent(type: type, result: result)
        }
        
        // Call the view's callback handlers directly
        withNativePaymentWidgetView(rootTag) { view in
            switch type {
            case "UPDATE_INTENT_INIT_RETURNED":
                view.handleUpdateIntentInitResponse(result)
            case "UPDATE_INTENT_COMPLETE_RETURNED":
                view.handleUpdateIntentCompleteResponse(result)
            default:
                break
            }
        }
    }

    @objc public func emitPaymentEvent(_ rootTag: NSNumber, eventType: String, payload: NSDictionary) {
        let map = (payload as? [String: Any]) ?? [:]
        resolveSubscribingTarget(rootTag) { target in
            if let widget = target as? PaymentWidget, widget.paymentEventListener != nil {
                widget.dispatchPaymentEvent(type: eventType, payload: map)
            } else if let cvc = target as? CVCWidget, cvc.paymentEventListener != nil {
                cvc.dispatchPaymentEvent(type: eventType, payload: map)
            } else if let sheet = target as? PaymentSheet, sheet.paymentEventListener != nil {
                sheet.dispatchPaymentEvent(type: eventType, payload: map)
            }
        }
    }

    @objc public func onPaymentConfirmButtonClick(_ rootTag: NSNumber, payload: String, callback: @escaping RCTResponseSenderBlock) {
        resolveSubscribingTarget(rootTag) { target in
            if let widget = target as? PaymentWidget {
                widget.handleShouldProceedWithPayment(payload: payload) { shouldProceed in
                    callback([shouldProceed])
                }
            } else if let sheet = target as? PaymentSheet {
                sheet.handleShouldProceedWithPayment(payload: payload) { shouldProceed in
                    callback([shouldProceed])
                }
            } else {
                callback([true])
            }
        }
    }

    // MARK: - 3DS / DDC iframe bridge

    @objc public func openIframeBridge(_ url: String, timeoutMs: NSNumber, callback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            let headlessWebView = HeadlessWebView(url: url, timeoutMs: timeoutMs, callback: callback)
            headlessWebView.startFlow()
        }
    }

    // MARK: - Helpers

    private static func jsonObject(from string: String) -> NSMutableDictionary {
        guard
            let data = string.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any]
        else {
            return NSMutableDictionary()
        }
        return NSMutableDictionary(dictionary: obj)
    }

    private func paymentResult(from rnMessage: String) -> PaymentResult {
        guard let data = rnMessage.data(using: .utf8) else {
            return .failed(
                error: NSError(
                    domain: "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": "An error has occurred."]
                )
            )
        }

        do {
            guard let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                return .failed(
                    error: NSError(
                        domain: "UNKNOWN_ERROR",
                        code: 0,
                        userInfo: ["message": "An error has occurred."]
                    )
                )
            }

            let status = jsonDictionary["status"]

            if status == "success" || status == "succeeded" || status == "completed" || status == "requires_capture" {
                return .completed(data: rnMessage)  // Pass full raw JSON
            } else if status == "cancelled" || status == "canceled" {
                return .canceled(data: rnMessage)  // Pass full raw JSON
            } else {
                // Store the original raw JSON string in userInfo so it can be passed through without loss
                let error = NSError(
                    domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "",
                    code: 0,
                    userInfo: [
                        "message": jsonDictionary["message"] ?? status ?? "An error has occurred.",
                        "rawJSON": rnMessage  // Preserve original JSON from embedded bundle
                    ]
                )
                return .failed(error: error)
            }
        } catch {
            return .failed(
                error: NSError(
                    domain: "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": "An error has occurred."]
                )
            )
        }
    }

    private func exitCardFormInternal(_ rnMessage: String) {
        var response: String?
        var error: NSError?

        if let data = rnMessage.data(using: .utf8) {
            do {
                if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    let status = jsonDictionary["status"]

                    if status == "failed" || status == "requires_payment_method" {
                        error = NSError(
                            domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR",
                            code: 0,
                            userInfo: ["message": jsonDictionary["message"] ?? "An error has occurred."]
                        )
                    } else {
                        response = status
                    }
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: response, error: error)
                } else {
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                        response: "failed",
                        error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                    )
                }
            } catch {
                RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                    response: "failed",
                    error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                )
            }
        } else {
            RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                response: "failed",
                error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
            )
        }
    }

    private func exitSheet(_ rnMessage: String) {
        var response: String?
        var error: NSError?

        if let data = rnMessage.data(using: .utf8) {
            do {
                if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    let status = jsonDictionary["status"]

                    if status == "failed" || status == "requires_payment_method" {
                        error = NSError(
                            domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR",
                            code: 0,
                            userInfo: ["message": jsonDictionary["message"] ?? "An error has occurred."]
                        )
                    } else {
                        response = status
                    }
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: response, error: error)
                } else {
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                        response: "failed",
                        error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                    )
                }
            } catch {
                RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                    response: "failed",
                    error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                )
            }
        } else {
            RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                response: "failed",
                error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
            )
        }
        DispatchQueue.main.async {
            if let view = RNViewManager.sharedInstance.rootView {
                let reactNativeVC: UIViewController? = view.reactViewController()
                reactNativeVC?.dismiss(animated: false, completion: nil)
            }
        }
    }

    // MARK: - Bridge-backed view lookup helpers (support both old-arch and Fabric)

    private func withWidget(_ rootTag: NSNumber, _ block: @escaping (PaymentWidget) -> Void) {
        // rootTag here is the EMBEDDED widget's tag (from hyperswitch.bundle)
        // Use registry to find the outer view, then access its paymentWidget
        DispatchQueue.main.async {
            if let view = NativePaymentWidgetRegistry.shared.view(forEmbeddedTag: rootTag),
               let widget = view.paymentWidget {
                block(widget)
            }
        }
    }
    
    private func withNativePaymentWidgetView(_ rootTag: NSNumber, _ block: @escaping (NativePaymentWidgetView) -> Void) {
        // rootTag here is the EMBEDDED widget's tag (from hyperswitch.bundle)
        // Use registry to find the outer view by embedded tag
        DispatchQueue.main.async {
            if let view = NativePaymentWidgetRegistry.shared.view(forEmbeddedTag: rootTag) {
                block(view)
            }
        }
    }
    
    private func resolveSubscribingTarget(_ rootTag: NSNumber, _ block: @escaping (AnyObject?) -> Void) {
        // rootTag here is the EMBEDDED widget's tag (from hyperswitch.bundle)
        // Use registry-based lookup for widgets, fall back to bridge for payment sheets
        DispatchQueue.main.async {
            // First try widget registry (using embedded tag lookup)
            if let view = NativePaymentWidgetRegistry.shared.view(forEmbeddedTag: rootTag) {
                // Check for PaymentWidget or CVCWidget inside the view
                if let widget = view.paymentWidget {
                    block(widget)
                    return
                }
                if let cvc = view.cvcWidget {
                    block(cvc)
                    return
                }
            }
            
            // Fall back to bridge lookup for payment sheets (modal presentations)
            // For sheets, rootTag IS the actual view tag (not embedded)
            guard let bridge = self.bridge else {
                block(nil)
                return
            }
            RCTGetUIManagerQueue().async {
                bridge.uiManager.addUIBlock { _, viewRegistry in
                    let view = viewRegistry?[rootTag]
                    let sheet = (view?.reactViewController() as? HyperUIViewController)?.paymentSheet
                    DispatchQueue.main.async { block(sheet) }
                }
            }
        }
    }
    
    private func withPaymentSheet(_ rootTag: NSNumber, _ block: @escaping (UIViewController?, PaymentSheet?) -> Void) {
        guard let bridge = self.bridge else { return }
        RCTGetUIManagerQueue().async {
            bridge.uiManager.addUIBlock { _, viewRegistry in
                let view = viewRegistry?[rootTag]
                let vc = view?.reactViewController() as? HyperUIViewController
                let sheet = vc?.paymentSheet
                DispatchQueue.main.async { block(vc, sheet) }
            }
        }
    }
}
