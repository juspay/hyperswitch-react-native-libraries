/* TypeScript file generated from CardNumberWidget.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as React from 'react';

import * as CardNumberWidgetJS from './CardNumberWidget.bs.js';

import type {brandIconMode as CardFieldOptions_brandIconMode} from './CardFieldOptions.gen';

import type {cardNumberState as VaultPublicState_cardNumberState} from './VaultPublicState.gen';

import type {errorDisplay as CardFieldOptions_errorDisplay} from './CardFieldOptions.gen';

import type {fieldStyles as CardFieldStyles_fieldStyles} from './CardFieldStyles.gen';

import type {labelBehavior as CardFieldOptions_labelBehavior} from './CardFieldOptions.gen';

export type Props = {
  readonly accessibilityHint?: string; 
  readonly accessibilityLabel?: string; 
  readonly brandIconMode?: CardFieldOptions_brandIconMode; 
  readonly children?: React.ReactNode; 
  readonly errorDisplay?: CardFieldOptions_errorDisplay; 
  readonly label?: string; 
  readonly labelBehavior?: CardFieldOptions_labelBehavior; 
  readonly onStateChange?: (_1:VaultPublicState_cardNumberState) => void; 
  readonly placeholder?: string; 
  readonly styles?: CardFieldStyles_fieldStyles; 
  readonly testID?: string; 
  readonly unstyled?: boolean
};

export const make: React.ComponentType<{
  readonly accessibilityHint?: string; 
  readonly accessibilityLabel?: string; 
  readonly brandIconMode?: CardFieldOptions_brandIconMode; 
  readonly children?: React.ReactNode; 
  readonly errorDisplay?: CardFieldOptions_errorDisplay; 
  readonly label?: string; 
  readonly labelBehavior?: CardFieldOptions_labelBehavior; 
  readonly onStateChange?: (_1:VaultPublicState_cardNumberState) => void; 
  readonly placeholder?: string; 
  readonly styles?: CardFieldStyles_fieldStyles; 
  readonly testID?: string; 
  readonly unstyled?: boolean
}> = CardNumberWidgetJS.make as any;
