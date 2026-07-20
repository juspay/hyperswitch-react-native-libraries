import type { PaymentResult } from './paymentresult';

export interface OverrideEndpointConfiguration {
  customBackendEndpoint?: string;
  customLoggingEndpoint?: string;
  customAssetEndpoint?: string;
  customSDKConfigEndpoint?: string;
  customAirborneEndpoint?: string;
}

export interface CommonEndpoint {
  commonEndpoint: string;
}

export interface OverrideEndpoints {
  overrideEndpoints: OverrideEndpointConfiguration;
}

export type HyperswitchEnvironment = 'PROD' | 'SANDBOX' | 'INTEG';

export type ElementType = 'paymentElement' | 'cvcWidget';


export interface HyperswitchConfiguration {
  publishableKey: string;
  platformPublishableKey?: string;
  profileId?: string;
  environment?: HyperswitchEnvironment;
  customEndpoints?: CommonEndpoint | OverrideEndpoints;
}

export interface PaymentSessionConfiguration {
  sdkAuthorization: string;
}

/**
 * Full payload sent to the native SDK. It is assembled internally from the
 * merchant-supplied configuration plus the SDK/payment-session metadata.
 */
export interface NativePaymentSheetPayload {
  hyperswitchConfig: Record<string, unknown>;
  paymentSessionConfig: { sdkAuthorization: string };
  configuration: Record<string, unknown>;
}

import type { ComponentType } from 'react';
import { CustomerSavedPaymentMethodsSession } from './savedPaymentMethods';





export interface PaymentSession {
  presentPaymentSheet(
    configuration?: Record<string, unknown>
  ): Promise<PaymentResult>;
  getCustomerSavedPaymentMethods(
    options?: any
  ): Promise<CustomerSavedPaymentMethodsSession>;
  updateIntent(
    intentResolver: () => Promise<PaymentSessionConfiguration>
  ): Promise<void>;
}

export interface PaymentElementHandle {
  confirmPayment(options?: {
    confirmParams?: Record<string, any>;
  }): Promise<PaymentResult>;
  collapse(): void;
  focus(): void;
  blur(): void;
  clear(): void;
  update(options: Record<string, any>): void;
  destroy(): void;
}

export interface PaymentElement extends PaymentElementHandle {
  Component?: ComponentType<any>;
  mount(selector: string): void;
  unmount(): void;
  on(event: string, handler?: (data?: any) => void): { remove: () => void };
  onPaymentResult(handler?: (data: PaymentResult) => void): {
    remove: () => void;
  };
  onPaymentConfirmButtonClick(handler?: (data: any) => boolean): {
    remove: () => void;
  };
}

export interface CvcWidget {
  Component?: ComponentType<any>;
  mount(selector: string, options?: Record<string, any>): void;
  unmount(): void;
  destroy(): void;
  on(
    event: string,
    handler?: (data?: any) => void
  ): { remove: () => void } | null;
}

