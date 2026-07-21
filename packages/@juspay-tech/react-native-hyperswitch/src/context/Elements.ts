import type {
  HyperswitchConfiguration,
  PaymentElementHandle,
  PaymentSessionConfiguration,
} from '../types/definitions';
import { buildPresentPaymentSheetPayload } from '../utils/LaunchOptions';
import {
  presentPaymentSheetWithPayload,
  updateIntent,
} from '../context/PaymentSession';
import type { PaymentResult } from '../types/paymentresult';
import type { CustomerSavedPaymentMethodsSession } from '../types/savedPaymentMethods';

import { getCustomerSavedPaymentMethods } from './SavedPaymentMethods';
import { Elements } from '../types/elements';

type ElementsNativeActions = Pick<
  Elements,
  | 'confirmPayment'
  | 'presentPaymentSheet'
  | 'getCustomerSavedPaymentMethods'
  | 'updateIntent'
>;

export function createElementsNativeActions(
  hyperswitchConfig: HyperswitchConfiguration,
  paymentSessionConfig: PaymentSessionConfiguration
): ElementsNativeActions {
  return {
    async presentPaymentSheet(
      configuration?: Record<string, unknown>
    ): Promise<PaymentResult> {
      const payload = buildPresentPaymentSheetPayload(
        hyperswitchConfig,
        paymentSessionConfig,
        configuration
      );
      return presentPaymentSheetWithPayload(payload);
    },

    async confirmPayment(
      paymentElementRef: { current: PaymentElementHandle | null } | string,
      _confirmOptions?: { confirmParams?: Record<string, any> }
    ): Promise<any> {
      //   if (typeof paymentElementRef === 'string') {
      //     const result = await widgetConfirm(paymentElementRef);
      //     return {
      //       type: mapStatus(result.status),
      //       message: result.message,
      //     };
      //   }
      //   const ref = paymentElementRef.current;
      //   if (!ref) {
      //     throw new Error('PaymentElement reference is not mounted');
      //   }
      //   return ref.confirmPayment(_confirmOptions);
    },

    async getCustomerSavedPaymentMethods(
      configuration?: Record<string, unknown>
    ): Promise<CustomerSavedPaymentMethodsSession> {
      return getCustomerSavedPaymentMethods(
        hyperswitchConfig,
        paymentSessionConfig,
        configuration
      );
    },

    updateIntent: updateIntent,
  };
}

export function createElements(
  hyperswitchConfig: HyperswitchConfiguration,
  paymentSessionConfig: PaymentSessionConfiguration
): Elements {
  return {
    ...createElementsNativeActions(hyperswitchConfig, paymentSessionConfig),
  };
}
