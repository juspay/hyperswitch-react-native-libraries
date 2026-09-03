/* TypeScript file generated from HyperswitchVaultSavedCardForm.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as React from 'react';

import * as HyperswitchVaultSavedCardFormJS from './HyperswitchVaultSavedCardForm.bs.js';

import type {appearance as VaultFormOptions_appearance} from './VaultFormOptions.gen';

import type {cvcOptions as CardFieldOptions_cvcOptions} from './CardFieldOptions.gen';

import type {cvcState as VaultPublicState_cvcState} from './VaultPublicState.gen';

import type {fieldStyles as CardFieldStyles_fieldStyles} from './CardFieldStyles.gen';

import type {vaultEndpointConfig as VaultEndpoint_vaultEndpointConfig} from './VaultEndpoint.gen';

import type {vaultEnvironment as VaultFormOptions_vaultEnvironment} from './VaultFormOptions.gen';

import type {vaultSession as VaultFormOptions_vaultSession} from './VaultFormOptions.gen';

import type {vaultTokenizeResult as VaultResult_vaultTokenizeResult} from './VaultResult.gen';

import type {viewStyleProp as CardFieldStyles_viewStyleProp} from './CardFieldStyles.gen';

export type savedCardHandle = {
  readonly updateSavedPaymentMethod: () => Promise<VaultResult_vaultTokenizeResult>; 
  readonly reset: () => void; 
  readonly focus: () => void; 
  readonly blur: () => void
};

export type Props = {
  readonly appearance?: VaultFormOptions_appearance; 
  readonly cardNetwork?: string; 
  readonly containerStyle?: CardFieldStyles_viewStyleProp; 
  readonly cvcOptions?: CardFieldOptions_cvcOptions; 
  readonly cvcStyles?: CardFieldStyles_fieldStyles; 
  readonly environment: VaultFormOptions_vaultEnvironment; 
  readonly onStateChange?: (_1:VaultPublicState_cvcState) => void; 
  readonly paymentMethodToken: string; 
  readonly session: VaultFormOptions_vaultSession; 
  readonly vaultEndpoint?: VaultEndpoint_vaultEndpointConfig
};

export const make: React.ComponentType<{
  readonly appearance?: VaultFormOptions_appearance; 
  readonly cardNetwork?: string; 
  readonly containerStyle?: CardFieldStyles_viewStyleProp; 
  readonly cvcOptions?: CardFieldOptions_cvcOptions; 
  readonly cvcStyles?: CardFieldStyles_fieldStyles; 
  readonly environment: VaultFormOptions_vaultEnvironment; 
  readonly onStateChange?: (_1:VaultPublicState_cvcState) => void; 
  readonly paymentMethodToken: string; 
  readonly session: VaultFormOptions_vaultSession; 
  readonly vaultEndpoint?: VaultEndpoint_vaultEndpointConfig
}> = HyperswitchVaultSavedCardFormJS.make as any;
