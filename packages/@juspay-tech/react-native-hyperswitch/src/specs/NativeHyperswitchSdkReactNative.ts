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
  
  // Widget control APIs
  goBack(widgetId: string): void;
  confirmPayment(widgetId: string): Promise<Record<string, unknown>>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'HyperswitchSdkReactNative'
);
