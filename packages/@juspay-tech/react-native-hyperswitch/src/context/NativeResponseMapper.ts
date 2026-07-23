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

function getType(type?: string, message?: string, status?: string): string {
  if (type && type !== '') {
    return type;
  } else if (message && message !== '') {
    return message;
  } else if (status && status !== '') {
    return status;
  } else {
    return '';
  }
}

export function mapNativeResponseToPaymentResult(
  raw: string | NativeResponse
): PaymentResult {
  const parsed = parseNativeResponse(raw);
  return {
    status: mapStatus(parsed.status),
    type: getType(parsed.type, parsed.message, parsed.status),
    message:
      getType(parsed.message, parsed.type, parsed.status) ?? parsed.code ?? '',
  };
}
