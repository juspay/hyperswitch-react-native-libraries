type localeTypes =
  | En
  | He
  | Fr
  | En_GB
  | Ar
  | Ja
  | De
  | Fr_BE
  | Es
  | Ca
  | Pt
  | It
  | Pl
  | Nl
  | NI_BE
  | Sv
  | Ru
  | Lt
  | Cs
  | Sk
  | Ls
  | Cy
  | El
  | Et
  | Fi
  | Nb
  | Bs
  | Da
  | Ms
  | Tr_CY

type fontFamilyTypes = DefaultIOS | DefaultAndroid | CustomFont(string) | DefaultWeb

type placeholder = {
  cardNumber?: string,
  expiryDate?: string,
  cvv?: string,
}

type address = {
  first_name?: string,
  last_name?: string,
  city?: string,
  country?: string,
  line1?: string,
  line2?: string,
  zip?: string,
  state?: string,
}

type phone = {
  number?: string,
  country_code?: string,
}

type addressDetails = {
  address?: address,
  email?: string,
  phone?: phone,
}

type customerConfiguration = {
  id?: string,
  ephemeralKeySecret?: string,
}

type colors = {
  primary?: string,
  background?: string,
  componentBackground?: string,
  componentBorder?: string,
  componentDivider?: string,
  componentText?: string,
  primaryText?: string,
  secondaryText?: string,
  placeholderText?: string,
  icon?: string,
  error?: string,
  loaderBackground?: string,
  loaderForeground?: string,
}

type colorType = {
  light?: colors,
  dark?: colors,
}

// IOS Specific
type offsetType = {
  x?: float,
  y?: float,
}
type shadowConfig = {
  color?: string,
  opacity?: float,
  blurRadius?: float,
  offset?: offsetType,
  intensity?: float,
}

type shapes = {
  borderRadius?: float,
  borderWidth?: float,
  shadow?: shadowConfig, // IOS Specific
}

type font = {
  family?: fontFamilyTypes,
  scale?: float,
  headingTextSizeAdjust?: float,
  subHeadingTextSizeAdjust?: float,
  placeholderTextSizeAdjust?: float,
  buttonTextSizeAdjust?: float,
  errorTextSizeAdjust?: float,
  linkTextSizeAdjust?: float,
  modalTextSizeAdjust?: float,
  cardTextSizeAdjust?: float,
}

type primaryButtonColor = {
  background?: string,
  text?: string,
  border?: string,
}
type primaryButtonColorType = {
  light?: primaryButtonColor, 
  dark?: primaryButtonColor
}

type primaryButton = {
  shapes?: shapes,
  primaryButtonColor?: primaryButtonColorType,
}

// ---- Wallet configuration types ----

type walletShowType =
  | @as("auto") Auto
  | @as("never") Never

type googlePayButtonType =
  | @as("BUY") BUY
  | @as("BOOK") BOOK
  | @as("CHECKOUT") CHECKOUT
  | @as("DONATE") DONATE
  | @as("ORDER") ORDER
  | @as("PAY") PAY
  | @as("SUBSCRIBE") SUBSCRIBE
  | @as("PLAIN") PLAIN

type applePayButtonType = [
  | #buy
  | #setUp
  | #inStore
  | #donate
  | #checkout
  | #book
  | #subscribe
  | #reload
  | #addMoney
  | #topUp
  | #rent
  | #order
  | #support
  | #tip
  | #contribute
  | #plain
]

type paypalButtonType =
  | @as("paypal") Paypal
  | @as("checkout") Checkout
  | @as("buynow") Buynow
  | @as("pay") Pay
  | @as("installment") Installment

type samsungPayButtonType = | @as("buy") Buy

type walletTheme =
  | @as("default") WalletDefault
  | @as("dark") WalletDark
  | @as("light") WalletLight
  | @as("outline") WalletOutline

type walletStyle = {
  applePayType?: applePayButtonType,
  googlePayType?: googlePayButtonType,
  paypalType?: paypalButtonType,
  samsungPayType?: samsungPayButtonType,
  theme?: walletTheme,
  height?: int,
  buttonRadius?: int,
}

type walletConfiguration = {
  applePay?: walletShowType,
  googlePay?: walletShowType,
  payPal?: walletShowType,
  klarna?: walletShowType,
  paze?: walletShowType,
  samsungPay?: walletShowType,
  style?: walletStyle,
}

type themeType =
  | Default
  | Light
  | Dark
  | Minimal
  | FlatMinimal

type layoutType = [#tabs | #accordion | #spacedAccordion]

type appearance = {
  locale?: localeTypes,
  colors?: colorType,
  shapes?: shapes,
  font?: font,
  primaryButton?: primaryButton,
  theme?: themeType,
  layout?: layoutType,
}

@genType
type options = {
  clientSecret?: string,
  sdkAuthorisation?: string,
  allowsDelayedPaymentMethods?: bool,
  appearance?: appearance,
  wallets?: walletConfiguration,
  shippingDetails?: addressDetails,
  primaryButtonLabel?: string,
  paymentSheetHeaderText?: string,
  savedPaymentScreenHeaderText?: string,
  merchantDisplayName?: string,
  defaultBillingDetails?: addressDetails,
  primaryButtonColor?: string,
  allowsPaymentMethodsRequiringShippingAddress?: bool,
  displaySavedPaymentMethodsCheckbox?: bool,
  displaySavedPaymentMethods?: bool,
  placeholder?: placeholder,
  defaultView?: bool,
  disableBranding?: bool,
  netceteraSDKApiKey?: string,
  displayDefaultSavedPaymentIcon?: bool,
  enablePartialLoading?: bool,
  customer?: customerConfiguration,
  paymentSheetHeaderLabel?: string,
  savedPaymentSheetHeaderLabel?: string,
}
