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
    switch onChange {
    | Some(callback) => callback(event.nativeEvent)
    | None => ()
    }
  }

  let fullAppearance: option<PaymentSheetConfiguration.appearance> = 
    options.appearance->Option.map(AppearanceTransformer.cvcAppearanceToAppearance)


  let fullOptions: PaymentSheetConfiguration.options = {
    clientSecret: ?Some(options.clientSecret),
    subscribedEvents: ?Some([CvcStatus]),
    appearance: ?fullAppearance,
    placeholder: ?options.placeholder->Option.map((cvv): PaymentSheetConfiguration.placeholder => {cvv: ?Some(cvv)}),
  }

  

  <NativePaymentWidget
    ref={viewRef}
    widgetId="cvc-widget"
    widgetType="cvcWidget"
    clientSecret={options.clientSecret}
    onPaymentEvent={onPaymentEventInternal}
    options={fullOptions}
    ?style
  />
}
