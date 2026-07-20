import { NativeModules } from 'react-native';
import type { options as PaymentSheetConfigurationOptions } from '../types/PaymentSheetConfiguration';

export type initPaymentSessionParams = { sdkAuthorization?: string };

export type initPaymentSessionResult = { error?: string };

export type presentPaymentSheetParams = PaymentSheetConfigurationOptions;

export type presentPaymentSheet = (
  params: presentPaymentSheetParams
) => Promise<string>;

export type paymentResult = {
  status: string;
  message: string;
  error?: string;
  type?: string;
};

export type error = { code?: string; message?: string };

export type presentPaymentSheetResult = {
  error?: error;
  paymentResult?: paymentResult;
};

export type cardDetails = {
  expiry_year: string;
  card_issuer: string;
  expiry_month: string;
  nick_name: string;
  last4_digits: string;
  card_holder_name: string;
  card_network: string;
  card_isin: string;
  scheme: string;
  issuer_country: string;
  card_type: string;
  saved_to_locker: boolean;
};

export type savedPaymentMethod = {
  card?: cardDetails;
  requires_cvv: boolean;
  payment_method_str: string;
  payment_method_type: string;
  payment_experience: string[];
  default_payment_method_set: boolean;
  recurring_enabled: boolean;
  payment_method_issuer: string;
  last_used_at: string;
  installment_payment_enabled: boolean;
  payment_method_id: string;
  customer_id: string;
  payment_token: string;
  created: string;
};

type ConfirmPaymentCallback = (result: paymentResult) => void;
type ConfirmPaymentCVCCallback = (result: paymentResult) => void;

type NativePaymentWidget = {
  confirmPayment: (viewId: number, callback: ConfirmPaymentCallback) => void;
  updateIntentInitForWidget: (
    viewId: number,
    callback: ConfirmPaymentCallback
  ) => void;
  updateIntentCompleteForWidget: (
    viewId: number,
    sdkAuthorization: string,
    callback: ConfirmPaymentCallback
  ) => void;
  confirmPaymentCVC: (
    viewId: number,
    paymentToken: string,
    paymentMethodId: string,
    callback: ConfirmPaymentCVCCallback
  ) => void;
};

const nativePaymentWidgetDict = NativeModules.NativePaymentWidget ?? {};

function getFunctionFromModule<T>(key: string, defaultFn: T): T {
  const fn = (nativePaymentWidgetDict as Record<string, unknown>)[key];
  return typeof fn === 'function' ? (fn as T) : defaultFn;
}

const nativePaymentWidget: NativePaymentWidget = {
  confirmPayment: getFunctionFromModule(
    'confirmPayment',
    (_viewId: number, _callback: ConfirmPaymentCallback) => {}
  ),
  updateIntentInitForWidget: getFunctionFromModule(
    'updateIntentInitForWidget',
    (_viewId: number, _callback: ConfirmPaymentCallback) => {}
  ),
  updateIntentCompleteForWidget: getFunctionFromModule(
    'updateIntentCompleteForWidget',
    (
      _viewId: number,
      _sdkAuthorization: string,
      _callback: ConfirmPaymentCallback
    ) => {}
  ),
  confirmPaymentCVC: getFunctionFromModule(
    'confirmPaymentCVC',
    (
      _viewId: number,
      _paymentToken: string,
      _paymentMethodId: string,
      _callback: ConfirmPaymentCVCCallback
    ) => {}
  ),
};

export function confirmPayment(
  viewId: number,
  callback: ConfirmPaymentCallback
): void {
  nativePaymentWidget.confirmPayment(viewId, callback);
}

export function updateIntentInitForWidget(
  viewId: number,
  callback: ConfirmPaymentCallback
): void {
  nativePaymentWidget.updateIntentInitForWidget(viewId, callback);
}

export function updateIntentCompleteForWidget(
  viewId: number,
  sdkAuthorization: string,
  callback: ConfirmPaymentCallback
): void {
  nativePaymentWidget.updateIntentCompleteForWidget(
    viewId,
    sdkAuthorization,
    callback
  );
}

export function confirmPaymentCVC(
  viewId: number,
  paymentToken: string,
  paymentMethodId: string,
  callback: ConfirmPaymentCVCCallback
): void {
  nativePaymentWidget.confirmPaymentCVC(
    viewId,
    paymentToken,
    paymentMethodId,
    callback
  );
}
