/* TypeScript file generated from CardFieldOptions.res by genType. */

/* eslint-disable */
/* tslint:disable */

import type {brandIconMode as CardIcons_brandIconMode} from './CardIcons.gen';

export type labelBehavior = "none" | "static" | "floating";

export type errorDisplay = "none" | "inline";

export type brandIconMode = CardIcons_brandIconMode;

export type cvcIconDisplay = "none" | "default";

export type fieldOptions = {
  readonly placeholder?: string; 
  readonly label?: string; 
  readonly labelBehavior?: labelBehavior; 
  readonly errorDisplay?: errorDisplay; 
  readonly accessibilityLabel?: string; 
  readonly accessibilityHint?: string; 
  readonly testID?: string; 
  readonly unstyled?: boolean
};

export type cardNumberOptions = {
  readonly placeholder?: string; 
  readonly label?: string; 
  readonly labelBehavior?: labelBehavior; 
  readonly errorDisplay?: errorDisplay; 
  readonly accessibilityLabel?: string; 
  readonly accessibilityHint?: string; 
  readonly testID?: string; 
  readonly unstyled?: boolean; 
  readonly brandIconMode?: brandIconMode
};

export type expiryOptions = fieldOptions;

export type cardholderNameOptions = fieldOptions;

export type cvcOptions = {
  readonly placeholder?: string; 
  readonly label?: string; 
  readonly labelBehavior?: labelBehavior; 
  readonly errorDisplay?: errorDisplay; 
  readonly accessibilityLabel?: string; 
  readonly accessibilityHint?: string; 
  readonly testID?: string; 
  readonly unstyled?: boolean; 
  readonly cvcIcon?: cvcIconDisplay
};

export type formFieldOptions = {
  readonly cardNumber?: cardNumberOptions; 
  readonly expiry?: expiryOptions; 
  readonly cvc?: cvcOptions; 
  readonly cardholderName?: cardholderNameOptions
};

export type cardholderNameMode = "collect" | "external" | "omit";

export type formLayout = "stacked" | "inline";

export type fieldArrangement = "separate" | "fused";
