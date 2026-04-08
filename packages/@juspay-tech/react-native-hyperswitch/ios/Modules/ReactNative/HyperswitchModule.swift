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
  private var paymentSession: PaymentSession?
  private var paymentSessionHandler: PaymentSessionHandler?
  @objc internal static var isCvcWidgetActive: Bool = false

  @objc(initialiseWithPublishableKey:customBackendUrl:customLogUrl:customParams:resolve:reject:)
  public func initialise(publishableKey: String,
                         customBackendUrl: String?,
                         customLogUrl: String?,
                         customParams: [String:Any],
                         resolve: @escaping RCTPromiseResolveBlock,
                         reject: @escaping RCTPromiseRejectBlock) -> Void {

    self.paymentSession = PaymentSession(publishableKey: publishableKey,
                                         customBackendUrl: customBackendUrl,
                                         customParams: customParams,
                                         customLogUrl: customLogUrl)
    resolve(NSNull())
  }

  @objc(initPaymentSessionWithpaymentIntentClientSecret:resolve:reject:)
  public func initPaymentSession(paymentIntentClientSecret: String,
                                 resolve: @escaping RCTPromiseResolveBlock,
                                 reject: @escaping RCTPromiseRejectBlock) -> Void {

    self.paymentSession?.initPaymentSession(paymentIntentClientSecret: paymentIntentClientSecret)
    resolve(NSNull())
  }

  @objc(presentPaymentSheetWithConfiguration:resolver:rejecter:)
  public func presentPaymentSheet(configuration: [String:Any],
                                  resolve: @escaping RCTPromiseResolveBlock,
                                  reject: @escaping RCTPromiseRejectBlock) -> Void{
    DispatchQueue.main.async {
      guard let vc = RCTPresentedViewController() else {
        reject("error", "Could not find presented view controller", NSError())
        return
      }
      self.paymentSession?.presentPaymentSheetWithParams(viewController: vc, params: configuration, completion: { result in
        switch result {
        case .completed(let data):
          resolve(["status": "completed", "message": "Payment completed", "data": data])
        case .failed(let error as NSError):
          resolve(["status": "failed", "code": error.domain, "message": "\(error.userInfo["message"] ?? "Payment failed")"])
        case .canceled(let data):
          resolve(["status": "cancelled", "message": "Payment cancelled", "data": data])
        }
      })
    }
  }

  // MARK: - Headless Payment Methods

  private func initSavedPaymentMethodSessionCallback(handler: PaymentSessionHandler)-> Void {
      self.paymentSessionHandler = handler
  }

  @objc
  public func getCustomerSavedPaymentMethods(
      withResolve resolve: @escaping RCTPromiseResolveBlock,
      reject: @escaping RCTPromiseRejectBlock
  ) -> Void {
      self.paymentSession?.getCustomerSavedPaymentMethods(initSavedPaymentMethodSessionCallback)

      resolve(["status": "success", "message": "Payment methods initialized"])
  }

  @objc
  public func getCustomerDefaultSavedPaymentMethodData(
    withResolve resolve: @escaping RCTPromiseResolveBlock,
      reject: @escaping RCTPromiseRejectBlock
  ) -> Void {
      guard let handler = self.paymentSessionHandler else {
          resolve([
              "status": "error",
              "code": "UNKNOWN",
              "message": "Payment session handler not initialized."
          ])
          return
      }

      let result = handler.getCustomerDefaultSavedPaymentMethodData()
      switch result {
      case .success(let paymentMethod):
          if let jsonData = try? JSONEncoder().encode(paymentMethod),
             let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
              resolve([
                  "status": "success",
                  "message": "Default payment method retrieved",
                  "data": jsonDict
              ])
          } else {
              resolve([
                  "status": "error",
                  "code": "ENCODE_ERROR",
                  "message": "Failed to encode payment method data"
              ])
          }
      case .failure(let error):
          resolve([
              "status": "failed",
              "code": error.code,
              "message": error.message
          ])
      }
  }

  @objc
  public func getCustomerLastUsedPaymentMethodData(
    withResolve resolve: @escaping RCTPromiseResolveBlock,
      reject: @escaping RCTPromiseRejectBlock
  ) -> Void {
      guard let handler = self.paymentSessionHandler else {
          resolve([
              "status": "error",
              "code": "UNKNOWN",
              "message": "Payment session handler not initialized."
          ])
          return
      }

      let result = handler.getCustomerLastUsedPaymentMethodData()
      switch result {
      case .success(let paymentMethod):
          if let jsonData = try? JSONEncoder().encode(paymentMethod),
             let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
              resolve([
                  "status": "success",
                  "message": "Last used payment method retrieved",
                  "data": jsonDict
              ])
          } else {
              resolve([
                  "status": "error",
                  "code": "ENCODE_ERROR",
                  "message": "Failed to encode payment method"
              ])
          }
      case .failure(let error):
          resolve([
              "status": "failed",
              "code": error.code,
              "message": error.message
          ])
      }
  }

  @objc(confirmWithCustomerDefaultPaymentMethodWithReactTag:withResolve:reject:)
  public func confirmWithCustomerDefaultPaymentMethod(
    reactTag: Int,
    withResolve resolve: @escaping RCTPromiseResolveBlock,
      reject: @escaping RCTPromiseRejectBlock
  ) -> Void {
      guard let handler = self.paymentSessionHandler else {
          resolve([
              "status": "error",
              "code": "UNKNOWN",
              "message": "Payment session handler not initialized."
          ])
          return
      }

      if reactTag > 0 {
          // CvcWidget reactTag provided — route through widget bridge
          let result = handler.getCustomerDefaultSavedPaymentMethodData()
          switch result {
          case .success(let paymentMethod):
              if paymentMethod.requiresCvv && paymentMethod.paymentMethod == "card" {
                  HyperswitchModule.confirmViaWidget(
                      reactTag: reactTag,
                      paymentToken: paymentMethod.paymentToken,
                      paymentMethodId: paymentMethod.paymentMethodId,
                      resolve: resolve
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
                  "message": error.message
              ])
          }
      } else {
          // No CvcWidget — confirm through HeadlessTask callback (cvc will be nil)
          handler.confirmWithCustomerDefaultPaymentMethod { result in
              resolve(HyperswitchModule.paymentResultToDict(result))
          }
      }
  }
  
