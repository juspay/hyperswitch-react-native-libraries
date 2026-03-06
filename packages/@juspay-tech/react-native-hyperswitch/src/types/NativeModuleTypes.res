@genType.as("paymentResultEvent")
type paymentResult = {
  status?: string,
  errorMessage?: string,
}

type widgetType = PAYMENT_SHEET | GOOGLE_PAY | CARD | BUTTON_SHEET | EXPRESS_CHECKOUT

type paymentResultInternal = {
  result?: string
}

type nativeEvent = {
  nativeEvent: paymentResultInternal,
}

type nativePaymentWidgetType = {
  ref?: ReactNative.Ref.valueRef<unit>,
  widgetId: string, // sessionId
  widgetType?: string,
  clientSecret?: string,
  sdkAuthorisation?: string,
  options?: PaymentSheetConfiguration.options, // apperance and client secret can be passed as options in JSON string format
  onPaymentResult?: nativeEvent => unit, // callback to receive payment result from native code
  style?: ReactNative.Style.t, // style for the view including min-height
}
