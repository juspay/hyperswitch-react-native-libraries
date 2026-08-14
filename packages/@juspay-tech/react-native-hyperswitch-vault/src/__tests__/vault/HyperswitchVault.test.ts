import HyperswitchVault from '../../vault/HyperswitchVault';
import {
  HyperswitchVaultAliasFormat,
  HyperswitchVaultStorageType,
} from '../../utils/tokenization/TokenizationConfiguration';

const originalFetch = global.fetch;

afterEach(() => {
  HyperswitchVault.reset();
  jest.clearAllMocks();
  global.fetch = originalFetch;
});

describe('HyperswitchVault id-based interface', () => {
  const id = 'checkout-card';

  it('submits registered fields for an id', async () => {
    const response = {
      ok: true,
      status: 200,
      json: async () => ({ ok: true }),
    };
    global.fetch = jest.fn().mockResolvedValue(response);

    HyperswitchVault.registerField(
      id,
      'pan',
      () => '4111111111111111',
      () => []
    );
    HyperswitchVault.registerField(
      id,
      'cvc',
      () => '123',
      () => []
    );

    const result = await HyperswitchVault.submit(id, {
      vaultId: 'tenant',
      environment: 'sandbox',
      vaultBaseUrl: 'vault.example.com',
      path: '/post',
      method: 'POST',
      extraData: { customer_id: 'cus_123' },
    });

    expect(result).toEqual({ status: 200, response });
    expect(global.fetch).toHaveBeenCalledWith(
      'https://tenant.sandbox.vault.example.com/post',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({
          pan: '4111111111111111',
          cvc: '123',
          customer_id: 'cus_123',
        }),
      })
    );
  });

  it('throws if no widgets are registered for an id', async () => {
    await expect(
      HyperswitchVault.submit('missing-form', {
        vaultId: 'tenant',
        environment: 'sandbox',
      })
    ).rejects.toThrow('No fields registered');
  });

  it('throws structured validation errors before submission', async () => {
    global.fetch = jest.fn();
    HyperswitchVault.registerField(
      id,
      'pan',
      () => '4111',
      () => ['INVALID_CARD_NUMBER']
    );

    await expect(
      HyperswitchVault.submit(id, {
        vaultId: 'tenant',
        environment: 'sandbox',
      })
    ).rejects.toMatchObject({
      details: { pan: ['INVALID_CARD_NUMBER'] },
    });
    expect(global.fetch).not.toHaveBeenCalled();
  });

  it('tokenizes configured fields and maps aliases back to field names', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        data: [
          {
            aliases: [
              {
                format: HyperswitchVaultAliasFormat.FPE_ACC_NUM_T_FOUR,
                alias: 'tok_card',
              },
            ],
          },
        ],
      }),
    });

    HyperswitchVault.registerField(
      id,
      'pan',
      () => '4111111111111111',
      () => [],
      {
        storage: HyperswitchVaultStorageType.PERSISTENT,
        format: HyperswitchVaultAliasFormat.FPE_ACC_NUM_T_FOUR,
      },
      'card'
    );

    const result = await HyperswitchVault.tokenize(id, {
      vaultId: 'tenant',
      environment: 'sandbox',
      vaultBaseUrl: 'vault.example.com',
    });

    expect(result).toEqual({ status: 200, data: { pan: 'tok_card' } });
    expect(global.fetch).toHaveBeenCalledWith(
      'https://tenant.sandbox.vault.example.com/tokens',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({
          data: [
            {
              value: '4111111111111111',
              storage: HyperswitchVaultStorageType.PERSISTENT,
              format: HyperswitchVaultAliasFormat.FPE_ACC_NUM_T_FOUR,
            },
          ],
        }),
      })
    );
  });

  it('creates a card through the card management endpoint', async () => {
    const response = {
      ok: true,
      status: 201,
      json: async () => ({ id: 'card_123' }),
    };
    global.fetch = jest.fn().mockResolvedValue(response);
    HyperswitchVault.registerField(
      id,
      'pan',
      () => '4111111111111111',
      () => []
    );

    const result = await HyperswitchVault.createCard(id, {
      vaultId: 'tenant',
      environment: 'sandbox',
      accessToken: 'jwt-token',
      cardManagementBaseUrl: 'cards.example.com',
      extraData: { data: { relationships: { customer: 'cus_123' } } },
    });

    expect(result).toEqual({ status: 201, response });
    expect(global.fetch).toHaveBeenCalledWith(
      'https://cards.example.com/cards',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'Content-Type': 'application/vnd.api+json',
          'Authorization': 'Bearer jwt-token',
        }),
        body: JSON.stringify({
          data: {
            relationships: { customer: 'cus_123' },
            attributes: { pan: '4111111111111111' },
          },
        }),
      })
    );
  });

  it('unregisters fields by id', async () => {
    HyperswitchVault.registerField(
      id,
      'pan',
      () => '4111111111111111',
      () => []
    );
    HyperswitchVault.unregisterField(id, 'pan');

    await expect(
      HyperswitchVault.submit(id, {
        vaultId: 'tenant',
        environment: 'sandbox',
      })
    ).rejects.toThrow('No fields registered');
  });

  it('updates CVC field config for detected card brand within the same id', () => {
    const updateCallback = jest.fn();
    HyperswitchVault.registerField(
      id,
      'cvc',
      () => '123',
      () => [],
      undefined,
      'cvc',
      [],
      updateCallback
    );

    HyperswitchVault.updateCvcFieldForBrand(id, 'amex');

    expect(updateCallback).toHaveBeenCalledWith({
      mask: '####',
      validationRules: expect.any(Array),
    });
  });
});
