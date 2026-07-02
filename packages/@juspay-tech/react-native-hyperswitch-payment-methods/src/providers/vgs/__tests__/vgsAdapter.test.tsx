import { createRef } from 'react';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

jest.mock(
  '@vgs/collect-react-native',
  () => {
    const React = require('react');
    const { Text } = require('react-native');
    class VGSCollect {
      id: string;
      environment?: string;
      routeId?: string;
      constructor(id: string, environment?: string) {
        this.id = id;
        this.environment = environment;
      }
      setRouteId(routeId: string) {
        this.routeId = routeId;
      }
      setCname() {
        return Promise.resolve();
      }
      submit = jest.fn(async () => ({
        status: 200,
        response: { card_number: 'tok_vgs' },
      }));
    }
    const makeField =
      (label: string) =>
      (props: {
        fieldName: string;
        onStateChange?: (state: unknown) => void;
      }) => {
        React.useEffect(() => {
          props.onStateChange?.({
            isValid: true,
            isEmpty: false,
            isDirty: true,
            isFocused: false,
            validationErrors: [],
            cardBrand: 'visa',
          });
        }, [props]);
        return React.createElement(
          Text,
          { testID: `vgs-${props.fieldName}` },
          label
        );
      };
    const VGSTextInput = makeField('text-input');
    const VGSCardInput = makeField('card-input');
    const VGSCVCInput = makeField('cvc-input');
    return {
      __esModule: true,
      VGSCollect,
      VGSTextInput,
      VGSCardInput,
      VGSCVCInput,
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
import { vgsAdapter } from '../adapter';
import type {
  HyperswitchFormHandle,
  ProviderConfig,
  SubmitResult,
} from '../../../core/types';

const vgsConfig: ProviderConfig = {
  vault_type: 'vgs',
  vault_data: { vault_id: 'tntabc123', environment: 'sandbox' },
};

type FakeCollector = { submit: jest.Mock };
function fakeCollector(
  impl: () => Promise<{ status: number; response: unknown }>
): { collector: unknown; submit: jest.Mock } {
  const submit = jest.fn(impl);
  return { collector: { submit } as FakeCollector, submit };
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('vgsAdapter', () => {
  it('renders a VGS field for each card widget and submits successfully', async () => {
    const ref = createRef<HyperswitchFormHandle>();
    render(
      <HyperswitchForm ref={ref} config={vgsConfig}>
        <CardNumberWidget />
        <CardExpiryWidget />
        <CardCVCWidget />
        <CardHolderWidget />
      </HyperswitchForm>
    );

    await waitFor(() =>
      expect(screen.getByTestId('vgs-card_number')).toBeTruthy()
    );
    expect(screen.getByTestId('vgs-expiration_date')).toBeTruthy();
    expect(screen.getByTestId('vgs-card_cvc')).toBeTruthy();
    expect(screen.getByTestId('vgs-card_holder')).toBeTruthy();

    expect(screen.getByTestId('vgs-card_number')).toHaveTextContent(
      'card-input'
    );
    expect(screen.getByTestId('vgs-card_cvc')).toHaveTextContent('cvc-input');
    expect(screen.getByTestId('vgs-expiration_date')).toHaveTextContent(
      'text-input'
    );
    expect(screen.getByTestId('vgs-card_holder')).toHaveTextContent(
      'text-input'
    );

    let result: SubmitResult | undefined;
    await act(async () => {
      result = await ref.current!.submit();
    });
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('vgs');
  });

  it('maps VGS field state to the widget onStateChange', async () => {
    const onStateChange = jest.fn();
    render(
      <HyperswitchForm config={vgsConfig}>
        <CardNumberWidget onStateChange={onStateChange} />
      </HyperswitchForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('vgs-card_number')).toBeTruthy()
    );

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
    it('accepts a config with a string vault_id', () => {
      expect(() =>
        vgsAdapter.validateVaultData({ vault_id: 'tnt', environment: 'live' })
      ).not.toThrow();
    });

    it('throws when vault_id is missing', () => {
      expect(() =>
        vgsAdapter.validateVaultData({ environment: 'live' })
      ).toThrow(/vault_id/i);
    });
  });

  describe('submit', () => {
    it('maps a 2xx VGS response to a success result with raw payload', async () => {
      const { collector, submit } = fakeCollector(async () => ({
        status: 200,
        response: { card_number: 'tok_1' },
      }));
      const result = await vgsAdapter.submit(collector);
      expect(submit).toHaveBeenCalledWith('/post', 'POST', undefined);
      expect(result.status).toBe('success');
      expect(result.data?.raw).toEqual({ card_number: 'tok_1' });
      expect(result.data?.tokens).toEqual({ card_number: 'tok_1' });
    });

    it('maps a non-2xx VGS response to an error result', async () => {
      const { collector } = fakeCollector(async () => ({
        status: 422,
        response: { error: 'bad' },
      }));
      const result = await vgsAdapter.submit(collector);
      expect(result.status).toBe('error');
      expect(result.errors?.[0]?.code).toMatch(/422/);
    });

    it('maps a rejected VGS submit to an error result', async () => {
      const { collector } = fakeCollector(async () => {
        throw new Error('validation failed');
      });
      const result = await vgsAdapter.submit(collector);
      expect(result.status).toBe('error');
      expect(result.errors?.[0]?.message).toMatch(/validation failed/);
    });

    it('forwards path, method and extraData from providerData', async () => {
      const { collector, submit } = fakeCollector(async () => ({
        status: 200,
        response: {},
      }));
      await vgsAdapter.submit(collector, {
        path: '/cards',
        method: 'PUT',
        extraData: { merchant: 'acme' },
      });
      expect(submit).toHaveBeenCalledWith('/cards', 'PUT', {
        merchant: 'acme',
      });
    });
  });
});
