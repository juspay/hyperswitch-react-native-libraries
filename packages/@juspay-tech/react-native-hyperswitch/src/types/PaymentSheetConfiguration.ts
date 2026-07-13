export type localeTypes =
  | 'En'
  | 'He'
  | 'Fr'
  | 'En_GB'
  | 'Ar'
  | 'Ja'
  | 'De'
  | 'Fr_BE'
  | 'Es'
  | 'Ca'
  | 'Pt'
  | 'It'
  | 'Pl'
  | 'Nl'
  | 'NI_BE'
  | 'Sv'
  | 'Ru'
  | 'Lt'
  | 'Cs'
  | 'Sk'
  | 'Ls'
  | 'Cy'
  | 'El'
  | 'Et'
  | 'Fi'
  | 'Nb'
  | 'Bs'
  | 'Da'
  | 'Ms'
  | 'Tr_CY';

export type placeholder = {
  cardNumber?: string;
  expiryDate?: string;
  cvv?: string;
};

export type address = {
  first_name?: string;
  last_name?: string;
  city?: string;
  country?: string;
  line1?: string;
  line2?: string;
  zip?: string;
  state?: string;
};

export type phone = {
  number?: string;
  country_code?: string;
};

export type addressDetails = {
  address?: address;
  email?: string;
  phone?: phone;
};

export type customerConfiguration = {
  id?: string;
  ephemeralKeySecret?: string;
};

export type colors = {
  primary?: string;
  background?: string;
  componentBackground?: string;
  componentBorder?: string;
  componentDivider?: string;
  componentText?: string;
  primaryText?: string;
  secondaryText?: string;
  placeholderText?: string;
  icon?: string;
  error?: string;
  loaderBackground?: string;
  loaderForeground?: string;
};

export type colorType = {
  light?: colors;
  dark?: colors;
};

export type offsetType = {
  x?: number;
  y?: number;
};

export type shadowConfig = {
  color?: string;
  opacity?: number;
  blurRadius?: number;
  offset?: offsetType;
  intensity?: number;
};

export type shapes = {
  borderRadius?: number;
  borderWidth?: number;
  shadow?: shadowConfig;
};

export type font = {
  family?: string;
  scale?: number;
};

export type primaryButtonColor = {
  background?: string;
  text?: string;
  border?: string;
};

export type primaryButtonColorType = {
  light?: primaryButtonColor;
  dark?: primaryButtonColor;
};

export type primaryButton = {
  shapes?: shapes;
  primaryButtonColor?: primaryButtonColorType;
};

export type googlePayButtonType =
  | 'BUY'
  | 'BOOK'
  | 'CHECKOUT'
  | 'DONATE'
  | 'ORDER'
  | 'PAY'
  | 'SUBSCRIBE'
  | 'PLAIN';

export type googlePayButtonStyle = 'light' | 'dark';

export type googlePayThemeBaseStyle = {
  light?: googlePayButtonStyle;
  dark?: googlePayButtonStyle;
};

export type googlePayConfiguration = {
  buttonType?: googlePayButtonType;
  buttonStyle?: googlePayThemeBaseStyle;
};

export type applePayButtonType =
  | 'buy'
  | 'setUp'
  | 'inStore'
  | 'donate'
  | 'checkout'
  | 'book'
  | 'subscribe'
  | 'plain';

export type applePayButtonStyle = 'white' | 'whiteOutline' | 'black';

export type applePayThemeBaseStyle = {
  light?: applePayButtonStyle;
  dark?: applePayButtonStyle;
};

export type applePayConfiguration = {
  buttonType?: applePayButtonType;
  buttonStyle?: applePayThemeBaseStyle;
};

export type themeType =
  | 'Default'
  | 'Light'
  | 'Dark'
  | 'Minimal'
  | 'FlatMinimal';

export type layoutType = 'tabs' | 'accordion' | 'spacedAccordion';

export type appearance = {
  locale?: localeTypes;
  colors?: colorType;
  shapes?: shapes;
  font?: font;
  primaryButton?: primaryButton;
  googlePay?: googlePayConfiguration;
  applePay?: applePayConfiguration;
  theme?: themeType;
  layout?: layoutType;
};

export type subscriptionEvent =
  | 'PAYMENT_METHOD_INFO_CARD'
  | 'PAYMENT_METHOD_STATUS'
  | 'FORM_STATUS'
  | 'PAYMENT_METHOD_INFO_ADDRESS'
  | 'CVC_STATUS';

export type cvcAppearance = {
  colors?: colorType;
  shapes?: shapes;
  font?: font;
};

export type cvcWidgetOptions = {
  sdkAuthorization?: string;
  appearance?: cvcAppearance;
  placeholder?: string;
};

export type options = {
  sdkAuthorization: string;
  allowsDelayedPaymentMethods?: boolean;
  appearance?: appearance;
  shippingDetails?: addressDetails;
  primaryButtonLabel?: string;
  paymentSheetHeaderText?: string;
  savedPaymentScreenHeaderText?: string;
  merchantDisplayName?: string;
  defaultBillingDetails?: addressDetails;
  primaryButtonColor?: string;
  allowsPaymentMethodsRequiringShippingAddress?: boolean;
  displaySavedPaymentMethodsCheckbox?: boolean;
  displaySavedPaymentMethods?: boolean;
  placeholder?: placeholder;
  defaultView?: boolean;
  disableBranding?: boolean;
  netceteraSDKApiKey?: string;
  displayDefaultSavedPaymentIcon?: boolean;
  enablePartialLoading?: boolean;
  customer?: customerConfiguration;
  paymentSheetHeaderLabel?: string;
  savedPaymentSheetHeaderLabel?: string;
  subscribedEvents?: subscriptionEvent[];
  hideConfirmButton?: boolean;
};
