import { PaymentResult } from "../paymentresult";
import type {
  PaymentElementHandle,
  PaymentSessionConfiguration,
} from "../definitions";
import { CustomerSavedPaymentMethodsSession } from "../savedPaymentMethods";

export interface Elements {
  confirmPayment(
    paymentElementRef: { current: PaymentElementHandle | null } | string,
    options?: { confirmParams?: Record<string, any> }
  ): Promise<PaymentResult>;
  presentPaymentSheet(
    configuration?: Record<string, unknown>
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
