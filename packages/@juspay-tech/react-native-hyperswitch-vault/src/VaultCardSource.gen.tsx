/* TypeScript file generated from VaultCardSource.res by genType. */

/* eslint-disable */
/* tslint:disable */

import type {MerchantSession as $$vaultSession} from './merchantTypes';

import type {confirmTokenMode as VaultConfirmBody_confirmTokenMode} from './VaultConfirmBody.gen';

export type vaultSession = $$vaultSession;

export type cardSourceType = "vault" | "direct";

export type paymentCardSource = {
  readonly type_: cardSourceType; 
  readonly session?: vaultSession; 
  readonly confirmTokenMode?: VaultConfirmBody_confirmTokenMode
};
