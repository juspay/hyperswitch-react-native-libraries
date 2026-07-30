import { PaymentSheetConfiguration } from '..';
import type {
  HyperswitchConfiguration,
  NativePaymentSheetPayload,
} from '../types/definitions';
import type { PaymentSessionConfiguration } from '../types/definitions';
import { PaymentResult } from '../types/paymentresult';

function buildPresentPaymentSheetPayload(
  hyperswitchConfig: HyperswitchConfiguration,
  paymentSessionConfig: PaymentSessionConfiguration,
  configuration?: PaymentSheetConfiguration
): NativePaymentSheetPayload {
  // platformPublishableKey is internal to the RN bridge; it is not part of the
  // merchant-facing hyperswitchConfig payload.
  const { platformPublishableKey: _platformPublishableKey, ...restConfig } =
    hyperswitchConfig;
  return {
    hyperswitchConfig: restConfig as Record<string, unknown>,
    paymentSessionConfig: paymentSessionConfig,
    configuration: (configuration ?? {}) as Record<string, unknown>,
  };
}

function mapStatus(status: string): PaymentResult['type'] {
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

export { buildPresentPaymentSheetPayload, mapStatus };
