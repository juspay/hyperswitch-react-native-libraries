//
//  NativePaymentWidgetViewRegistry.h
//
//  Shared tag → UIView registry that bridges the old-arch NativePaymentWidget view manager
//  and the new-arch (Fabric) NativePaymentElementView component.
//
//  Old arch: NativePaymentWidget view manager's commands (confirmPayment, etc.) use
//            bridge.uiManager which finds NativePaymentWidgetView directly.
//
//  New arch: The Fabric NativePaymentElementView wraps an inner NativePaymentWidgetView.
//            The React tag resolves to the Fabric host view, not the inner widget view.
//            This registry lets commands find the inner NativePaymentWidgetView by tag.
//

#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NativePaymentWidgetViewRegistry : NSObject

/// Shared singleton.
+ (instancetype)shared;

/// Register the inner NativePaymentWidgetView for a given React tag.
/// The registry holds a weak reference so deallocation is automatic.
- (void)registerView:(UIView *)view forTag:(NSNumber *)tag;

/// Remove the entry for the given React tag.
- (void)unregisterForTag:(NSNumber *)tag;

/// Return the inner NativePaymentWidgetView (or nil if none registered / already deallocated).
- (nullable UIView *)viewForTag:(NSNumber *)tag;

@end

NS_ASSUME_NONNULL_END
