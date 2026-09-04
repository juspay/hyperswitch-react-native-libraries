import type {
  TokenizeErrorCode,
  TokenizeErrorType,
  TokenizeResult,
  VaultType,
} from './types';

/** The web's classification: the two field-level codes are validation errors, the rest API errors. */
export function errorTypeFor(code: TokenizeErrorCode): TokenizeErrorType {
  return code === 'validation_error' || code === 'incomplete_field_set'
    ? 'validation_error'
    : 'api_error';
}

export function errorResult(
  vaultType: VaultType | undefined,
  code: TokenizeErrorCode,
  message: string
): TokenizeResult {
  const type = errorTypeFor(code);
  return {
    status: type === 'validation_error' ? 'validation_error' : 'error',
    vaultType,
    error: { code, message, type },
  };
}

export function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
