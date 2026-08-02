#import "HyperModule.h"

#import <React/RCTComponent.h>
#import <memory>


#if __has_include("HyperswitchSdkReactNative-Swift.h")
#import "HyperswitchSdkReactNative-Swift.h"
#else
// When using use_frameworks! :linkage => :static in Podfile
#import <HyperswitchSdkReactNative/HyperswitchSdkReactNative-Swift.h>
#endif

/**
 * ObjC++ bridge for the "HyperModule" TurboModule.
 *
 * Responsibilities:
 *   1. Register the module under the exact name "HyperModule"
 *      (matches TurboModuleRegistry.get('HyperModule') in the embedded bundle).
 *   2. Act as the RCTEventEmitter the bundle wraps in `new NativeEventEmitter(...)`.
 *   3. Forward every spec method to the Swift singleton HyperModuleImpl.shared.
 *   4. Vend the codegen JSI TurboModule for the New Architecture.
 */
@implementation HyperModule

RCT_EXPORT_MODULE(HyperModule)

- (instancetype)init
{
    if (self = [super init]) {
        // Let the Swift logic layer dispatch events / reach the bridge through us.
        HyperModuleImpl.shared.eventEmitter = self;
    }
    return self;
}

- (NSArray<NSString *> *)supportedEvents
{
     return @[ @"confirm", @"updateIntentInit", @"updateIntentComplete", @"triggerWidgetAction" ];
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

// NOTE: `addListener:` and `removeListeners:` required by the spec are inherited
// from RCTEventEmitter and satisfy the protocol as-is.

// MARK: - Generic message passing

- (void)sendMessageToNative:(NSString *)message
{
    [HyperModuleImpl.shared sendMessageToNative:message];
}

// MARK: - Google Pay (Android only)

- (void)launchGPay:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
    callback(@[ @"Google Pay is not available on iOS" ]);
}

// MARK: - Apple Pay

- (void)launchApplePay:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
    [HyperModuleImpl.shared launchApplePay:requestObj callback:callback];
}

- (void)startApplePay:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
    [HyperModuleImpl.shared startApplePay:requestObj callback:callback];
}

- (void)presentApplePay:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
    [HyperModuleImpl.shared presentApplePay:requestObj callback:callback];
}

// MARK: - Payment sheet exits

- (void)exitPaymentsheet:(double)rootTag result:(NSString *)result reset:(BOOL)reset
{
    [HyperModuleImpl.shared exitPaymentsheet:@(rootTag) result:result reset:reset];
}

- (void)exitPaymentMethodManagement:(double)rootTag result:(NSString *)result reset:(BOOL)reset
{
    [HyperModuleImpl.shared exitPaymentMethodManagement:@(rootTag) result:result reset:reset];
}

- (void)exitWidgetPaymentsheet:(double)rootTag result:(NSString *)result reset:(BOOL)reset
{
    [HyperModuleImpl.shared exitWidgetPaymentsheet:@(rootTag) result:result reset:reset];
}

// MARK: - Widget

- (void)exitWidget:(NSString *)result widgetType:(NSString *)widgetType
{
    // No dedicated iOS implementation (Android-oriented); no-op.
}

- (void)exitCardForm:(NSString *)result
{
    [HyperModuleImpl.shared exitCardForm:result];
}

- (void)launchWidgetPaymentSheet:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
    [HyperModuleImpl.shared launchWidgetPaymentSheet:requestObj callback:callback];
}

- (void)updateWidgetHeight:(double)height
{
    // Height is driven by the native widget view on iOS; no-op.
}

- (void)notifyWidgetPaymentResult:(double)rootTag result:(NSString *)result
{
    [HyperModuleImpl.shared notifyWidgetPaymentResult:@(rootTag) result:result];
}

// MARK: - Payment method management

- (void)onAddPaymentMethod:(NSString *)data
{
    [HyperModuleImpl.shared onAddPaymentMethod:data];
}

// MARK: - Payment events

- (void)emitPaymentEvent:(double)rootTag eventType:(NSString *)eventType payload:(NSDictionary *)payload
{
    [HyperModuleImpl.shared emitPaymentEvent:@(rootTag) eventType:eventType payload:payload];
}

- (void)onUpdateIntentEvent:(double)rootTag type:(NSString *)type result:(NSString *)result
{
    [HyperModuleImpl.shared onUpdateIntentEvent:@(rootTag) type:type result:result];
}

- (void)onPaymentConfirmButtonClick:(double)rootTag payload:(NSString *)payload callback:(RCTResponseSenderBlock)callback
{
    [HyperModuleImpl.shared onPaymentConfirmButtonClick:@(rootTag) payload:payload callback:callback];
}

// MARK: - 3DS / DDC iframe bridge

- (void)openIframeBridge:(NSString *)url timeoutMs:(double)timeoutMs callback:(RCTResponseSenderBlock)callback
{
    [HyperModuleImpl.shared openIframeBridge:url timeoutMs:@(timeoutMs) callback:callback];
}

// MARK: - TurboModule (New Architecture) — JSI spec wiring

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeHyperModuleSpecJSI>(params);
}

@end
