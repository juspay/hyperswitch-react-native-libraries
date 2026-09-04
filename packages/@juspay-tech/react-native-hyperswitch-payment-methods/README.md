# react-native-hyperswitch-payment-methods

Provider-agnostic React Native card collection. Render **one** set of card fields and
let the backend decide which vault/tokenization provider is used — your app code never
branches on the provider. The names, options, events and results are the ones
hyperswitch-web's separate card fields and `@juspay-tech/react-native-hyperswitch-vault`
use, so one integration reads the same across all three.

```tsx
<CardNumberField />
<CardExpiryField />
<CardCVCField />
<CardholderNameField />
```

Supported providers: **VGS, Skyflow, Basis Theory, Evervault** (vault/tokenizing).

## Installation

```sh
npm install react-native-hyperswitch-payment-methods
```

Then install **only** the provider SDK(s) you actually use (they are optional peer
dependencies, so you only pay for — and natively link — what you configure):

| `vaultType`    | Peer dependency to install                          |
| -------------- | --------------------------------------------------- |
| `vgs`          | `@vgs/collect-react-native`                         |
| `skyflow`      | `skyflow-react-native`                              |
| `basis_theory` | `@basis-theory/react-native-elements` (v3+)         |
| `evervault`    | `@evervault/react-native` (+ `react-native-webview`)|

If a `vaultType` is configured without its SDK installed, the form surfaces an
actionable "install X" error via `onError`.

## Usage

The backend tells you which vault to use; pass it as `vaultDetails` — the web SDK's
shape, `{vaultType, vaultData}` — to one `<CardForm>`, drop the four fields inside, and
call `tokenize()` on the form ref. The same code works for every provider.

```tsx
import { useRef } from 'react';
import {
  CardForm,
  CardNumberField,
  CardExpiryField,
  CardCVCField,
  CardholderNameField,
  type CardFormHandle,
} from 'react-native-hyperswitch-payment-methods';

function Checkout({ vaultDetails }) {
  const form = useRef<CardFormHandle>(null);

  const pay = async () => {
    const result = await form.current?.tokenize();
    if (result?.status === 'success') {
      // result.data.tokens -> the provider's tokens
    } else if (result?.error) {
      showMessage(result.error.message); // result.error.code names the cause
    }
  };

  return (
    <CardForm ref={form} vaultDetails={vaultDetails} onError={console.warn}>
      <CardNumberField />
      <CardExpiryField />
      <CardCVCField />
      <CardholderNameField />
    </CardForm>
  );
}
```

### `vaultDetails`

| `vaultType`    | `vaultData`                                                                 |
| -------------- | --------------------------------------------------------------------------- |
| `vgs`          | `{vaultId, environment?, routeId?, cname?}`                                 |
| `skyflow`      | `{vaultId, vaultUrl, table, bearerToken?, columns?, options?}`              |
| `basis_theory` | `{apiKey, baseUrl?}`                                                        |
| `evervault`    | `{teamId, appId}`                                                           |

### Tokenizing from outside the tree

If a Pay button can't reach the form ref, give the form an `id` and tokenize by id:

```tsx
<CardForm id="checkout" vaultDetails={vaultDetails}>...</CardForm>;

import { HyperswitchPaymentMethods } from 'react-native-hyperswitch-payment-methods';
await HyperswitchPaymentMethods.tokenize('checkout');
```

Descendant components can also use the `useCardForm()` hook.

## The result shape

```ts
type TokenizeResult =
  | { status: 'success'; vaultType?: VaultType; data?: { tokens?: Record<string, unknown>; raw?: unknown } }
  | { status: 'validation_error' | 'error'; vaultType?: VaultType; error: { code; message; type } };
```

`tokenize()` never throws. `if (result.error)` reads the same way it does with the web
SDK; `status` lets TypeScript narrow.

| `error.code`           | `type`             | Meaning                                                              |
| ---------------------- | ------------------ | -------------------------------------------------------------------- |
| `validation_error`     | `validation_error` | a field is empty or malformed (the message names it)                 |
| `incomplete_field_set` | `validation_error` | no `<CardForm id>` is mounted for the id given to `tokenize(id)`     |
| `sdk_not_ready`        | `api_error`        | the provider's SDK has not finished initialising                     |
| `tokenization_failed`  | `api_error`        | the provider refused, answered unreadably, or failed to initialise   |

Two `tokenize()` calls at once share one request.

## Events

Every field takes the web's four events. The change carries no card value:

```tsx
<CardNumberField
  onReady={(e) => {/* e.elementType === 'cardNumber' */}}
  onFocus={(e) => setActive(e.elementType)}
  onBlur={() => setActive(null)}
  onChange={(s) => setValid(s.valid)}
  // s: {elementType, empty, complete, valid, brand?, error?, touched}
/>
```

`brand` is spelt as the web spells it (`Visa`, `Mastercard`, `AmericanExpress`, …).
Focus and blur are reported where the provider reports them (VGS, Skyflow); change is
wired for VGS, Skyflow and Basis Theory (Evervault reports validity at the card level).

The form emits the web's `cardDetailsChange` on every change, always on:

```tsx
<CardForm
  vaultDetails={vaultDetails}
  onReady={(e) => {/* e.elementType === 'cardForm' */}}
  onChange={(e) => {
    // e.eventName === 'cardDetailsChange'
    setCanPay(e.complete && e.valid);
    e.payload; // {bin, last4, brand, expiryMonth, expiryYear, formattedExpiry, is*Complete, is*Valid}
    e.fields;  // the latest change per mounted field
  }}
>
```

A provider's secure input keeps the digits to itself, so `bin`, `last4` and the expiry
parts are `null` unless the provider reports them (Evervault does); the flags are derived
from the fields.

## Handles

- Form ref (`CardFormHandle`): `tokenize(providerData?)`, `status`
  (`initializing | ready | tokenizing | error`).
- Field ref (`FieldHandle`): `focus()`, `blur()`, `clear()` — no-ops where the provider's
  secure input does not support them.

```tsx
const field = useRef<FieldHandle>(null);
<CardNumberField ref={field} />;
field.current?.focus();
```

## Styling

Every field takes `styles`, with the same slot names as the Hyperswitch vault fields:

- `styles.container` — the field's **box** (border, background, radius, height, padding).
- `styles.input` — the secure input's **text** (color, fontSize, fontFamily).
- `placeholder` — placeholder text.

```tsx
<CardNumberField
  styles={{
    container: { borderWidth: 1, borderColor: '#ccc', borderRadius: 8, height: 44, paddingHorizontal: 12 },
    input: { color: '#111', fontSize: 16 },
  }}
  placeholder="1234 5678 9012 3456"
/>
```

`styles.input` is forwarded to the provider's underlying secure input where supported
(VGS `textStyle`, Basis Theory / Evervault field style); providers that don't support
text styling ignore it.

## Custom providers

Register your own adapter (also handy in tests):

```ts
import { registerAdapter } from 'react-native-hyperswitch-payment-methods';
const off = registerAdapter(myAdapter); // off() to unregister
```

An adapter provides `vaultType`, `validateVaultData`, a `Host`, a `Field` (which
receives `elementType`, `styles`, `placeholder`, `onChange`, `onFocus`, `onBlur`) and
`tokenize(collector, providerData?)`.

## Notes

- **VGS** uses `@vgs/collect-react-native`, currently in **beta** — pin the version.
- **Basis Theory** targets `@basis-theory/react-native-elements` **v3+** (the older SDK is
  deprecated).
- **Evervault** additionally requires `react-native-webview`.

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
