#import "HyperswitchSdkReactNative.h"
#import <React/RCTComponent.h>
#if __has_include("HyperswitchSdkReactNative-Swift.h")
#import "HyperswitchSdkReactNative-Swift.h"
#else
// When using use_frameworks! :linkage => :static in Podfile
#import <HyperswitchSdkReactNative/HyperswitchSdkReactNative-Swift.h>
#endif


@implementation HyperswitchSdkReactNative
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(initialise:(nonnull NSString *)publishableKey
                  customBackendUrl:(nullable NSString *)customBackendUrl
                  customLogUrl:(nullable NSString *)customLogUrl
                  customParams:(nullable NSDictionary *)customParams
                  resolve:(nonnull RCTPromiseResolveBlock)resolve
                  reject:(nonnull RCTPromiseRejectBlock)reject) {
  [HyperswitchModule.shared initialiseWithPublishableKey:publishableKey customBackendUrl:customBackendUrl customLogUrl:customLogUrl customParams:customParams resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(initPaymentSession:(nonnull NSString *)paymentIntentClientSecret
                  resolve:(nonnull RCTPromiseResolveBlock)resolve
                  reject:(nonnull RCTPromiseRejectBlock)reject) {

  [HyperswitchModule.shared initPaymentSessionWithpaymentIntentClientSecret:paymentIntentClientSecret resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(presentPaymentSheet:(nonnull NSDictionary *)configuration
                  resolve:(nonnull RCTPromiseResolveBlock)resolve
                  reject:(nonnull RCTPromiseRejectBlock)reject)
{
  [HyperswitchModule.shared presentPaymentSheetWithConfiguration:configuration resolver:resolve rejecter:reject];
}

//RCT_EXPORT_METHOD(confirmPayment:(nonnull NSString *)widgetId
//                  resolve:(nonnull RCTPromiseResolveBlock)resolve
//                  reject:(nonnull RCTPromiseRejectBlock)reject)
//{
//  [HyperswitchModule.shared confirmPaymentWithWidgetId:widgetId resolve:resolve reject:reject];
//}

#pragma mark - Headless Payment Methods

RCT_EXPORT_METHOD(getCustomerSavedPaymentMethods:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [HyperswitchModule.shared getCustomerSavedPaymentMethodsWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(getCustomerDefaultSavedPaymentMethodData:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [HyperswitchModule.shared getCustomerDefaultSavedPaymentMethodDataWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(getCustomerLastUsedPaymentMethodData:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [HyperswitchModule.shared getCustomerLastUsedPaymentMethodDataWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(confirmWithCustomerDefaultPaymentMethod:(nonnull NSString *)widgetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [HyperswitchModule.shared confirmWithCustomerDefaultPaymentMethodWithWidgetId:widgetId withResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(confirmWithCustomerLastUsedPaymentMethod:(nonnull NSString *)widgetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [HyperswitchModule.shared confirmWithCustomerLastUsedPaymentMethodWithWidgetId:widgetId withResolve:resolve reject:reject];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

@end
