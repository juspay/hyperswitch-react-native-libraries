import type { TurboModule } from 'react-native';
import { NativeModules, TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  confirmPayment(
    reactTag: number,
    callback: (result: Object) => void
  ): void;
  updateIntentInitForWidget(
    reactTag: number,
    callback: (result: Object) => void
  ): void;
  updateIntentCompleteForWidget(
    reactTag: number,
    sdkAuthorization: string,
    callback: (result: Object) => void
  ): void;
}


const NativePaymentElementModule =
  TurboModuleRegistry.get<Spec>('NativePaymentElementModule') ??
  NativeModules.NativePaymentElementModule;

export default NativePaymentElementModule as Spec;
