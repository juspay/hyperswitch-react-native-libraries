import { describe, it, expect, jest } from '@jest/globals';
import { createFormSession } from '../formSession';
import type { ProviderAdapter } from '../ProviderAdapter';
import type { SubmitResult } from '../types';

const success: SubmitResult = {
  status: 'success',
  vaultType: 'vgs',
  data: { tokens: { card_number: 'tok_123' } },
};

function fakeAdapter(
  submit: ProviderAdapter['submit'] = async () => success
): ProviderAdapter {
  return {
    vaultType: 'vgs',
    validateVaultData: (raw) => raw,
    Host: () => null,
    Field: () => null,
    submit,
  };
}

describe('createFormSession', () => {
  it('starts in the initializing state', () => {
    const session = createFormSession(fakeAdapter());
    expect(session.status).toBe('initializing');
  });

  it('becomes ready once a collector attaches', () => {
    const session = createFormSession(fakeAdapter());
    session.attachCollector({});
    expect(session.status).toBe('ready');
  });

  it('delegates submit to the adapter once ready, passing providerData', async () => {
    const submit = jest.fn(async () => success);
    const collector = { id: 'collector' };
    const session = createFormSession(fakeAdapter(submit));
    session.attachCollector(collector);

    const result = await session.submit({ extra: 1 });

    expect(result).toEqual(success);
    expect(submit).toHaveBeenCalledWith(collector, { extra: 1 });
    expect(session.status).toBe('ready');
  });

  it('awaits a collector that attaches after submit is called', async () => {
    const session = createFormSession(fakeAdapter(), { readyTimeoutMs: 1000 });
    const pending = session.submit();
    setTimeout(() => session.attachCollector({}), 5);
    await expect(pending).resolves.toEqual(success);
  });

  it('returns not_ready if no collector attaches before the timeout', async () => {
    const session = createFormSession(fakeAdapter(), { readyTimeoutMs: 10 });
    const result = await session.submit();
    expect(result.status).toBe('not_ready');
    expect(result.vaultType).toBe('vgs');
  });

  it('returns an error result when the host has failed', async () => {
    const session = createFormSession(fakeAdapter(), { readyTimeoutMs: 1000 });
    session.fail(new Error('init blew up'));
    const result = await session.submit();
    expect(result.status).toBe('error');
    expect(result.errors?.[0]?.message).toMatch(/init blew up/);
  });

  it('maps an adapter submit rejection to an error result and recovers status', async () => {
    const session = createFormSession(
      fakeAdapter(async () => {
        throw new Error('tokenization failed');
      })
    );
    session.attachCollector({});
    const result = await session.submit();
    expect(result.status).toBe('error');
    expect(result.errors?.[0]?.message).toMatch(/tokenization failed/);
    expect(session.status).toBe('ready');
  });

  it('reports submitting while the adapter submit is in flight', async () => {
    let resolveSubmit!: (r: SubmitResult) => void;
    const session = createFormSession(
      fakeAdapter(() => new Promise<SubmitResult>((r) => (resolveSubmit = r)))
    );
    session.attachCollector({});
    const pending = session.submit();
    expect(session.status).toBe('submitting');
    resolveSubmit(success);
    await pending;
    expect(session.status).toBe('ready');
  });
});
