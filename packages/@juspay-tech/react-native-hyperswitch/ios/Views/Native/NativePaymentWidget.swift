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

    @objc func updateIntentInitForWidget(_ rootTag: NSNumber, _ rnCallback: @escaping RCTResponseSenderBlock) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[rootTag] as? NativePaymentWidgetView else { return }
            view.updateIntentInit(rnCallback)
        }
    }

    @objc func updateIntentCompleteForWidget(
        _ rootTag: NSNumber,
        _ sdkAuthorization: String,
        _ rnCallback: @escaping RCTResponseSenderBlock
    ) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[rootTag] as? NativePaymentWidgetView else { return }
            view.updateIntentComplete(sdkAuthorization: sdkAuthorization, resolve: rnCallback)
        }
    }

    @objc func confirmPaymentCVC(
        _ reactTag: NSNumber,
        _ paymentToken: String,
        _ paymentMethodId: String,
        _ rnCallback: @escaping RCTResponseSenderBlock
    ) {
        bridge.uiManager.addUIBlock { _, viewRegistry in
            guard let view = viewRegistry?[reactTag] as? NativePaymentWidgetView else { return }
            view.confirmCVCPayment(paymentToken: paymentToken, paymentMethodId: paymentMethodId, resolve: rnCallback)
        }
    }
}

internal class NativePaymentWidgetView: UIView {

    private var paymentWidget: PaymentWidget?
    private var cvcWidget: CVCWidget?
    internal var cvcWidgetRef: CVCWidget? { cvcWidget }
    @objc private var widgetType: String?
    @objc private var sdkAuthorization: String?
    @objc private var options: [String: Any]?
    @objc private var onPaymentEvent: RCTDirectEventBlock?
    @objc private var onPaymentResult: RCTDirectEventBlock?
    private var responseSenderCallback: RCTResponseSenderBlock?
    private var appliedConfigKey: String?

    internal var rctRootTag: NSNumber?

