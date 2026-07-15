import { ColorType, Font, Shapes } from './AppearanceTypes';

export type SubscriptionEvent =
  | 'PAYMENT_METHOD_INFO_CARD'
  | 'PAYMENT_METHOD_STATUS'
  | 'FORM_STATUS'
  | 'PAYMENT_METHOD_INFO_BILLING_ADDRESS'
  | 'CVC_STATUS';

export type Theme =
  | 'Default'
  | 'Light'
  | 'Dark'
  | 'Minimal'
  | 'FlatMinimal'
  | 'Brutal'
  | 'Glass'
  | 'Skeu'
  | 'Clay'
  | 'Charcoal'
  | 'Soft';
export type LayoutType = 'tabs' | 'accordion';
export type PaymentMethodsArrangement = 'grid' | 'auto';
export type RedirectionInfo = 'hidden' | 'shown';
export type CvcIconDisplay = 'shown' | 'hidden';

export interface GroupingBehavior {
  displayInSeparateScreen?: boolean;
  displayInSeparateSection?: boolean;
  groupByPaymentMethods?: boolean;
}

export interface SavedPaymentMethodsConfiguration {
  hiddenPaymentMethods?: string[];
}

export interface SavedMethodCustomization {
  defaultCollapsed?: boolean;
  hideCardExpiry?: boolean;
  hideCVCError?: boolean;
  cvcIcon?: CvcIconDisplay;
  groupingBehavior?: GroupingBehavior;
  hiddenPaymentMethods?: string[];
}

export type CardBrandIconDisplay = 'hidden' | 'animated' | 'standard' | 'hideGeneric';

export interface PaymentMethodLayout {
  type?: LayoutType;
  showOneClickWalletsOnTop?: boolean;
  paymentMethodsArrangementForTabs?: PaymentMethodsArrangement;
  defaultCollapsed?: boolean;
  radios?: boolean;
  spacedAccordionItems?: boolean;
  maxAccordionItems?: number;
  cvcIcon?: CvcIconDisplay;
  cardBrandIcon?: CardBrandIconDisplay;
  showCheckedIconForSelection?: boolean;
  savedMethodCustomization?: SavedMethodCustomization;
}

export interface PrimaryButtonColors {
  background?: string;
  text?: string;
  border?: string;
}

export interface PrimaryButtonColorType {
  light?: PrimaryButtonColors;
  dark?: PrimaryButtonColors;
}

export interface PrimaryButton {
  shapes?: Shapes;
  colors?: PrimaryButtonColorType;
  height?: number;
}

export type GooglePayButtonType = 'BUY' | 'BOOK' | 'CHECKOUT' | 'DONATE' | 'ORDER' | 'PAY' | 'SUBSCRIBE' | 'PLAIN';
export type GooglePayButtonStyle = 'light' | 'dark';

export interface GooglePayThemeBaseStyle {
  light?: GooglePayButtonStyle;
  dark?: GooglePayButtonStyle;
}

export interface GooglePayConfiguration {
  visibility?: 'hidden' | 'shown';
  buttonType?: GooglePayButtonType;
  buttonStyle?: GooglePayThemeBaseStyle;
}

export type ApplePayButtonType = 'buy' | 'setUp' | 'inStore' | 'donate' | 'checkout' | 'book' | 'subscribe' | 'plain';
export type ApplePayButtonStyle = 'white' | 'whiteOutline' | 'black';

export interface ApplePayThemeBaseStyle {
  light?: ApplePayButtonStyle;
  dark?: ApplePayButtonStyle;
}

export interface ApplePayConfiguration {
  visibility?: 'hidden' | 'shown';
  buttonType?: ApplePayButtonType;
  buttonStyle?: ApplePayThemeBaseStyle;
}

export type PayPalButtonType = 'paypal' | 'checkout' | 'buynow' | 'pay';
export type PayPalButtonStyle = 'gold' | 'blue' | 'white' | 'black' | 'silver';

export interface PayPalThemeBaseStyle {
  light?: PayPalButtonStyle;
  dark?: PayPalButtonStyle;
}

