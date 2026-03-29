//
//  HyperModule.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation
import React

@objc(HyperModule)
internal class HyperModule: RCTEventEmitter {

  private let applePayPaymentHandler = ApplePayHandler()
  private let expressCheckoutHandler = ExpressCheckoutLauncher()
  private var presentCallback: RCTResponseSenderBlock? = nil
  internal static var shared:HyperModule?

  override init() {
    super.init()
    HyperModule.shared = self
  }

  @objc
  internal override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc
  internal override func supportedEvents() -> [String] {
    return ["confirm", "confirmEC", "triggerWidgetAction"]
  }

  @objc
  internal func confirm(data: [String: Any]) {
    self.sendEvent(withName: "confirm", body: data)
  }

  @objc
  func confirmPayment(_ widgetId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let eventData: [String: String] = [
      "widgetId": widgetId,
      "actionType": "confirmPayment"
    ]
    RNViewManager.sharedInstance.setConfirmPromise(widgetId: widgetId, resolve: resolve, reject: reject)
    self.sendEvent(withName: "triggerWidgetAction", body: eventData)
  }

  // MARK: WIP
  //    @objc func confirmEC(data: [String: Any]) {
  //        self.sendEvent(withName: "confirmEC", body: data)
  //    }

  @objc
  private func sendMessageToNative(_ rnMessage: String) {}

  //React Native Wrapper Function
  @objc
  private func presentPaymentSheet(_ request: NSMutableDictionary, _ callBack: @escaping RCTResponseSenderBlock) -> Void {
    DispatchQueue.main.async {
      let paymentSheet = PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
      paymentSheet.presentWithParams(
        from: (UIApplication.shared.delegate?.window??.rootViewController)!, //TODO: safely check this
        props: request as! [String : Any],
        completion: { result2 in
          switch result2 {
          case .completed(let data):
            callBack([["status": "completed", "message": data]])
          case .failed(let error as NSError):
            callBack([["status": "failed", "code": error.domain, "message": "Payment failed: \(error.userInfo["message"] ?? "Failed")"]])
          case .canceled(let data):
            callBack([["status": "cancelled", "message": data]])
          }
        }
      )
    }
  }

  @objc
  private func launchWidgetPaymentSheet(_ request: NSMutableDictionary, _ callback: @escaping RCTResponseSenderBlock) -> Void {
    expressCheckoutHandler.launchPaymentSheet(paymentResult: request,callBack: callback)
  }

  @objc
  private func onAddPaymentMethod(_ rnMessage: String) -> Void {
    PaymentMethodManagementWidget.onAddPaymentMethod?()
  }

  @objc
  private func launchApplePay (_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
    applePayPaymentHandler.startPayment(rnMessage: rnMessage, rnCallback: rnCallback, presentCallback: self.presentCallback)
  }

  @objc
  private func startApplePay (_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
    rnCallback([])
  }

  @objc
  private func presentApplePay (_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
    self.presentCallback = rnCallback
  }

  @objc
  private func exitPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
    exitSheet(rnMessage)
  }

  @objc
  private func exitWidgetPaymentsheet(_ rootTag: NSNumber,_ widgetId: String ,_ result: String, _ reset: Bool) {
    // Structure: ["status": string, "code": string?, "message": string, "data": Any?]
    var structuredResponse: [String: Any] = [:]
    if let data = result.data(using: .utf8) {
      do {
        if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
          if let status = jsonObject["status"] as? String {
            structuredResponse["status"] = status
          } else {
            structuredResponse["status"] = "unknown"
          }

          if let message = jsonObject["message"] as? String {
            structuredResponse["message"] = message
          } else {
            structuredResponse["message"] = ""
          }

          if let code = jsonObject["code"] as? String {
            structuredResponse["code"] = code
          }

          if let dataValue = jsonObject["data"] {
            structuredResponse["data"] = dataValue
          }
        }
      } catch {
        structuredResponse = [
          "status": "error",
          "code": "PARSE_ERROR",
          "message": "Failed to parse response: \(error.localizedDescription)"
        ]
      }
    } else {
      structuredResponse = [
        "status": "error",
        "code": "INVALID_DATA",
        "message": "Invalid response data"
      ]
    }

    // Resolve the confirm promise for the given widgetId with the structured response
    RNViewManager.sharedInstance.resolveConfirmPromise(widgetId: widgetId, result: structuredResponse)

    // Keep the response handler call for backward compatibility
    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: result, error: nil)
  }

  @objc
  private func exitPaymentMethodManagement(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
    exitSheet(rnMessage)
  }

  @objc
  private func exitCardForm(_ rnMessage: String) {
    var response: String?
    var error: NSError?

    if let data = rnMessage.data(using: .utf8) {
      do {
        if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
          let status = jsonDictionary["status"]

          if (status == "failed" || status == "requires_payment_method") {
            error = NSError(domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR", code: 0, userInfo: ["message" : jsonDictionary["message"] ?? "An error has occurred."])
          } else {
            response = status
          }
          RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: response, error: error)
        } else {
          RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
        }
      } catch {
        RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
      }
    } else {
      RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
    }
  }

  @objc
  private func notifyWidgetPaymentResult(_ widgetId: String, _ rnMessage: String) {
    guard let data = rnMessage.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
      return
    }
    let status  = json["status"]  ?? "failed"
    let code    = json["code"]    ?? "form_validation_failed"
    let message = json["message"] ?? "Form validation failed."

    var structuredResponse: [String: Any] = [
      "status": status,
      "message": message
    ]
    structuredResponse["code"] = code

    // Resolve the confirm promise for the given widgetId with the structured response
    RNViewManager.sharedInstance.resolveConfirmPromise(widgetId: widgetId, result: structuredResponse)
  }

  @objc
  private func exitSheet(_ rnMessage: String) {
    var response: String?
    var error: NSError?

    if let data = rnMessage.data(using: .utf8) {
      do {
        if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
          let status = jsonDictionary["status"]

          if (status == "failed" || status == "requires_payment_method") {
            error = NSError(domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR", code: 0, userInfo: ["message" : jsonDictionary["message"] ?? "An error has occurred."])
          } else {
            response = status
          }
          RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: response, error: error)
        } else {
          RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
        }
      } catch {
        RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
      }
    } else {
      RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
    }
    DispatchQueue.main.async {
      if let view = RNViewManager.sharedInstance.rootView {
        let reactNativeVC: UIViewController? = view.reactViewController()
        reactNativeVC?.dismiss(animated: false, completion: nil)
      }
    }
  }
}

