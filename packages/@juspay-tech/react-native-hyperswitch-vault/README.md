# react-native-hyperswitch-vault

React Native SDK for collecting sensitive payment data in app UI, validating it locally, and submitting or tokenizing it through a Hyperswitch Vault-compatible API.

This package groups secure card widgets by an `id`. Mount widgets with the same `id`, then pass that `id` to `HyperswitchVault.submit`, `HyperswitchVault.tokenize`, `HyperswitchVault.createAliases`, or `HyperswitchVault.createCard`.

## Installation

```sh
npm install react-native-hyperswitch-vault
```

```sh
yarn add react-native-hyperswitch-vault
```

For iOS, run pods after installation:

```sh
cd ios && pod install
```

## Quick Start

```tsx
import {
  CardCVCWidget,
  CardExpiryWidget,
  CardHolderWidget,
  CardNumberWidget,
  HyperswitchVault,
  HyperswitchTokenizationConfiguration,
  HyperswitchVaultError,
  HyperswitchVaultErrorCode,
} from 'react-native-hyperswitch-vault';

const CARD_FORM_ID = 'checkout-card';

function CardForm() {
  const handleSubmit = async () => {
    try {
      const result = await HyperswitchVault.submit(CARD_FORM_ID, {
        vaultId: 'yourVaultId',
        environment: 'sandbox',
        vaultBaseUrl: 'https://vault.example.com',
        path: '/post',
        method: 'POST',
      });
      console.log('Vault status:', result.status);
    } catch (error) {
      if (
        error instanceof HyperswitchVaultError &&
        error.code === HyperswitchVaultErrorCode.InputDataIsNotValid
      ) {
        console.warn('Invalid fields:', error.details);
      }
    }
  };

  return (
    <>
      <CardNumberWidget
        id={CARD_FORM_ID}
        placeholder="Card number"
        tokenization={HyperswitchTokenizationConfiguration.presets.card}
      />
      <CardExpiryWidget
        id={CARD_FORM_ID}
        placeholder="MM/YY"
      />
      <CardCVCWidget
        id={CARD_FORM_ID}
        placeholder="CVC"
        tokenization={HyperswitchTokenizationConfiguration.presets.cvc}
      />
      <CardHolderWidget
        id={CARD_FORM_ID}
        placeholder="Cardholder name"
      />
    </>
  );
}
```

## Public API

- `HyperswitchVault`: static orchestrator for `submit`, `tokenize`, `createAliases`, and `createCard`.
- `CardNumberWidget`, `CardExpiryWidget`, `CardCVCWidget`, and `CardHolderWidget`: secure card collection widgets that register under a shared `id`.
- Validators: `NotEmptyRule`, `LengthRule`, `LengthMatchRule`, `PatternRule`, `CardExpDateRule`, `PaymentCardRule`, `LuhnCheckRule`, `DateRangeRule`, and `MatchFieldRule`.
- `ExpDateSeparateSerializer`: splits a visible expiration date into request keys like `exp_month` and `exp_year`.
- `HyperswitchTokenizationConfiguration`: tokenization presets and storage/alias format enums.
- `HyperswitchVaultError` and `HyperswitchVaultErrorCode`: structured validation/configuration errors.

## Notes

- Do not log, persist, or send raw PAN/CVC/SSN values outside the Vault flow.
- Widget `id` values should be unique per mounted form.
- Standard card widgets default to `pan`, `expDate`, `cvc`, and `cardholder` field names. Override `fieldName` only when your Vault route or backend requires different keys.
- The SDK defaults to a placeholder `hyperswitch-vault.com` base domain. Pass `vaultBaseUrl` to `submit`, `tokenize`, `createAliases`, or `createCard` when wiring it to a real environment.

## License

MIT
