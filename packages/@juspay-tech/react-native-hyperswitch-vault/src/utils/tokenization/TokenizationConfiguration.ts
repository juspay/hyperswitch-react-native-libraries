import type { HyperswitchInputType } from '../../components/HyperswitchInputType';
/**
 * Tokenization configuration for a field.
 * Provides `storage` policy and alias `format`.
 */
export interface HyperswitchTokenizationConfiguration {
  storage?: HyperswitchVaultStorageType; // Add vault storage type
  format?: HyperswitchVaultAliasFormat; // Add alias format
}

/** Enum for VaultStorageType. */
export enum HyperswitchVaultStorageType {
  PERSISTENT = 'PERSISTENT',
  VOLATILE = 'VOLATILE',
}

/** Enum for VaultAliasFormat. */
export enum HyperswitchVaultAliasFormat {
  FPE_ACC_NUM_T_FOUR = 'FPE_ACC_NUM_T_FOUR',
  FPE_ALPHANUMERIC_ACC_NUM_T_FOUR = 'FPE_ALPHANUMERIC_ACC_NUM_T_FOUR',
  FPE_SIX_T_FOUR = 'FPE_SIX_T_FOUR',
  FPE_SSN_T_FOUR = 'FPE_SSN_T_FOUR',
  FPE_T_FOUR = 'FPE_T_FOUR',
  NUM_LENGTH_PRESERVING = 'NUM_LENGTH_PRESERVING',
  PFPT = 'PFPT',
  RAW_UUID = 'RAW_UUID',
  UUID = 'UUID',
  GENERIC_T_FOUR = 'GENERIC_T_FOUR',
  ALPHANUMERIC_SIX_T_FOUR = 'ALPHANUMERIC_SIX_T_FOUR',
  ALPHANUMERIC_LENGTH_PRESERVING = 'ALPHANUMERIC_LENGTH_PRESERVING',
  ALPHANUMERIC_LENGTH_PRESERVING_T_FOUR = 'ALPHANUMERIC_LENGTH_PRESERVING_T_FOUR',
  ALPHANUMERIC_SSN_T_FOUR = 'ALPHANUMERIC_SSN_T_FOUR',
  ALPHANUMERIC_LENGTH_PRESERVING_SIX_T_FOUR = 'ALPHANUMERIC_LENGTH_PRESERVING_SIX_T_FOUR',
}

/**
 * Validates tokenization config per input `type`.
 * Ensures `cvc` uses VOLATILE and `card` uses PERSISTENT storage policies.
 *
 * @param value - `false` to disable or a config object.
 * @param inputType - Field type to validate against.
 * @returns Original config when valid, or `false` when invalid.
 */
export function tokenizationConfigValidation(
  value: false | HyperswitchTokenizationConfiguration,
  inputType: HyperswitchInputType
): HyperswitchTokenizationConfiguration | false {
  if (
    typeof value === 'object' &&
    value !== null &&
    'storage' in value &&
    'format' in value
  ) {
    if (
      inputType === 'cvc' &&
      value.storage !== HyperswitchVaultStorageType.VOLATILE
    ) {
      return false;
    } else if (
      inputType === 'card' &&
      value.storage !== HyperswitchVaultStorageType.PERSISTENT
    ) {
      return false;
    }
    return value;
  }
  return value;
}
