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
  confirmPayment(reactTag: number, callback: (result: string) => void): void;
  
  // Headless Payment Methods
  getCustomerSavedPaymentMethods(): Promise<string>;
  getCustomerDefaultSavedPaymentMethodData(): Promise<string>;
  getCustomerLastUsedPaymentMethodData(): Promise<string>;
  confirmWithCustomerDefaultPaymentMethod(reactTag: number): Promise<string>;
  confirmWithCustomerLastUsedPaymentMethod(reactTag: number): Promise<string>;
  confirmWithCustomerPaymentToken(paymentToken: string): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'HyperswitchSdkReactNative'
);
