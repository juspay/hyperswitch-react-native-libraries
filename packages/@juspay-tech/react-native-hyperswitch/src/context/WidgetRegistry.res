let widgetHashMap = ref(Dict.make())

// Register widget
let registerWidget = (widgetId: string, nativeViewId) => {
  widgetHashMap.contents->Dict.set(widgetId, nativeViewId)
}
// Get widget callback
let getWidget = (widgetId: string) => {
  widgetHashMap.contents->Dict.get(widgetId)
}

// Remove widget on unmount
let unregisterWidget = (widgetId: string) => {
  widgetHashMap.contents->Dict.delete(widgetId)
}

// Confirm — safe, handles missing id
let confirmPayment = (widgetId: string): promise<NativeHyperswitchSdk.paymentResult> => {
  switch widgetHashMap.contents->Dict.get(widgetId) {
  | Some(nativeId) => Promise.make((resolve, _) => {
      NativeHyperswitchSdk.confirmPayment(nativeId, (
        result: NativeHyperswitchSdk.paymentResult,
      ) => {
        resolve(({status : result.status, message: result.message}: NativeHyperswitchSdk.paymentResult))
      })
    })
  | None => {
      let message = "Widget " ++ widgetId ++ " not found or not mounted"
      Console.warn(message)
      let response: NativeHyperswitchSdk.paymentResult = {
        status: "failed",
        message,
      }
      Promise.resolve(response)
    }
  }
}
