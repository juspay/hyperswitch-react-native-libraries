@genType
type paymentResult = {
  paymentResult: string,
  error: string,
}
@genType.as("widgetType")
type widgetType = PAYMENT_SHEET | GOOGLE_PAY | CARD | BUTTON_SHEET | EXPRESS_CHECKOUT

@genType.genType.as("paymentWidgetProps")
type paymentWidgetProps = {
  widgetId?: string,
  widgetType?: widgetType,
  clientSecret?: string,
  options?: PaymentSheetConfiguration.options,
  onPaymentResult?: paymentResult => unit,
   style?: ReactNative.Style.style,
}

@genType
type nativePaymentWidgetType = {
  ref?: ReactNative.Ref.valueRef<unit>,
  widgetId?: string, // sessionId
  clientSecret?: string,
  widgetType?: widgetType,
  options?: string, // apperance and client secret can be passed as options in JSON string format
  onPaymentResult?: paymentResult => unit, // callback to receive payment result from native code
  style?: ReactNative.Style.style, // style for the view including min-height
}
