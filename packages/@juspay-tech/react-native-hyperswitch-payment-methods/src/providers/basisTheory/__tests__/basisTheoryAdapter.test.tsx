import { createRef } from 'react';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

jest.mock(
  '@basis-theory/react-native-elements',
  () => {
    const React = require('react');
    const { Text } = require('react-native');
    const bt = {
      tokens: { create: jest.fn(async () => ({ id: 'tok_bt_123' })) },
    };
    const useBasisTheory = () => ({ bt });
    const BasisTheoryProvider = ({ children }: { children: React.ReactNode }) =>
      React.createElement(React.Fragment, null, children);
    const element =
      (name: string) => (props: { onChange?: (event: unknown) => void }) => {
        React.useEffect(() => {
          props.onChange?.({
            empty: false,
            valid: true,
            errors: [],
            brand: 'visa',
          });
        }, [props]);
        return React.createElement(Text, { testID: `bt-${name}` }, name);
      };
    return {
      __esModule: true,
      useBasisTheory,
      BasisTheoryProvider,
      CardNumberElement: element('number'),
      CardExpirationDateElement: element('expiry'),
      CardVerificationCodeElement: element('cvc'),
      TextElement: element('holder'),
      __bt: bt,
    };
  },
  { virtual: true }
);

import { HyperswitchForm } from '../../../core/HyperswitchForm';
import {
  CardNumberWidget,
  CardExpiryWidget,
  CardCVCWidget,
  CardHolderWidget,
} from '../../../widgets';
import { basisTheoryAdapter } from '../adapter';
import type {
  HyperswitchFormHandle,
  ProviderConfig,
  SubmitResult,
} from '../../../core/types';

const btConfig: ProviderConfig = {
  vault_type: 'basis_theory',
  vault_data: { api_key: 'key_test' },
};

function fakeCollector(createImpl: () => Promise<unknown>): {
  collector: unknown;
  create: jest.Mock;
} {
  const create = jest.fn(createImpl);
  const refs = {
    card_number: { current: { id: 'n' } },
    card_expiry: {
      current: {
        month: () => ({ datepart: 'month' }),
        year: () => ({ datepart: 'year' }),
      },
    },
    card_cvc: { current: { id: 'c' } },
    card_holder: { current: { id: 'h' } },
  };
  return { collector: { bt: { tokens: { create } }, refs }, create };
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('basisTheoryAdapter', () => {
  it('renders a BT element per widget and creates a card token on submit', async () => {
    const ref = createRef<HyperswitchFormHandle>();
    render(
      <HyperswitchForm ref={ref} config={btConfig}>
        <CardNumberWidget />
        <CardExpiryWidget />
        <CardCVCWidget />
        <CardHolderWidget />
      </HyperswitchForm>
    );

    await waitFor(() => expect(screen.getByTestId('bt-number')).toBeTruthy());
    expect(screen.getByTestId('bt-expiry')).toBeTruthy();
    expect(screen.getByTestId('bt-cvc')).toBeTruthy();
    expect(screen.getByTestId('bt-holder')).toBeTruthy();

    let result: SubmitResult | undefined;
    await act(async () => {
      result = await ref.current!.submit();
    });
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('basis_theory');

    const mod = require('@basis-theory/react-native-elements');
    expect(mod.__bt.tokens.create).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'card' }),
      undefined
    );
  });

  it('maps Basis Theory element events to the widget onStateChange', async () => {
    const onStateChange = jest.fn();
    render(
      <HyperswitchForm config={btConfig}>
        <CardNumberWidget onStateChange={onStateChange} />
      </HyperswitchForm>
    );
    await waitFor(() => expect(screen.getByTestId('bt-number')).toBeTruthy());

    const state = onStateChange.mock.calls.at(-1)?.[0] as {
      kind: string;
      isValid: boolean;
      brand?: string;
    };
    expect(state.kind).toBe('card_number');
    expect(state.isValid).toBe(true);
    expect(state.brand).toBe('visa');
  });

  describe('validateVaultData', () => {
    it('accepts a config with an api_key', () => {
      expect(() =>
        basisTheoryAdapter.validateVaultData({ api_key: 'key' })
      ).not.toThrow();
    });

    it('throws when api_key is missing', () => {
      expect(() => basisTheoryAdapter.validateVaultData({})).toThrow(
        /api_key/i
      );
    });
  });

  describe('submit', () => {
    it('builds a card token from the field refs and returns the token id', async () => {
      const { collector, create } = fakeCollector(async () => ({
        id: 'tok_bt_999',
      }));
      const result = await basisTheoryAdapter.submit(collector);

      expect(create).toHaveBeenCalledTimes(1);
      const [payload] = create.mock.calls[0] as [
        { type: string; data: Record<string, unknown> }
      ];
      expect(payload.type).toBe('card');
      expect(payload.data.number).toEqual({ id: 'n' });
      expect(payload.data.expiration_month).toEqual({ datepart: 'month' });
      expect(result.status).toBe('success');
      expect(result.data?.raw).toEqual({ id: 'tok_bt_999' });
    });

    it('maps a rejected token create to an error result', async () => {
      const { collector } = fakeCollector(async () => {
        throw new Error('tokenization failed');
      });
      const result = await basisTheoryAdapter.submit(collector);
      expect(result.status).toBe('error');
      expect(result.errors?.[0]?.message).toMatch(/tokenization failed/);
    });
  });
});
