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

type commands = {createView: string}

type viewManagerConfig = {\"Commands": commands}

let nativeConfirmPayment = viewId => {
  ReactNativeUtils.dispatchViewManagerCommand(~viewId, ~commandId=3, ~commandArgs=[])
}

// Confirm — safe, handles missing id
let confirmPayment = (widgetId: string): promise<HyperTypes.nativeResponse> => {
  switch widgetHashMap.contents->Dict.get(widgetId) {
  | Some(nativeId) => {
      nativeConfirmPayment(nativeId)
      let response: HyperTypes.nativeResponse = {
        status: HyperTypes.Succeeded,
        message: "Payment confirmation triggered",
      }
      Promise.resolve(response)
    }
  | None => {
      let message = "Widget " ++ widgetId ++ " not found or not mounted"
      Console.warn(message)
      let response: HyperTypes.nativeResponse = {
        status: HyperTypes.Failed,
        message: message,
      }
      Promise.resolve(response)
    }
  }
}