@module("react-native") @scope("UIManager")
external dispatchViewManagerCommand: (
  ~viewId: int,
  ~commandId: int,
  ~commandArgs: array<int>,
) => unit = "dispatchViewManagerCommand"

@module("react-native")
external findNodeHandle: Js.Nullable.t<unit> => int = "findNodeHandle"

@scope("JSON") @val external parse: string => NativeModuleTypes.paymentResult = "parse"

type commands = {createView: string}

type viewManagerConfig = {\"Commands": commands}

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

type paymentWidgetRef = {confirmPayment: unit => promise<HyperTypes.nativeResponse>}

type pendingConfirmation = {
  resolve: HyperTypes.nativeResponse => unit,
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
          let id = findNodeHandle(viewRef.current)
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
        confirmPayment: (): promise<HyperTypes.nativeResponse> => {
          switch Nullable.toOption(viewRef.current) {
          | None =>
            Promise.resolve(
              ({status: HyperTypes.Failed, message: "Widget not ready"}: HyperTypes.nativeResponse),
            )
          | Some(_) =>
            let id = findNodeHandle(viewRef.current)
            if id == -1 {
              Promise.resolve(
                ({status: HyperTypes.Failed, message: "Widget not ready"}: HyperTypes.nativeResponse),
              )
            } else {
              Promise.make((resolve, _) => {
                NativeHyperswitchSdk.nativeHyperswitchSdk.confirmPayment(id, (result: NativeHyperswitchSdk.paymentResult) => {
                  let status = switch result.status {
                  | "succeeded" => HyperTypes.Succeeded
                  | "failed" => HyperTypes.Failed
                  | "cancelled" => HyperTypes.Cancelled
                  | _ => HyperTypes.Error
                  }
                  resolve(({status, message: result.message}: HyperTypes.nativeResponse))
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
