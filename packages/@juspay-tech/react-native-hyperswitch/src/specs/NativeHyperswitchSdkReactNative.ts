import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  initialise(
    publishableKey: string,
    customBackendUrl: undefined | string,
    customLogUrl: undefined | string,
    customParams: undefined | Object
  ): Promise<void>;
  initPaymentSession(paymentIntentClientSecret: string): Promise<string>;
  presentPaymentSheet(configuration: Object): Promise<string>;
  
  // Headless Payment Methods
  getCustomerSavedPaymentMethods(): Promise<string>;
  getCustomerDefaultSavedPaymentMethodData(): Promise<string>;
  getCustomerLastUsedPaymentMethodData(): Promise<string>;
  confirmWithCustomerDefaultPaymentMethod(): Promise<string>;
  confirmWithCustomerLastUsedPaymentMethod(): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'HyperswitchSdkReactNative'
);
