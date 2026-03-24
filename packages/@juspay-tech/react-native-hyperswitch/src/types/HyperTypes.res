// Options for HyperElements - payment session configuration
@genType
type hyperElementsOptions = {
  sdkAuthorisation?: string,
  clientSecret?: string,
}

// Widget-specific element options
@genType
type widgetElementOptions = {
  // Widget-specific options
}

// Configuration for PaymentWidget
@genType
type configuration = {
  elementOptions?: widgetElementOptions,
  appearance?: PaymentSheetConfiguration.appearance,
}
