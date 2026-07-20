// Adapter that wraps the handle-based react-native-hyperswitch native module
// into the universal HyperswitchSession shape consumed by
// @juspay-tech/react-hyperswitch.

import type {
  HyperswitchConfiguration,
  PaymentSession,
  PaymentSessionConfiguration,
} from './types/definitions';
export type * from './types/definitions';

import NativeHyperswitchModule from './specs/NativeHyperswitchModule';
import { createPaymentSession } from './context/PaymentSession';
import { createElements } from './context/Elements';
import { Elements } from './types/elements';

/**
 * Initialise the Hyperswitch SDK and return a session handle that exposes the
 * universal contract used by @juspay-tech/react-hyperswitch:
 *   - initPaymentSession: headless payment-sheet session
 *   - elements: factory for PaymentElement / CvcWidget handles
 */
export function loadHyper(
  config: HyperswitchConfiguration
): Promise<any> {
  return NativeHyperswitchModule.initialise(
    config.publishableKey,
    config.platformPublishableKey ?? '',
    config.profileId ?? '',
    config.environment ?? 'PROD',
    config.customEndpoints ?? {}
  ).then(() => {
    return {
      publishableKey: config.publishableKey,
      async initPaymentSession(
        options: PaymentSessionConfiguration
      ): Promise<PaymentSession> {
        // const instanceHandle = await instanceHandlePromise;
        // await NativeHyperswitchModule.initPaymentSession(
        //   instanceHandle,
        //   options.sdkAuthorization
        // );
        return createPaymentSession(config, options);
      },
      async elements(options: PaymentSessionConfiguration): Promise<Elements> {
        // await NativeHyperswitchModule.initPaymentSession(
        //   instanceHandle,
        //   options.sdkAuthorization
        // );
        return createElements(config, options);
      },
    }
  }).catch((error) => {
    console.error('Error initializing Hyperswitch SDK:', error);
    throw error;
  });

}
