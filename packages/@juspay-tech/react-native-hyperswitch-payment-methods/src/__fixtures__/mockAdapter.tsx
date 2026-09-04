import { Fragment, useEffect } from 'react';
import { Text } from 'react-native';
import { fieldChange } from '../core/fieldChange';
import type { FieldChangeInput } from '../core/fieldChange';
import type {
  ProviderAdapter,
  ProviderFieldProps,
  ProviderHostProps,
} from '../core/ProviderAdapter';
import type { TokenizeResult, VaultType } from '../core/types';

export interface MockAdapterOptions {
  vaultType?: VaultType;

  readyDelayMs?: number;

  neverReady?: boolean;

  failOnInit?: unknown;

  tokenizeResult?: TokenizeResult;

  /** What every mock field reports on mount, through `onChange`. */
  fieldState?: FieldChangeInput;
}

export function createMockAdapter(
  options: MockAdapterOptions = {}
): ProviderAdapter {
  const vaultType: VaultType = options.vaultType ?? 'vgs';

  function Host({ onReady, onError, children }: ProviderHostProps) {
    useEffect(() => {
      if (options.failOnInit !== undefined) {
        onError(options.failOnInit);
        return;
      }
      if (options.neverReady) return;

      const delay = options.readyDelayMs ?? 0;
      const timer = setTimeout(() => onReady({ mock: true }), delay);
      return () => clearTimeout(timer);
    }, [onReady, onError]);

    return <Fragment>{children}</Fragment>;
  }

  function Field({ elementType, onChange }: ProviderFieldProps) {
    const state = options.fieldState;
    useEffect(() => {
      if (state) onChange?.(fieldChange(elementType, state));
    }, [elementType, onChange, state]);
    return (
      <Text testID={`mock-field-${elementType}`}>{`mock:${elementType}`}</Text>
    );
  }

  return {
    vaultType,
    validateVaultData: (raw) => raw,
    Host,
    Field,
    tokenize: async () =>
      options.tokenizeResult ?? {
        status: 'success',
        vaultType,
        data: { tokens: { card_number: 'tok_mock' } },
      },
  };
}
