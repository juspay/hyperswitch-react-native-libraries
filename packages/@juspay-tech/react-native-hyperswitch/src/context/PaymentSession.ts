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
import { isInitializing, isSheetPresented, setSheetPresented } from '../utils/InitializationState';

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
  if (isInitializing()) {
    return {
      type: 'failed',
      message: 'SDK is reloading. Please wait for initialisation to complete before presenting the payment sheet.',
    };
  }
  if (isSheetPresented()) {
    // A sheet is already open (e.g. a hot-reload fired while the sheet was visible).
    // Silently skip so the existing sheet is not covered by a new one.
    return {
      type: 'canceled',
      message: 'A payment sheet is already presented.',
    };
  }
  setSheetPresented(true);
  try {
    console.log('Presenting payment sheet with payload:', payload);
    const raw = await NativeHyperswitchModule.presentPaymentSheet({
      hyperswitchConfig: payload.hyperswitchConfig,
      paymentSessionConfig: payload.paymentSessionConfig,
      configuration: payload.configuration,
    });
    console.log('Native response from presentPaymentSheet:', raw);
    return mapNativeResponseToPaymentResult(raw);
  } finally {
    setSheetPresented(false);
  }
}

export async function updateIntent(
  _intentResolver: () => Promise<PaymentSessionConfiguration>
): Promise<void> {
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
