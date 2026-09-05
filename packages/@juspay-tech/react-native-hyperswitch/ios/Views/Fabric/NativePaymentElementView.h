//
//  NativePaymentElementView.h
//
//  Fabric (New Architecture) component for RCTNativePaymentWidget.
//  Matches Android's PaymentElementViewManager (view name "RCTNativePaymentWidget").
//
//  Old arch uses requireNativeComponent('NativePaymentWidget') →  NativePaymentWidget.swift
//  New arch uses codegenNativeComponent('RCTNativePaymentWidget') →  this file
//

#pragma once
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NativePaymentElementView : RCTViewComponentView

@end

NS_ASSUME_NONNULL_END
