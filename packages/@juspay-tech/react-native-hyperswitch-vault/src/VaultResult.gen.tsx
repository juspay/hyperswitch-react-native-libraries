/* TypeScript file generated from VaultResult.res by genType. */

/* eslint-disable */
/* tslint:disable */

import type {nextActionType as VaultNavigation_nextActionType} from './VaultNavigation.gen';

import type {safeDdc as VaultNavigation_safeDdc} from './VaultNavigation.gen';

import type {safeNextAction as VaultNavigation_safeNextAction} from './VaultNavigation.gen';

import type {safeSessionToken as VaultNavigation_safeSessionToken} from './VaultNavigation.gen';

import type {safeThreeDs as VaultNavigation_safeThreeDs} from './VaultNavigation.gen';

export type safeVaultErrorCode = 
    "invalid_session"
  | "invalid_card_data"
  | "not_ready"
  | "forbidden_card_data"
  | "unsupported_configuration"
  | "card_not_eligible"
  | "server_error"
  | "unknown_outcome";

export type safeVaultError = { readonly code: safeVaultErrorCode; readonly message: string };

export type nextActionType = VaultNavigation_nextActionType;

export type safeThreeDs = VaultNavigation_safeThreeDs;

export type safeDdc = VaultNavigation_safeDdc;

export type safeSessionToken = VaultNavigation_safeSessionToken;

export type safeNextAction = VaultNavigation_safeNextAction;

export type vaultPaymentStatus = 
    "succeeded"
  | "processing"
  | "requires_customer_action"
  | "failed"
  | "validation_error"
  | "not_ready";

export type vaultTokenizeStatus = 
    "success"
  | "validation_error"
  | "not_ready"
  | "error";

export type vaultPaymentResult = {
  readonly status: vaultPaymentStatus; 
  readonly error?: safeVaultError; 
  readonly nextAction?: safeNextAction
};

export type vaultTokenizeResult = {
  readonly status: vaultTokenizeStatus; 
  readonly token?: string; 
  readonly error?: safeVaultError
};
