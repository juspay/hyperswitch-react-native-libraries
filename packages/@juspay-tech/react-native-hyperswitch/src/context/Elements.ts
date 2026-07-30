import type {
  ElementType,
  HyperswitchConfiguration,
  PaymentElementHandle,
  PaymentSessionConfiguration,
} from '../types/definitions';
import { buildPresentPaymentSheetPayload } from '../utils/LaunchOptions';
import {
  mapNativeResponseToPaymentResult,
  presentPaymentSheetWithPayload,
  updateIntent,
} from '../context/PaymentSession';
import type { PaymentResult } from '../types/paymentresult';
import type { CustomerSavedPaymentMethodsSession } from '../types/savedPaymentMethods';

import { getCustomerSavedPaymentMethods } from './SavedPaymentMethods';
import { Elements } from '../types/elements';
import { confirmPayment as confirmWidgetPayment } from './WidgetRegistry';
import { PaymentSheetConfiguration } from '..';

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
      configuration?: PaymentSheetConfiguration
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
      confirmOptions?: { confirmParams?: Record<string, any> }
    ): Promise<PaymentResult> {
      if (typeof paymentElementRef === 'string') {
        const result = await confirmWidgetPayment(paymentElementRef);
        return mapNativeResponseToPaymentResult(result);
      }

      const ref = paymentElementRef.current;
      if (!ref) {
        throw new Error('PaymentElement reference is not mounted');
      }
      return ref.confirmPayment(confirmOptions);
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
    hyperswitchConfig,
    ...createElementsNativeActions(hyperswitchConfig, paymentSessionConfig),
  };
}
