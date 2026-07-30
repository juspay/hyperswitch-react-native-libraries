import { PaymentResult } from '../paymentresult';
import type {
  HyperswitchConfiguration,
  PaymentElementHandle,
  PaymentSessionConfiguration,
} from '../definitions';
import { CustomerSavedPaymentMethodsSession } from '../savedPaymentMethods';
import { PaymentSheetConfiguration } from '../PaymentSheetConfiguration';

export interface Elements {
  hyperswitchConfig: HyperswitchConfiguration;
  confirmPayment(
    paymentElementRef: { current: PaymentElementHandle | null } | string,
    options?: { confirmParams?: Record<string, any> }
  ): Promise<PaymentResult>;
  presentPaymentSheet(
    configuration?: PaymentSheetConfiguration
  ): Promise<PaymentResult>;
  updateIntent(
    intentResolver: () => Promise<PaymentSessionConfiguration>
  ): Promise<void>;
  getCustomerSavedPaymentMethods(
    options?: any
  ): Promise<CustomerSavedPaymentMethodsSession>;
}

export interface ElementsActions {
  confirmPayment: (
    paymentElementRef: { current: PaymentElementHandle | null } | string,
    options?: { confirmParams?: Record<string, any> }
  ) => Promise<PaymentResult>;
  updateIntent: (
    intentResolver: () => Promise<PaymentSessionConfiguration>
  ) => Promise<void>;
  getCustomerSavedPaymentMethods(): Promise<CustomerSavedPaymentMethodsSession>;
}
