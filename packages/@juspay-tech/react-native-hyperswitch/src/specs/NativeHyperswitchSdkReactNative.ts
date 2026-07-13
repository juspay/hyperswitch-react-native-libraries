import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
export interface Spec extends TurboModule {
  initialise(
   config: {
    publishableKey: string;
    profileId?: string;
    environment?: 'sandbox' | 'production';
    customEndpoints?: {
      commonEndpoint?: string;
      overrideEndpoints?: {
        customBackendEndpoint?: string;
        customLoggingEndpoint?: string;
        customAssetEndpoint?: string;
        customSDKConfigEndpoint?: string;
        customAirborneEndpoint?: string;
      };
    };
   }
  ): Promise<string>;

  initPaymentSession(
    instanceHandle: string,
    sdkAuthorization: string
  ): Promise<string>;

  getCustomerSavedPaymentMethods(
    options: undefined | Object
  ): Promise<string>;

  getCustomerDefaultSavedPaymentMethodData(): Promise<string>;

  getCustomerLastUsedPaymentMethodData(): Promise<string>;

  confirmWithCustomerDefaultPaymentMethod(
    cvcWidgetReactTag: undefined | string
  ): Promise<string>;

  confirmWithCustomerLastUsedPaymentMethod(
    cvcWidgetReactTag: undefined | string
  ): Promise<string>;

  confirmWithCustomerPaymentToken(
    paymentToken: string
  ): Promise<string>;

  updateIntent(
    sdkAuthorization: string
  ): Promise<string>;

  presentPaymentSheet(
    configuration: Object
  ): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'HyperswitchSdkReactNative'
);
