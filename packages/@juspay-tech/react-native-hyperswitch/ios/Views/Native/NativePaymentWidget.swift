//
//  NativePaymentWidget.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 05/03/26.
//

import React
import UIKit

@objc(NativePaymentWidget)
internal class NativePaymentWidget: RCTViewManager {

    override func view() -> NativePaymentWidgetView {
        return NativePaymentWidgetView()
    }

    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc func showWidget(_ reactTag: NSNumber) {
        //        bridge.uiManager.addUIBlock { uiManager, viewRegistry in
        //            guard let view = viewRegistry?[reactTag] as? NativePaymentWidgetView else { return }
        //                        view.showWidget()
        //        }
    }

    @objc func removeWidget(_ reactTag: NSNumber) {
        //        bridge.uiManager.addUIBlock { uiManager, viewRegistry in
        //            guard let view = viewRegistry?[reactTag] as? NativePaymentWidgetView else { return }
        //                        view.removeWidget()
        //        }
    }

    @objc func confirmPayment(_ reactTag: NSNumber, _ rnCallback: @escaping RCTResponseSenderBlock) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? NativePaymentWidgetView else { return }
            view.confirmPayment(rnCallback)
        }
    }

    @objc func confirmPaymentCVC(_ reactTag: NSNumber, _ paymentToken: String, _ paymentMethodId: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? NativePaymentWidgetView else { return }
            view.confirmCVCPayment(paymentToken: paymentToken, paymentMethodId: paymentMethodId, resolve: rnCallback)
        }
  }
}

internal class NativePaymentWidgetView: UIView {

    @objc private var rootView: RCTRootView?
    @objc private var widgetType: String?
    @objc private var clientSecret: String?
    @objc private var options: [String: Any]?
    @objc private var onPaymentResult: RCTDirectEventBlock?
    private var responseSenderCallback: RCTResponseSenderBlock?

    internal var rctRootTag: NSNumber?

    @objc func didSetProps() {
        if let clientSecret = clientSecret {
            // Track CVC widget active state
            if widgetType == "cvcWidget" {
                HyperswitchModule.isCvcWidgetActive = true
            }

            let hyperParams = HyperParams.getHyperParams()
            var configuration = self.options ?? [:]
            configuration["hideConfirmButton"] = true
            let props: [String : Any] = [
                "configuration": configuration,
                "type": self.widgetType as Any,
                "clientSecret": clientSecret as Any,
                "publishableKey": APIClient.shared.publishableKey as Any,
                "hyperParams": hyperParams,
                "customBackendUrl": APIClient.shared.customBackendUrl as Any,
                "customLogUrl": APIClient.shared.customLogUrl as Any,
                "customParams": APIClient.shared.customParams as Any
            ]
            let initialProperties = ["props": props]
            self.rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties:initialProperties as [String : Any])

            if let rootView = self.rootView {
                self.rctRootTag = rootView.reactTag
                self.addSubview(rootView)

                WidgetResponseRegistry.shared.register(rootTag: rootView.reactTag, action: .paymentEvent) { [weak self] response, shouldRemoveView in
                    guard let self = self else { return }
                    self.onPaymentResult?(["result": response])
                    if shouldRemoveView {
                        self.rootView?.removeFromSuperview()
                    }
                }
            }
        }
    }

    override func didSetProps(_ changedProps: [String]) {
        self.didSetProps()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal override func layoutSubviews() {
        super.layoutSubviews()
        if let rootView = self.rootView {
            rootView.frame = self.bounds
        }
    }

    internal func confirmPayment(_ rnCallback: @escaping RCTResponseSenderBlock) {
      // avoiding duplicate confirm calls (confirmPayment triggered multiple times from RN layer)
      if self.responseSenderCallback != nil {
        let response = ["status": "failed", "error": "invalid call"]
        rnCallback([["result": response]])
        return
      }

      self.responseSenderCallback = rnCallback

      if let tag = self.rctRootTag {
        WidgetResponseRegistry.shared.register(rootTag: tag, action: .confirmPayment) { [weak self] response, shouldRemoveView in
            guard let self = self else { return }
            self.responseSenderCallback?([["result": response]])
            self.responseSenderCallback = nil
            if shouldRemoveView {
                self.rootView?.removeFromSuperview()
            }
        }
      }

      let eventData: [String: Any] = [
          "rootTag": self.rctRootTag ?? -1,
          "actionType": "confirmPayment"
      ]
      self.rootView?.bridge.enqueueJSCall("RCTDeviceEventEmitter", method: "emit", args: ["triggerWidgetAction", eventData], completion: nil)
    }

    internal func confirmCVCPayment(paymentToken: String, paymentMethodId: String, resolve: @escaping RCTResponseSenderBlock) {
        if let tag = self.rctRootTag {
            WidgetResponseRegistry.shared.register(rootTag: tag, action: .confirmCVCPayment) { [weak self] response, shouldRemoveView in
                guard let self = self else { return }
                resolve([response])
            }
        }


        let payload: [String: Any] = [
            "actionType": "CONFIRM_CVC_PAYMENT",
            "rootTag": self.rctRootTag ?? -1,
            "paymentToken": paymentToken,
            "paymentMethodId": paymentMethodId
        ]
        self.rootView?.bridge.enqueueJSCall("RCTDeviceEventEmitter", method: "emit", args: ["triggerWidgetAction", payload], completion: nil)
    }

    deinit {
        if let tag = rctRootTag {
            WidgetResponseRegistry.shared.unregisterAll(rootTag: tag)
        }
    }
}
