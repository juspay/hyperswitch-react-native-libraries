import NativeHyperswitchModule from '../specs/NativeHyperswitchModule';
import {
  HyperswitchConfiguration,
  PaymentSessionConfiguration,
} from '../types/definitions';
import {
  CustomerSavedPaymentMethodsSession,
  CustomerLastUsedPaymentMethod,
} from '../types/savedPaymentMethods';
import { buildPresentPaymentSheetPayload } from '../utils/LaunchOptions';

function parsePaymentMethod(raw: string): CustomerLastUsedPaymentMethod {
  const parsed = JSON.parse(raw) as CustomerLastUsedPaymentMethod & {
    billing?: string | object | null;
  };
  if (parsed.billing && typeof parsed.billing === 'string') {
    try {
      parsed.billing = JSON.parse(parsed.billing);
    } catch {
      parsed.billing = null;
    }
  }
  return parsed as CustomerLastUsedPaymentMethod;
}

export function createCustomerSavedPaymentMethodsSession(): CustomerSavedPaymentMethodsSession {
  return {
    async getCustomerLastUsedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null> {
      const raw =
        await NativeHyperswitchModule.getCustomerLastUsedPaymentMethodData();
      return parsePaymentMethod(raw);
    },

    async getCustomerDefaultSavedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null> {
      const raw =
        await NativeHyperswitchModule.getCustomerDefaultSavedPaymentMethodData();
      return parsePaymentMethod(raw);
    },

    async getCustomerSavedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null> {
      const raw =
        await NativeHyperswitchModule.getCustomerSavedPaymentMethodData();
      return parsePaymentMethod(raw);
    },

    async confirmWithCustomerLastUsedPaymentMethod(args?: {
      id?: string;
    }): Promise<any> {
      const raw = await NativeHyperswitchModule
        .confirmWithCustomerLastUsedPaymentMethod
        // args?.id
        ();
      // return mapNativeResponseToPaymentResult(raw);
    },

    async confirmWithCustomerDefaultPaymentMethod(args?: {
      id?: string;
    }): Promise<any> {
      const raw = await NativeHyperswitchModule
        .confirmWithCustomerDefaultPaymentMethod
        // args?.id
        ();
      // return mapNativeResponseToPaymentResult(raw);
    },
  };
}

export async function getCustomerSavedPaymentMethods(
  hyperswitchConfig: HyperswitchConfiguration,
  paymentSessionConfig: PaymentSessionConfiguration,
  configuration?: Record<string, unknown>
): Promise<CustomerSavedPaymentMethodsSession> {
  const payload = buildPresentPaymentSheetPayload(
    hyperswitchConfig,
    paymentSessionConfig,
    configuration
  );
  await NativeHyperswitchModule.getCustomerSavedPaymentMethods(payload);
  return createCustomerSavedPaymentMethodsSession();
}
