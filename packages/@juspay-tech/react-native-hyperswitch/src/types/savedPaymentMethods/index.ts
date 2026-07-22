import type { PaymentResult } from '../paymentresult';

export interface SavedPaymentMethodsConfiguration {
  hiddenPaymentMethods?: string[];
}

export interface CustomerLastUsedPaymentMethodCard {
  scheme: string;
  issuer_country: string;
  last4_digits: string;
  expiry_month: string;
  expiry_year: string;
  card_token: string | null;
  card_holder_name: string;
  card_fingerprint: string | null;
  nick_name: string;
  card_network: string;
  card_isin: string;
  card_issuer: string;
  card_type: string;
  saved_to_locker: boolean;
}

export interface CustomerPaymentMethodBillingAddress {
  line1?: string;
  line2?: string;
  line3?: string;
  city?: string;
  state?: string;
  country?: string;
  first_name?: string;
  last_name?: string;
}

export interface CustomerPaymentMethodBilling {
  address?: CustomerPaymentMethodBillingAddress;
  phone?: Record<string, unknown>;
  email?: string;
}

export interface CustomerLastUsedPaymentMethod {
  payment_token: string;
  payment_method_id: string;
  customer_id: string;
  payment_method: string;
  payment_method_type: string;
  payment_method_issuer: string;
  payment_method_issuer_code: string | null;
  recurring_enabled: boolean;
  installment_payment_enabled: boolean;
  payment_experience: string[];
  card: CustomerLastUsedPaymentMethodCard | null;
  metadata: string | null;
  created: string;
  bank: string | null;
  surcharge_details: string | null;
  requires_cvv: boolean;
  last_used_at: string;
  default_payment_method_set: boolean;
  billing: CustomerPaymentMethodBilling | null;
  error?: any;
}

export interface CustomerSavedPaymentMethodsSession {
  getCustomerLastUsedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null>;
  getCustomerDefaultSavedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null>;
  getCustomerSavedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null>;
  confirmWithCustomerLastUsedPaymentMethod(args?: {
    id?: string;
  }): Promise<PaymentResult>;
  confirmWithCustomerDefaultPaymentMethod?(args?: {
    id?: string;
  }): Promise<PaymentResult>;
}
