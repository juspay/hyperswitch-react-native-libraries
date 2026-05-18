import { NativeModules } from 'react-native';

const { HyperswitchPaypal } = NativeModules;

export const isAvailable = !!HyperswitchPaypal;

export type PayPalResult = {
  status: string;
  orderId?: string;
  payerId?: string;
  error_message?: string;
};

export type PayPalRequest = {
  clientId: string;
  environment?: 'SANDBOX' | 'PRODUCTION';
  orderId: string;
  returnUrl?: string;
  fundingSource?: 'PAYPAL' | 'PAY_LATER' | 'PAYPAL_CREDIT';
};

export function launchPayPal(
  requestObj: string,
  callback: (result: PayPalResult) => void
): void {

  if (!HyperswitchPaypal) {
    callback({ status: 'failed', error_message: 'PayPal module not available' });
    return;
  }
  return HyperswitchPaypal.launchPayPal(requestObj, callback);
}
