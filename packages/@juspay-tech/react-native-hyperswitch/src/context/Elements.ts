import type {
  HyperswitchConfiguration,
  PaymentElementHandle,
  ElementType,
  PaymentSessionConfiguration,
} from '../types/definitions';
import { buildPresentPaymentSheetPayload } from '../utils/LaunchOptions';
import {
  presentPaymentSheetWithPayload,
  updateIntent,
} from '../context/PaymentSession';
import type { PaymentResult } from '../types/paymentresult';
import type { CustomerSavedPaymentMethodsSession } from '../types/savedPaymentMethods';

import { createPaymentElement } from '../views/PaymentElement';
import { getCustomerSavedPaymentMethods } from './SavedPaymentMethods';
import { Elements } from '../types/elements';
import { createCvcWidget } from '../views/CVCElement';

type ElementsNativeActions = Pick<
  Elements,
  | 'confirmPayment'
  | 'presentPaymentSheet'
  | 'getCustomerSavedPaymentMethods'
  | 'updateIntent'
>;

const SUPPORTED_ELEMENT_TYPES: readonly ElementType[] = [
  'paymentElement',
  'cvcWidget',
];


function isElementType(type: string): type is ElementType {
  return SUPPORTED_ELEMENT_TYPES.includes(type as ElementType);
}

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
    create(opts: { type: string; id?: string; options?: any }): any {
      if (!isElementType(opts.type)) {
        throw new Error(
          `[react-native-hyperswitch] elements.create('${opts.type}') is not supported. ` +
            `Supported types are 'paymentElement' and 'cvcWidget'.`
        );
      }

      switch (opts.type) {
        case 'paymentElement':
          return createPaymentElement({
            id: opts.id,
            options: opts.options,
            hyperswitchConfig,
            paymentSessionConfig,
          });
        case 'cvcWidget':
          return createCvcWidget({
            id: opts.id,
            options: opts.options,
            hyperswitchConfig,
            paymentSessionConfig,
          });
      }
    },

    ...createElementsNativeActions(hyperswitchConfig, paymentSessionConfig),
  };
}
