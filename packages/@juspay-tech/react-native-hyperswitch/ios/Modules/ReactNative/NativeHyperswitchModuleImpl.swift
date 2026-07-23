//
//  NativeHyperswitchModuleImpl.swift
//  HyperswitchSdkReactNative
//
//  Mirrors the Android ReactNativeHyperswitchModule (NativeHyperswitchModule) API exactly.
//  Method signatures must stay in sync with:
//    - src/specs/NativeHyperswitchModule.ts
//    - android/src/main/java/com/hyperswitchsdkreactnative/modules/ReactNativeHyperswitchModule.kt
//

import Foundation
import React

@objc(NativeHyperswitchModuleImpl)
public class NativeHyperswitchModuleImpl: NSObject {

    @objc public static let shared: NativeHyperswitchModuleImpl = NativeHyperswitchModuleImpl()

    private var hyperswitchConfiguration: HyperswitchConfiguration?
    private var activePaymentSession: PaymentSession?
    private var activePaymentSessionHandler: PaymentSessionHandler?

    // MARK: - initialise
    // Flat params — matches Android's:
    //   initialise(publishableKey, platformPublishableKey, profileId, environment, customEndpoints, promise)

    @objc(initialiseWithPublishableKey:platformPublishableKey:profileId:environment:customEndpoints:resolve:reject:)
    public func initialise(
        publishableKey: String,
        platformPublishableKey: String,
        profileId: String,
        environment: String,
        customEndpoints: [String: Any],
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        // Build CustomEndpointConfiguration from the JS-side customEndpoints object
        var endpointsConfig: CustomEndpointConfiguration? = nil
        if let overrideDict = customEndpoints["overrideEndpoints"] as? [String: Any] {
            endpointsConfig = .overrideEndpoints(OverrideEndpointConfiguration(
                customBackendEndpoint: overrideDict["customBackendEndpoint"] as? String,
                customAssetEndpoint: overrideDict["customAssetEndpoint"] as? String,
                customSDKConfigEndpoint: overrideDict["customSDKConfigEndpoint"] as? String,
                customConfirmEndpoint: overrideDict["customConfirmEndpoint"] as? String,
                customAirborneEndpoint: overrideDict["customAirborneEndpoint"] as? String,
                customLoggingEndpoint: overrideDict["customLoggingEndpoint"] as? String
            ))
        } else if let common = customEndpoints["commonEndpoint"] as? String, !common.isEmpty {
            endpointsConfig = .commonEndpoint(common)
        }

        // Map environment string (Android uses "PROD"/"SANDBOX") to the Swift enum
        let envEnum: HyperswitchEnvironment?
        switch environment.uppercased() {
        case "PROD", "PRODUCTION":
            envEnum = .production
        case "SANDBOX":
            envEnum = .sandbox
        default:
            envEnum = nil
        }

        hyperswitchConfiguration = HyperswitchConfiguration(
            publishableKey: publishableKey,
            profileId: profileId.isEmpty ? nil : profileId,
            customEndpoints: endpointsConfig,
            environment: envEnum
        )

        // Resolve with a UUID handle (matches Android behaviour)
        resolve(UUID().uuidString)
    }

    // MARK: - presentPaymentSheet
    // params: { hyperswitchConfig, paymentSessionConfig: { sdkAuthorization }, configuration }
    // Mirrors Android: presentPaymentSheet(params: ReadableMap?, promise: Promise?)

    @objc(presentPaymentSheet:resolve:reject:)
    public func presentPaymentSheet(
        params: [String: Any],
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let hyperswitchConfig = hyperswitchConfiguration else {
            resolve([
                "status": "failed",
                "code": "NOT_INITIALIZED",
                "message": "SDK not initialized. Call initialise first.",
            ])
            return
        }

        guard
            let sessionConfig = params["paymentSessionConfig"] as? [String: Any],
            let sdkAuthorization = sessionConfig["sdkAuthorization"] as? String,
            !sdkAuthorization.isEmpty
        else {
            resolve([
                "status": "failed",
                "code": "INVALID_PARAMS",
                "message": "paymentSessionConfig.sdkAuthorization is required",
            ])
            return
        }

        let session = PaymentSession(
            paymentSessionConfiguration: PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization),
            hyperswitchConfiguration: hyperswitchConfig
        )
        activePaymentSession = session
        activePaymentSessionHandler = nil

