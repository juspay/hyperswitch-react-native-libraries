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

    // MARK: - JSON string helpers

    /// Serialise a plain `[String: Any?]` to a compact JSON string.
    /// Returns `"{}"` on failure so callers always receive a valid string.
    private static func toJSONString(_ dict: [String: Any?]) -> String {
        // JSONSerialization can't handle `Any?` keys that are nil, so strip them first.
        let cleaned = dict.compactMapValues { $0 }
        guard
            let data = try? JSONSerialization.data(withJSONObject: cleaned, options: []),
            let str = String(data: data, encoding: .utf8)
        else { return "{}" }
        return str
    }

    /// Encode an `Encodable` value to a JSON string.
    private static func encodeToJSONString<T: Encodable>(_ value: T) -> String? {
        guard
            let data = try? JSONEncoder().encode(value),
            let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }

    ///   `{"code": ..., "message": ..., "status": ..., "error": ...}`
    private static func standardResult(
        status: String,
        code: String? = nil,
        message: String? = nil,
        error: String? = nil
    ) -> String {
        return toJSONString([
            "status": status,
            "code": code as Any?,
            "message": message as Any?,
            "error": error as Any?,
        ])
    }

    private static func paymentResultToJSONString(_ result: PaymentResult) -> String {
        switch result {
        case .completed:
            return standardResult(status: "success")
        case .failed(let error as NSError):
            let msg = error.userInfo["message"] as? String ?? error.localizedDescription
            return standardResult(status: "failed", code: error.domain, message: msg, error: msg)
        case .canceled:
            return standardResult(status: "cancelled", message: "Payment cancelled")
        }
    }

    // MARK: - initialise

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

    // MARK: - presentPaymentSheet

    @objc(presentPaymentSheet:resolve:reject:)
    public func presentPaymentSheet(
        configuration: [String: Any],
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = activePaymentSession else {
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "PRESENT_ERROR",
                message: "Payment session not initialized. Call initPaymentSession first.",
                error: "Payment session not initialized."
            ))
            return
        }

        DispatchQueue.main.async {
            guard let vc = RCTPresentedViewController() else {
                resolve(HyperswitchModule.standardResult(
                    status: "failed",
                    code: "PRESENT_ERROR",
                    message: "Could not find presented view controller",
                    error: "Could not find presented view controller"
                ))
                return
            }
            session.presentPaymentSheetWithParams(
                viewController: vc,
                params: configuration,
                rawCompletion: { raw in
                    // `raw` is the unmodified JSON string sent by the JS bundle via
                    // exitPaymentsheet — identical to what Android resolves with.
                    resolve(raw)
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
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "NO_SESSION",
                message: "Payment session not initialized. Call initPaymentSession first.",
                error: "Payment session not initialized."
            ))
            return
        }

        session.getCustomerSavedPaymentMethods { [weak self] handler in
            self?.activePaymentSessionHandler = handler
            resolve(HyperswitchModule.toJSONString([
                "code": "success",
                "message": "Saved payment methods is initialized",
            ]))
        }
    }

    /// Mirrors Android: resolves with the payment-method data JSON string directly (no wrapper).
    @objc(getCustomerDefaultSavedPaymentMethodDataWithResolve:reject:)
    public func getCustomerDefaultSavedPaymentMethodData(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "NO_HANDLER",
                message: "Payment session handler not initialized.",
                error: "Payment session handler not initialized."
            ))
            return
        }

        let result = handler.getCustomerDefaultSavedPaymentMethodData()
        switch result {
        case .success(let paymentMethod):
            // Return the payment-method data JSON directly, matching Android's
            // `ConversionUtils.convertMapToJson(data.toMap()).toString()`.
            resolve(HyperswitchModule.encodeToJSONString(paymentMethod) ?? "{}")
        case .failure(let error):
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: error.code,
                message: error.message,
                error: error.message
            ))
        }
    }

    /// Mirrors Android: resolves with the payment-method data JSON string directly (no wrapper).
    @objc(getCustomerLastUsedPaymentMethodDataWithResolve:reject:)
    public func getCustomerLastUsedPaymentMethodData(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "NO_HANDLER",
                message: "Payment session handler not initialized.",
                error: "Payment session handler not initialized."
            ))
            return
        }

        let result = handler.getCustomerLastUsedPaymentMethodData()
        switch result {
        case .success(let paymentMethod):
            resolve(HyperswitchModule.encodeToJSONString(paymentMethod) ?? "{}")
        case .failure(let error):
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: error.code,
                message: error.message,
                error: error.message
            ))
        }
    }

    /// Mirrors Android: resolves with a JSON array string of all saved payment methods.
    @objc(getCustomerSavedPaymentMethodDataWithResolve:reject:)
    public func getCustomerSavedPaymentMethodData(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "NO_HANDLER",
                message: "Payment session handler not initialized.",
                error: "Payment session handler not initialized."
            ))
            return
        }

        let result = handler.getCustomerSavedPaymentMethodData()
        switch result {
        case .success(let paymentMethods):
            // Return a JSON array string, matching Android's `jsonArray.toString()`.
            resolve(HyperswitchModule.encodeToJSONString(paymentMethods) ?? "[]")
        case .failure(let error):
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: error.code,
                message: error.message,
                error: error.message
            ))
        }
    }

    // MARK: - Confirm methods

    @objc(confirmWithCustomerDefaultPaymentMethod:resolve:reject:)
    public func confirmWithCustomerDefaultPaymentMethod(
        cvcWidgetReactTag: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "NO_HANDLER",
                message: "Payment session handler not initialized.",
                error: "Payment session handler not initialized."
            ))
            return
        }

        let reactTag = Int(cvcWidgetReactTag ?? "") ?? 0

        if reactTag > 0 {
            let result = handler.getCustomerDefaultSavedPaymentMethodData()
            switch result {
            case .success(let paymentMethod):
                if paymentMethod.requiresCvv && paymentMethod.paymentMethod == "card" {
                    self.withNativePaymentWidgetView(
                        NSNumber(value: reactTag),
                        onFound: { _ in
                            // CVC widget confirm path — not yet fully wired; fall through.
                        },
                        onMissing: {
                            resolve(HyperswitchModule.standardResult(
                                status: "failed",
                                code: "WIDGET_NOT_FOUND",
                                message: "CVC widget view not found for reactTag \(reactTag)",
                                error: "CVC widget view not found for reactTag \(reactTag)"
                            ))
                        }
                    )
                } else {
                    handler.confirmWithCustomerDefaultPaymentMethod { result in
                        resolve(HyperswitchModule.paymentResultToJSONString(result))
                    }
                }
            case .failure(let error):
                resolve(HyperswitchModule.standardResult(
                    status: "failed",
                    code: error.code,
                    message: error.message,
                    error: error.message
                ))
            }
        } else {
            handler.confirmWithCustomerDefaultPaymentMethod { result in
                resolve(HyperswitchModule.paymentResultToJSONString(result))
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
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "NO_HANDLER",
                message: "Payment session handler not initialized.",
                error: "Payment session handler not initialized."
            ))
            return
        }

        let reactTag = Int(cvcWidgetReactTag ?? "") ?? 0

        if reactTag > 0 {
            let result = handler.getCustomerLastUsedPaymentMethodData()
            switch result {
            case .success(let paymentMethod):
                if paymentMethod.requiresCvv && paymentMethod.paymentMethod == "card" {
                    self.withNativePaymentWidgetView(
                        NSNumber(value: reactTag),
                        onFound: { _ in
                            // CVC widget confirm path — not yet fully wired; fall through.
                        },
                        onMissing: {
                            resolve(HyperswitchModule.standardResult(
                                status: "failed",
                                code: "WIDGET_NOT_FOUND",
                                message: "CVC widget view not found for reactTag \(reactTag)",
                                error: "CVC widget view not found for reactTag \(reactTag)"
                            ))
                        }
                    )
                } else {
                    resolve(HyperswitchModule.standardResult(
                        status: "failed",
                        code: "CVC_WIDGET_REQUIRED",
                        message: "CVC widget is required to confirm the last used card payment method",
                        error: "CVC widget is required"
                    ))
                }
            case .failure(let error):
                resolve(HyperswitchModule.standardResult(
                    status: "failed",
                    code: error.code,
                    message: error.message,
                    error: error.message
                ))
            }
        } else {
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "CVC_WIDGET_REQUIRED",
                message: "CVC widget is required to confirm the last used payment method",
                error: "CVC widget is required"
            ))
        }
    }

    @objc(confirmWithCustomerPaymentToken:resolve:reject:)
    public func confirmWithCustomerPaymentToken(
        paymentToken: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve(HyperswitchModule.standardResult(
                status: "failed",
                code: "NO_HANDLER",
                message: "Payment session handler not initialized.",
                error: "Payment session handler not initialized."
            ))
            return
        }

        handler.confirmWithCustomerPaymentToken(paymentToken: paymentToken) { result in
            resolve(HyperswitchModule.paymentResultToJSONString(result))
        }
    }

    @objc(updateIntent:resolve:reject:)
    public func updateIntent(
        sdkAuthorization: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let session = activePaymentSession else {
            reject(
                "UPDATE_INTENT_ERROR",
                "Payment session not initialized. Call initPaymentSession first.",
                NSError(domain: "HyperswitchModule", code: 0)
            )
            return
        }

        session.updateIntent(
            authorizationProvider: { completion in
                completion(sdkAuthorization)
            },
            completion: { result in
                switch result {
                case .success:
                    resolve(HyperswitchModule.standardResult(status: "success", message: "Payment intent updated"))
                case .cancelled:
                    resolve(HyperswitchModule.standardResult(status: "cancelled", message: "Payment intent update cancelled"))
                case .failure(let error as NSError):
                    reject(error.domain, error.userInfo[NSLocalizedDescriptionKey] as? String ?? "Payment intent update failed", error)
                }
            }
        )
    }

    // MARK: - CvcWidget View Lookup

    private func withNativePaymentWidgetView(
        _ reactTag: NSNumber,
        onFound: @escaping (PaymentWidget) -> Void,
        onMissing: @escaping () -> Void
    ) {
        guard let viewRegistry = self.viewRegistry_DEPRECATED else {
            onMissing()
            return
        }
        let view = viewRegistry.view(forReactTag: reactTag)
        var current: UIView? = view
        while let v = current {
            if let nativeWidget = v as? PaymentWidget {
                onFound(nativeWidget)
                return
            }
            current = v.superview
        }
        onMissing()
    }

    // MARK: - Internal helpers (used by HyperswitchModule.mm)

    internal static func paymentResultToDict(_ result: PaymentResult) -> [String: Any] {
        switch result {
        case .completed:
            return ["status": "success", "code": NSNull(), "message": NSNull(), "error": NSNull()]
        case .failed(let error as NSError):
            let msg = error.userInfo["message"] as? String ?? error.localizedDescription
            return ["status": "failed", "code": error.domain, "message": msg, "error": msg]
        case .canceled:
            return ["status": "cancelled", "code": NSNull(), "message": "Payment cancelled", "error": NSNull()]
        }
    }
}
