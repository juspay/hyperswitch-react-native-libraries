import type { PaymentResult } from '../types/paymentresult';

interface NativeResponse {
  status: string;
  message: string;
  code?: string;
  type?: string;
  data?: any;
}

export function parseNativeResponse(
  raw: string | NativeResponse
): NativeResponse {
  if (typeof raw === 'object' && raw !== null) {
    return raw as NativeResponse;
  }
  try {
    return JSON.parse(raw as string) as NativeResponse;
  } catch {
    return { status: 'failed', message: String(raw) };
  }
}

export function mapStatus(status: string): PaymentResult['status'] {
  switch (status) {
    case 'succeeded':
    case 'completed':
    case 'requires_capture':
    case 'success':
      return 'completed';
    case 'cancelled':
    case 'canceled':
      return 'canceled';
    case 'failed':
    case 'error':
    default:
      return 'failed';
  }
}

export function mapNativeResponseToPaymentResult(
  raw: string | NativeResponse
): PaymentResult {
  const parsed = parseNativeResponse(raw);
  return {
    status: mapStatus(parsed.status),
    type: parsed.type ?? parsed.code ?? mapStatus(parsed.status) ?? '',
    message: parsed.message ?? parsed.code ?? '',
  };
}
