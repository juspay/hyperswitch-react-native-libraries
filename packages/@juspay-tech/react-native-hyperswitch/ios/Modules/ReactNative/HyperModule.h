#import <HyperswitchSdkReactNativeSpec/HyperswitchSdkReactNativeSpec.h>

@protocol HyperModuleShim;
@class HyperModuleImpl;


@interface HyperModule : NativeHyperModuleSpecBase <NativeHyperModuleSpec, HyperModuleShim>
@property (nonatomic, weak) HyperModuleImpl *impl;
@end
