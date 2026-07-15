// Native SDK interactions shared by the PaymentSession and Elements handles.

import NativeHyperswitchSdk from '../specs/NativeHyperswitchSdkReactNative';
import {
  confirmPayment as widgetConfirm,
  getWidget,
} from '../context/WidgetRegistry';
import type {
  CustomerLastUsedPaymentMethod,
  CustomerSavedPaymentMethodsSession,
  Elements,
  HyperswitchConfiguration,
  PaymentElementHandle,
  PaymentResult,
  PaymentSession,
  PaymentSessionConfiguration,
  PaymentSheetOptions,
} from '../types/definitions';

// ------------------------------------------------------------------
// Instance cache
// ------------------------------------------------------------------

const instanceHandleCache = new Map<string, Promise<string>>();

function getCacheKey(config: HyperswitchConfiguration): string {
  return `${config.publishableKey}:${config.profileId ?? ''}:${JSON.stringify(config.customEndpoints ?? {})}`;
}

export function getInstanceHandle(
  config: HyperswitchConfiguration
): Promise<string> {
  const key = getCacheKey(config);
  const cached = instanceHandleCache.get(key);
  if (cached) {
    return cached;
  }
  const instanceHandlePromise = NativeHyperswitchSdk.initialise(config);
  instanceHandleCache.set(key, instanceHandlePromise);
  return instanceHandlePromise;
}

// ------------------------------------------------------------------
// Response mapping helpers
// ------------------------------------------------------------------

interface NativeResponse {
  status: string;
  message: string;
  data?: any;
}

function parseNativeResponse(raw: string | NativeResponse): NativeResponse {
  if (typeof raw === 'object' && raw !== null) {
    return raw as NativeResponse;
  }
  try {
    return JSON.parse(raw as string) as NativeResponse;
  } catch {
    return { status: 'failed', message: String(raw) };
  }
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

export function mapNativeResponseToPaymentResult(
  raw: string | NativeResponse
): PaymentResult {
  const parsed = parseNativeResponse(raw);
  return {
    type: mapStatus(parsed.status),
    message: parsed.message,
  };
}

function parseSavedMethodData(
  raw: string | NativeResponse
): CustomerLastUsedPaymentMethod | null {
  const parsed = parseNativeResponse(raw);
  if (parsed.status !== 'succeeded' && parsed.status !== 'success') {
    return null;
  }
  if (!parsed.data) {
    return null;
  }
  const data = parsed.data as any;
  return {
    payment_method:
      data.payment_method_str ?? data.payment_method ?? data.paymentMethod,
    payment_method_type: data.payment_method_type ?? data.paymentMethodType,
    card: data.card,
    ...data,
  };
}

// ------------------------------------------------------------------
// Saved payment methods session
// ------------------------------------------------------------------

function createCustomerSavedPaymentMethodsSession(): CustomerSavedPaymentMethodsSession {
  return {
    async getCustomerLastUsedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null> {
      const raw =
        await NativeHyperswitchSdk.getCustomerLastUsedPaymentMethodData();
      return parseSavedMethodData(raw);
    },

    async getCustomerDefaultSavedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null> {
      const raw =
        await NativeHyperswitchSdk.getCustomerDefaultSavedPaymentMethodData();
      return parseSavedMethodData(raw);
    },

    async confirmWithCustomerLastUsedPaymentMethod(args?: {
      id?: string;
    }): Promise<PaymentResult> {
      const raw =
        await NativeHyperswitchSdk.confirmWithCustomerLastUsedPaymentMethod(
          args?.id ? String(getWidget(args.id) ?? '') : undefined
        );
      return mapNativeResponseToPaymentResult(raw);
    },

    async confirmWithCustomerDefaultPaymentMethod(args?: {
      id?: string;
    }): Promise<PaymentResult> {
      const raw =
        await NativeHyperswitchSdk.confirmWithCustomerDefaultPaymentMethod(
          args?.id ? String(getWidget(args.id) ?? '') : undefined
        );
      return mapNativeResponseToPaymentResult(raw);
    },
  };
}

// ------------------------------------------------------------------
// Intent update helper
// ------------------------------------------------------------------

export async function updateIntent(
  intentResolver: () => Promise<PaymentSessionConfiguration>
): Promise<void> {
  const cfg = await intentResolver();
  const raw = await NativeHyperswitchSdk.updateIntent(cfg.sdkAuthorization);
  const parsed = parseNativeResponse(raw);
  if (mapStatus(parsed.status) === 'failed') {
    throw new Error(parsed.message || 'Update intent failed');
  }
}

// ------------------------------------------------------------------
// PaymentSession factory
// ------------------------------------------------------------------

export function createPaymentSession(): PaymentSession {
  return {
    async presentPaymentSheet(
      options?: PaymentSheetOptions
    ): Promise<PaymentResult> {
      const raw = await NativeHyperswitchSdk.presentPaymentSheet(options ?? {});
      return mapNativeResponseToPaymentResult(raw);
    },

    async getCustomerSavedPaymentMethods(
      options?: any
    ): Promise<CustomerSavedPaymentMethodsSession> {
      // Ensure the native session has loaded saved methods before exposing the handler.
      await NativeHyperswitchSdk.getCustomerSavedPaymentMethods(options);
      return createCustomerSavedPaymentMethodsSession();
    },

    async updateIntent(intentResolver): Promise<void> {
      await updateIntent(intentResolver);
    },
  };
}

// ------------------------------------------------------------------
// Elements native actions
// ------------------------------------------------------------------

type ElementsNativeActions = Pick<
  Elements,
  | 'confirmPayment'
  | 'presentPaymentSheet'
  | 'updateIntent'
  | 'getCustomerSavedPaymentMethods'
>;

export function createElementsNativeActions(): ElementsNativeActions {
  return {
    async presentPaymentSheet(
      options?: PaymentSheetOptions
    ): Promise<PaymentResult> {
      const raw = await NativeHyperswitchSdk.presentPaymentSheet(options ?? {});
      return mapNativeResponseToPaymentResult(raw);
    },

    async confirmPayment(
      paymentElementRef: { current: PaymentElementHandle | null } | string,
      _confirmOptions?: { confirmParams?: Record<string, any> }
    ): Promise<PaymentResult> {
      if (typeof paymentElementRef === 'string') {
        const result = await widgetConfirm(paymentElementRef);
        return {
          type: mapStatus(result.status),
          message: result.message,
        };
      }

      const ref = paymentElementRef.current;
      if (!ref) {
        throw new Error('PaymentElement reference is not mounted');
      }
      return ref.confirmPayment(_confirmOptions);
    },

    async updateIntent(intentResolver): Promise<void> {
      await updateIntent(intentResolver);
    },

    async getCustomerSavedPaymentMethods(
      options?: any
    ): Promise<CustomerSavedPaymentMethodsSession> {
      await NativeHyperswitchSdk.getCustomerSavedPaymentMethods(options);
      return createCustomerSavedPaymentMethodsSession();
    },
  };
}
