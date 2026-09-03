/* TypeScript file generated from CardCVCWidget.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as React from 'react';

import * as CardCVCWidgetJS from './CardCVCWidget.bs.js';

import type {cvcIconDisplay as CardFieldOptions_cvcIconDisplay} from './CardFieldOptions.gen';

import type {cvcState as VaultPublicState_cvcState} from './VaultPublicState.gen';

import type {errorDisplay as CardFieldOptions_errorDisplay} from './CardFieldOptions.gen';

import type {fieldStyles as CardFieldStyles_fieldStyles} from './CardFieldStyles.gen';

import type {labelBehavior as CardFieldOptions_labelBehavior} from './CardFieldOptions.gen';

export type Props = {
  readonly accessibilityHint?: string; 
  readonly accessibilityLabel?: string; 
  readonly children?: React.ReactNode; 
  readonly cvcIcon?: CardFieldOptions_cvcIconDisplay; 
  readonly errorDisplay?: CardFieldOptions_errorDisplay; 
  readonly label?: string; 
  readonly labelBehavior?: CardFieldOptions_labelBehavior; 
  readonly onStateChange?: (_1:VaultPublicState_cvcState) => void; 
  readonly placeholder?: string; 
  readonly styles?: CardFieldStyles_fieldStyles; 
  readonly testID?: string; 
  readonly unstyled?: boolean
};

export const make: React.ComponentType<{
  readonly accessibilityHint?: string; 
  readonly accessibilityLabel?: string; 
  readonly children?: React.ReactNode; 
  readonly cvcIcon?: CardFieldOptions_cvcIconDisplay; 
  readonly errorDisplay?: CardFieldOptions_errorDisplay; 
  readonly label?: string; 
  readonly labelBehavior?: CardFieldOptions_labelBehavior; 
  readonly onStateChange?: (_1:VaultPublicState_cvcState) => void; 
  readonly placeholder?: string; 
  readonly styles?: CardFieldStyles_fieldStyles; 
  readonly testID?: string; 
  readonly unstyled?: boolean
}> = CardCVCWidgetJS.make as any;
