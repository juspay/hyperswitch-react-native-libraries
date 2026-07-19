import { CustomerSavedPaymentMethodsSession } from './CustomerSavedPaymentMethodsSessionTypes';
import { CvcWidget, CvcWidgetOptions } from './CvcWidgetTypes';
import { PaymentElement, PaymentElementHandle, PaymentElementOptions } from './PaymentElementTypes';
import { PaymentSessionConfiguration } from './HyperswitchSessionTypes';
import { PaymentSession } from './PaymentSessionTypes';
import { PaymentResult } from './PaymentTypes';

export type Elements = Omit<PaymentSession, 'presentPaymentSheet'> & {
  presentPaymentSheet?: PaymentSession['presentPaymentSheet'];
  confirmPayment?(
    paymentElementRef: { current: PaymentElementHandle | null } | string,
    options?: { confirmParams?: Record<string, Object> },
  ): Promise<PaymentResult>;
  create(options: { type: 'paymentElement'; id?: string; options?: PaymentElementOptions }): PaymentElement;
  create(options: { type: 'cvcWidget'; id?: string; options?: CvcWidgetOptions }): CvcWidget;
};

export interface ElementsActions {
  confirmPayment: (
    paymentElementRef: { current: PaymentElementHandle | null } | string,
    options?: { confirmParams?: Record<string, Object> },
  ) => Promise<PaymentResult>;
  updateIntent: (intentResolver: () => Promise<PaymentSessionConfiguration>) => Promise<void>;
  getCustomerSavedPaymentMethods(): Promise<CustomerSavedPaymentMethodsSession>;
}
