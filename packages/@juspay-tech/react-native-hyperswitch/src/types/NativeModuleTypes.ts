import type { ViewStyle } from 'react-native';
import type { PaymentSheetConfiguration } from './PaymentSheetConfiguration';
import {
  HyperswitchConfiguration,
  PaymentSessionConfiguration,
} from './definitions';

export type paymentResult = {
  status?: string;
  errorMessage?: string;
};

export type paymentResultEvent = paymentResult;

export type cardInfo = {
  bin: string | undefined;
  last4: string | undefined;
  brand: string | undefined;
  expiryMonth: string | undefined;
  expiryYear: string | undefined;
  formattedExpiry: string | undefined;
  isCardNumberComplete: boolean;
  isCvcComplete: boolean;
  isExpiryComplete: boolean;
  isCardNumberValid: boolean;
  isExpiryValid: boolean;
};

export type paymentMethodStatusEvent = {
  paymentMethod: string;
  paymentMethodType: string;
  isSavedPaymentMethod: boolean;
  isOneClickWallet: boolean;
};

export type formStatusEvent = { status: string };

export type paymentMethodInfoAddress = {
  country: string;
  state: string;
  postalCode: string;
};

export type cvcStatusEvent = {
  isCvcFocused: boolean;
  isCvcBlur: boolean;
  isCvcEmpty: boolean;
};

export type paymentEventResult = {
  eventName: string;
  payload: Record<string, unknown>;
};

export type paymentEventNative = { nativeEvent: paymentEventResult };

export type paymentResultInternal = { result?: string };

export type nativeEvent = { nativeEvent: paymentResultInternal };

export type nativePaymentWidgetType = {
  ref?: React.Ref<unknown>;
  widgetType?: string;
  sdkAuthorization?: string;
  options?: {
    hyperswitchConfig?: HyperswitchConfiguration;
    paymentSessionConfig?: PaymentSessionConfiguration;
    configuration?: PaymentSheetConfiguration;
  };
  onPaymentResult?: (event: nativeEvent) => void;
  style?: ViewStyle;
  onPaymentEvent?: (event: paymentEventNative) => void;
};
