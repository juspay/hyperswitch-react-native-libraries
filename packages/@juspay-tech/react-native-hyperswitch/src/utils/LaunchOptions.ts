import { PaymentSheetConfiguration } from '..';
import type {
  HyperswitchConfiguration,
  NativePaymentSheetPayload,
  PaymentSessionConfiguration,
} from '../types/definitions';

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

export { buildPresentPaymentSheetPayload };
