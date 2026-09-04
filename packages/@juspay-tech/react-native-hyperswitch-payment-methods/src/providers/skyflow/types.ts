import type { ElementType } from '../../core/types';

/** `vaultDetails.vaultData` for Skyflow, in the web's camelCase. */
export interface SkyflowVaultData {
  vaultId: string;
  vaultUrl: string;
  table: string;
  bearerToken?: string;
  /** Column per field; defaults to `card_number`, `card_expiration`, `cvv`, `cardholder_name`. */
  columns?: Partial<Record<ElementType, string>>;
  options?: Record<string, unknown>;
}

/** `tokenize(providerData)` for Skyflow. */
export interface SkyflowTokenizeOptions {
  tokens?: boolean;
}
