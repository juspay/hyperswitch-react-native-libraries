import NativeHyperswitchModule from '../codegen/modules/NativeHyperswitchModule';
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
import {
  isInitializing,
  isSheetPresented,
  setSheetPresented,
} from '../utils/InitializationState';
import { mapNativeResponseToPaymentResult } from './NativeResponseMapper';
import { PaymentSheetConfiguration } from '..';

export { parseNativeResponse, mapStatus, mapNativeResponseToPaymentResult } from './NativeResponseMapper';

export async function presentPaymentSheetWithPayload(
  payload: NativePaymentSheetPayload
): Promise<PaymentResult> {
  if (isInitializing()) {
    return {
      status: 'failed',
      type: 'initialization_in_progress',
      message:
        'SDK is reloading. Please wait for initialisation to complete before presenting the payment sheet.',
    };
  }
  if (isSheetPresented()) {
    // A sheet is already open (e.g. a hot-reload fired while the sheet was visible).
    // Silently skip so the existing sheet is not covered by a new one.
    return {
      status: 'canceled',
      type: 'sheet_already_presented',
      message: 'A payment sheet is already presented.',
    };
  }
  setSheetPresented(true);
  try {
    const raw = await NativeHyperswitchModule.presentPaymentSheet({
      hyperswitchConfig: payload.hyperswitchConfig,
      paymentSessionConfig: payload.paymentSessionConfig,
      configuration: payload.configuration,
    });
    return mapNativeResponseToPaymentResult(raw);
  } finally {
    setSheetPresented(false);
  }
}

export async function updateIntent(
  _intentResolver: () => Promise<PaymentSessionConfiguration>
): Promise<void> {
  // This feature is not yet implemented. Throw an explicit error rather than
  // silently succeeding so integrators get immediate feedback.
  throw new Error('updateIntent is not yet supported by this SDK version');
}

export function createPaymentSession(
  hyperswitchConfig: HyperswitchConfiguration,
  paymentSessionConfig: PaymentSessionConfiguration
): PaymentSession {
  return {
    async presentPaymentSheet(
      configuration?: PaymentSheetConfiguration
    ): Promise<PaymentResult> {
      const payload = buildPresentPaymentSheetPayload(
        hyperswitchConfig,
        paymentSessionConfig,
        configuration
      );
      return presentPaymentSheetWithPayload(payload);
    },

    async getCustomerSavedPaymentMethods(
      configuration?: PaymentSheetConfiguration
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
