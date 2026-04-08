// open NativeHyperswitchSdk

// type paymentEvent = {
//   eventName: string,
//   payload?: JSON.t,
// }

// @module("../utils/PaymentSheetEventManager.res.js")
// external registerCallback: (paymentEvent => unit) => unit = "registerCallback"

// @module("../utils/PaymentSheetEventManager.res.js")
// external unregisterCallback: unit => unit = "unregisterCallback"

// let emitUnknownEventWarning = (callback: paymentEvent => unit, invalidEvents: array<string>) => {
//   let warningPayload = EventValidator.makeUnknownEventWarningPayload(invalidEvents)
//   let payloadJson = Dict.fromArray([
//     ("message", JSON.Encode.string(warningPayload.message)),
//     ("invalidEvents", JSON.Encode.array(warningPayload.invalidEvents->Array.map(JSON.Encode.string))),
//     ("validEvents", JSON.Encode.array(warningPayload.validEvents->Array.map(JSON.Encode.string))),
//   ])->JSON.Encode.object
//   callback({
//     eventName: "UNKNOWN_EVENT_SUBSCRIBED",
//     payload: payloadJson,
//   })
// }

// // let getError: (~error: string=?) => presentPaymentSheetResult = (
// //   ~error="Unknown error occurred while presenting payment sheet",
// // ) => {
// //   {
// //     error: {
// //       code: "failed",
// //       message: error,
// //     },
// //   }
// // }

// let _initPaymentSession = async (params: initPaymentSessionParams): initPaymentSessionResult => {
//   try {
//     await nativeHyperswitchSdk.initPaymentSession(
//       ~paymentIntentClientSecret=params.paymentIntentClientSecret->Option.getOr(""),
//     )
//     {}
//   } catch {
//   | Exn.Error(obj) =>
//     switch Exn.message(obj) {
//     | Some(msg) => {error: msg}
//     | None => {error: "Unknown error occurred while initializing payment sheet"}
//     | _ => {error: "Unexpected error occurred while initializing payment sheet"}
//     }
//   }
// }

// let getData = (data, ~key: string, ~fallback: string) => {
//   data
//   ->Option.flatMap(obj => obj->Dict.get(key)->Option.flatMap(json => json->JSON.Decode.string))
//   ->Option.getOr(fallback)
// }

// let parsePaymentSheetResult = (result: 'a): presentPaymentSheetResult => {
//   try {
//     let parsed = switch typeof(result) {
//     | #string => JSON.parseExn(result)
//     | _ => result->Obj.magic
//     }
//     let decodedObject = parsed->JSON.Decode.object

//     let status = decodedObject->getData(~key="status", ~fallback="failed")
//     let errorMessage = decodedObject->getData(~key="error", ~fallback="")

//     let code = decodedObject->getData(~key="code", ~fallback="")

//     let typeData = decodedObject->getData(~key="type", ~fallback="")
//     let message = decodedObject->getData(~key="message", ~fallback="failed")

// //     let paymentResult = {
// //       status,
// //       message,
// //       error: errorMessage,
// //       type_: typeData,
// //     }

// //     let error = {
// //       code,
// //       message: errorMessage,
// //     }

// //     if errorMessage != "" {
// //       {error, paymentResult}
// //     } else {
// //       {paymentResult: paymentResult}
// //     }
// //   } catch {
// //   | _ => getError(~error="Failed to parse payment sheet result")
// //   }
// // }

// let _presentPaymentSheet = async (params: presentPaymentSheetParams): presentPaymentSheetResult => {
//   try {
//     let result = await nativeHyperswitchSdk.presentPaymentSheet(params)
//     result->parsePaymentSheetResult
//   } catch {
//   | Exn.Error(obj) =>
//     switch typeof(obj) {
//     | #object =>
//       try {
//         let errorObj = obj->Obj.magic
//         let parsedError = errorObj->parsePaymentSheetResult
//         parsedError
//       } catch {
//       | _ =>
//         switch Exn.message(obj) {
//         | Some(error) => getError(~error)
//         | None => getError()
//         }
//       }
//     | _ =>
//       switch Exn.message(obj) {
//       | Some(error) => getError(~error)
//       | None => getError()
//       }
//     }
//   | _ => getError()
//   }
// }

// type useHyper = {
//   initPaymentSession: initPaymentSessionParams => promise<initPaymentSessionResult>,
//   presentPaymentSheet: (
//     presentPaymentSheetParams,
//     option<paymentEvent => unit>,
//   ) => promise<presentPaymentSheetResult>,
// }

// @genType
// let useHyper = () => {
//   let (contextData, _) = React.useContext(HyperProvider.hyperProviderContext)
//   let isReady = contextData.isInitialized && contextData.error->Option.isNone

//   let initPaymentSession = React.useCallback0((params: initPaymentSessionParams) => {
//     _initPaymentSession(params)
//   })

//   let presentPaymentSheet = React.useCallback1(
//     (params: presentPaymentSheetParams, onPaymentEvent: option<paymentEvent => unit>) => {
//       if !isReady {
//         Promise.resolve(getError(~error="Hyperswitch is not initialized"))
//       } else {
//         let subscribedEventStrings = params.subscribedEvents->Obj.magic
//         let invalidEvents = EventValidator.validateSubscribedEventStrings(subscribedEventStrings)
        
//         switch onPaymentEvent {
//         | Some(callback) => {
//             if Array.length(invalidEvents) > 0 {
//               emitUnknownEventWarning(callback, invalidEvents)
//             }
//             registerCallback(callback)
//           }
//         | None => ()
//         }
//         _presentPaymentSheet(params)->Promise.then(res => {
//           unregisterCallback()
//           Promise.resolve(res)
//         })
//       }
//     },
//     [isReady],
//   )

// //   {
// //     initPaymentSession,
// //     presentPaymentSheet,
// //   }
// // }
