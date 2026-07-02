import { createRef } from 'react';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

jest.mock(
  'skyflow-react-native',
  () => {
    const React = require('react');
    const { Text } = require('react-native');
    const container = {
      collect: jest.fn(async () => ({
        records: [{ table: 'cards', fields: { card_number: 'tok_sky' } }],
      })),
    };
    const SkyflowProvider = ({ children }: { children: React.ReactNode }) =>
      React.createElement(React.Fragment, null, children);
    const useCollectContainer = () => container;
    const element =
      (name: string) =>
      (props: { column: string; onChange?: (state: unknown) => void }) => {
        React.useEffect(() => {
          props.onChange?.({
            isValid: true,
            isEmpty: false,
            isFocused: false,
            selectedCardScheme: 'VISA',
          });
        }, [props]);
        return React.createElement(
          Text,
          { testID: `skyflow-${name}-${props.column}` },
          name
        );
      };
    return {
      __esModule: true,
      SkyflowProvider,
      useCollectContainer,
      CardNumberElement: element('number'),
      ExpirationDateElement: element('expiry'),
      CvvElement: element('cvv'),
      CardHolderNameElement: element('holder'),
      __container: container,
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
import { skyflowAdapter } from '../adapter';
import type {
  FieldKind,
  HyperswitchFormHandle,
  ProviderConfig,
  SubmitResult,
} from '../../../core/types';

const skyflowConfig: ProviderConfig = {
  vault_type: 'skyflow',
  vault_data: {
    vault_id: 'v123',
    vault_url: 'https://vault.skyflow.test',
    table: 'cards',
    bearer_token: 'tok_bearer',
  },
};

const columns: Record<FieldKind, string> = {
  card_number: 'card_number',
  card_expiry: 'card_expiration',
  card_cvc: 'cvv',
  card_holder: 'cardholder_name',
};

function fakeCollector(collectImpl: () => Promise<unknown>): {
  collector: unknown;
  collect: jest.Mock;
} {
  const collect = jest.fn(collectImpl);
  return {
    collector: { container: { collect }, table: 'cards', columns },
    collect,
  };
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('skyflowAdapter', () => {
  it('renders a Skyflow element per widget (via the hook bridge) and submits', async () => {
    const ref = createRef<HyperswitchFormHandle>();
    render(
      <HyperswitchForm ref={ref} config={skyflowConfig}>
        <CardNumberWidget />
        <CardExpiryWidget />
        <CardCVCWidget />
        <CardHolderWidget />
      </HyperswitchForm>
    );

    await waitFor(() =>
      expect(screen.getByTestId('skyflow-number-card_number')).toBeTruthy()
    );
    expect(screen.getByTestId('skyflow-expiry-card_expiration')).toBeTruthy();
    expect(screen.getByTestId('skyflow-cvv-cvv')).toBeTruthy();
    expect(screen.getByTestId('skyflow-holder-cardholder_name')).toBeTruthy();

    let result: SubmitResult | undefined;
    await act(async () => {
      result = await ref.current!.submit();
    });
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('skyflow');

    const skyflow = require('skyflow-react-native');
    expect(skyflow.__container.collect).toHaveBeenCalledWith({ tokens: true });
  });

  it('maps Skyflow element state to the widget onStateChange', async () => {
    const onStateChange = jest.fn();
    render(
      <HyperswitchForm config={skyflowConfig}>
        <CardNumberWidget onStateChange={onStateChange} />
      </HyperswitchForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('skyflow-number-card_number')).toBeTruthy()
    );

    const state = onStateChange.mock.calls.at(-1)?.[0] as {
      kind: string;
      isValid: boolean;
      brand?: string;
    };
    expect(state.kind).toBe('card_number');
    expect(state.isValid).toBe(true);
    expect(state.brand).toBe('VISA');
  });

  describe('validateVaultData', () => {
    it('accepts a complete config', () => {
      expect(() =>
        skyflowAdapter.validateVaultData({
          vault_id: 'v',
          vault_url: 'https://x',
          table: 'cards',
        })
      ).not.toThrow();
    });

    it('throws when vault_url is missing', () => {
      expect(() =>
        skyflowAdapter.validateVaultData({ vault_id: 'v', table: 'cards' })
      ).toThrow(/vault_url/i);
    });
  });

  describe('submit', () => {
    it('collects with tokens and extracts tokens from records', async () => {
      const { collector, collect } = fakeCollector(async () => ({
        records: [{ table: 'cards', fields: { card_number: 'tok_1' } }],
      }));
      const result = await skyflowAdapter.submit(collector);
      expect(collect).toHaveBeenCalledWith({ tokens: true });
      expect(result.status).toBe('success');
      expect(result.data?.tokens).toEqual({ card_number: 'tok_1' });
    });

    it('maps a rejected collect to an error result', async () => {
      const { collector } = fakeCollector(async () => {
        throw new Error('collect failed');
      });
      const result = await skyflowAdapter.submit(collector);
      expect(result.status).toBe('error');
      expect(result.errors?.[0]?.message).toMatch(/collect failed/);
    });
  });
});
