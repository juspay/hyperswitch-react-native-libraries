open NativeHyperswitchSdk

let getError: (~error: string=?) => presentPaymentSheetResult = (
  ~error="Unknown error occurred while presenting payment sheet",
) => {
  {
    error: {
      code: "failed",
      message: error,
    },
  }
}

let getData = (data, ~key: string, ~fallback: string) => {
  data
  ->Option.flatMap(obj => obj->Dict.get(key)->Option.flatMap(json => json->JSON.Decode.string))
  ->Option.getOr(fallback)
}

let parsePaymentSheetResult = (result: 'a): presentPaymentSheetResult => {
  try {
    let parsed = switch Js.typeof(result) {
    | "string" => JSON.parseExn(result)
    | _ => result->Obj.magic
    }
    let decodedObject = parsed->JSON.Decode.object

    let status = decodedObject->getData(~key="status", ~fallback="failed")
    let errorMessage = decodedObject->getData(~key="error", ~fallback="")

    let code = decodedObject->getData(~key="code", ~fallback="")

    let typeData = decodedObject->getData(~key="type", ~fallback="")

    let message = decodedObject->getData(~key="message", ~fallback="failed")

    let paymentResult = {
      status,
      message,
      error: errorMessage,
      \"type": typeData,
    }
    let error = {
      code,
      message: errorMessage,
    }

    if errorMessage != "" {
      {error, paymentResult}
    } else {
      {paymentResult: paymentResult}
    }
  } catch {
  | _ => getError(~error="Failed to parse payment sheet result")
  }
}

let _presentPaymentSheet = async (params: presentPaymentSheetParams): presentPaymentSheetResult => {
  try {
    let result = await nativeHyperswitchSdk.presentPaymentSheet(params)
    result->parsePaymentSheetResult
  } catch {
  | Exn.Error(obj) =>
    // Check if the error is an object error - if so, return the error
    switch Js.typeof(obj) {
    | "object" =>
      // Try to parse the object error
      try {
        let errorObj = obj->Obj.magic
        let parsedError = errorObj->parsePaymentSheetResult
        parsedError
      } catch {
      | _ =>
        switch Exn.message(obj) {
        | Some(error) => getError(~error)
        | None => getError()
        }
      }
    | _ =>
      switch Exn.message(obj) {
      | Some(error) => getError(~error)
      | None => getError()
      }
    }
  | _ => getError()
  }
}

@genType
type useHyper = {
  // confirmPayment: unit => promise<presentPaymentSheetResult>,
  presentPaymentSheet: presentPaymentSheetParams => promise<presentPaymentSheetResult>,
  isReady: bool,
  isSessionInitialized: bool,
}

@genType
let useHyper = (): useHyper => {
  let (providerData, _) = React.useContext(HyperProvider.hyperProviderContext)
  let hyperElements = React.useContext(HyperElements.hyperElementsContext)

  let isProviderReady = providerData.isInitialized && providerData.error->Option.isNone
  let isSessionInitialized = hyperElements.isSessionInitialized
  let isReady = isProviderReady && isSessionInitialized

  let clientSecret = hyperElements.clientSecret
  let sdkAuthorisation = hyperElements.sdkAuthorisation

  let presentPaymentSheet = React.useCallback1((params: presentPaymentSheetParams) => {
    if !isReady {
      let a: promise<presentPaymentSheetResult> = Promise.resolve(
        getError(~error="Hyperswitch is not initialized"),
      )
      a
    } else {
      _presentPaymentSheet(params)
    }
  }, [isReady])

  // Confirm payment - for headless flow
  // let confirmPayment = React.useCallback3(() => {
  //   if !isReady {
  //     let a: promise<presentPaymentSheetResult> = Promise.resolve(
  //       getError(~error="Hyperswitch is not initialized or session is not ready"),
  //     )
  //     a
  //   } else {
  //     // Build params from context
  //     let params: presentPaymentSheetParams = {
  //       ?clientSecret,
  //       ?sdkAuthorisation,
  //     }
  //     _presentPaymentSheet(params)
  //   }
  // }, (isReady, clientSecret, sdkAuthorisation))

  {
    // confirmPayment,
    presentPaymentSheet,
    isReady,
    isSessionInitialized,
  }
}
