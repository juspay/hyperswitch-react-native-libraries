import NativeHyperswitchNetcetera from './NativeHyperswitchNetcetera';

const HyperswitchNetcetera3ds = NativeHyperswitchNetcetera || null;
const isAvailable =
  HyperswitchNetcetera3ds &&
  typeof HyperswitchNetcetera3ds.initialiseNetceteraSDK === 'function';

function initialiseNetceteraSDK(
  apiKey: string,
  hsSDKEnvironment: string,
  callback: (status: statusType) => void
) {
  if (isAvailable) {
    return HyperswitchNetcetera3ds.initialiseNetceteraSDK(
      apiKey,
      hsSDKEnvironment,
      callback
    );
  }
}

function generateAReqParams(
  messageVersion: string,
  directoryServerId: string,
  callback: (aReqParams: AReqParams, status: statusType) => void
) {
  if (isAvailable) {
    return HyperswitchNetcetera3ds.generateAReqParams(
      messageVersion,
      directoryServerId,
      callback
    );
  }
}

function recieveChallengeParamsFromRN(
  acsSignedContent: string,
  acsRefNumber: string,
  acsTransactionId: string,
  threeDSServerTransId: string,
  callback: (status: statusType) => void,
  threeDSRequestorAppURL?: string
) {
  if (isAvailable) {
    return HyperswitchNetcetera3ds.recieveChallengeParamsFromRN(
      acsSignedContent,
      acsRefNumber,
      acsTransactionId,
      threeDSServerTransId,
      callback,
      threeDSRequestorAppURL
    );
  }
}
function generateChallenge(callback: (status: statusType) => void) {
  if (isAvailable) {
    return HyperswitchNetcetera3ds.generateChallenge(callback);
  }
}

export type statusType = {
  status: string;
  message: string;
};

export type AReqParams = {
  deviceData: string;
  messageVersion: string;
  sdkTransId: string;
  sdkAppId: string;
  sdkEphemeralKey: any;
  sdkReferenceNo: string;
};

export {
  isAvailable,
  initialiseNetceteraSDK,
  generateAReqParams,
  recieveChallengeParamsFromRN,
  generateChallenge,
};
