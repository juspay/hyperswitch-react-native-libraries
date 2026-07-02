import { Fragment, useEffect } from 'react';
import { Text } from 'react-native';
import type {
  ProviderAdapter,
  ProviderFieldProps,
  ProviderHostProps,
} from '../core/ProviderAdapter';
import type { SubmitResult, VaultType } from '../core/types';

export interface MockAdapterOptions {
  vaultType?: VaultType;

  readyDelayMs?: number;

  neverReady?: boolean;

  failOnInit?: unknown;

  submitResult?: SubmitResult;
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

  function Field({ kind }: ProviderFieldProps) {
    return <Text testID={`mock-field-${kind}`}>{`mock:${kind}`}</Text>;
  }

  return {
    vaultType,
    validateVaultData: (raw) => raw,
    Host,
    Field,
    submit: async () =>
      options.submitResult ?? {
        status: 'success',
        vaultType,
        data: { tokens: { card_number: 'tok_mock' } },
      },
  };
}
