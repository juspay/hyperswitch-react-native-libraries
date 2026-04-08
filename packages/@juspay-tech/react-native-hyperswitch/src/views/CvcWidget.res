let createView = viewId => {
  ReactNativeUtils.dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

@react.component @genType
let make = React.forwardRef((
  ~options: PaymentSheetConfiguration.cvcWidgetOptions,
  ~onChange: option<NativeModuleTypes.paymentEventResult => unit>=?,
  ~onFocus: option<unit => unit>=?,
  ~onBlur: option<unit => unit>=?,
  ~style: option<ReactNative.Style.t>=?,
  _ref,
) => {
  let (viewId, setViewId) = React.useState(_ => None)
  let viewRef: React.ref<Nullable.t<unit>> = React.useRef(Nullable.null)
  let isRegisteredRef = React.useRef(false)
  let (contextData, _) = React.useContext(HyperElements.hyperElementsContext)
  // Detect native view and get node handle when ready (with retry)
  React.useEffect0(() => {
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

    findNodeHandle(0)

    Some(() => isMounted.contents = false)
  })

  // Register/unregister widget with registry
  React.useEffect1(() => {
    switch viewId {
    | Some(id) =>
      WidgetRegistry.registerWidget(options.widgetId, id)
      isRegisteredRef.current = true
      Some(
        () => {
          if isRegisteredRef.current {
            WidgetRegistry.unregisterWidget(options.widgetId)
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
    placeholder: ?options.placeholder->Option.map((cvv): PaymentSheetConfiguration.placeholder => {
      cvv: ?Some(cvv),
    }),
    sdkAuthorization: options.sdkAuthorization,
  }

  <NativePaymentWidget
    ref={viewRef}
    widgetId={options.widgetId}
    widgetType="cvcWidget"
    sdkAuthorization={options.sdkAuthorization}
    onPaymentEvent={onPaymentEventInternal}
    options={fullOptions}
    ?style
  />
})
