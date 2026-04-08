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
let updateIntentInitForAllWidgets = (): promise<array<NativeHyperswitchSdk.paymentResult>> => {
  let promises = widgetHashMap.contents
  ->Dict.valuesToArray
  ->Array.map(nativeId => {
    Console.log2("Sending update intent init event to widget with nativeId: ", nativeId)
    Promise.make((resolve, _) => {
      NativeHyperswitchSdk.updateIntentInitForWidget(nativeId, (result) => {
        resolve(result)
      })
    })
  })

  Promise.all(promises)
}

let updateIntentCompleteForAllWidgets = (_sdkAuthorization): promise<array<NativeHyperswitchSdk.paymentResult>> => {
  let promises = widgetHashMap.contents
  ->Dict.valuesToArray
  ->Array.map(nativeId => {
    Promise.make((resolve, _) => {
      NativeHyperswitchSdk.updateIntentCompleteForWidget(nativeId, _sdkAuthorization, (result) => {
        resolve(result)
      })
    })
  })

  Promise.all(promises)
}
