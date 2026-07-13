// Adapter that wraps the handle-based react-native-hyperswitch native module
// into the universal HyperswitchSession shape consumed by
// @juspay-tech/react-hyperswitch.

import NativeHyperswitchSdk from './specs/NativeHyperswitchSdkReactNative';
import type {
  Elements,
  HyperswitchConfiguration,
  HyperswitchSession,
  PaymentSession,
  PaymentSessionConfiguration,
} from './definitions';
export type * from './definitions';

import {
  createElementsNativeActions,
  createPaymentSession,
  getInstanceHandle,
} from './native';

import { createPaymentElement } from './views/PaymentElement';
import { createCvcWidget } from './views/CvcWidget';

type ElementType = 'paymentElement' | 'cvcWidget';

const SUPPORTED_ELEMENT_TYPES: readonly ElementType[] = [
  'paymentElement',
  'cvcWidget',
];

function isElementType(type: string): type is ElementType {
  return SUPPORTED_ELEMENT_TYPES.includes(type as ElementType);
}

// ------------------------------------------------------------------
// Elements factory
// ------------------------------------------------------------------

function createElements(): Elements {
  return {
    create(opts: { type: string; id?: string; options?: any }): any {
      if (!isElementType(opts.type)) {
        throw new Error(
          `[react-native-hyperswitch] elements.create('${opts.type}') is not supported. ` +
            `Supported types are 'paymentElement' and 'cvcWidget'.`
        );
      }

      switch (opts.type) {
        case 'paymentElement':
          return createPaymentElement({
            id: opts.id,
            options: opts.options,
          });
        case 'cvcWidget':
          return createCvcWidget({
            id: opts.id,
            options: opts.options,
          });
      }
    },

    ...createElementsNativeActions(),
  };
}

/**
 * Initialise the Hyperswitch SDK and return a session handle that exposes the
 * universal contract used by @juspay-tech/react-hyperswitch:
 *   - initPaymentSession: headless payment-sheet session
 *   - elements: factory for PaymentElement / CvcWidget handles
 */
export function loadHyper(
  config: HyperswitchConfiguration
): Promise<HyperswitchSession> {
  const instanceHandlePromise = getInstanceHandle(config);

  const session: HyperswitchSession = {
    publishableKey: config.publishableKey,

    async initPaymentSession(
      options: PaymentSessionConfiguration
    ): Promise<PaymentSession> {
      const instanceHandle = await instanceHandlePromise;
      await NativeHyperswitchSdk.initPaymentSession(
        instanceHandle,
        options.sdkAuthorization
      );
      return createPaymentSession();
    },

    async elements(options: PaymentSessionConfiguration): Promise<Elements> {
      const instanceHandle = await instanceHandlePromise;
      await NativeHyperswitchSdk.initPaymentSession(
        instanceHandle,
        options.sdkAuthorization
      );
      return createElements();
    },
  };

  return Promise.resolve(session);
}
