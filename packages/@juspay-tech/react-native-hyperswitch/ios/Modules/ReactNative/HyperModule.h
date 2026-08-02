#import <React/RCTEventEmitter.h>
#import <HyperswitchSdkReactNativeSpec/HyperswitchSdkReactNativeSpec.h>

/**
 * RN-facing "HyperModule" native module for the New Architecture.
 *
 * The embedded payment-sheet bundle resolves this as
 *   `TurboModuleRegistry.get('HyperModule')`
 * and uses the SAME object for BOTH:
 *   • `new NativeEventEmitter(HyperModule)` — hence it subclasses RCTEventEmitter
 *   • imperative method calls (sendMessageToNative, launchApplePay, exit*, …)
 *
 * The C++ `getTurboModule:` cannot be expressed in Swift, so this ObjC++ class is
 * the registered module; all business logic lives in the Swift singleton
 * `HyperModuleImpl.shared`, to which every call is forwarded.
 *
 * The generated spec protocol/JSI (`NativeHyperModuleSpec` /
 * `NativeHyperModuleSpecJSI`) is produced by codegen from
 * `src/codegen/modules/NativeHyperModule.ts`. Note the spec FILENAME drives those
 * class names; the runtime module name ("HyperModule") comes from
 * `TurboModuleRegistry.get('HyperModule')` + `RCT_EXPORT_MODULE(HyperModule)`.
 */
@interface HyperModule : RCTEventEmitter <NativeHyperModuleSpec>

@end
