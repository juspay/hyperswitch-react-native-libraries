// usePaymentSession.res
// Hook for accessing payment session methods from HyperElements context

// Return type for the hook
type usePaymentSessionResult = {
  isReady: bool,
  error: option<string>,
  paymentSession: option<HyperTypes.paymentSession>,
  getCustomerDefaultSavedPaymentMethodData: unit => promise<HyperTypes.nativeResponse>,
  getCustomerLastUsedPaymentMethodData: unit => promise<HyperTypes.nativeResponse>,
  confirmWithCustomerDefaultPaymentMethod: string => promise<HyperTypes.nativeResponse>,
  confirmWithCustomerLastUsedPaymentMethod: string => promise<HyperTypes.nativeResponse>,
  confirmWithCustomerPaymentToken: string => promise<HyperTypes.nativeResponse>,
  presentPaymentSheet: (
    NativeHyperswitchSdk.presentPaymentSheetParams,
    option<HyperTypes.paymentEvent => unit>,
  ) => promise<NativeHyperswitchSdk.presentPaymentSheetResult>,
  updateIntent: (~callback: unit => promise<string>) => promise<HyperTypes.nativeResponse>,
}

// Default/error return values for when session is not ready
let notReadyResponse: HyperTypes.nativeResponse = {
  status: HyperTypes.Failed,
  message: "Payment session not initialized",
}

let notReadySheetResult: NativeHyperswitchSdk.presentPaymentSheetResult = {
  error: {
    code: "NOT_READY",
    message: "Payment session not initialized",
  },
}

@genType
let usePaymentSession = (): usePaymentSessionResult => {
  let (contextData, _) = HyperElements.useHyperElements()

  let session = contextData.paymentSession
  let isReady = contextData.isInitialized && contextData.error->Option.isNone
  let error = contextData.error

  // Wrapper functions that check if session is ready
  let getCustomerDefaultSavedPaymentMethodData = React.useCallback0(() => {
    switch session {
    | Some(s) => s.getCustomerDefaultSavedPaymentMethodData()
    | None => Promise.resolve(notReadyResponse)
    }
  })

  let getCustomerLastUsedPaymentMethodData = React.useCallback0(() => {
    switch session {
    | Some(s) => s.getCustomerLastUsedPaymentMethodData()
    | None => Promise.resolve(notReadyResponse)
    }
  })

  let confirmWithCustomerDefaultPaymentMethod = React.useCallback0((widgetId: string) => {
    switch session {
    | Some(s) => s.confirmWithCustomerDefaultPaymentMethod(widgetId)
    | None => Promise.resolve(notReadyResponse)
    }
  })

  let confirmWithCustomerLastUsedPaymentMethod = React.useCallback0((widgetId: string) => {
    switch session {
    | Some(s) => s.confirmWithCustomerLastUsedPaymentMethod(widgetId)
    | None => Promise.resolve(notReadyResponse)
    }
  })

  let confirmWithCustomerPaymentToken = React.useCallback0((token: string) => {
    switch session {
    | Some(s) => s.confirmWithCustomerPaymentToken(token)
    | None => Promise.resolve(notReadyResponse)
    }
  })

  let presentPaymentSheet = React.useCallback0((
    params: NativeHyperswitchSdk.presentPaymentSheetParams,
    onPaymentEvent: option<HyperTypes.paymentEvent => unit>,
  ) => {
    switch session {
    | Some(s) => s.presentPaymentSheet(params, onPaymentEvent)
    | None => Promise.resolve(notReadySheetResult)
    }
  })

  let updateIntent = React.useCallback0((~callback: unit => promise<string>) => {
    switch session {
    | Some(s) => s.updateIntent(~callback)
    | None => Promise.resolve(notReadyResponse)
    }
  })

  {
    isReady,
    error,
    paymentSession: session,
    getCustomerDefaultSavedPaymentMethodData,
    getCustomerLastUsedPaymentMethodData,
    confirmWithCustomerDefaultPaymentMethod,
    confirmWithCustomerLastUsedPaymentMethod,
    confirmWithCustomerPaymentToken,
    presentPaymentSheet,
    updateIntent,
  }
}
