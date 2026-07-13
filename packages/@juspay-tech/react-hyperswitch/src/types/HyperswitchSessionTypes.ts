import { Elements } from './ElementsTypes';
import { PaymentSession } from './PaymentSessionTypes';

export interface OverrideEndpontConfiguration {
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
  overrideEndpoints: OverrideEndpontConfiguration;
}

export type HyperswitchEnvironment = 'sandbox' | 'production';

export interface HyperswitchConfiguration {
  publishableKey: string;
  profileId?: string;
  environment?: HyperswitchEnvironment;
  customEndpoints?: CommonEndpoint | OverrideEndpoints;
}

export interface PaymentSessionConfiguration {
  sdkAuthorization: string;
}

export interface HyperswitchSession {
  publishableKey?: string;
  initPaymentSession(options: PaymentSessionConfiguration): Promise<PaymentSession>;
  elements(options: PaymentSessionConfiguration): Promise<Elements>;
}
