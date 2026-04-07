@module("react-native") @scope("UIManager")
external dispatchViewManagerCommand: (
  ~viewId: int,
  ~commandId: int,
  ~commandArgs: array<int>,
) => unit = "dispatchViewManagerCommand"

@module("react-native")
external findNodeHandle: Nullable.t<unit> => int = "findNodeHandle"

type commands = {createView: string}

type viewManagerConfig = {\"Commands": commands}

let createView = viewId => {
  dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

@react.component @genType
let make = (
  ~options: PaymentSheetConfiguration.cvcWidgetOptions,
  ~onChange: option<NativeModuleTypes.paymentEventResult => unit>=?,
  ~onFocus: option<unit => unit>=?,
  ~onBlur: option<unit => unit>=?,
  ~style: option<ReactNative.Style.t>=?,
) => {
  let (viewId, setViewId) = React.useState(_ => None)
  let viewRef: React.ref<Nullable.t<unit>> = React.useRef(Nullable.null)
  React.useEffect0(() => {
    switch Nullable.toOption(viewRef.current) {
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

  let onPaymentEventInternal = (event: NativeModuleTypes.paymentEventNative) => {
    // Forward the raw event to onChange
    switch onChange {
    | Some(callback) => callback(event.nativeEvent)
    | None => ()
    }

    // Route CVC_STATUS events to onFocus/onBlur convenience callbacks
    switch event.nativeEvent.eventName {
    | "CVC_STATUS" =>
      try {
        switch event.nativeEvent.payload->JSON.parseExn->JSON.Decode.object {
        | Some(outerDict) =>
          switch outerDict->Dict.get("cvcStatus")->Option.flatMap(JSON.Decode.object) {
          | Some(cvcDict) => {
              let isCvcFocused =
                cvcDict
                ->Dict.get("isCvcFocused")
                ->Option.flatMap(JSON.Decode.bool)
                ->Option.getOr(false)
              let isCvcBlur =
                cvcDict
                ->Dict.get("isCvcBlur")
                ->Option.flatMap(JSON.Decode.bool)
                ->Option.getOr(false)
              if isCvcFocused {
                switch onFocus {
                | Some(cb) => cb()
                | None => ()
                }
              }
              if isCvcBlur {
                switch onBlur {
                | Some(cb) => cb()
                | None => ()
                }
              }
            }
          | None => ()
          }
        | None => ()
        }
      } catch {
      | _ => ()
      }
    | _ => ()
    }
  }

  let fullAppearance: option<PaymentSheetConfiguration.appearance> = 
    options.appearance->Option.map(AppearanceTransformer.cvcAppearanceToAppearance)


  let fullOptions: PaymentSheetConfiguration.options = {
    subscribedEvents: ?Some([CvcStatus]),
    appearance: ?fullAppearance,
    placeholder: ?options.placeholder->Option.map((cvv): PaymentSheetConfiguration.placeholder => {cvv: ?Some(cvv)}),
  }

  

  <NativePaymentWidget
    ref={viewRef}
    widgetId={options.widgetId}
    widgetType="cvcWidget"
    clientSecret={options.clientSecret}
    onPaymentEvent={onPaymentEventInternal}
    options={fullOptions}
    ?style
  />
}
