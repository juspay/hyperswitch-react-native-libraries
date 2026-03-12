@genType.as("paymentResultEvent")
type paymentResult = {
  status?: string,
  errorMessage?: string,
}

@genType
type cardInfo = {
  bin: string,
  brand: string,
  last4: string,
  country: string,
  fundingType: string,
  isComplete: bool,
}

type formStatusValue =
  | Empty
  | Filling
  | Complete

@genType
type paymentMethodStatusEvent = {
  paymentMethod: string,
  paymentMethodType: string,
  isSavedPaymentMethod: bool,
}

@genType
type formStatusEvent = {
  status: string, // "EMPTY" | "FILLING" | "COMPLETE"
  paymentMethod: option<string>,
}

@genType
type paymentMethodInfoAddress = {
  city: option<string>,
  country: option<string>,
  line1: option<string>,
  line2: option<string>,
  postalCode: option<string>,
  state: option<string>,
}

type paymentEventPayload =
  | CardInfoPayload(cardInfo)
  | PaymentMethodStatusPayload(paymentMethodStatusEvent)
  | FormStatusPayload(formStatusEvent)
  | AddressInfoPayload(paymentMethodInfoAddress)

@genType
type paymentEventResult = {
  eventName: string,
  payload: string,
}

type paymentEventNative = {nativeEvent: paymentEventResult}

type widgetType = PAYMENT_SHEET | GOOGLE_PAY | CARD | BUTTON_SHEET | EXPRESS_CHECKOUT

type paymentResultInternal = {result?: string}

type nativeEvent = {nativeEvent: paymentResultInternal}

type nativePaymentWidgetType = {
  ref?: ReactNative.Ref.valueRef<unit>,
  widgetId: string, // sessionId
  widgetType?: string,
  clientSecret?: string,
  sdkAuthorisation?: string,
  options?: PaymentSheetConfiguration.options, // apperance and client secret can be passed as options in JSON string format
  onPaymentResult?: nativeEvent => unit, // callback to receive payment result from native code
  style?: ReactNative.Style.t, // style for the view including min-height
  onPaymentEvent?: paymentEventNative => unit,
}
