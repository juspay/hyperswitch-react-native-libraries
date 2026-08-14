import {
  CardCVCWidget,
  CardExpDateRule,
  CardExpiryWidget,
  CardHolderWidget,
  CardNumberWidget,
  ExpDateSeparateSerializer,
  HyperswitchTokenizationConfiguration,
  HyperswitchVault,
  HyperswitchVaultError,
  HyperswitchVaultErrorCode,
} from '..';

describe('package exports', () => {
  it('exports the Hyperswitch Vault public API', () => {
    expect(HyperswitchVault).toBeDefined();
    expect(CardNumberWidget).toBeDefined();
    expect(CardHolderWidget).toBeDefined();
    expect(CardExpiryWidget).toBeDefined();
    expect(CardCVCWidget).toBeDefined();
    expect(ExpDateSeparateSerializer).toBeDefined();
    expect(HyperswitchTokenizationConfiguration).toBeDefined();
    expect(HyperswitchTokenizationConfiguration.presets.card).toBeDefined();
    expect(HyperswitchVaultError).toBeDefined();
    expect(HyperswitchVaultErrorCode.InputDataIsNotValid).toBe(1001);
    expect(CardExpDateRule).toBeDefined();
  });
});