        DispatchQueue.main.async {
            guard let vc = RCTPresentedViewController() else {
                resolve([
                    "status": "failed",
                    "code": "NO_VIEW_CONTROLLER",
                    "message": "Could not find presented view controller",
                ])
                return
            }

            // The SDK's getRootViewWithParams wraps the whole `props` dictionary
            // under the `configuration` key, so we must pass the contents that
            // belong inside `configuration`: the merchant-supplied configuration
            // plus the session/hyperswitch metadata.
            var sheetProps = params["configuration"] as? [String: Any] ?? [:]
            sheetProps["hyperswitchConfig"] = params["hyperswitchConfig"]
            sheetProps["paymentSessionConfig"] = params["paymentSessionConfig"]

            session.presentPaymentSheetWithParams(
                viewController: vc,
                params: sheetProps,
                completion: { result in
                    switch result {
                    case .completed(let data):
                        resolve(["status": "completed", "message": data])
                    case .failed(let error as NSError):
                        resolve([
                            "status": "failed",
                            "code": error.domain,
                            "message": "\(error.userInfo["message"] ?? "Failed")",
                        ])
                    case .canceled(let data):
                        resolve(["status": "cancelled", "message": data])
                    }
                }
            )
        }
    }

    // MARK: - getCustomerSavedPaymentMethods
    // params: { hyperswitchConfig, paymentSessionConfig: { sdkAuthorization }, configuration }
    // Mirrors Android: getCustomerSavedPaymentMethods(params: ReadableMap?, promise: Promise)

    @objc(getCustomerSavedPaymentMethods:resolve:reject:)
    public func getCustomerSavedPaymentMethods(
        params: [String: Any]?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let hyperswitchConfig = hyperswitchConfiguration else {
            resolve("{\"code\":\"error\",\"message\":\"SDK not initialized. Call initialise first.\"}")
            return
        }

        guard
            let p = params,
            let sessionConfig = p["paymentSessionConfig"] as? [String: Any],
            let sdkAuthorization = sessionConfig["sdkAuthorization"] as? String,
            !sdkAuthorization.isEmpty
        else {
            resolve("{\"code\":\"error\",\"message\":\"paymentSessionConfig.sdkAuthorization is required\"}")
            return
        }

        let session = PaymentSession(
            paymentSessionConfiguration: PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization),
            hyperswitchConfiguration: hyperswitchConfig
        )
        activePaymentSession = session

        session.getCustomerSavedPaymentMethods { [weak self] handler in
            self?.activePaymentSessionHandler = handler
            // Matches Android: JSONObject { "code": "success", "message": "Saved payment methods is initialized" }.toString()
            resolve("{\"code\":\"success\",\"message\":\"Saved payment methods is initialized\"}")
        }
    }

    // MARK: - getCustomerLastUsedPaymentMethodData
    // Mirrors Android: getCustomerLastUsedPaymentMethodData(promise: Promise)
    // Returns: JSON string of the PaymentMethod (snake_case keys via CodingKeys)

    @objc(getCustomerLastUsedPaymentMethodDataWithResolve:reject:)
    public func getCustomerLastUsedPaymentMethodData(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve("{\"status\":\"error\",\"message\":\"Payment session handler not initialized.\"}")
            return
        }

        let result = handler.getCustomerLastUsedPaymentMethodData()
        switch result {
        case .success(let paymentMethod):
            if let jsonData = try? JSONEncoder().encode(paymentMethod),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                resolve(jsonString)
            } else {
                resolve("{\"status\":\"error\",\"message\":\"Failed to encode payment method\"}")
            }
        case .failure(let error):
            resolve("{\"status\":\"failed\",\"code\":\"\(error.code)\",\"message\":\"\(error.message)\"}")
        }
    }

    // MARK: - getCustomerDefaultSavedPaymentMethodData
    // Mirrors Android: getCustomerDefaultSavedPaymentMethodData(promise: Promise)

    @objc(getCustomerDefaultSavedPaymentMethodDataWithResolve:reject:)
    public func getCustomerDefaultSavedPaymentMethodData(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve("{\"status\":\"error\",\"message\":\"Payment session handler not initialized.\"}")
            return
        }

        let result = handler.getCustomerDefaultSavedPaymentMethodData()
        switch result {
        case .success(let paymentMethod):
            if let jsonData = try? JSONEncoder().encode(paymentMethod),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                resolve(jsonString)
            } else {
                resolve("{\"status\":\"error\",\"message\":\"Failed to encode payment method\"}")
            }
        case .failure(let error):
            resolve("{\"status\":\"failed\",\"code\":\"\(error.code)\",\"message\":\"\(error.message)\"}")
        }
    }

    // MARK: - getCustomerSavedPaymentMethodData  ← NEW (not in prior iOS module)
    // Mirrors Android: getCustomerSavedPaymentMethodData(promise: Promise)
    // Returns: JSON array string of all saved PaymentMethod objects

    @objc(getCustomerSavedPaymentMethodDataWithResolve:reject:)
    public func getCustomerSavedPaymentMethodData(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let handler = activePaymentSessionHandler else {
            resolve("{\"status\":\"error\",\"message\":\"Payment session handler not initialized.\"}")
            return
        }

        let result = handler.getCustomerSavedPaymentMethodData()
        switch result {
        case .success(let paymentMethods):
            if let jsonData = try? JSONEncoder().encode(paymentMethods),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                resolve(jsonString)
            } else {
                resolve("{\"status\":\"error\",\"message\":\"Failed to encode payment methods\"}")
            }
        case .failure(let error):
            resolve("{\"status\":\"failed\",\"code\":\"\(error.code)\",\"message\":\"\(error.message)\"}")
        }
    }

    // MARK: - confirmWithCustomerLastUsedPaymentMethod
    // JS / Android: confirmWithCustomerLastUsedPaymentMethod(reactTag: Double, promise: Promise?)

    @objc(confirmWithCustomerLastUsedPaymentMethod:resolve:reject:)
    public func confirmWithCustomerLastUsedPaymentMethod(
        reactTag: Double,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        // TODO: Not yet implemented — mirrors Android
        resolve("{\"status\":\"failed\",\"message\":\"Not yet implemented\"}")
    }

    // MARK: - confirmWithCustomerDefaultPaymentMethod
    // JS / Android: confirmWithCustomerDefaultPaymentMethod(reactTag: Double, promise: Promise?)

    @objc(confirmWithCustomerDefaultPaymentMethod:resolve:reject:)
    public func confirmWithCustomerDefaultPaymentMethod(
        reactTag: Double,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        // TODO: Not yet implemented — mirrors Android
        resolve("{\"status\":\"failed\",\"message\":\"Not yet implemented\"}")
    }
}
