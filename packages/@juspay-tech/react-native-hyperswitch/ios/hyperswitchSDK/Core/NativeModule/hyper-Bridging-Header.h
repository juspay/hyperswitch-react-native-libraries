#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTRootView.h>
#import <React/RCTUtils.h>
#import <React/RCTConvert.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
// Shared view registry — exposes NativePaymentWidgetViewRegistry to Swift so that
// the old-arch NativePaymentWidget view-manager commands can fall back to Fabric views.
#import "NativePaymentWidgetViewRegistry.h"
