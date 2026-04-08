@scope("JSON") @val external parse: string => NativeModuleTypes.paymentResult = "parse"

let createView = viewId => {
  ReactNativeUtils.dispatchViewManagerCommand(~viewId, ~commandId=1, ~commandArgs=[])
}

type paymentWidgetRef = {confirmPayment: unit => promise<NativeHyperswitchSdk.paymentResult>}

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
      Some(() => {
        if isRegisteredRef.current {
          WidgetRegistry.unregisterWidget(widgetId)
          isRegisteredRef.current = false
        }
      })
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
              {status: "failed", message: "Widget not ready"}: NativeHyperswitchSdk.paymentResult,
            )
          | Some(_) =>
            let id = ReactNativeUtils.findNodeHandle(viewRef.current)
            if id == -1 {
              Promise.resolve(
                {status: "failed", message: "Widget not ready"}: NativeHyperswitchSdk.paymentResult,
              )
            } else {
              Promise.make((resolve, _) => {
                NativeHyperswitchSdk.confirmPayment(id, (result: NativeHyperswitchSdk.paymentResult) => {
                  resolve({status: result.status, message: result.message}: NativeHyperswitchSdk.paymentResult)
                })
              })
            }
          }
        },
      }
    },
    [viewId],
  )

  let onPaymentResultInternal = (event: NativeModuleTypes.nativeEvent) => {
    onPaymentResult(event.nativeEvent.result->Option.getOr("")->parse)
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
        ?options
        ?style
      />
    | None => React.null
    }
  }
})
