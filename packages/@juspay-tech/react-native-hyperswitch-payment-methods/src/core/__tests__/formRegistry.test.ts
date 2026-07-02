import { describe, it, expect } from '@jest/globals';
import { registerForm, getFormSubmit } from '../formRegistry';
import type { SubmitResult } from '../types';

const ok: SubmitResult = { status: 'success', vaultType: 'vgs' };

describe('formRegistry', () => {
  it('returns undefined for an unregistered id', () => {
    expect(getFormSubmit('nope')).toBeUndefined();
  });

  it('routes to the registered submit function', async () => {
    let called = false;
    const off = registerForm('checkout', async () => {
      called = true;
      return ok;
    });
    try {
      const fn = getFormSubmit('checkout');
      expect(fn).toBeDefined();
      await fn!();
      expect(called).toBe(true);
    } finally {
      off();
    }
  });

  it('unregister removes the registration', () => {
    const off = registerForm('temp', async () => ok);
    off();
    expect(getFormSubmit('temp')).toBeUndefined();
  });

  it('stale unregister does not evict a newer registration for the same id', async () => {
    const offA = registerForm('dup', async () => ({ ...ok, vaultType: 'vgs' }));
    const second = async (): Promise<SubmitResult> => ({
      ...ok,
      vaultType: 'skyflow',
    });
    const offB = registerForm('dup', second);
    offA();
    try {
      const fn = getFormSubmit('dup');
      expect(fn).toBe(second);
    } finally {
      offB();
    }
  });
});