    private func callbackPayload(_ data: Any?) -> Any {
        guard let stringData = data as? String,
            let jsonData = stringData.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            return data ?? NSNull()
        }
        return json
    }

    private func nonEmptyString(_ value: String?) -> String? {
        guard let value = value, !value.isEmpty else { return nil }
        return value
    }

    private func optionString(_ key: String) -> String? {
        return options?[key] as? String
    }

    private func effectiveSdkAuthorization() -> String? {
        return nonEmptyString(sdkAuthorization)
            ?? nonEmptyString(optionString("sdkAuthorization"))
            ?? nonEmptyString(PaymentSession.activeSession?.paymentSessionConfiguration.sdkAuthorization)
    }

    private func effectivePublishableKey() -> String? {
        return nonEmptyString(optionString("publishableKey"))
            ?? nonEmptyString(HyperswitchModule.getActivePublishableKey())
    }

    private func effectiveProfileId() -> String? {
        return nonEmptyString(optionString("profileId"))
            ?? nonEmptyString(HyperswitchModule.getActiveProfileId())
    }

    private func isSupportedWidgetType() -> Bool {
        return widgetType == "cvcWidget" || widgetType == "paymentElement" || widgetType == "widgetPaymentSheet"
    }

    private func activeOrNewHyperswitch() -> Hyperswitch? {
        if let active = HyperswitchModule.getActiveHyperswitch(), nonEmptyString(optionString("publishableKey")) == nil {
            return active
        }

        guard let publishableKey = effectivePublishableKey() else { return nil }
        return Hyperswitch(
            configuration: HyperswitchConfiguration(
                publishableKey: publishableKey,
                profileId: effectiveProfileId()
            )
        )
    }

    private func activeOrNewPaymentSession(sdkAuthorization: String) -> PaymentSession? {
        if let activeSession = HyperswitchModule.getActivePaymentSession(), nonEmptyString(optionString("sdkAuthorization")) == nil {
            return activeSession
        }

        return activeOrNewHyperswitch()?.initPaymentSession(
            configuration: PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)
        )
    }

    private func subscribedEvents() -> [String] {
        return options?["subscribedEvents"] as? [String] ?? []
    }

    private func clearWidget() {
        paymentWidget?.removeFromSuperview()
        cvcWidget?.removeFromSuperview()
        paymentWidget = nil
        cvcWidget = nil
        rctRootTag = nil
        responseSenderCallback = nil
    }

    private func paymentResultPayload(_ result: PaymentResult) -> String {
        let payload = paymentResultMap(result)

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
            let json = String(data: data, encoding: .utf8)
        else {
            return "{\"status\":\"failed\",\"message\":\"Invalid payment result\"}"
        }
        return json
    }

    private func paymentResultMap(_ result: PaymentResult) -> [String: Any] {
        switch result {
        case .completed(let data):
            return [
                "status": "success",
                "message": "Payment confirmed successfully",
                "data": data,
            ]
        case .canceled(let data):
            return [
                "status": "cancelled",
                "message": "Payment confirmation cancelled",
                "data": data,
            ]
        case .failed(let error as NSError):
            return [
                "status": "failed",
                "code": error.domain,
                "message": error.userInfo["message"] as? String ?? error.localizedDescription,
            ]
        }
    }

    private func handlePaymentResult(_ result: PaymentResult) {
        let payload = paymentResultPayload(result)
        if let callback = responseSenderCallback {
            callback([paymentResultMap(result)])
            responseSenderCallback = nil
            return
        }
        onPaymentResult?(["result": payload])
    }

    internal func handleConfirmPaymentNotification(_ result: PaymentResult) {
        guard let callback = responseSenderCallback else { return }
        switch result {
        case .failed:
            callback([paymentResultMap(result)])
            responseSenderCallback = nil
        default:
            break
        }
    }

    @objc func didSetProps() {
        guard isSupportedWidgetType(), let sdkAuthorization = effectiveSdkAuthorization() else { return }

        let configKey = [widgetType ?? "", effectivePublishableKey() ?? "", effectiveProfileId() ?? "", sdkAuthorization].joined(separator: ":")
        if paymentWidget != nil || cvcWidget != nil, appliedConfigKey == configKey {
            return
        }

        clearWidget()
        appliedConfigKey = configKey

        var configuration = options ?? [:]
        if widgetType != "cvcWidget" {
            configuration["hideConfirmButton"] = true
        }
        configuration["subscribedEvents"] = subscribedEvents()

        let listener = PaymentEventListener { [weak self] event in
            self?.onPaymentEvent?([
                "eventName": event.type,
                "payload": event.payload,
            ])
        }

        let widget: UIView?
        if widgetType == "cvcWidget" {
            guard let hyperswitch = activeOrNewHyperswitch() else { return }
            let cvc = CVCWidget(
                hyperswitch: hyperswitch,
                configurationDict: configuration,
                subscribe: nil
            )
            cvc.setPaymentEventListener(listener)
            cvcWidget = cvc
            widget = cvc
        } else {
            guard let session = activeOrNewPaymentSession(sdkAuthorization: sdkAuthorization) else { return }
            let payment = PaymentWidget(
                paymentSession: session,
                configurationDict: configuration,
                completion: { [weak self] result in
                    self?.handlePaymentResult(result)
                },
                subscribe: nil
            )
            payment.setPaymentEventListener(listener)
            paymentWidget = payment
            widget = payment
        }

        guard let widget = widget else { return }
        addSubview(widget)
        widget.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widget.topAnchor.constraint(equalTo: topAnchor),
            widget.bottomAnchor.constraint(equalTo: bottomAnchor),
            widget.leadingAnchor.constraint(equalTo: leadingAnchor),
            widget.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        if let paymentWidget = widget as? PaymentWidget {
            rctRootTag = paymentWidget.rootReactTag
        } else if let cvcWidget = widget as? CVCWidget {
            rctRootTag = cvcWidget.rootReactTag
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
        paymentWidget?.frame = bounds
        cvcWidget?.frame = bounds
    }

    internal func confirmPayment(_ rnCallback: @escaping RCTResponseSenderBlock) {
        // avoiding duplicate confirm calls (confirmPayment triggered multiple times from RN layer)
        if self.responseSenderCallback != nil {
            let response = ["status": "failed", "error": "invalid call"]
            rnCallback([response])
            return
        }

        self.responseSenderCallback = rnCallback
        guard let paymentWidget = paymentWidget else {
            self.responseSenderCallback = nil
            rnCallback([[
                "status": "failed",
                "code": "WIDGET_NOT_READY",
                "message": "Widget not ready",
            ]])
            return
        }
        paymentWidget.confirm()
    }

    internal func updateIntentInit(_ resolve: @escaping RCTResponseSenderBlock) {
        guard let tag = rctRootTag else {
            resolve([["status": "failed", "message": "Widget root tag not found"]])
            return
        }

        WidgetResponseRegistry.shared.register(rootTag: tag, action: .updateIntentInit) { [weak self] response, _ in
            guard let self = self else { return }
            resolve([self.callbackPayload(response["data"])])
        }

        let eventData: [String: Any] = ["rootTag": tag]
        RNViewManager.sharedInstance.bridge.enqueueJSCall(
            "RCTDeviceEventEmitter",
            method: "emit",
            args: ["updateIntentInit", eventData],
            completion: nil
        )
    }

    internal func updateIntentComplete(sdkAuthorization: String, resolve: @escaping RCTResponseSenderBlock) {
        guard let tag = rctRootTag else {
            resolve([["status": "failed", "message": "Widget root tag not found"]])
            return
        }

        WidgetResponseRegistry.shared.register(rootTag: tag, action: .updateIntentComplete) { [weak self] response, _ in
            guard let self = self else { return }
            resolve([self.callbackPayload(response["data"])])
        }

        let eventData: [String: Any] = [
            "rootTag": tag,
            "sdkAuthorization": sdkAuthorization,
        ]
        RNViewManager.sharedInstance.bridge.enqueueJSCall(
            "RCTDeviceEventEmitter",
            method: "emit",
            args: ["updateIntentComplete", eventData],
            completion: nil
        )
    }

    internal func confirmCVCPayment(paymentToken: String, paymentMethodId: String, resolve: @escaping RCTResponseSenderBlock) {
        if let tag = rctRootTag {
            WidgetResponseRegistry.shared.register(rootTag: tag, action: .confirmCVCPayment) { [weak self] response, shouldRemoveView in
                guard let self = self else { return }
                resolve([self.callbackPayload(response["data"])])
            }
        }

        if let sdkAuthorization = effectiveSdkAuthorization(), let cvcWidget = cvcWidget {
            cvcWidget.confirm(sdkAuthorization: sdkAuthorization, paymentToken: paymentToken, paymentMethodId: paymentMethodId)
        }
    }

    deinit {
        clearWidget()
    }
}