//  @objc(confirmPaymentWithWidgetId:resolve:reject:)
//  public func confirmPayment(
//    withWidgetId widgetId: String,
//    resolve: @escaping RCTPromiseResolveBlock,
//    reject: @escaping RCTPromiseRejectBlock
//  ) -> Void {
//    guard let hyperModule = HyperModule.shared else {
//      resolve([
//          "status": "error",
//          "code": "NOT_INITIALIZED",
//          "message": "HyperModule is not initialized."
//      ])
//      return
//    }
//    hyperModule.confirmPayment(widgetId, resolve: resolve, reject: reject)
//  }

  @objc(confirmWithCustomerLastUsedPaymentMethodWithReactTag:withResolve:reject:)
  public func confirmWithCustomerLastUsedPaymentMethod(
    reactTag: Int,
    withResolve resolve: @escaping RCTPromiseResolveBlock,
      reject: @escaping RCTPromiseRejectBlock
  ) -> Void {
      guard let handler = self.paymentSessionHandler else {
          resolve([
              "status": "error",
              "code": "NO_HANDLER",
              "message": "Payment session handler not initialized."
          ])
          return
      }

      if reactTag > 0 {
          // CvcWidget reactTag provided — route through widget bridge
          let result = handler.getCustomerLastUsedPaymentMethodData()
          switch result {
          case .success(let paymentMethod):
              if paymentMethod.requiresCvv && paymentMethod.paymentMethod == "card" {
                  HyperswitchModule.confirmViaWidget(
                      reactTag: reactTag,
                      paymentToken: paymentMethod.paymentToken,
                      paymentMethodId: paymentMethod.paymentMethodId,
                      resolve: resolve
                  )
              } else {
                  // Not a card or requiresCvv is false — bypass CvcWidget, confirm directly with cvc = nil
                  handler.confirmWithCustomerLastUsedPaymentMethod { result in
                      resolve(HyperswitchModule.paymentResultToDict(result))
                  }
              }
          case .failure(let error):
              resolve([
                  "status": "failed",
                  "code": error.code,
                  "message": error.message
              ])
          }
      } else {
          // No CvcWidget — confirm through HeadlessTask callback (cvc will be nil)
          handler.confirmWithCustomerLastUsedPaymentMethod { result in
              resolve(HyperswitchModule.paymentResultToDict(result))
          }
      }
  }

  // MARK: - CvcWidget Confirm Routing

  /// Emit "triggerWidgetAction" with CONFIRM_CVC_PAYMENT on the widget bridge so CvcWidget.res
  /// handles the confirm. The reactTag is passed directly — no view lookup needed since
  /// iOS can't resolve views across bridges (two-bridge problem). The reactTag from JS is
  /// the rootTag of the CvcWidget's React root, matching nativeProp.rootTag in the inner bundle.
  private static func confirmViaWidget(
      reactTag: Int,
      paymentToken: String,
      paymentMethodId: String,
      resolve: @escaping RCTPromiseResolveBlock
  ) {
      // Set PaymentSession.completion so exitHeadless routes back to this resolve
      PaymentSession.setConfirmCompletion { result in
          resolve(paymentResultToDict(result))
      }

      // Emit "triggerWidgetAction" with CONFIRM_CVC_PAYMENT on the widget bridge
      let payload: [String: Any] = [
          "actionType": "CONFIRM_CVC_PAYMENT",
          "rootTag": reactTag,
          "paymentToken": paymentToken,
          "paymentMethodId": paymentMethodId
      ]
      DispatchQueue.main.async {
          if let hyperModule = RNViewManager.sharedInstance.bridge.module(for: HyperModule.self) as? HyperModule {
              hyperModule.sendEvent(withName: "triggerWidgetAction", body: payload)
          } else {
              resolve([
                  "status": "failed",
                  "code": "NO_WIDGET_BRIDGE",
                  "message": "Widget bridge not available for CvcWidget confirm"
              ])
          }
      }
  }

  /// Convert a PaymentResult to a dictionary suitable for RCTPromiseResolveBlock.
  private static func paymentResultToDict(_ result: PaymentResult) -> [String: Any] {
      switch result {
      case .completed(let data):
          return [
              "status": "success",
              "message": "Payment confirmed successfully",
              "data": data
          ]
      case .failed(let error as NSError):
          return [
              "status": "failed",
              "code": error.domain,
              "message": error.userInfo["message"] as? String ?? "Payment confirmation failed"
          ]
      case .canceled(let data):
          return [
              "status": "cancelled",
              "message": "Payment confirmation cancelled",
              "data": data
          ]
      }
  }
}
