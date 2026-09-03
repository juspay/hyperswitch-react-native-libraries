/* TypeScript file generated from CardExpiryWidget.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as React from 'react';

import * as CardExpiryWidgetJS from './CardExpiryWidget.bs.js';

import type {errorDisplay as CardFieldOptions_errorDisplay} from './CardFieldOptions.gen';

import type {expiryState as VaultPublicState_expiryState} from './VaultPublicState.gen';

import type {expiryStyles as CardFieldStyles_expiryStyles} from './CardFieldStyles.gen';

import type {labelBehavior as CardFieldOptions_labelBehavior} from './CardFieldOptions.gen';

export type Props = {
  readonly accessibilityHint?: string; 
  readonly accessibilityLabel?: string; 
  readonly children?: React.ReactNode; 
  readonly errorDisplay?: CardFieldOptions_errorDisplay; 
  readonly label?: string; 
  readonly labelBehavior?: CardFieldOptions_labelBehavior; 
  readonly onStateChange?: (_1:VaultPublicState_expiryState) => void; 
  readonly placeholder?: string; 
  readonly styles?: CardFieldStyles_expiryStyles; 
  readonly testID?: string; 
  readonly unstyled?: boolean
};

export const make: React.ComponentType<{
  readonly accessibilityHint?: string; 
  readonly accessibilityLabel?: string; 
  readonly children?: React.ReactNode; 
  readonly errorDisplay?: CardFieldOptions_errorDisplay; 
  readonly label?: string; 
  readonly labelBehavior?: CardFieldOptions_labelBehavior; 
  readonly onStateChange?: (_1:VaultPublicState_expiryState) => void; 
  readonly placeholder?: string; 
  readonly styles?: CardFieldStyles_expiryStyles; 
  readonly testID?: string; 
  readonly unstyled?: boolean
}> = CardExpiryWidgetJS.make as any;
