//
//  HyperswitchModule.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 12/09/25.
//

import Foundation
import React

@objc(HyperswitchModule)
public class HyperswitchModule: NSObject {

    @objc public static let shared: HyperswitchModule = HyperswitchModule()

    // Instance handle -> Hyperswitch created with publishable key only.
    private var instances = [String: Hyperswitch]()

    private var activeHyperswitch: Hyperswitch?
    private var activePublishableKey: String?
    private var activeProfileId: String?
    private var activePaymentSession: PaymentSession?
    private var activePaymentSessionHandler: PaymentSessionHandler?
    @objc internal static var isCvcWidgetActive: Bool = false

    /// View-registry reference injected by HyperswitchSdkReactNative.mm so this singleton
    /// can resolve native widget views by reactTag.
    @objc public var viewRegistry_DEPRECATED: RCTViewRegistry?

    @objc(initialiseWithPublishableKey:customBackendUrl:customLogUrl:customParams:resolve:reject:)
    public func initialise(
        publishableKey: String,
        customBackendUrl: String?,
        customLogUrl: String?,
        customParams: [String: Any]?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        activePublishableKey = publishableKey
        activeProfileId = customParams?["profileId"] as? String

        let customEndpoints = CustomEndpointConfiguration.overrideEndpoints(
            OverrideEndpointConfiguration(
                customBackendEndpoint: customBackendUrl,
                customLoggingEndpoint: customLogUrl
            )
        )
        let hyperswitch = Hyperswitch(
            configuration: HyperswitchConfiguration(
                publishableKey: publishableKey,
                profileId: activeProfileId,
                customEndpoints: customEndpoints
            )
        )

        let handle = UUID().uuidString
        instances[handle] = hyperswitch

        resolve(handle)
    }

    @objc(initPaymentSession:sdkAuthorization:resolve:reject:)
    public func initPaymentSession(
        instanceHandle: String,
        sdkAuthorization: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let hyperswitch = instances[instanceHandle] else {
            reject("INIT_ERROR", "Hyperswitch instance not found for handle: \(instanceHandle)", NSError(domain: "HyperswitchModule", code: 0))
            return
        }

        activeHyperswitch = nil
        activePaymentSession = nil
        activePaymentSessionHandler = nil

        let session = hyperswitch.initPaymentSession(
            configuration: PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)
        )

        activeHyperswitch = hyperswitch
        activePaymentSession = session
        activePaymentSessionHandler = nil

