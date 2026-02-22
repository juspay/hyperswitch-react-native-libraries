import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
export interface Spec extends TurboModule {
  initialiseNetceteraSDK(
    apiKey: string,
    hsSDKEnvironment: string,
    callback: (status: { status: string; message: string }) => void
  ): void;
  generateAReqParams(
    messageVersion: string,
    directoryServerId: string,
    callback: (
      aReqParams: {
        deviceData: string;
        messageVersion: string;
        sdkTransId: string;
        sdkAppId: string;
        sdkEphemeralKey: Object;
        sdkReferenceNo: string;
      },
      status: {
        status: string;
        message: string;
      }
    ) => void
  ): void;
  recieveChallengeParamsFromRN(
    acsSignedContent: string,
    acsRefNumber: string,
    acsTransactionId: string,
    threeDSServerTransId: string,
    callback: (status: { status: string; message: string }) => void,
    threeDSRequestorAppURL?: string
  ): void;
  generateChallenge(
    callback: (status: { status: string; message: string }) => void
  ): void;
}

export default TurboModuleRegistry.get<Spec>('HyperswitchNetcetera3ds');
