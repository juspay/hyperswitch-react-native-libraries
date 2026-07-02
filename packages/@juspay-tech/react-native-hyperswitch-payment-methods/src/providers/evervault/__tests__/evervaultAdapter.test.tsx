import { createRef } from 'react';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

jest.mock(
  '@evervault/react-native',
  () => {
    const React = require('react');
    const { Text } = require('react-native');
    const state: { onChange?: (payload: unknown) => void } = {};
    const Card = ({
      onChange,
      children,
    }: {
      onChange?: (payload: unknown) => void;
      children: React.ReactNode;
    }) => {
      state.onChange = onChange;
      return React.createElement(React.Fragment, null, children);
    };
    const EvervaultProvider = ({ children }: { children: React.ReactNode }) =>
      React.createElement(React.Fragment, null, children);
    const field = (name: string) => () =>
      React.createElement(Text, { testID: `ev-${name}` }, name);
    return {
      __esModule: true,
      EvervaultProvider,
      useEvervault: () => ({}),
      Card,
      CardNumber: field('number'),
      CardExpiry: field('expiry'),
      CardCvc: field('cvc'),
      CardHolder: field('holder'),
      __emit: (payload: unknown) => state.onChange?.(payload),
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
import { evervaultAdapter } from '../adapter';
import type {
  HyperswitchFormHandle,
  ProviderConfig,
  SubmitResult,
} from '../../../core/types';

const evervaultConfig: ProviderConfig = {
  vault_type: 'evervault',
  vault_data: { team_id: 'team_1', app_id: 'app_1' },
};

const completePayload = {
  card: {
    name: 'enc_name',
    brand: 'visa',
    localBrands: [],
    number: 'enc_number',
    lastFour: '4242',
    bin: '424242',
    expiry: { month: '12', year: '30' },
    cvc: 'enc_cvc',
  },
  isValid: true,
  isComplete: true,
  errors: {},
};

function fakeCollector(payload: unknown): unknown {
  return { getPayload: () => payload };
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('evervaultAdapter', () => {
  it('renders an Evervault field per widget and returns the encrypted payload', async () => {
    const ref = createRef<HyperswitchFormHandle>();
    render(
      <HyperswitchForm ref={ref} config={evervaultConfig}>
        <CardNumberWidget />
        <CardExpiryWidget />
        <CardCVCWidget />
        <CardHolderWidget />
      </HyperswitchForm>
    );

    await waitFor(() => expect(screen.getByTestId('ev-number')).toBeTruthy());
    expect(screen.getByTestId('ev-expiry')).toBeTruthy();
    expect(screen.getByTestId('ev-cvc')).toBeTruthy();
    expect(screen.getByTestId('ev-holder')).toBeTruthy();

    const mod = require('@evervault/react-native');
    let result: SubmitResult | undefined;
    await act(async () => {
      mod.__emit(completePayload);
      result = await ref.current!.submit();
    });
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('evervault');
    expect(result?.data?.raw).toEqual(completePayload.card);
  });

  describe('validateVaultData', () => {
    it('accepts a config with team_id and app_id', () => {
      expect(() =>
        evervaultAdapter.validateVaultData({ team_id: 't', app_id: 'a' })
      ).not.toThrow();
    });

    it('throws when app_id is missing', () => {
      expect(() =>
        evervaultAdapter.validateVaultData({ team_id: 't' })
      ).toThrow(/app_id/i);
    });
  });

  describe('submit', () => {
    it('returns success with encrypted card data when complete', async () => {
      const result = await evervaultAdapter.submit(
        fakeCollector(completePayload)
      );
      expect(result.status).toBe('success');
      expect(result.data?.tokens?.number).toBe('enc_number');
    });

    it('returns a validation_error with field errors when incomplete', async () => {
      const result = await evervaultAdapter.submit(
        fakeCollector({
          card: {},
          isValid: false,
          isComplete: false,
          errors: { number: 'Invalid card number' },
        })
      );
      expect(result.status).toBe('validation_error');
      expect(result.errors?.[0]?.field).toBe('card_number');
    });

    it('returns a validation_error when no payload has arrived', async () => {
      const result = await evervaultAdapter.submit(fakeCollector(null));
      expect(result.status).toBe('validation_error');
    });
  });
});
