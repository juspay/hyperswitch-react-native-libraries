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

    override func view() -> (NativePaymentWidgetView) {
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
}

internal class NativePaymentWidgetView: UIView, RNResponseHandler {

    @objc private var rootView: RCTRootView?
    @objc private var widgetId: String?
    @objc private var widgetType: String?
    @objc private var clientSecret: String?
    @objc private var options: [String: Any]?
    @objc private var onPaymentResult: RCTDirectEventBlock?

    @objc func didSetProps() {
        if let clientSecret = clientSecret {
            RNViewManager.sharedInstance.responseHandler = self
            let hyperParams = HyperParams.getHyperParams()
            let props: [String : Any] = [
                "configuration": self.options as Any,
                "type": self.widgetType as Any,
                "widgetId": self.widgetId as Any,
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
                self.addSubview(rootView)
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

    func didReceiveResponse(response: String?, error: Error?) {
        if let onPaymentResult = onPaymentResult,
           let response = response  {
            onPaymentResult(["result": response])
            // TODO: temp 
            self.rootView?.removeFromSuperview()
        }
    }
}
