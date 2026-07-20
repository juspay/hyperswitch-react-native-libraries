import { PaymentResult } from "../paymentresult";
import type {
  PaymentElementHandle,
  PaymentSessionConfiguration,
  PaymentSession,
  PaymentElement,
  CvcWidget,
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
  create(options: {
    type: 'paymentElement';
    id?: string;
    options?: any;
  }): PaymentElement;
  create(options: { type: 'cvcWidget'; id?: string; options?: any }): CvcWidget;
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

export interface HyperswitchSession {
  publishableKey: string;
  elements(options: PaymentSessionConfiguration): Promise<Elements>;
  initPaymentSession(
    options: PaymentSessionConfiguration
  ): Promise<PaymentSession>;
}
