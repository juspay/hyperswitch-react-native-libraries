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

import { CustomerSavedPaymentMethodsSession, SavedPaymentMethodsConfiguration } from './savedPaymentMethods';
import type { Elements } from './elements';
import type { ColorType, Shapes, Theme, Font, SubscriptionEvent, PaymentSheetConfiguration } from './PaymentSheetConfiguration';

export interface PaymentSession {
  presentPaymentSheet(
    configuration?: PaymentSheetConfiguration
  ): Promise<PaymentResult>;
  getCustomerSavedPaymentMethods(
    options?: SavedPaymentMethodsConfiguration
  ): Promise<CustomerSavedPaymentMethodsSession>;
  updateIntent(
    intentResolver: () => Promise<PaymentSessionConfiguration>
  ): Promise<void>;
}

export interface PaymentElementHandle {
  confirmPayment(options?: {
    confirmParams?: Record<string, any>;
  }): Promise<PaymentResult>;
}

// export interface PaymentElement extends PaymentElementHandle {
//   Component?: ComponentType<any>;
//   mount(selector: string): void;
//   unmount(): void;
//   on(event: string, handler?: (data?: any) => void): { remove: () => void };
//   onPaymentResult(handler?: (data: PaymentResult) => void): {
//     remove: () => void;
//   };
//   onPaymentConfirmButtonClick(handler?: (data: any) => boolean): {
//     remove: () => void;
//   };
// }

// export interface CvcWidget {
//   Component?: ComponentType<any>;
//   mount(selector: string, options?: Record<string, any>): void;
//   unmount(): void;
//   destroy(): void;
//   on(
//     event: string,
//     handler?: (data?: any) => void
//   ): { remove: () => void } | null;
// }

export interface HyperswitchSession {
  publishableKey: string;
  elements(options: PaymentSessionConfiguration): Promise<Elements>;
  initPaymentSession(
    options: PaymentSessionConfiguration
  ): Promise<PaymentSession>;
}
  
export interface CvcAppearance {
  theme?: Theme;
  colors?: ColorType;
  shapes?: Shapes;
  font?: Pick<Font, 'family' | 'scale'>;
}

export interface CvcWidgetOptions {
  appearance?: CvcAppearance;
  placeholder?: string;
  cvcIcon?: 'hidden' | 'shown';
  subscribedEvents?: SubscriptionEvent[];
}