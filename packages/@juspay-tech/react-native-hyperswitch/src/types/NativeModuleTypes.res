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
}

@genType
type nativePaymentWidgetType = {
  widgetId?: string,
  widgetType?: widgetType,
  clientSecret?: string,
  options?: string,
  onPaymentResult?: paymentResult => unit,
}