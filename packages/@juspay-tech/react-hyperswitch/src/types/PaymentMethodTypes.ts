export type PaymentMethod =
  | 'card'
  | 'wallet'
  | 'card_redirect'
  | 'pay_later'
  | 'bank_redirect'
  | 'open_banking'
  | 'bank_debit'
  | 'bank_transfer'
  | 'crypto'
  | 'reward'
  | 'gift_card'
  | string;

export interface Card {
  scheme: string;
  last4_digits: string;
  card_holder_name: string;
  card_network: string;
  card_type: string;
  expiry_year: string;
  issuer_country: string;
  expiry_month: string;
  card_fingerprint: string | null;
  card_issuer: string;
  saved_to_locker: boolean;
  card_token: string | null;
  nick_name: string;
  card_isin: string;
}

export interface PaymentMethodTypes {
  payment_method_type: string;
  metadata: string | null;
  default_payment_method_set: boolean;
  created: string;
  payment_token: string;
  payment_method_issuer_code: string | null;
  surcharge_details: string | null;
  billing: string | null;
  payment_method_issuer: string;
  last_used_at: string;
  payment_method_id: string;
  bank: string | null;
  installment_payment_enabled: boolean;
  requires_cvv: boolean;
  customer_id: string;
  payment_experience: string[];
  payment_method?: PaymentMethod;
  payment_method_str?: PaymentMethod;
  card: Card | null;
  recurring_enabled: boolean;
}

export interface PaymentMethodData {
  data: PaymentMethodTypes | null;
  error?: string;
}

export interface PaymentMethodListData {
  data: PaymentMethodTypes[];
  error?: string;
}
