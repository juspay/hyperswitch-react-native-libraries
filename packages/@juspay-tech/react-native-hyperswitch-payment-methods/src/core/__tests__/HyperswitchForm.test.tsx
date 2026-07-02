import { createRef } from 'react';
import { Text } from 'react-native';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

import { HyperswitchForm } from '../HyperswitchForm';
import { useHyperswitchForm } from '../useHyperswitchForm';
import { registerAdapter } from '../../providers/registry';
import { getFormSubmit } from '../formRegistry';
import { HyperswitchPaymentMethods } from '../../HyperswitchPaymentMethods';
import {
  CardNumberWidget,
  CardExpiryWidget,
  CardCVCWidget,
  CardHolderWidget,
} from '../../widgets';
import { createMockAdapter } from '../../__fixtures__/mockAdapter';
import type {
  HyperswitchFormHandle,
  ProviderConfig,
  SubmitResult,
  WidgetHandle,
} from '../types';

const cleanups: Array<() => void> = [];
afterEach(() => {
  while (cleanups.length) cleanups.pop()!();
});

function useMock(options: Parameters<typeof createMockAdapter>[0] = {}) {
  const adapter = createMockAdapter(options);
  cleanups.push(registerAdapter(adapter));
  return adapter;
}

const config = (vault_type: ProviderConfig['vault_type']): ProviderConfig => ({
  vault_type,
  vault_data: {},
});

function Fields() {
  return (
    <>
      <CardNumberWidget />
      <CardExpiryWidget />
      <CardCVCWidget />
      <CardHolderWidget />
    </>
  );
}

