export interface PaymentResult {
  type: 'completed' | 'canceled' | 'failed';
  message?: string;
}

export interface PaymentEventData {
  type: string;
  payload: Record<string, string>;
}

type paymentMethodType = 'CARD' | 'APPLE_PAY' | 'GOOGLE_PAY' | 'SAMSUNG_PAY' | 'PAYPAL' | string;

export interface PaymentRequestData {
  paymentMethodType: paymentMethodType;
  [key: string]: any;
}
