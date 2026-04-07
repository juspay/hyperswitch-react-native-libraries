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

  @objc
  public func confirmWithCustomerDefaultPaymentMethod(
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

      handler.confirmWithCustomerDefaultPaymentMethod { result in
          switch result {
          case .completed(let data):
              resolve([
                  "status": "success",
                  "message": "Payment confirmed successfully",
                  "data": data
              ])
          case .failed(let error as NSError):
              resolve([
                  "status": "failed",
                  "code": error.domain,
                  "message": error.userInfo["message"] as? String ?? "Payment confirmation failed"
              ])
          case .canceled(let data):
              resolve([
                  "status": "cancelled",
                  "message": "Payment confirmation cancelled",
                  "data": data
              ])
          }
      }
  }

  @objc
  public func confirmWithCustomerLastUsedPaymentMethod(
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

      handler.confirmWithCustomerLastUsedPaymentMethod { result in
          switch result {
          case .completed(let data):
              resolve([
                  "status": "success",
                  "message": "Payment confirmed successfully",
                  "data": data
              ])
          case .failed(let error as NSError):
              resolve([
                  "status": "failed",
                  "code": error.domain,
                  "message": error.userInfo["message"] as? String ?? "Payment confirmation failed"
              ])
          case .canceled(let data):
              resolve([
                  "status": "cancelled",
                  "message": "Payment confirmation cancelled",
                  "data": data
              ])
          }
      }
  }
}
