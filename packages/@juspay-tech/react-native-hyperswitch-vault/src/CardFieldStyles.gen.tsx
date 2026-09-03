/* TypeScript file generated from CardFieldStyles.res by genType. */

/* eslint-disable */
/* tslint:disable */

import type {VaultTextStyleProp as $$textStyleProp} from './styleTypes';

import type {VaultViewStyleProp as $$viewStyleProp} from './styleTypes';

export type viewStyleProp = $$viewStyleProp;

export type textStyleProp = $$textStyleProp;

export type fieldStyles = {
  readonly root?: viewStyleProp; 
  readonly container?: viewStyleProp; 
  readonly input?: textStyleProp; 
  readonly placeholder?: textStyleProp; 
  readonly label?: textStyleProp; 
  readonly error?: textStyleProp; 
  readonly accessory?: viewStyleProp
};

export type expiryStyles = {
  readonly root?: viewStyleProp; 
  readonly container?: viewStyleProp; 
  readonly input?: textStyleProp; 
  readonly placeholder?: textStyleProp; 
  readonly label?: textStyleProp; 
  readonly error?: textStyleProp
};

export type formFieldStyles = {
  readonly cardNumber?: fieldStyles; 
  readonly expiry?: expiryStyles; 
  readonly cvc?: fieldStyles; 
  readonly cardholderName?: fieldStyles
};