describe('HyperswitchForm', () => {
  it('renders a placeholder for each field before the collector is ready', () => {
    useMock({ vaultType: 'vgs', neverReady: true });
    render(
      <HyperswitchForm config={config('vgs')}>
        <Fields />
      </HyperswitchForm>
    );

    expect(screen.getByTestId('hs-placeholder-card_number')).toBeTruthy();
    expect(screen.getByTestId('hs-placeholder-card_expiry')).toBeTruthy();
    expect(screen.queryByTestId('mock-field-card_number')).toBeNull();
  });

  it('swaps placeholders for provider fields once the collector attaches', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    render(
      <HyperswitchForm config={config('vgs')}>
        <Fields />
      </HyperswitchForm>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-card_number')).toBeTruthy()
    );
    expect(screen.getByTestId('mock-field-card_expiry')).toBeTruthy();
    expect(screen.getByTestId('mock-field-card_cvc')).toBeTruthy();
    expect(screen.getByTestId('mock-field-card_holder')).toBeTruthy();
    expect(screen.queryByTestId('hs-placeholder-card_number')).toBeNull();
  });

  it('submit resolves with the provider result once ready', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    const ref = createRef<HyperswitchFormHandle>();
    render(
      <HyperswitchForm ref={ref} config={config('vgs')}>
        <Fields />
      </HyperswitchForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('mock-field-card_number')).toBeTruthy()
    );

    let result: SubmitResult | undefined;
    await act(async () => {
      result = await ref.current!.submit();
    });

    expect(result?.status).toBe('success');
    expect(result?.data?.tokens?.card_number).toBe('tok_mock');
  });

  it('submit called before ready waits for the collector then succeeds', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 40 });
    const ref = createRef<HyperswitchFormHandle>();
    render(
      <HyperswitchForm ref={ref} config={config('vgs')} readyTimeoutMs={1000}>
        <Fields />
      </HyperswitchForm>
    );

    let result: SubmitResult | undefined;
    await act(async () => {
      result = await ref.current!.submit();
    });

    expect(result?.status).toBe('success');
  });

  it('submit returns not_ready when the collector never attaches', async () => {
    useMock({ vaultType: 'vgs', neverReady: true });
    const ref = createRef<HyperswitchFormHandle>();
    render(
      <HyperswitchForm ref={ref} config={config('vgs')} readyTimeoutMs={30}>
        <Fields />
      </HyperswitchForm>
    );

    let result: SubmitResult | undefined;
    await act(async () => {
      result = await ref.current!.submit();
    });

    expect(result?.status).toBe('not_ready');
    expect(result?.vaultType).toBe('vgs');
  });

  it('surfaces an adapter-resolution failure (e.g. missing provider SDK) via onError without crashing', async () => {
    const onError = jest.fn();
    const ref = createRef<HyperswitchFormHandle>();

    const unknown = 'no_such_provider' as ProviderConfig['vault_type'];
    render(
      <HyperswitchForm ref={ref} config={config(unknown)} onError={onError}>
        <Fields />
      </HyperswitchForm>
    );

    expect(screen.getByTestId('hs-placeholder-card_number')).toBeTruthy();

    await waitFor(() => expect(onError).toHaveBeenCalledTimes(1));
    expect(String(onError.mock.calls[0]?.[0])).toMatch(/no provider adapter/i);

    let result: SubmitResult | undefined;
    await act(async () => {
      result = await ref.current!.submit();
    });
    expect(result?.status).toBe('error');
    expect(result?.vaultType).toBe(unknown);
  });

  it('exposes submit to descendants via useHyperswitchForm', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    function StatusProbe() {
      const { status } = useHyperswitchForm();
      return <Text testID="probe-status">{status}</Text>;
    }
    render(
      <HyperswitchForm config={config('vgs')}>
        <StatusProbe />
      </HyperswitchForm>
    );

    await waitFor(() =>
      expect(screen.getByTestId('probe-status').props.children).toBe('ready')
    );
  });

  it('routes HyperswitchPaymentMethods.submit(id) to the form and unregisters on unmount', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    const view = render(
      <HyperswitchForm id="checkout" config={config('vgs')}>
        <Fields />
      </HyperswitchForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('mock-field-card_number')).toBeTruthy()
    );

    let result: SubmitResult | undefined;
    await act(async () => {
      result = await HyperswitchPaymentMethods.submit('checkout');
    });
    expect(result?.status).toBe('success');

    view.unmount();
    expect(getFormSubmit('checkout')).toBeUndefined();
  });

  it('widget focus()/blur() are safe no-ops when the provider does not support them', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    const ref = createRef<WidgetHandle>();
    render(
      <HyperswitchForm config={config('vgs')}>
        <CardNumberWidget ref={ref} />
      </HyperswitchForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('mock-field-card_number')).toBeTruthy()
    );

    act(() => {
      ref.current?.focus();
      ref.current?.blur();
    });
    expect(typeof ref.current?.focus).toBe('function');
  });

  it('keeps two forms with different providers isolated', async () => {
    useMock({
      vaultType: 'vgs',
      readyDelayMs: 0,
      submitResult: { status: 'success', vaultType: 'vgs' },
    });
    useMock({
      vaultType: 'skyflow',
      readyDelayMs: 0,
      submitResult: { status: 'success', vaultType: 'skyflow' },
    });
    const vgsRef = createRef<HyperswitchFormHandle>();
    const skyflowRef = createRef<HyperswitchFormHandle>();
    render(
      <>
        <HyperswitchForm ref={vgsRef} config={config('vgs')}>
          <CardNumberWidget />
        </HyperswitchForm>
        <HyperswitchForm ref={skyflowRef} config={config('skyflow')}>
          <CardNumberWidget />
        </HyperswitchForm>
      </>
    );
    await waitFor(() =>
      expect(screen.getAllByTestId('mock-field-card_number').length).toBe(2)
    );

    let vgsResult: SubmitResult | undefined;
    let skyflowResult: SubmitResult | undefined;
    await act(async () => {
      vgsResult = await vgsRef.current!.submit();
      skyflowResult = await skyflowRef.current!.submit();
    });

    expect(vgsResult?.vaultType).toBe('vgs');
    expect(skyflowResult?.vaultType).toBe('skyflow');
  });
});
