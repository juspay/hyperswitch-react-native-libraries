@genType.as("paymentResultEvent")
type paymentResult = {
  status?: string,
  errorMessage?: string,
}

@genType
type cardInfo = {
  bin: option<string>,
  last4: option<string>,
  brand: option<string>,
  expiryMonth: option<string>,
  expiryYear: option<string>,
  formattedExpiry: option<string>,
  isCardNumberComplete: bool,
  isCvcComplete: bool,
  isExpiryComplete: bool,
  isCardNumberValid: bool,
  isExpiryValid: bool,
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
  isOneClickWallet: bool,
}

@genType
type formStatusEvent = {status: string}

@genType
type paymentMethodInfoAddress = {
  country: string,
  state: string,
  postalCode: string,
}

@genType
type cvcStatusEvent = {
  isCvcFocused: bool,
  isCvcBlur: bool,
  isCvcEmpty: bool,
  // isCvcComplete: bool,
}

type paymentEventPayload =
  | CardInfoPayload(cardInfo)
  | PaymentMethodStatusPayload(paymentMethodStatusEvent)
  | FormStatusPayload(formStatusEvent)
  | AddressInfoPayload(paymentMethodInfoAddress)
  | CvcStatusPayload(cvcStatusEvent)

@genType
type paymentEventResult = {
  eventName: string,
  payload: JSON.t,
}

type paymentEventNative = {nativeEvent: paymentEventResult}

type widgetType = PAYMENT_SHEET | GOOGLE_PAY | CARD | BUTTON_SHEET | EXPRESS_CHECKOUT | CVC_WIDGET

type paymentResultInternal = {result?: string}

type nativeEvent = {nativeEvent: paymentResultInternal}

@genType
type nativePaymentWidgetType = {
  ref?: ReactNative.Ref.valueRef<unit>,
  widgetId: string, // sessionId
  widgetType?: string,
  sdkAuthorization: string,
  options?: PaymentSheetConfiguration.options, // appearance and other configs can be passed as options in JSON string format
  onPaymentResult?: nativeEvent => unit, // callback to receive payment result from native code
  style?: ReactNative.Style.t, // style for the view including min-height
  onPaymentEvent?: paymentEventNative => unit,
}
