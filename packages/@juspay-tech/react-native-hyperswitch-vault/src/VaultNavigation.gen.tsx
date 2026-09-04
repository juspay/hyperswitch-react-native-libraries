/* TypeScript file generated from VaultNavigation.res by genType. */

/* eslint-disable */
/* tslint:disable */

export type nextActionType = 
    "three_ds_invoke"
  | "third_party_sdk_session_token"
  | "display_bank_transfer_information"
  | "invoke_ddc"
  | "redirect_to_url";

export type safeThreeDs = {
  readonly authenticationUrl: string; 
  readonly authorizeUrl: string; 
  readonly messageVersion: string; 
  readonly directoryServerId: string; 
  readonly pollId: string; 
  readonly delayInSecs: number; 
  readonly frequency: number
};

export type safeDdc = { readonly iframeUrl: string; readonly timeoutMs: number };

export type safeSessionToken = { readonly walletName: string; readonly openBankingSessionToken: string };

export type safeNextAction = {
  readonly type_: nextActionType; 
  readonly redirectUrl?: string; 
  readonly threeDs?: safeThreeDs; 
  readonly ddc?: safeDdc; 
  readonly sessionToken?: safeSessionToken
};
