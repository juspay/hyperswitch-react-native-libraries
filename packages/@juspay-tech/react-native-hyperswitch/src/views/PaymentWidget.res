@scope("JSON") @val external parse: string => NativeModuleTypes.paymentResult = "parse"

let createView = viewId => {
  ReactNativeUtils.dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

type paymentWidgetRef = {confirmPayment: unit => promise<NativeHyperswitchSdk.paymentResult>}

type pendingConfirmation = {
  resolve: NativeHyperswitchSdk.paymentResult => unit,
  reject: exn => unit,
}

@react.component @genType
let make = React.forwardRef((
  ~widgetId: string,
  ~onPaymentResult: NativeModuleTypes.paymentResult => unit,
  ~options: option<PaymentSheetConfiguration.options>=?,
  ~style: option<ReactNative.Style.t>=?,
  ref,
) => {
  let (viewId, setViewId) = React.useState(_ => None)
  let viewRef: React.ref<Nullable.t<unit>> = React.useRef(Nullable.null)
  let (hyperElementsContext, _) = HyperElements.useHyperElements()
  let isRegisteredRef = React.useRef(false)
  let mountCountRef = React.useRef(0)

  // Effect to detect when native view is mounted and get its node handle
  React.useEffect(() => {
    let checkAndRegister = () => {
      switch Js.Nullable.toOption(viewRef.current) {
      | Some(_) => {
          let id = ReactNativeUtils.findNodeHandle(viewRef.current)
          if id != -1 {
            setViewId(_ => Some(id))
          }
        }
      | None => ()
      }
    }
    // Delay slightly to ensure native view is mounted
    let timeoutId = Js.Global.setTimeout(checkAndRegister, 100)
    Some(() => Js.Global.clearTimeout(timeoutId))
  }, [mountCountRef.current])

  // Registration effect - runs when viewId becomes available
  React.useEffect(() => {
    switch viewId {
    | Some(id) => {
        WidgetRegistry.registerWidget(widgetId, id)
        isRegisteredRef.current = true
        Some(() => {
          if isRegisteredRef.current {
            WidgetRegistry.unregisterWidget(widgetId)
            isRegisteredRef.current = false
          }
        })
      }
    | None => None
    }
  }, [viewId])

  React.useImperativeHandle(
    ref,
    () => {
      {
        confirmPayment: (): promise<NativeHyperswitchSdk.paymentResult> => {
          switch Nullable.toOption(viewRef.current) {
          | None =>
            Promise.resolve(
              ({status: "failed", message: "Widget not ready"}: NativeHyperswitchSdk.paymentResult),
            )
          | Some(_) =>
            let id = ReactNativeUtils.findNodeHandle(viewRef.current)
            if id == -1 {
              Promise.resolve(
                ({status: "failed", message: "Widget not ready"}: NativeHyperswitchSdk.paymentResult ),
              )
            } else {
              Promise.make((resolve, _) => {
                NativeHyperswitchSdk.confirmPayment(id, (result: NativeHyperswitchSdk.paymentResult) => {
                  let status = result.status 
                  resolve(({status, message: result.message}: NativeHyperswitchSdk.paymentResult))
                })
              })
            }
          }
        },
      }
    },
    [viewId],
  )

  React.useEffect(() => {
    switch viewId {
    | Some(id) => {
        createView(id)
      }
    | None => ()
    }
    None
  }, [viewId])

  let onPaymentResultInternal = (event: NativeModuleTypes.nativeEvent) => {
    onPaymentResult(event.nativeEvent.result->Option.getOr("")->parse)
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
        onPaymentResult={onPaymentResultInternal}
        ?options
        ?style
      />
    | None => React.null
    }
  }
})
