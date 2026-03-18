import { NativeModules } from 'react-native';

console.log('PAYPAL_DEBUG [index.tsx]: Module loading...');

const { HyperswitchPaypal } = NativeModules;

console.log('PAYPAL_DEBUG [index.tsx]: NativeModules.HyperswitchPaypal exists =', !!HyperswitchPaypal);
console.log('PAYPAL_DEBUG [index.tsx]: All NativeModules keys =', Object.keys(NativeModules).join(', '));

export const isAvailable = !!HyperswitchPaypal;

console.log('PAYPAL_DEBUG [index.tsx]: isAvailable =', isAvailable);

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
  console.log('PAYPAL_DEBUG [index.tsx]: launchPayPal called with requestObj =', requestObj);
  if (!HyperswitchPaypal) {
    console.log('PAYPAL_DEBUG [index.tsx]: HyperswitchPaypal module is null, cannot launch');
    callback({ status: 'failed', error_message: 'PayPal module not available' });
    return;
  }
  console.log('PAYPAL_DEBUG [index.tsx]: Calling native HyperswitchPaypal.launchPayPal');
  return HyperswitchPaypal.launchPayPal(requestObj, callback);
}
