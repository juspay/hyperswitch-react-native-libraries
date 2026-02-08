import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  launchScanCard(
    scanCardRequest: string,
    callback: (result: {
      status: string;
      data?: { pan: string; expiryMonth?: string; expiryYear?: string };
    }) => void
  ): void;
}

export default TurboModuleRegistry.get<Spec>('HyperswitchScancard');