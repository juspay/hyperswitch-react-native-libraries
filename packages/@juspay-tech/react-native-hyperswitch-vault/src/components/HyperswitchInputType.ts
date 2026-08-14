import { DEFAULT_CARD_MASK_19 } from '../utils/paymentCards/PaymentCardBrand';
import type { HyperswitchTokenizationConfiguration } from '../utils/tokenization/TokenizationConfiguration';
import { PatternRule, PaymentCardRule, LengthRule } from '../utils/validators';
import {
  HyperswitchVaultStorageType,
  HyperswitchVaultAliasFormat,
} from '../utils/tokenization/TokenizationConfiguration';
import { CardExpDateRule } from '../utils/validators/CardExpDateRule';
import { ValidationRule } from '../utils/validators/Validator';

/**
 * Supported input types for `HyperswitchTextInput` components.
 */
export type HyperswitchInputType =
  'text' | 'card' | 'cardHolderName' | 'expDate' | 'date' | 'cvc' | 'ssn';

/**
 * Predefined defaults per input `type`.
 * Includes mask, keyboard type, and validation rules.
 * Consumers can override via `HyperswitchTextInput` props.
 */
export const inputTypeDefaults: Record<
  HyperswitchInputType,
  {
    mask?: string;
    keyboardType?: 'default' | 'email-address' | 'numeric' | 'phone-pad';
    validationRules?: ValidationRule[];
  }
> = {
  // For standard text input (no custom config)
  text: {
    mask: undefined,
    keyboardType: 'default',
    validationRules: [],
  },

  cardHolderName: {
    mask: undefined,
    keyboardType: 'default',
    // Basic pattern check: "Invalid cardholder name"
    validationRules: [
      new PatternRule(
        "^([a-zA-Z0-9\\ \\,\\.\\-\\']{2,})$",
        'INVALID_CARDHOLDER_NAME'
      ),
    ],
  },

  card: {
    mask: DEFAULT_CARD_MASK_19,
    keyboardType: 'numeric',
    validationRules: [new PaymentCardRule('INVALID_CARD_NUMBER', false)],
  },

  cvc: {
    mask: '###',
    keyboardType: 'numeric',
    validationRules: [
      new PatternRule('\\d*$', 'INVALID_CVC'),
      new LengthRule(3, 3, 'INVALID_CVC_LEHGTH'),
    ],
  },

  expDate: {
    mask: '##/##', // e.g., "MM/YY
    keyboardType: 'numeric',
    validationRules: [new CardExpDateRule('mmyy', 'INVALID_EXP_DATE')],
  },

  date: {
    mask: '##-##-####', // e.g., "MM-DD-YYYY"
    keyboardType: 'numeric',
  },

  ssn: {
    mask: '###-##-####',
    keyboardType: 'numeric',
    validationRules: [
      new PatternRule(
        '^(?!000|666|9\\d{2})\\d{3}(-|\\s)?(?!00)\\d{2}(-|\\s)?(?!0000)\\d{4}$',
        'INVALID_SSN'
      ),
    ],
  },
};

// Default TokenizationConfig for each field type
export const HyperswitchTokenizationConfigurationType: Record<
  HyperswitchInputType,
  HyperswitchTokenizationConfiguration
> = {
  text: {
    storage: HyperswitchVaultStorageType.PERSISTENT,
    format: HyperswitchVaultAliasFormat.UUID,
  },
  card: {
    storage: HyperswitchVaultStorageType.PERSISTENT,
    format: HyperswitchVaultAliasFormat.FPE_ACC_NUM_T_FOUR,
  },
  cvc: {
    storage: HyperswitchVaultStorageType.VOLATILE,
    format: HyperswitchVaultAliasFormat.NUM_LENGTH_PRESERVING,
  },
  expDate: {
    storage: HyperswitchVaultStorageType.PERSISTENT,
    format: HyperswitchVaultAliasFormat.UUID,
  },
  date: {
    storage: HyperswitchVaultStorageType.PERSISTENT,
    format: HyperswitchVaultAliasFormat.UUID,
  },
  ssn: {
    storage: HyperswitchVaultStorageType.PERSISTENT,
    format: HyperswitchVaultAliasFormat.FPE_SSN_T_FOUR,
  },
  cardHolderName: {
    storage: HyperswitchVaultStorageType.PERSISTENT,
    format: HyperswitchVaultAliasFormat.UUID,
  },
};

// String mapping used for analytics events
export function getTypeAnalyticsString(
  inputType: HyperswitchInputType
): string {
  switch (inputType) {
    case 'card':
      return 'card-number';
    case 'cardHolderName':
      return 'card-holder-name';
    case 'expDate':
      return 'card-expiration-date';
    case 'cvc':
      return 'card-security-code';
    case 'ssn':
      return 'ssn';
    case 'text':
      return 'text';
    default:
      return 'text';
  }
}
