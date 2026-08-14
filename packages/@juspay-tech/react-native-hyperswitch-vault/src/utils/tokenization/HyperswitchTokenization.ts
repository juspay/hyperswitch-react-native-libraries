import { HyperswitchTokenizationConfigurationType } from '../../components/HyperswitchInputType';
import {
  HyperswitchVaultAliasFormat,
  HyperswitchVaultStorageType,
} from './TokenizationConfiguration';

/**
 * HyperswitchTokenizationConfiguration
 *
 * Public namespace exposing tokenization presets and enums.
 * Use `presets` for per-type defaults, `storage` and `aliasFormat` for policies.
 */
export default class HyperswitchTokenizationConfiguration {
  /**
   * Default tokenization configuration per field type.
   */
  static presets: typeof HyperswitchTokenizationConfigurationType =
    HyperswitchTokenizationConfigurationType;

  /**
   * Enum for storage policies.
   */
  static storage: typeof HyperswitchVaultStorageType =
    HyperswitchVaultStorageType;

  /**
   * Enum for alias formats.
   */
  static aliasFormat: typeof HyperswitchVaultAliasFormat =
    HyperswitchVaultAliasFormat;
}
