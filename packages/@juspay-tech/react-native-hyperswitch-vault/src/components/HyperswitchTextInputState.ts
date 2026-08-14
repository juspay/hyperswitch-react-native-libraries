import type { HyperswitchInputType } from './HyperswitchInputType';
type CardState = {
  type: 'card';
  cardBin?: string;
  last4?: string;
  cardBrand?: string;
};
type SsnState = { type: 'ssn'; last4?: string };
type DefaultState = { type: HyperswitchInputType };
type ExtraState = CardState | SsnState | DefaultState;

/**
 * State emitted by `HyperswitchTextInput` components.
 * Captures validation, focus, and input metadata.
 */
export type HyperswitchTextInputState = ExtraState & {
  isValid: boolean;
  isEmpty: boolean;
  isDirty: boolean;
  isFocused: boolean;
  inputLength: number;
  validationErrors: string[];
  fieldName: string;
};
