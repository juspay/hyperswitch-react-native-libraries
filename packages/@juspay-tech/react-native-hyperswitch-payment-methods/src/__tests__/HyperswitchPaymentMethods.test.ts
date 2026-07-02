import { describe, it, expect, jest } from '@jest/globals';
import { HyperswitchPaymentMethods } from '../HyperswitchPaymentMethods';
import { registerForm } from '../core/formRegistry';
import type { SubmitResult } from '../core/types';

const ok: SubmitResult = { status: 'success', vaultType: 'skyflow' };

describe('HyperswitchPaymentMethods.submit', () => {
  it('returns a no_form error when no form is registered for the id', async () => {
    const result = await HyperswitchPaymentMethods.submit('absent');
    expect(result.status).toBe('error');
    expect(result.errors?.[0]?.code).toBe('no_form');
  });

  it('routes to the registered form and forwards providerData', async () => {
    const submit = jest.fn(async () => ok);
    const off = registerForm('checkout', submit);
    try {
      const result = await HyperswitchPaymentMethods.submit('checkout', {
        token: 'abc',
      });
      expect(submit).toHaveBeenCalledWith({ token: 'abc' });
      expect(result).toEqual(ok);
    } finally {
      off();
    }
  });
});