export interface PayPalConfiguration {
  visibility?: 'hidden' | 'shown';
  buttonType?: PayPalButtonType;
  buttonStyle?: PayPalThemeBaseStyle;
}

export interface WalletButtonsConfiguration {
  googlePay?: GooglePayConfiguration;
  applePay?: ApplePayConfiguration;
  payPal?: PayPalConfiguration;
}

export interface LogoColors {
  backgroundColor?: string;
  selected?: string;
  unselected?: string;
}

export interface LogoColorType {
  light?: LogoColors;
  dark?: LogoColors;
}

export interface CheckedIconColors {
  color?: string;
  stroke?: string;
}

export interface CheckedIconColorType {
  light?: CheckedIconColors;
  dark?: CheckedIconColors;
}

export interface CheckedIconForSelection {
  colors?: CheckedIconColorType;
  size?: number;
  bottom?: number;
  right?: number;
}

export interface LogoCustomization {
  borderRadius?: number;
  colors?: LogoColorType;
  checkedIconForSelection?: CheckedIconForSelection;
}

export interface Appearance {
  theme?: Theme;
  colors?: ColorType;
  shapes?: Shapes;
  font?: Font;
  primaryButton?: PrimaryButton;
  logo?: LogoCustomization;
}

export interface Placeholder {
  cardNumber?: string;
  expiryDate?: string;
  cvv?: string;
}

export interface Address {
  first_name?: string;
  last_name?: string;
  city?: string;
  country?: string;
  line1?: string;
  line2?: string;
  line3?: string;
  postalCode?: string;
  state?: string;
}

export interface Phone {
  number?: string;
  code?: string;
}

export interface AddressDetails {
  address?: Address;
  email?: string;
  phone?: Phone;
}

export interface CustomerConfiguration {
  id?: string;
  ephemeralKeySecret?: string;
}

export interface PaymentMethodConfig {
  paymentMethod: string;
  message?: string;
}

type locale =
  | 'en'
  | 'he'
  | 'fr'
  | 'en-GB'
  | 'ar'
  | 'ja'
  | 'de'
  | 'fr-BE'
  | 'es'
  | 'ca'
  | 'pt'
  | 'it'
  | 'pl'
  | 'nl'
  | 'nI-BE'
  | 'sv'
  | 'ru'
  | 'lt'
  | 'cs'
  | 'sk'
  | 'ls'
  | 'cy'
  | 'el'
  | 'et'
  | 'fi'
  | 'nb'
  | 'bs'
  | 'da'
  | 'ms'
  | 'tr-CY';

export interface PaymentSheetOptions {
  publishableKey?: string;
  sdkAuthorization?: string;
  allowsDelayedPaymentMethods?: boolean;
  appearance?: Appearance;
  shippingDetails?: AddressDetails;
  primaryButtonLabel?: string;
  paymentSheetHeaderText?: string;
  savedPaymentScreenHeaderText?: string;
  merchantDisplayName?: string;
  billingDetails?: AddressDetails;
  primaryButtonColor?: string;
  allowsPaymentMethodsRequiringShippingAddress?: boolean;
  displaySavedPaymentMethodsCheckbox?: boolean;
  displaySavedPaymentMethods?: boolean;
  displayPayButton?: boolean;
  placeholder?: Placeholder;
  defaultView?: boolean;
  disableBranding?: boolean;
  netceteraSDKApiKey?: string;
  displayDefaultSavedPaymentIcon?: boolean;
  enablePartialLoading?: boolean;
  customer?: CustomerConfiguration;
  paymentSheetHeaderLabel?: string;
  savedPaymentSheetHeaderLabel?: string;
  subscribedEvents?: SubscriptionEvent[];
  hideConfirmButton?: boolean;
  locale?: locale;
  redirectionInfo?: RedirectionInfo;
  stickyPayButton?: boolean;
  paymentMethodLayout?: PaymentMethodLayout;
  walletButtonsConfiguration?: WalletButtonsConfiguration;
  paymentMethodsConfig?: PaymentMethodConfig[];
  paymentMethodOrder?: string[];
  preloadCardElement?: boolean;
  alwaysSendCustomerAcceptance?: boolean;
  opensCardScannerAutomatically?: boolean;
  splitCardFields?: boolean;
}
