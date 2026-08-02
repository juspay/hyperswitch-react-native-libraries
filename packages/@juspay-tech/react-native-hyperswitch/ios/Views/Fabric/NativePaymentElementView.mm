//
//  NativePaymentElementView.mm
//
//  Fabric (New Architecture) host view for the PaymentElement and CVCWidget.
//  Component name: "RCTNativePaymentElement"   (matches PaymentElementNativeComponent.ts)
//
//  Architecture:
//    ┌─────────────────────────────────────────────────────────────────────┐
//    │  NativePaymentElementView  (RCTViewComponentView — Fabric host)     │
//    │    • receives props via updateProps (widgetType, sdkAuth, options)  │
//    │    • fires events via Fabric RCTNativePaymentWidgetEventEmitter     │
//    │    └── NativePaymentWidgetView  (inner UIView — actual widget)      │
//    │          • shared with the old-arch NativePaymentWidget ViewManager  │
//    │          • registered in NativePaymentWidgetViewRegistry by tag      │
//    └─────────────────────────────────────────────────────────────────────┘
//
//  The NativePaymentWidgetViewRegistry registration lets the old-arch view
//  manager commands (confirmPayment, updateIntentInitForWidget, etc.) AND the
//  NativePaymentElementModule TurboModule find the inner widget by React tag.
//

#import "NativePaymentElementView.h"
#import "NativePaymentWidgetViewRegistry.h"

// Defines RCTPromiseResolveBlock/RCTPromiseRejectBlock and RCTDirectEventBlock,
// referenced by the HyperswitchModule / NativePaymentWidgetView interfaces
// declared in the generated Swift header below.
#import <React/RCTBridgeModule.h>
#import <React/RCTComponent.h>

#include <folly/json.h>

#import <react/renderer/components/HyperswitchSdkReactNativeSpec/ComponentDescriptors.h>
#import <react/renderer/components/HyperswitchSdkReactNativeSpec/EventEmitters.h>
#import <react/renderer/components/HyperswitchSdkReactNativeSpec/Props.h>
#import <react/renderer/components/HyperswitchSdkReactNativeSpec/RCTComponentViewHelpers.h>
#import "RCTFabricComponentsPlugins.h"

#if __has_include("HyperswitchSdkReactNative-Swift.h")
#import "HyperswitchSdkReactNative-Swift.h"
#else
#import <HyperswitchSdkReactNative/HyperswitchSdkReactNative-Swift.h>
#endif

// Category to expose internal event block properties
@interface NativePaymentWidgetView (FabricEvents)
@property (nonatomic, copy) RCTDirectEventBlock onPaymentResult;
@property (nonatomic, copy) RCTDirectEventBlock onPaymentEvent;
@end

using namespace facebook::react;

// ─────────────────────────────────────────────────────────────────────────────
// Helper: folly::dynamic (object) → NSDictionary via JSON round-trip
// ─────────────────────────────────────────────────────────────────────────────
static NSDictionary * _Nullable dynamicToDict(const folly::dynamic &dyn)
{
    if (!dyn.isObject() && !dyn.isArray()) {
        return nil;
    }
    NSString *json = [NSString stringWithUTF8String:folly::toJson(dyn).c_str()];
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [obj isKindOfClass:[NSDictionary class]] ? (NSDictionary *)obj : nil;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: NSDictionary → folly::dynamic via JSON round-trip
// ─────────────────────────────────────────────────────────────────────────────
static folly::dynamic dictToDynamic(NSDictionary * _Nullable dict)
{
    if (!dict) return folly::dynamic::object();
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    if (!data) return folly::dynamic::object();
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!json) return folly::dynamic::object();
    return folly::parseJson(std::string([json UTF8String]));
}

// ─────────────────────────────────────────────────────────────────────────────
@interface NativePaymentElementView () <RCTRCTNativePaymentWidgetViewProtocol>
@end

@implementation NativePaymentElementView {
    NativePaymentWidgetView *_widgetView;
}

// ── Fabric component descriptor ──────────────────────────────────────────────

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<RCTNativePaymentWidgetComponentDescriptor>();
}

