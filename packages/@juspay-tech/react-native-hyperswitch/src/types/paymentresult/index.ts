export interface PaymentResult {
  type: 'completed' | 'canceled' | 'failed';
  message?: string;
}
