#import "HyperswitchSdkReactNative.h"
#import <React/RCTComponent.h>
#import <memory>
#if __has_include("HyperswitchSdkReactNative-Swift.h")
#import "HyperswitchSdkReactNative-Swift.h"
#else
// When using use_frameworks! :linkage => :static in Podfile
#import <HyperswitchSdkReactNative/HyperswitchSdkReactNative-Swift.h>
#endif


@implementation HyperswitchSdkReactNative

@synthesize viewRegistry_DEPRECATED = _viewRegistry_DEPRECATED;

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(initialise:(nonnull NSDictionary *)config
                  resolve:(nonnull RCTPromiseResolveBlock)resolve
                  reject:(nonnull RCTPromiseRejectBlock)reject) {
  NSString *publishableKey = [config[@"publishableKey"] isKindOfClass:NSString.class] ? config[@"publishableKey"] : nil;
  NSString *profileId = [config[@"profileId"] isKindOfClass:NSString.class] ? config[@"profileId"] : nil;
  NSDictionary *customEndpoints = [config[@"customEndpoints"] isKindOfClass:NSDictionary.class] ? config[@"customEndpoints"] : nil;
  NSDictionary *overrideEndpoints = [customEndpoints[@"overrideEndpoints"] isKindOfClass:NSDictionary.class] ? customEndpoints[@"overrideEndpoints"] : nil;
  NSString *customBackendUrl = [overrideEndpoints[@"customBackendEndpoint"] isKindOfClass:NSString.class] ? overrideEndpoints[@"customBackendEndpoint"] : nil;
  NSString *customLogUrl = [overrideEndpoints[@"customLoggingEndpoint"] isKindOfClass:NSString.class] ? overrideEndpoints[@"customLoggingEndpoint"] : nil;

  NSMutableDictionary *customParams = [NSMutableDictionary dictionary];
  if (profileId != nil) {
    customParams[@"profileId"] = profileId;
  }

  [[self hyperswitchModule] initialiseWithPublishableKey:publishableKey customBackendUrl:customBackendUrl customLogUrl:customLogUrl customParams:customParams resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(initPaymentSession:(nonnull NSString *)instanceHandle
                  sdkAuthorization:(nonnull NSString *)sdkAuthorization
                  resolve:(nonnull RCTPromiseResolveBlock)resolve
                  reject:(nonnull RCTPromiseRejectBlock)reject) {
  [[self hyperswitchModule] initPaymentSession:instanceHandle sdkAuthorization:sdkAuthorization resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(presentPaymentSheet:(nonnull NSDictionary *)configuration
                  resolve:(nonnull RCTPromiseResolveBlock)resolve
                  reject:(nonnull RCTPromiseRejectBlock)reject)
{
  [[self hyperswitchModule] presentPaymentSheet:configuration resolve:resolve reject:reject];
}

#pragma mark - Headless Payment Methods

RCT_EXPORT_METHOD(getCustomerSavedPaymentMethods:(nullable NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [[self hyperswitchModule] getCustomerSavedPaymentMethods:options resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(getCustomerDefaultSavedPaymentMethodData:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [[self hyperswitchModule] getCustomerDefaultSavedPaymentMethodDataWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(getCustomerLastUsedPaymentMethodData:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [[self hyperswitchModule] getCustomerLastUsedPaymentMethodDataWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(confirmWithCustomerDefaultPaymentMethod:(nullable NSString *)cvcWidgetReactTag
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [[self hyperswitchModule] confirmWithCustomerDefaultPaymentMethod:cvcWidgetReactTag resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(confirmWithCustomerLastUsedPaymentMethod:(nullable NSString *)cvcWidgetReactTag
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [[self hyperswitchModule] confirmWithCustomerLastUsedPaymentMethod:cvcWidgetReactTag resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(confirmWithCustomerPaymentToken:(nonnull NSString *)paymentToken
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [[self hyperswitchModule] confirmWithCustomerPaymentToken:paymentToken resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(updateIntent:(nonnull NSString *)sdkAuthorization
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [[self hyperswitchModule] updateIntent:sdkAuthorization resolve:resolve reject:reject];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeHyperswitchSdkNativeSpecJSI>(params);
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (HyperswitchModule *)hyperswitchModule
{
  HyperswitchModule.shared.viewRegistry_DEPRECATED = self.viewRegistry_DEPRECATED;
  return HyperswitchModule.shared;
}

@end
