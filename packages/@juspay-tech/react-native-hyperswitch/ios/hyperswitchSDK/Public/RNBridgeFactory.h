//
//  RNBridgeFactory.h
//  HyperswitchSdkReactNative
//
//  Factory for the SDK's internal React Native surface. On React Native 0.79+
//  with the New Architecture enabled this uses RCTRootViewFactory so that core
//  TurboModules (DeviceInfo, ExceptionsManager, etc.) and codegen-generated
//  third-party modules are registered in the secondary bridge.
//

#import <UIKit/UIKit.h>

@class RCTBridge;

NS_ASSUME_NONNULL_BEGIN

@interface RNBridgeFactory : NSObject

+ (instancetype)sharedInstance;

- (UIView *)hyperswitchViewForModuleName:(NSString *)moduleName
                       initialProperties:(nullable NSDictionary *)initialProperties;

@property (nonatomic, readonly, nullable) RCTBridge *bridge;

@end

NS_ASSUME_NONNULL_END
