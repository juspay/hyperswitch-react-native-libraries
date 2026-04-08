type event
type subscription

@module("react-native") external deviceEventEmitter: 'a = "DeviceEventEmitter"
@send external addListener: ('a, string, event => unit) => subscription = "addListener"

let paymentSheetCallback: ref<option<event => unit>> = ref(None)
let eventSubscription: ref<option<subscription>> = ref(None)

let registerCallback = (callback: event => unit): unit => {
  switch eventSubscription.contents {
  | None =>
    let subscription = deviceEventEmitter->addListener("onPaymentSheetEvent", event => {
      switch paymentSheetCallback.contents {
      | Some(cb) => cb(event)
      | None => ()
      }
    })
    eventSubscription := Some(subscription)
  | Some(_) => ()
  }
  paymentSheetCallback := Some(callback)
}

let unregisterCallback = (): unit => {
  paymentSheetCallback := None
}
