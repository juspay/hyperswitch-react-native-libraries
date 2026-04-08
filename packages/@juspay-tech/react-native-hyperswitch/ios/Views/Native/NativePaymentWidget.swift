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
    private var nativePaymentWidgetView: NativePaymentWidgetView?
    
    override func view() -> NativePaymentWidgetView {
      self.nativePaymentWidgetView = NativePaymentWidgetView()
      return self.nativePaymentWidgetView ?? NativePaymentWidgetView()
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

    @objc func confirmPayment(_ reactTag: NSNumber) {
        bridge.uiManager.addUIBlock { uiManager, viewRegistry in
          guard let _view = viewRegistry?[reactTag] as? NativePaymentWidgetView else { return
          }
          print("-- react Tag: ", reactTag);
          print("-- root Tag from bundle: ", self.nativePaymentWidgetView?.id?.stringValue);
          
          HyperModule.shared?.confirmPayment(self.nativePaymentWidgetView?.id?.stringValue ?? "", resolve: {
                response in print("-- confirm payment resposne: ", response)
            }, reject: {
                a, b, error in print("-- confirm payment error: ", a, b, error)
            })
        }
    }
}

internal class NativePaymentWidgetView: UIView {

    @objc private var rootView: RCTRootView?
    @objc private var widgetId: String?
    @objc private var widgetType: String?
    @objc private var sdkAuthorization: String?
    @objc private var options: [String: Any]?
    @objc internal var onPaymentResult: RCTDirectEventBlock?
    internal var id: NSNumber?

    @objc func didSetProps() {
      print()
        if let sdkAuthorization = sdkAuthorization {
            // Track CVC widget active state
            if widgetType == "cvcWidget" {
                HyperswitchModule.isCvcWidgetActive = true
            }

            RNViewManager.sharedInstance.responseHandler = self

            let hyperParams = HyperParams.getHyperParams()
            var configuration = self.options ?? [:]
            configuration["hideConfirmButton"] = true
            let props: [String : Any] = [
                "configuration": configuration,
                "type": self.widgetType as Any,
                "widgetId": self.reactTag as Any,
                "sdkAuthorization": sdkAuthorization as Any,
                "publishableKey": APIClient.shared.publishableKey as Any,
                "hyperParams": hyperParams,
                "customBackendUrl": APIClient.shared.customBackendUrl as Any,
                "customLogUrl": APIClient.shared.customLogUrl as Any,
                "customParams": APIClient.shared.customParams as Any
            ]
            let initialProperties = ["props": props]
            self.rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties:initialProperties as [String : Any])

            if let rootView = self.rootView {
                self.id = rootView.reactTag
                self.addSubview(rootView)
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleWidgetResponse(_:)),
                    name: .hyperWidgetPaymentResult,
                    object: nil
                )
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

    @objc private func handleWidgetResponse(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let rootTag = userInfo["rootTag"] as? NSNumber,
              let response = userInfo["response"] as? String,
              rootTag == self.id else { return }
        onPaymentResult?(["result": response])
        let shouldRemoveView = userInfo["shouldRemoveView"] as? Bool ?? false
        if shouldRemoveView {
            self.rootView?.removeFromSuperview()
            NotificationCenter.default.removeObserver(self, name: .hyperWidgetPaymentResult, object: nil)
        }
    }

    override func removeFromSuperview() {
        if widgetType == "cvcWidget" {
            HyperswitchModule.isCvcWidgetActive = false
        }
        rootView?.removeFromSuperview()
        rootView = nil
        super.removeFromSuperview()

    }
}
