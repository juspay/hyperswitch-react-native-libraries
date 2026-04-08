@scope("JSON") @val external parse: string => NativeModuleTypes.paymentResult = "parse"

type commands = {createView: string}

type viewManagerConfig = {\"Commands": commands}

let emitUnknownEventWarningWidget = (
  callback: NativeModuleTypes.paymentEventResult => unit,
  invalidEvents: array<string>,
) => {
  let warningPayload = EventValidator.makeUnknownEventWarningPayload(invalidEvents)
  let payloadJson =
    Dict.fromArray([
      ("message", JSON.Encode.string(warningPayload.message)),
      (
        "invalidEvents",
        JSON.Encode.array(warningPayload.invalidEvents->Array.map(JSON.Encode.string)),
      ),
      ("validEvents", JSON.Encode.array(warningPayload.validEvents->Array.map(JSON.Encode.string))),
    ])->JSON.Encode.object
  let payloadStr = payloadJson->JSON.stringify
  callback({
    eventName: "UNKNOWN_EVENT_SUBSCRIBED",
    payload: payloadStr,
  })
}

// @module("react-native") @scope("UIManager")
// external getViewManagerConfig: string => viewManagerConfig = "getViewManagerConfig"
// @send external commands: Js.t<{..}> => Js.t<{..}> = "Commands"
// @send external createViewCmd: Js.t<{..}> => string = "createView"

// @val external toString: 't => string = "toString"

// let getCreateViewCommand = () => {
//   getViewManagerConfig("NativePaymentWidget").\"Commands".createView->toString
//   }

let createView = viewId => {
  ReactNativeUtils.dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

type paymentWidgetRef = {confirmPayment: unit => promise<NativeHyperswitchSdk.paymentResult>}

@react.component @genType
let make = React.forwardRef((
  ~widgetId: string,
  ~onPaymentResult: NativeModuleTypes.paymentResult => unit,
  ~onPaymentEvent: option<NativeModuleTypes.paymentEventResult => unit>=?,
  ~options: option<PaymentSheetConfiguration.options>=?,
  ~style: option<ReactNative.Style.t>=?,
  ref,
) => {
  let (viewId, setViewId) = React.useState(_ => None)
  let viewRef: React.ref<Nullable.t<unit>> = React.useRef(Nullable.null)
  let (hyperElementsContext, _) = HyperElements.useHyperElements()
  let isRegisteredRef = React.useRef(false)

  // Detect native view and get node handle when ready
  React.useEffect2(() => {
    let isMounted = {contents: true}

    let rec findNodeHandle = attempt => {
      if !isMounted.contents {
        ()
      } else {
        switch Js.Nullable.toOption(viewRef.current) {
        | Some(_) =>
          let id = ReactNativeUtils.findNodeHandle(viewRef.current)
          if id != -1 {
            setViewId(_ => Some(id))
          } else if attempt < 20 {
            let _ = Js.Global.setTimeout(() => findNodeHandle(attempt + 1), 100)
          }
        | None =>
          if attempt < 20 {
            let _ = Js.Global.setTimeout(() => findNodeHandle(attempt + 1), 100)
          }
        }
      }
    }

    if hyperElementsContext.isInitialized && Option.isSome(hyperElementsContext.clientSecret) {
      findNodeHandle(0)
    }

    Some(() => isMounted.contents = false)
  }, (hyperElementsContext.isInitialized, hyperElementsContext.clientSecret))

  // Register/unregister widget with registry
  React.useEffect1(() => {
    switch viewId {
    | Some(id) =>
      WidgetRegistry.registerWidget(widgetId, id)
      isRegisteredRef.current = true
      Some(
        () => {
          if isRegisteredRef.current {
            WidgetRegistry.unregisterWidget(widgetId)
            isRegisteredRef.current = false
          }
        },
      )
    | None => None
    }
  }, [viewId])

  // Create native view when viewId available
  React.useEffect1(() => {
    switch viewId {
    | Some(id) => createView(id)
    | None => ()
    }
    None
  }, [viewId])

  // Expose imperative handle for direct confirmPayment calls
  React.useImperativeHandle(
    ref,
    () => {
      {
        confirmPayment: () => {
          switch Nullable.toOption(viewRef.current) {
          | None =>
            Promise.resolve(
              (
                {
                  status: "failed",
                  message: "Widget not ready",
                  error: "Widget not ready",
                }: NativeHyperswitchSdk.paymentResult
              ),
            )
          | Some(_) =>
            let id = ReactNativeUtils.findNodeHandle(viewRef.current)
            if id == -1 {
              Promise.resolve(
                (
                  {
                    status: "failed",
                    message: "Widget not ready",
                    error: "Unable to find native view handle",
                  }: NativeHyperswitchSdk.paymentResult
                ),
              )
            } else {
              Promise.make((resolve, _) => {
                NativeHyperswitchSdk.confirmPayment(
                  id,
                  (result: NativeHyperswitchSdk.paymentResult) => {
                    resolve(
                      (
                        {
                          status: result.status,
                          message: result.message,
                          // error: result.error,
                        }: NativeHyperswitchSdk.paymentResult
                      ),
                    )
                  },
                )
              })
            }
          }
        },
      }
    },
    [viewId],
  )

  let warningEmitted = React.useRef(false)

  React.useEffect0(() => {
    switch (options, onPaymentEvent) {
    | (Some(opts), Some(callback)) if !warningEmitted.current =>
      let subscribedEventStrings: option<array<string>> = opts.subscribedEvents->Obj.magic
      let invalidEvents = EventValidator.validateSubscribedEventStrings(subscribedEventStrings)
      if Array.length(invalidEvents) > 0 {
        warningEmitted.current = true
        emitUnknownEventWarningWidget(callback, invalidEvents)
      }
      ()
    | _ => ()
    }
    None
  })

  let onPaymentResultInternal = (event: NativeModuleTypes.nativeEvent) => {
    onPaymentResult(event.nativeEvent.result->Option.getOr("")->parse)
  }

  let onPaymentEventInternal = (event: NativeModuleTypes.paymentEventNative) => {
    switch onPaymentEvent {
    | Some(callback) => callback(event.nativeEvent)
    | None => ()
    }
  }

  // Render conditions
  if !hyperElementsContext.isInitialized {
    React.null
  } else {
    switch hyperElementsContext.clientSecret {
    | Some(clientSecret) =>
      <NativePaymentWidget
        ref={viewRef}
        widgetId={widgetId}
        widgetType={"widgetPaymentSheet"}
        clientSecret={clientSecret}
        onPaymentResult={onPaymentResultInternal}
        onPaymentEvent={onPaymentEventInternal}
        ?options
        ?style
      />
    | None => React.null
    }
  }
})
