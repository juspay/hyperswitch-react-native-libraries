// useWidget.res
// Hook for accessing widget methods within HyperElements context

open NativeHyperswitchSdk

type useWidget = {
  isReady: bool,
  confirmPayment: string => promise<NativeHyperswitchSdk.paymentResult>,
}

// Hook to access widget methods and state
@genType
let useWidget = () => {
  let (contextData, _) = HyperElements.useHyperElements()
  let (isReady, setIsReady) = React.useState(_ => false)

  let isInitialized = contextData.isInitialized && contextData.error->Option.isNone
  let _hyperInstance = contextData.hyperInstance

  // Update ready state when initialization changes
  React.useEffect1(() => {
    setIsReady(_ => isInitialized)
    None
  }, [isInitialized])

  // confirmPayment method - triggers payment confirmation via native module
  // Returns the actual payment result from the native SDK instead of calling onPaymentResult callback
  let confirmPayment = React.useCallback1((widgetId: string) => {
    if !isReady {
      Promise.resolve(
        (
          {
            status: "failed",
            message: "Widget is not ready",
          }: NativeHyperswitchSdk.paymentResult
        ),
      )
    } else {
      WidgetRegistry.confirmPayment(widgetId)
    }
  }, [isReady])
  {
    isReady,
    confirmPayment,
  }
}

// Legacy hook for backwards compatibility
// This hook provides access to the old initPaymentSession and presentPaymentSheet methods
// type initPaymentSessionFn = initPaymentSessionParams => promise<initPaymentSessionResult>
// type presentPaymentSheetFn = presentPaymentSheetParams => promise<presentPaymentSheetResult>

// type useWidgetLegacyResult = {
//   initPaymentSession: initPaymentSessionFn,
//   presentPaymentSheet: presentPaymentSheetFn,
// }

// @genType
// let useWidgetLegacy = (): useWidgetLegacyResult => {
//   let (contextData, _) = HyperElements.useHyperElements()
//   let isReady = contextData.isInitialized && contextData.error->Option.isNone

//   let initPaymentSession = React.useCallback0((params: initPaymentSessionParams) => {
//     nativeHyperswitchSdk.initPaymentSession(
//       ~paymentIntentClientSecret=params.paymentIntentClientSecret->Option.getOr(""),
//     )
//     ->Promise.then(result => {
//       // Parse the result string
//       let resultObj: initPaymentSessionResult = try {
//         let obj = Js.Json.parseExn(result)
//         let decoded = obj->Js.Json.decodeObject->Option.getOr(Js.Dict.empty())
//         let errorMsg =
//           decoded
//           ->Js.Dict.get("error")
//           ->Option.flatMap(x => Js.Json.decodeString(x))
//         switch errorMsg {
//         | Some(msg) => {error: msg}
//         | None => {}
//         }
//       } catch {
//       | _ => {error: "Failed to parse response"}
//       }
//       Promise.resolve(resultObj)
//     })
//     ->Promise.catch(_err => {
//       Promise.resolve(({error: "Failed to initialize payment session"}: initPaymentSessionResult))
//     })
//   })

//   let presentPaymentSheet: presentPaymentSheetFn = React.useCallback1(
//     (params: presentPaymentSheetParams) => {
//       if !isReady {
//         Promise.resolve(
//           {
//             error: {
//               code: "failed",
//               message: "Hyperswitch is not initialized",
//             },
//           }: presentPaymentSheetResult,
//         )
//       } else {
//         nativeHyperswitchSdk.presentPaymentSheet(params->Obj.magic)
//         ->Promise.then(result => {
//           let parsed = switch Js.typeof(result) {
//           | "string" => Js.Json.parseExn(result)
//           | _ => result->Obj.magic
//           }

//           let decodedObject = parsed->Js.Json.decodeObject

//           let status =
//             decodedObject
//             ->Option.flatMap(obj => Js.Dict.get(obj, "status"))
//             ->Option.flatMap(x => Js.Json.decodeString(x))
//             ->Option.getOr("failed")

//           let errorMessage =
//             decodedObject
//             ->Option.flatMap(obj => Js.Dict.get(obj, "error"))
//             ->Option.flatMap(x => Js.Json.decodeString(x))
//             ->Option.getOr("")

//           let code =
//             decodedObject
//             ->Option.flatMap(obj => Js.Dict.get(obj, "code"))
//             ->Option.flatMap(x => Js.Json.decodeString(x))
//             ->Option.getOr("")

//           let typeData =
//             decodedObject
//             ->Option.flatMap(obj => Js.Dict.get(obj, "type"))
//             ->Option.flatMap(x => Js.Json.decodeString(x))
//             ->Option.getOr("")

//           let message =
//             decodedObject
//             ->Option.flatMap(obj => Js.Dict.get(obj, "message"))
//             ->Option.flatMap(x => Js.Json.decodeString(x))
//             ->Option.getOr("failed")

//           let paymentResult: paymentResult = {
//             status,
//             message,
//             error: errorMessage,
//             type_: typeData,
//           }

//           let error: error = {
//             code,
//             message: errorMessage,
//           }

//           if errorMessage != "" {
//             Promise.resolve({error, paymentResult})
//           } else {
//             Promise.resolve({paymentResult: paymentResult})
//           }
//         })
//         ->Promise.catch(_err => {
//           Promise.resolve(
//             {
//               error: {
//                 code: "failed",
//                 message: "Failed to present payment sheet",
//               },
//             }: presentPaymentSheetResult,
//           )
//         })
//       }
//     },
//     [isReady],
//   )

//   {
//     initPaymentSession,
//     presentPaymentSheet,
//   }
// }