// ── Lifecycle ────────────────────────────────────────────────────────────────

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _widgetView = [[NativePaymentWidgetView alloc] initWithFrame:frame];
        [self addSubview:_widgetView];
        [self setupEventForwarding];
    }
    return self;
}

- (void)prepareForRecycle
{
    [super prepareForRecycle];
    // Remove the inner view from the Fabric registry so that dangling tag lookups fail
    // cleanly.  The tag is the same integer as self.tag.
    [[NativePaymentWidgetViewRegistry shared] unregisterForTag:@(self.tag)];
    _widgetView.onPaymentResult = nil;
    _widgetView.onPaymentEvent  = nil;
}

- (void)willMoveToWindow:(nullable UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    if (newWindow == nil) {
        [[NativePaymentWidgetViewRegistry shared] unregisterForTag:@(self.tag)];
    }
}

// ── Props ────────────────────────────────────────────────────────────────────

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps
{
    const auto &p = *std::static_pointer_cast<RCTNativePaymentWidgetProps const>(props);

    NSString *widgetType   = [NSString stringWithUTF8String:p.widgetType.c_str()];
    NSString *sdkAuth      = [NSString stringWithUTF8String:p.sdkAuthorization.c_str()];

    _widgetView.widgetType        = widgetType.length > 0 ? widgetType : nil;
    _widgetView.sdkAuthorization  = sdkAuth.length   > 0 ? sdkAuth    : nil;

    // options is now Readonly<{}> from codegen - just pass nil for now
    // TODO: properly handle options struct
    _widgetView.options = nil;

    // Notify the inner view that all props have been applied (mirrors
    // the old-arch bridge calling didSetProps:changedProps: after KVC sets).
    [_widgetView didSetProps];

    // Register the inner widget view in the shared registry keyed by this
    // component's React tag, so that NativePaymentWidget view-manager commands
    // and NativePaymentElementModule TurboModule can find it by tag.
    [[NativePaymentWidgetViewRegistry shared] registerView:_widgetView forTag:@(self.tag)];

    [super updateProps:props oldProps:oldProps];
}

// ── Layout ───────────────────────────────────────────────────────────────────

- (void)layoutSubviews
{
    [super layoutSubviews];
    _widgetView.frame = self.bounds;
}

// ── Event forwarding (inner UIView → Fabric event emitter) ───────────────────

- (void)setupEventForwarding
{
    __weak NativePaymentElementView *weakSelf = self;

    // onPaymentResult: fired by NativePaymentWidgetView when a payment completes.
    _widgetView.onPaymentResult = ^(NSDictionary *event) {
        NativePaymentElementView *strongSelf = weakSelf;
        if (!strongSelf) return;

        auto em = std::dynamic_pointer_cast<const RCTNativePaymentWidgetEventEmitter>(
            strongSelf->_eventEmitter);
        if (!em) return;

        NSString *result = event[@"result"] ?: @"";
        RCTNativePaymentWidgetEventEmitter::OnPaymentResult payload;
        payload.result = std::string([result UTF8String]);
        em->onPaymentResult(std::move(payload));
    };

    // onPaymentEvent: fired for all intermediate payment events.
    _widgetView.onPaymentEvent = ^(NSDictionary *event) {
        NativePaymentElementView *strongSelf = weakSelf;
        if (!strongSelf) return;

        auto em = std::dynamic_pointer_cast<const RCTNativePaymentWidgetEventEmitter>(
            strongSelf->_eventEmitter);
        if (!em) return;

        NSString *eventName = event[@"eventName"] ?: @"";
        id payloadObj = event[@"payload"];

        RCTNativePaymentWidgetEventEmitter::OnPaymentEvent paymentEvent;
        paymentEvent.eventName = std::string([eventName UTF8String]);
        // TODO: Fix payload struct after updating codegen types
        // if ([payloadObj isKindOfClass:[NSDictionary class]]) {
        //     paymentEvent.payload = dictToDynamic((NSDictionary *)payloadObj);
        // }
        em->onPaymentEvent(std::move(paymentEvent));
    };
}

@end

// Required by RCTFabricComponentsPlugins to auto-register the component.
Class<RCTComponentViewProtocol> NativePaymentElementViewCls(void)
{
    return NativePaymentElementView.class;
}
