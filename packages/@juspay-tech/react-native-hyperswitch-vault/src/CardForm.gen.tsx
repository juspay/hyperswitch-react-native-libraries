/* TypeScript file generated from CardForm.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as React from 'react';

import * as CardFormJS from './CardForm.bs.js';

import type {appearance as VaultFormOptions_appearance} from './VaultFormOptions.gen';

import type {cardholderNameMode as CardFieldOptions_cardholderNameMode} from './CardFieldOptions.gen';

import type {eligibilityConfig as VaultFormOptions_eligibilityConfig} from './VaultFormOptions.gen';

import type {localisation as VaultFormOptions_localisation} from './VaultFormOptions.gen';

import type {vaultEndpointConfig as VaultEndpoint_vaultEndpointConfig} from './VaultEndpoint.gen';

import type {vaultEnvironment as VaultFormOptions_vaultEnvironment} from './VaultFormOptions.gen';

import type {vaultFormState as VaultPublicState_vaultFormState} from './VaultPublicState.gen';

import type {vaultSession as VaultFormOptions_vaultSession} from './VaultFormOptions.gen';

export type widgetHandle = { readonly focus: () => void; readonly blur: () => void };

export type Props = {
  readonly accessible?: boolean; 
  readonly appearance?: VaultFormOptions_appearance; 
  readonly cardholderName?: CardFieldOptions_cardholderNameMode; 
  readonly children: React.ReactNode; 
  readonly disabled?: boolean; 
  readonly eligibility?: VaultFormOptions_eligibilityConfig; 
  readonly enabledCardSchemes?: string[]; 
  readonly environment: VaultFormOptions_vaultEnvironment; 
  readonly localisation?: VaultFormOptions_localisation; 
  readonly onFormStateChange?: (_1:VaultPublicState_vaultFormState) => void; 
  readonly session?: VaultFormOptions_vaultSession; 
  readonly unstyled?: boolean; 
  readonly vaultEndpoint?: VaultEndpoint_vaultEndpointConfig
};

export const make: React.ComponentType<{
  readonly accessible?: boolean; 
  readonly appearance?: VaultFormOptions_appearance; 
  readonly cardholderName?: CardFieldOptions_cardholderNameMode; 
  readonly children: React.ReactNode; 
  readonly disabled?: boolean; 
  readonly eligibility?: VaultFormOptions_eligibilityConfig; 
  readonly enabledCardSchemes?: string[]; 
  readonly environment: VaultFormOptions_vaultEnvironment; 
  readonly localisation?: VaultFormOptions_localisation; 
  readonly onFormStateChange?: (_1:VaultPublicState_vaultFormState) => void; 
  readonly session?: VaultFormOptions_vaultSession; 
  readonly unstyled?: boolean; 
  readonly vaultEndpoint?: VaultEndpoint_vaultEndpointConfig
}> = CardFormJS.make as any;
