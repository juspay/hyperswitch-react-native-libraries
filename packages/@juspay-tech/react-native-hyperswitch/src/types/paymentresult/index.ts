export interface PaymentResult {
  status: 'completed' | 'canceled' | 'failed';
  type?: string;
  message?: string;
}
