import { NativeModules } from 'react-native';

// Declare the global type for TurboModule proxy
declare global {
  var __turboModuleProxy: unknown;
}

// Try to get the TurboModule first, fallback to legacy NativeModules
const isTurboModuleEnabled = global.__turboModuleProxy != null;

const HyperswitchScancardModule = isTurboModuleEnabled
  ? require('./NativeHyperswitchScancard').default
  : NativeModules.HyperswitchScancard;

const HyperswitchScancard = HyperswitchScancardModule || null;

const isAvailable =
  HyperswitchScancard && typeof HyperswitchScancard.launchScanCard === 'function';

export interface ScanCardReturnType {
  status: string;
  data?: ScanCardData;
}

interface ScanCardData {
  pan: string;
  expiryMonth: string;
  expiryYear: string;
}

function launchScanCard(callback: (s: ScanCardReturnType) => void): void {
  if (isAvailable) {
    return HyperswitchScancard.launchScanCard(
      '',
      (response: Record<string, any>) => {
        const status = response.status || 'Default';
        const data: ScanCardData | undefined = response.data;
        const scanData: ScanCardReturnType = {
          status,
          data: data
            ? {
                pan: data.pan || '',
                expiryMonth: data.expiryMonth || '',
                expiryYear: data.expiryYear || '',
              }
            : undefined,
        };
        callback(scanData);
      }
    );
  }
}

export { isAvailable, launchScanCard };