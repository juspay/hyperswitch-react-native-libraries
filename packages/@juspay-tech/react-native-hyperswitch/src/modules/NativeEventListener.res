open ReactNative

let setupNativeEventListener = (eventName, handler) => {
  let nativeEventEmitter = NativeEventEmitter.make(
    Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule"),
  )

  let eventSubscription = NativeEventEmitter.addListener(nativeEventEmitter, eventName, handler)

  () => {
    eventSubscription->EventSubscription.remove
  }
}