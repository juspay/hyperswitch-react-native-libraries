import { Fragment, useEffect } from 'react';
import { Text } from 'react-native';
import { fieldChange } from '../core/fieldChange';
import type { FieldChangeInput } from '../core/fieldChange';
import type {
  ProviderAdapter,
  ProviderFieldProps,
  ProviderHostProps,
} from '../core/ProviderAdapter';
import type { CardDetails, TokenizeResult, VaultType } from '../core/types';

export interface MockAdapterOptions {
  vaultType?: VaultType;

  readyDelayMs?: number;

  neverReady?: boolean;

  failOnInit?: unknown;

  tokenizeResult?: TokenizeResult;

  /** What every mock field reports on mount, through `onChange`. */
  fieldState?: FieldChangeInput;

  /** What the mock host reports about the card, as Evervault's host does. */
  cardDetails?: Partial<CardDetails>;
}

export function createMockAdapter(
  options: MockAdapterOptions = {}
): ProviderAdapter {
  const vaultType: VaultType = options.vaultType ?? 'vgs';

  function Host({
    onReady,
    onError,
    onCardDetails,
    children,
  }: ProviderHostProps) {
    useEffect(() => {
      if (options.failOnInit !== undefined) {
        onError(options.failOnInit);
        return;
      }
      if (options.neverReady) return;

      const delay = options.readyDelayMs ?? 0;
      const timer = setTimeout(() => {
        onReady({ mock: true });
        if (options.cardDetails) onCardDetails?.(options.cardDetails);
      }, delay);
      return () => clearTimeout(timer);
    }, [onReady, onError, onCardDetails]);

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
