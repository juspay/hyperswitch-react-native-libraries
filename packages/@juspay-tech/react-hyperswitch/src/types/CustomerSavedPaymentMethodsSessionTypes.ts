import { PaymentResult } from './PaymentTypes';
import { CustomerLastUsedPaymentMethod } from './CustomerLastUsedPaymentMethodTypes';
import { CustomerDefaultSavedPaymentMethod } from './CustomerDefaultSavedPaymentMethodTypes';

export type CustomerSavedPaymentMethodsSession = {
  getCustomerLastUsedPaymentMethodData: () => Promise<CustomerLastUsedPaymentMethod | null>;
  getCustomerDefaultSavedPaymentMethodData: () => Promise<CustomerDefaultSavedPaymentMethod | null>;
  confirmWithCustomerLastUsedPaymentMethod: (args?: { id?: string }) => Promise<PaymentResult>;
  confirmWithCustomerDefaultPaymentMethod?: (args?: { id?: string }) => Promise<PaymentResult>;
};
