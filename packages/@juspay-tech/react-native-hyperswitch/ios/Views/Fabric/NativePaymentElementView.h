//
//  NativePaymentElementView.h
//
//  Fabric (New Architecture) component for RCTNativePaymentElement.
//  Matches Android's PaymentElementViewManager (view name "RCTNativePaymentElement").
//
//  Old arch uses requireNativeComponent('NativePaymentWidget') →  NativePaymentWidget.swift
//  New arch uses codegenNativeComponent('RCTNativePaymentElement') →  this file
//

#pragma once
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NativePaymentElementView : RCTViewComponentView

@end

NS_ASSUME_NONNULL_END
