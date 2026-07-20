import type { TurboModule } from 'react-native';
import { NativeModules, TurboModuleRegistry } from 'react-native';

export type CustomEndpoints = Object;

export interface sessionData {
  hyperswitchConfig: Object;
  paymentSessionConfig: { sdkAuthorization: string };
  configuration: Object;
}

export interface SavedPaymentMethodsConfiguration {
  hiddenPaymentMethods?: string[];
}

export interface Spec extends TurboModule {
  initialise(
    publishableKey: string,
    platformPublishableKey: string,
    profileId: string,
    environment: string,
    customEndpoints: CustomEndpoints
  ): Promise<string>;

  presentPaymentSheet(params: sessionData): Promise<string>;

  getCustomerSavedPaymentMethods(params?: sessionData): Promise<string>;

  getCustomerLastUsedPaymentMethodData(): Promise<string>;

  getCustomerDefaultSavedPaymentMethodData(): Promise<string>;

  getCustomerSavedPaymentMethodData(): Promise<string>;

  confirmWithCustomerLastUsedPaymentMethod(): Promise<string>;

  confirmWithCustomerDefaultPaymentMethod(): Promise<string>;
}

/**
 * Use `TurboModuleRegistry.get` first for new-arch TurboModules, and fall back
 * to `NativeModules` for legacy/old-arch support.
 */
const NativeHyperswitchModule =
  TurboModuleRegistry.get<Spec>('NativeHyperswitchModule') ??
  NativeModules.NativeHyperswitchModule;
console.log('NativeHyperswitchModule', NativeHyperswitchModule);
export default NativeHyperswitchModule as Spec;
export { NativeHyperswitchModule };
