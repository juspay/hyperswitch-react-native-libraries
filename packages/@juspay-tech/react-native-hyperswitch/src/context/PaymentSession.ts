import NativeHyperswitchModule from '../specs/NativeHyperswitchModule';
import type {
  HyperswitchConfiguration,
  NativePaymentSheetPayload,
  PaymentSession,
  PaymentSessionConfiguration,
} from '../types/definitions';
import { buildPresentPaymentSheetPayload } from '../utils/LaunchOptions';
import { getCustomerSavedPaymentMethods } from './SavedPaymentMethods';
import type { PaymentResult } from '../types/paymentresult';
import type { CustomerSavedPaymentMethodsSession } from '../types/savedPaymentMethods';

interface NativeResponse {
  status: string;
  message: string;
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

export function mapStatus(status: string): PaymentResult['type'] {
  switch (status) {
    case 'succeeded':
    case 'completed':
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
    type: mapStatus(parsed.status),
    message: parsed.message,
  };
}

export async function presentPaymentSheetWithPayload(
  payload: NativePaymentSheetPayload
): Promise<PaymentResult> {
  const raw = await NativeHyperswitchModule.presentPaymentSheet({
    hyperswitchConfig: payload.hyperswitchConfig,
    paymentSessionConfig: payload.paymentSessionConfig,
    configuration: payload.configuration,
  });
  return mapNativeResponseToPaymentResult(raw);
}

export async function updateIntent(
  _intentResolver: () => Promise<PaymentSessionConfiguration>
): Promise<void> {
  //   const cfg = await intentResolver();
  //   const raw = await NativeHyperswitchModule.updateIntent(cfg.sdkAuthorization);
  //   const parsed = parseNativeResponse(raw);
  //   if (mapStatus(parsed.status) === 'failed') {
  //     throw new Error(parsed.message || 'Update intent failed');
  //   }
}

export function createPaymentSession(
  hyperswitchConfig: HyperswitchConfiguration,
  paymentSessionConfig: PaymentSessionConfiguration
): PaymentSession {
  return {
    async presentPaymentSheet(
      configuration?: Record<string, unknown>
    ): Promise<PaymentResult> {
      const payload = buildPresentPaymentSheetPayload(
        hyperswitchConfig,
        paymentSessionConfig,
        configuration
      );
      return presentPaymentSheetWithPayload(payload);
    },

    async getCustomerSavedPaymentMethods(
      configuration?: Record<string, unknown>
    ): Promise<CustomerSavedPaymentMethodsSession> {
      return getCustomerSavedPaymentMethods(
        hyperswitchConfig,
        paymentSessionConfig,
        configuration
      );
    },

    updateIntent,
  };
}
