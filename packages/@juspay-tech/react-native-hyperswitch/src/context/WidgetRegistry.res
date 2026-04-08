let widgetHashMap = ref(Dict.make())

let registerWidget = (widgetId: string, nativeViewId) => {
  widgetHashMap.contents->Dict.set(widgetId, nativeViewId)
}

let getWidget = (widgetId: string) => {
  widgetHashMap.contents->Dict.get(widgetId)
}

let unregisterWidget = (widgetId: string) => {
  widgetHashMap.contents->Dict.delete(widgetId)
}

let confirmPayment = (widgetId: string): promise<NativeHyperswitchSdk.paymentResult> => {
  switch widgetHashMap.contents->Dict.get(widgetId) {
  | Some(nativeId) =>
    Promise.make((resolve, _) => {
      NativeHyperswitchSdk.confirmPayment(nativeId, (result: NativeHyperswitchSdk.paymentResult) => {
        resolve({status: result.status, message: result.message}: NativeHyperswitchSdk.paymentResult)
      })
    })
  | None =>
    Promise.resolve({
      status: "failed",
      message: "Widget " ++ widgetId ++ " not found or not mounted",
    }: NativeHyperswitchSdk.paymentResult)
  }
}

// let updateIntent = (widgetId: string): promise<NativeHyperswitchSdk.paymentResult> => {
//   switch widgetHashMap.contents->Dict.get(widgetId) {
//   | Some(nativeId) =>
//     Promise.make((resolve, _) => {
//       NativeHyperswitchSdk.updateInte(nativeId, (result: NativeHyperswitchSdk.paymentResult) => {
//         resolve({status: result.status, message: result.message}: NativeHyperswitchSdk.paymentResult)
//       })
//     })
//   | None =>
//     Promise.resolve({
//       status: "failed",
//       message: "Widget " ++ widgetId ++ " not found or not mounted",
//     }: NativeHyperswitchSdk.paymentResult)
//   }
// }
