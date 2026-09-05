//
//  NativeWidgetHelperModuleImpl.swift
//  Hyperswitch
//
//  Swift implementation for NativeWidgetHelperModule TurboModule.
//  Provides widget operations: confirmPayment, updateIntentInit, updateIntentComplete
//
//  Called from MERCHANT APP's JS layer with OUTER view tags (NativePaymentWidgetView.reactTag).
//  Uses registry.view(forTag:) to find views by outer tag.
//
//  Created by Kuntimaddi Manideep on 02/08/26.
//

import Foundation
import React

@objc(NativeWidgetHelperModuleImpl)
public class NativeWidgetHelperModuleImpl: NSObject {
    
    @objc public static let shared = NativeWidgetHelperModuleImpl()
    
    private override init() {
        super.init()
    }
    
    @objc public func confirmPayment(
        reactTag: NSNumber,
        callback: @escaping RCTResponseSenderBlock
    ) {
        DispatchQueue.main.async {
            guard let view = NativePaymentWidgetRegistry.shared.view(forTag: reactTag) else {
                callback([["status": "failed", "message": "Widget view not found for tag \(reactTag)"]])
                return
            }
            view.confirmPayment(callback)
        }
    }
    
    @objc public func updateIntentInit(
        reactTag: NSNumber,
        callback: @escaping RCTResponseSenderBlock
    ) {
        DispatchQueue.main.async {
            guard let view = NativePaymentWidgetRegistry.shared.view(forTag: reactTag) else {
                callback([["status": "failed", "message": "Widget view not found for tag \(reactTag)"]])
                return
            }
            view.updateIntentInit(callback)
        }
    }
    
    @objc public func updateIntentComplete(
        reactTag: NSNumber,
        sdkAuthorization: String,
        callback: @escaping RCTResponseSenderBlock
    ) {
        DispatchQueue.main.async {
            guard let view = NativePaymentWidgetRegistry.shared.view(forTag: reactTag) else {
                callback([["status": "failed", "message": "Widget view not found for tag \(reactTag)"]])
                return
            }
            view.updateIntentComplete(sdkAuthorization: sdkAuthorization, resolve: callback)
        }
    }
}

