import { HyperswitchVaultErrorCode } from './HyperswitchVaultErrorCodes';

/** Class representing an error in the Hyperswitch Vault SDK. */
export class HyperswitchVaultError extends Error {
  code: HyperswitchVaultErrorCode;
  details?: any;

  constructor(code: HyperswitchVaultErrorCode, message: string, details?: any) {
    super(message);
    this.code = code;
    this.details = details;
  }
}