        resolve("active")
    }

    internal static func getActiveHyperswitch() -> Hyperswitch? {
        return shared.activeHyperswitch
    }

    internal static func getActivePaymentSession() -> PaymentSession? {
        return shared.activePaymentSession
    }

    internal static func getActivePublishableKey() -> String? {
        return shared.activePublishableKey
    }

    internal static func getActiveProfileId() -> String? {
        return shared.activeProfileId
    }

    @objc(presentPaymentSheet:resolve:reject:)
    public func presentPaymentSheet(
        configuration: [String: Any],
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = activePaymentSession else {
            reject("PRESENT_ERROR", "Payment session not initialized. Call initPaymentSession first.", NSError(domain: "HyperswitchModule", code: 0))
            return
        }

        DispatchQueue.main.async {
            guard let vc = RCTPresentedViewController() else {
                reject("error", "Could not find presented view controller", NSError())
                return
            }
            session.presentPaymentSheetWithParams(
                viewController: vc,
                params: configuration,
                completion: { result in
                    switch result {
                    case .completed(let data):
                        resolve(["status": "completed", "message": data])
                    case .failed(let error as NSError):
                        resolve([
                            "status": "failed", "code": error.domain, "message": "Payment failed: \(error.userInfo["message"] ?? "Failed")",
                        ])
                    case .canceled(let data):
                        resolve(["status": "cancelled", "message": data])
                    }
                }
            )
        }
    }

    // MARK: - Headless Payment Methods

    @objc(getCustomerSavedPaymentMethods:resolve:reject:)
    public func getCustomerSavedPaymentMethods(
        options: [String: Any]?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = activePaymentSession else {
            resolve([
                "status": "error",
                "code": "NO_SESSION",
                "message": "Payment session not initialized. Call initPaymentSession first.",
            ])
            return
        }

        session.getCustomerSavedPaymentMethods { [weak self] handler in
            self?.activePaymentSessionHandler = handler
            resolve(["status": "success", "message": "Payment methods initialized"])
        }
    }

    @objc(getCustomerDefaultSavedPaymentMethodDataWithResolve:reject:)
    public func getCustomerDefaultSavedPaymentMethodData(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve([
                "status": "error",
                "message": "Payment session handler not initialized.",
            ])
            return
        }

        let result = handler.getCustomerDefaultSavedPaymentMethodData()
        switch result {
        case .success(let paymentMethod):
            if let jsonData = try? JSONEncoder().encode(paymentMethod),
                let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            {
                resolve([
                    "status": "success",
                    "message": "Default payment method retrieved",
                    "data": jsonDict,
                ])
            } else {
                resolve([
                    "status": "error",
                    "code": "ENCODE_ERROR",
                    "message": "Failed to encode payment method data",
                ])
            }
        case .failure(let error):
            resolve([
                "status": "failed",
                "code": error.code,
                "message": error.message,
            ])
        }
    }

    @objc(getCustomerLastUsedPaymentMethodDataWithResolve:reject:)
    public func getCustomerLastUsedPaymentMethodData(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve([
                "status": "error",
                "message": "Payment session handler not initialized.",
            ])
            return
        }

        let result = handler.getCustomerLastUsedPaymentMethodData()
        switch result {
        case .success(let paymentMethod):
            if let jsonData = try? JSONEncoder().encode(paymentMethod),
                let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            {
                resolve([
                    "status": "success",
                    "message": "Last used payment method retrieved",
                    "data": jsonDict,
                ])
            } else {
                resolve([
                    "status": "error",
                    "code": "ENCODE_ERROR",
                    "message": "Failed to encode payment method",
                ])
            }
        case .failure(let error):
            resolve([
                "status": "failed",
                "code": error.code,
                "message": error.message,
            ])
        }
    }

    @objc(confirmWithCustomerDefaultPaymentMethod:resolve:reject:)
    public func confirmWithCustomerDefaultPaymentMethod(
        cvcWidgetReactTag: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve([
                "status": "error",
                "message": "Payment session handler not initialized.",
            ])
            return
        }

        let reactTag = Int(cvcWidgetReactTag ?? "") ?? 0

        if reactTag > 0 {
            // CvcWidget reactTag provided — route through the native widget view
            // so we can use the inner RCTRootView tag (widgetReactTag).
            let result = handler.getCustomerDefaultSavedPaymentMethodData()
            switch result {
            case .success(let paymentMethod):
                if paymentMethod.requiresCvv && paymentMethod.paymentMethod == "card" {
                    self.withNativePaymentWidgetView(
                        NSNumber(value: reactTag),
                        onFound: { view in
                            view.confirmCVCPayment(
                                paymentToken: paymentMethod.paymentToken,
                                paymentMethodId: paymentMethod.paymentMethodId,
                                resolve: resolve
                            )
                        },
                        onMissing: {
                            resolve([
                                "status": "failed",
                                "code": "WIDGET_NOT_FOUND",
                                "message": "CVC widget view not found for reactTag \(reactTag)",
                            ])
                        }
                    )
                } else {
                    // Not a card or requiresCvv is false — bypass CvcWidget, confirm directly with cvc = nil
                    handler.confirmWithCustomerDefaultPaymentMethod { result in
                        resolve(HyperswitchModule.paymentResultToDict(result))
                    }
                }
            case .failure(let error):
                resolve([
                    "status": "failed",
                    "code": error.code,
                    "message": error.message,
                ])
            }
        } else {
            // No CvcWidget — confirm through HeadlessTask callback (cvc will be nil)
            handler.confirmWithCustomerDefaultPaymentMethod { result in
                resolve(HyperswitchModule.paymentResultToDict(result))
            }
        }
    }

    @objc(confirmWithCustomerLastUsedPaymentMethod:resolve:reject:)
    public func confirmWithCustomerLastUsedPaymentMethod(
        cvcWidgetReactTag: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve([
                "status": "error",
                "message": "Payment session handler not initialized.",
            ])
            return
        }

        let reactTag = Int(cvcWidgetReactTag ?? "") ?? 0

        if reactTag > 0 {
            // CvcWidget reactTag provided — route through the native widget view
            // so we can use the inner RCTRootView tag (widgetReactTag).
            let result = handler.getCustomerLastUsedPaymentMethodData()
            switch result {
            case .success(let paymentMethod):
                if paymentMethod.requiresCvv && paymentMethod.paymentMethod == "card" {
                    self.withNativePaymentWidgetView(
                        NSNumber(value: reactTag),
                        onFound: { view in
                            guard let cvcWidget = view.cvcWidgetRef else {
                                resolve([
                                    "status": "failed",
                                    "code": "WIDGET_NOT_READY",
                                    "message": "CVC widget is not ready",
                                ])
                                return
                            }
                            handler.confirmWithCustomerLastUsedPaymentMethod(cvcWidget) { result in
                                resolve(HyperswitchModule.paymentResultToDict(result))
                            }
                        },
                        onMissing: {
                            resolve([
                                "status": "failed",
                                "code": "WIDGET_NOT_FOUND",
                                "message": "CVC widget view not found for reactTag \(reactTag)",
                            ])
                        }
                    )
                } else {
                    // Not a card or requiresCvv is false — bypass CvcWidget, confirm directly with cvc = nil
                    resolve([
                        "status": "failed",
                        "code": "CVC_WIDGET_REQUIRED",
                        "message": "CVC widget is required to confirm the last used card payment method",
                    ])
                }
            case .failure(let error):
                resolve([
                    "status": "failed",
                    "code": error.code,
                    "message": error.message,
                ])
            }
        } else {
            resolve([
                "status": "failed",
                "code": "CVC_WIDGET_REQUIRED",
                "message": "CVC widget is required to confirm the last used payment method",
            ])
        }
    }

    @objc(confirmWithCustomerPaymentToken:resolve:reject:)
    public func confirmWithCustomerPaymentToken(
        paymentToken: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve([
                "status": "error",
                "message": "Payment session handler not initialized.",
            ])
            return
        }

      handler.confirmWithCustomerPaymentToken(paymentToken: paymentToken) { result in
            resolve(HyperswitchModule.paymentResultToDict(result))
        }
    }

    @objc(updateIntent:resolve:reject:)
    public func updateIntent(
        sdkAuthorization: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = activePaymentSession else {
            reject("UPDATE_INTENT_ERROR", "Payment session not initialized. Call initPaymentSession first.", NSError(domain: "HyperswitchModule", code: 0))
            return
        }

        session.updateIntent(
            authorizationProvider: { completion in
                completion(sdkAuthorization)
            },
            completion: { result in
                switch result {
                case .success:
                    resolve(["status": "success", "message": "Payment intent updated"])
                case .cancelled:
                    resolve(["status": "cancelled", "message": "Payment intent update cancelled"])
                case .failure(let error as NSError):
                    reject(error.domain, error.userInfo[NSLocalizedDescriptionKey] as? String ?? "Payment intent update failed", error)
                }
            }
        )
    }

    // MARK: - CvcWidget View Lookup

    /// Looks up the NativePaymentWidgetView for the supplied React tag by walking up the view
    /// hierarchy, mirroring the approach used in HyperModule. Calls `onFound` when the widget
    /// wrapper is located, otherwise `onMissing`.
    private func withNativePaymentWidgetView(
        _ reactTag: NSNumber,
        onFound: @escaping (NativePaymentWidgetView) -> Void,
        onMissing: @escaping () -> Void
    ) {
        guard let viewRegistry = self.viewRegistry_DEPRECATED else {
            onMissing()
            return
        }
        let view = viewRegistry.view(forReactTag: reactTag)
        var current: UIView? = view
        while let v = current {
            if let nativeWidget = v as? NativePaymentWidgetView {
                onFound(nativeWidget)
                return
            }
            current = v.superview
        }
        onMissing()
    }

    /// Convert a PaymentResult to a dictionary suitable for RCTPromiseResolveBlock.
    private static func paymentResultToDict(_ result: PaymentResult) -> [String: Any] {
        switch result {
        case .completed(let data):
            return [
                "status": "success",
                "message": "Payment confirmed successfully",
                "data": data,
            ]
        case .failed(let error as NSError):
            return [
                "status": "failed",
                "code": error.domain,
                "message": error.userInfo["message"] as? String ?? "Payment confirmation failed",
            ]
        case .canceled(let data):
            return [
                "status": "cancelled",
                "message": "Payment confirmation cancelled",
                "data": data,
            ]
        }
    }
}
