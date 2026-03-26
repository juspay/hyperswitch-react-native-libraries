// useWidget.res
// Hook for accessing widget methods within HyperElements context

open NativeHyperswitchSdk

// Hook to access widget methods and state
@genType
let useWidget = (): HyperTypes.widgetController => {
  let (contextData, _) = HyperElements.useHyperElements()
  let (isConfirmDisabled, setIsConfirmDisabled) = React.useState(_ => false)
  let (isLoading, setIsLoading) = React.useState(_ => false)
  let (isReady, setIsReady) = React.useState(_ => false)

  let isInitialized = contextData.isInitialized && contextData.error->Option.isNone
  let hyperInstance = contextData.hyperInstance

  // Update ready state when initialization changes
  React.useEffect1(() => {
    setIsReady(_ => isInitialized)
    None
  }, [isInitialized])

  // confirmPayment method - triggers payment confirmation
  let confirmPayment = React.useCallback0(() => {
    switch hyperInstance {
    | Some(instance) => {
        setIsLoading(_ => true)
        setIsConfirmDisabled(_ => true)

        let paymentParamsDict = Js.Dict.empty()
        paymentParamsDict->Js.Dict.set(
          "sdkAuthorisation",
          contextData.sdkAuthorisation->Option.getOr("")->Js.Json.string,
        )
        let paymentParams = paymentParamsDict->Js.Json.object_

        instance.confirmPayment(paymentParams)
        ->Promise.then(result => {
          setIsLoading(_ => false)
          setIsConfirmDisabled(_ => false)
          Promise.resolve(result)
        })
        ->Promise.catch(_err => {
          setIsLoading(_ => false)
          setIsConfirmDisabled(_ => false)

          let errorObj = Js.Dict.empty()
          errorObj->Js.Dict.set("status", "failed"->Js.Json.string)
          errorObj->Js.Dict.set("message", "Payment confirmation failed"->Js.Json.string)
          Promise.resolve(errorObj->Js.Json.object_)
        })
      }
    | None => {
        let errorObj = Js.Dict.empty()
        errorObj->Js.Dict.set("status", "failed"->Js.Json.string)
        errorObj->Js.Dict.set("message", "Hyper instance not initialized"->Js.Json.string)
        Promise.resolve(errorObj->Js.Json.object_)
      }
    }
  })

  let presentPaymentSheet = React.useCallback1(
    (params: presentPaymentSheetParams) => {
      if !isReady {
        Promise.resolve(({
          error: {
            code: "failed",
            message: "Hyperswitch is not initialized",
          },
        }: presentPaymentSheetResult))
      } else {
        nativeHyperswitchSdk.presentPaymentSheet(params->Obj.magic)
        ->Promise.then(result => {
          let parsed = switch Js.typeof(result) {
          | "string" => Js.Json.parseExn(result)
          | _ => result->Obj.magic
          }

          let decodedObject = parsed->Js.Json.decodeObject

          let status =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "status"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("failed")

          let errorMessage =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "error"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("")

          let code =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "code"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("")

          let typeData =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "type"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("")

          let message =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "message"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("failed")

          let paymentResult: paymentResult = {
            status,
            message,
            error: errorMessage,
            type_: typeData,
          }

          let error: error = {
            code,
            message: errorMessage,
          }

          if errorMessage != "" {
            Promise.resolve({error, paymentResult: paymentResult})
          } else {
            Promise.resolve({paymentResult: paymentResult})
          }
        })
        ->Promise.catch(_err => {
          Promise.resolve(({
            error: {
              code: "failed",
              message: "Failed to present payment sheet",
            },
          }: presentPaymentSheetResult))
        })
      }
    },
    [isReady],
  )

  {
    confirmPayment,
    presentPaymentSheet,
    isConfirmDisabled,
    isLoading,
    isReady,
  }
}

// Legacy hook for backwards compatibility
// This hook provides access to the old initPaymentSession and presentPaymentSheet methods
type initPaymentSessionFn = initPaymentSessionParams => promise<initPaymentSessionResult>
type presentPaymentSheetFn = presentPaymentSheetParams => promise<presentPaymentSheetResult>

type useWidgetLegacyResult = {
  initPaymentSession: initPaymentSessionFn,
  presentPaymentSheet: presentPaymentSheetFn,
}

@genType
let useWidgetLegacy = (): useWidgetLegacyResult => {
  let (contextData, _) = HyperElements.useHyperElements()
  let isReady = contextData.isInitialized && contextData.error->Option.isNone

  let initPaymentSession = React.useCallback0((params: initPaymentSessionParams) => {
    nativeHyperswitchSdk.initPaymentSession(~paymentIntentClientSecret=params.paymentIntentClientSecret->Option.getOr(""))->Promise.then(result => {
      // Parse the result string
      let resultObj: initPaymentSessionResult = try {
        let obj = Js.Json.parseExn(result)
        let decoded = obj->Js.Json.decodeObject->Option.getOr(Js.Dict.empty())
        let errorMsg =
          decoded
          ->Js.Dict.get("error")
          ->Option.flatMap(x => Js.Json.decodeString(x))
        switch errorMsg {
        | Some(msg) => {error: msg}
        | None => {}
        }
      } catch {
      | _ => {error: "Failed to parse response"}
      }
      Promise.resolve(resultObj)
    })
    ->Promise.catch(_err => {
      Promise.resolve(({error: "Failed to initialize payment session"}: initPaymentSessionResult))
    })
  })

  let presentPaymentSheet: presentPaymentSheetFn = React.useCallback1(
    (params: presentPaymentSheetParams) => {
      if !isReady {
        Promise.resolve(({
          error: {
            code: "failed",
            message: "Hyperswitch is not initialized",
          },
        }: presentPaymentSheetResult))
      } else {
        nativeHyperswitchSdk.presentPaymentSheet(params->Obj.magic)
        ->Promise.then(result => {
          let parsed = switch Js.typeof(result) {
          | "string" => Js.Json.parseExn(result)
          | _ => result->Obj.magic
          }

          let decodedObject = parsed->Js.Json.decodeObject

          let status =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "status"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("failed")

          let errorMessage =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "error"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("")

          let code =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "code"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("")

          let typeData =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "type"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("")

          let message =
            decodedObject
            ->Option.flatMap(obj => Js.Dict.get(obj, "message"))
            ->Option.flatMap(x => Js.Json.decodeString(x))
            ->Option.getOr("failed")

          let paymentResult: paymentResult = {
            status,
            message,
            error: errorMessage,
            type_: typeData,
          }

          let error: error = {
            code,
            message: errorMessage,
          }

          if errorMessage != "" {
            Promise.resolve({error, paymentResult: paymentResult})
          } else {
            Promise.resolve({paymentResult: paymentResult})
          }
        })
        ->Promise.catch(_err => {
          Promise.resolve(({
            error: {
              code: "failed",
              message: "Failed to present payment sheet",
            },
          }: presentPaymentSheetResult))
        })
      }
    },
    [isReady],
  )

  {
    initPaymentSession,
    presentPaymentSheet,
  }
}
