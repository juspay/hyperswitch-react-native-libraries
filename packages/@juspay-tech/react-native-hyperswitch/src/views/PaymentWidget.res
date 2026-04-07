@module("react-native") @scope("UIManager")
external dispatchViewManagerCommand: (
  ~viewId: int,
  ~commandId: int,
  ~commandArgs: array<int>,
) => unit = "dispatchViewManagerCommand"

@module("react-native")
external findNodeHandle: Nullable.t<unit> => int = "findNodeHandle"

@scope("JSON") @val external parse: string => NativeModuleTypes.paymentResult = "parse"

type commands = {createView: string}

type viewManagerConfig = {\"Commands": commands}

let emitUnknownEventWarningWidget = (callback: NativeModuleTypes.paymentEventResult => unit, invalidEvents: array<string>) => {
  let warningPayload = EventValidator.makeUnknownEventWarningPayload(invalidEvents)
  let payloadJson = Dict.fromArray([
    ("message", JSON.Encode.string(warningPayload.message)),
    ("invalidEvents", JSON.Encode.array(warningPayload.invalidEvents->Array.map(JSON.Encode.string))),
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
  dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

@react.component @genType
let make = (
  ~widgetId,
  ~onPaymentResult,
  ~onPaymentEvent: option<NativeModuleTypes.paymentEventResult => unit>=?,
  ~options: option<PaymentSheetConfiguration.options>=?,
  ~style: option<ReactNative.Style.t>=?,
) => {
  let (viewId, setViewId) = React.useState(_ => None)
  let viewRef: React.ref<Nullable.t<unit>> = React.useRef(Nullable.null)
  let (hyperElementsContext, _) = HyperElements.useHyperElements()

  React.useEffect(() => {
    switch Js.Nullable.toOption(viewRef.current) {
    | Some(_) =>
      setViewId(_ => Some(findNodeHandle(viewRef.current)))
      ()
    | None => ()
    }
    None
  })

  React.useEffect1(() => {
    switch viewId {
    | Some(id) => createView(id)
    | None => ()
    }
    None
  }, [viewId])

  let warningEmitted = React.useRef(false)
  
  React.useEffect0(() => {
    switch (options, onPaymentEvent) {
    | (Some(opts), Some(callback)) when !warningEmitted.current =>
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

  // Only render if HyperElements is initialized
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
        // sdkAuthorisation={hyperElementsContext.sdkAuthorisation->Option.getOr("")}
        onPaymentResult={onPaymentResultInternal}
        options=?options
        style=?style
      />
    | None =>
      React.null
    }
  }
}
