//
//  RNBridgeFactory.mm
//  HyperswitchSdkReactNative
//

#import "RNBridgeFactory.h"

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTLog.h>
#import <React/RCTRootView.h>
#import <React-RCTAppDelegate/RCTRootViewFactory.h>
#import <React/CoreModulesPlugins.h>

#if __has_include(<React-RCTAppDelegate/RCTDependencyProvider.h>)
#import <React-RCTAppDelegate/RCTDependencyProvider.h>
#endif

#if __has_include(<ReactAppDependencyProvider/RCTAppDependencyProvider.h>)
#import <ReactAppDependencyProvider/RCTAppDependencyProvider.h>
#endif

#if __has_include(<ReactCodegen/RCTModuleProviders.h>)
#import <ReactCodegen/RCTModuleProviders.h>
#endif

#if __has_include(<react/nativemodule/defaults/DefaultTurboModules.h>)
#include <react/nativemodule/defaults/DefaultTurboModules.h>
#endif

#if __has_include(<ReactCommon/RCTHost.h>)
#import <ReactCommon/RCTHost.h>
#endif

@interface RNBridgeFactory () <RCTBridgeDelegate, RCTTurboModuleManagerDelegate, RCTHostDelegate>

@property (nonatomic, strong, nullable) RCTRootViewFactory *factory;
@property (nonatomic, strong, nullable) id<RCTDependencyProvider> dependencyProvider;

@end

@implementation RNBridgeFactory

+ (instancetype)sharedInstance {
    static RNBridgeFactory *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    if (![self isModernFactoryAvailable]) {
        return self;
    }

    self.dependencyProvider = [[RCTAppDependencyProvider alloc] init];

    NSURL *bundleURL = [self sourceURLForBridge:nil];

    BOOL newArch = RCTIsNewArchEnabled();
    RCTRootViewFactoryConfiguration *configuration =
        [[RCTRootViewFactoryConfiguration alloc] initWithBundleURL:bundleURL
                                                    newArchEnabled:newArch
                                                turboModuleEnabled:newArch || RCTTurboModuleEnabled()
                                                 bridgelessEnabled:NO];

    configuration.sourceURLForBridge = ^NSURL *(RCTBridge *bridge) {
        return [RNBridgeFactory.sharedInstance sourceURLForBridge:bridge];
    };

    self.factory = [[RCTRootViewFactory alloc] initWithTurboModuleDelegate:self
                                                              hostDelegate:self
                                                             configuration:configuration];
    return self;
}

- (BOOL)isModernFactoryAvailable {
    return NSClassFromString(@"RCTRootViewFactory") != nil
        && NSClassFromString(@"RCTAppDependencyProvider") != nil
        && NSClassFromString(@"RCTDependencyProvider") != nil;
}

- (nullable RCTBridge *)bridge {
    return self.factory.bridge;
}

- (UIView *)hyperswitchViewForModuleName:(NSString *)moduleName
                       initialProperties:(nullable NSDictionary *)initialProperties {
    if (self.factory) {
        return [self.factory viewWithModuleName:moduleName
                              initialProperties:initialProperties
                                  launchOptions:nil];
    }

    return [[RCTRootView alloc] initWithBridge:[[RCTBridge alloc] initWithDelegate:self launchOptions:nil]
                                    moduleName:moduleName
                             initialProperties:initialProperties];
}

#pragma mark - RCTBridgeDelegate

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
    NSString *source = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"HyperswitchSource"];

    if ([source isEqualToString:@"LocalHosted"]) {
        return [RCTBundleURLProvider.sharedSettings jsBundleURLForBundleRoot:@"index"];
    }

    if ([source isEqualToString:@"LocalBundle"]) {
        return [[NSBundle mainBundle] URLForResource:@"hyperswitch" withExtension:@"bundle"];
    }

    return [[NSBundle bundleForClass:[self class]] URLForResource:@"hyperswitch" withExtension:@"bundle"];
}

#pragma mark - RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(const char *)name {
#if RN_DISABLE_OSS_PLUGIN_HEADER
    Class klass = NSClassFromString(@"RCTTurboModulePluginClassProvider");
    if (klass) {
        return ((Class (*)(const char *))[klass methodForSelector:NSSelectorFromString(@"pluginClassProvider:")])(name);
    }
    return nil;
#else
    return RCTCoreModulesClassProvider(name);
#endif
}

- (nullable id<RCTModuleProvider>)getModuleProvider:(const char *)name {
    if (!self.dependencyProvider) {
        return nil;
    }

    NSDictionary<NSString *, id<RCTModuleProvider>> *providers = [self.dependencyProvider moduleProviders];
    return providers[[NSString stringWithUTF8String:name]];
}

#ifdef __cplusplus
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker {
#if __has_include(<react/nativemodule/defaults/DefaultTurboModules.h>)
    return facebook::react::DefaultTurboModules::getTurboModule(name, jsInvoker);
#else
    return nullptr;
#endif
}
#endif

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass {
    return [[moduleClass alloc] init];
}

#pragma mark - RCTHostDelegate

- (void)hostDidStart:(RCTHost *)host {
    // no-op
}

@end
