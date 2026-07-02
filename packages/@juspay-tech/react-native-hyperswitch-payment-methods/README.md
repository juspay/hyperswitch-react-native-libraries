# react-native-hyperswitch-payment-methods

Provider-agnostic React Native card collection. Render **one** set of card widgets and
let the backend decide which vault/tokenization provider is used — your app code never
branches on the provider.

```tsx
<CardNumberWidget />
<CardExpiryWidget />
<CardCVCWidget />
<CardHolderWidget />
```

Supported providers: **VGS, Skyflow, Basis Theory, Evervault** (vault/tokenizing).

## Installation

```sh
npm install react-native-hyperswitch-payment-methods
```

Then install **only** the provider SDK(s) you actually use (they are optional peer
dependencies, so you only pay for — and natively link — what you configure):

| `vault_type`   | Peer dependency to install                          |
| -------------- | --------------------------------------------------- |
| `vgs`          | `@vgs/collect-react-native`                         |
| `skyflow`      | `skyflow-react-native`                              |
| `basis_theory` | `@basis-theory/react-native-elements` (v3+)         |
| `evervault`    | `@evervault/react-native` (+ `react-native-webview`)|

If a `vault_type` is configured without its SDK installed, the form surfaces an
actionable "install X" error via `onError`.

## Usage

The backend returns `{ vault_type, vault_data }`. Pass it to one `<HyperswitchForm>`,
drop the four widgets inside, and submit through the form ref. The same code works for
every provider.

```tsx
import { useRef } from 'react';
import {
  HyperswitchForm,
  CardNumberWidget,
  CardExpiryWidget,
  CardCVCWidget,
  CardHolderWidget,
  type HyperswitchFormHandle,
} from 'react-native-hyperswitch-payment-methods';

function Checkout({ config }) {
  const form = useRef<HyperswitchFormHandle>(null);

  const pay = async () => {
    const result = await form.current?.submit();
    // result.status: 'success' | 'error' | 'not_ready' | 'validation_error'
    // result.data?.tokens   -> vault providers
  };

  return (
    <HyperswitchForm ref={form} config={config} onError={console.warn}>
      <CardNumberWidget />
      <CardExpiryWidget />
      <CardCVCWidget />
      <CardHolderWidget />
    </HyperswitchForm>
  );
}
```

### Submitting from outside the tree

If a Pay button can't reach the form ref, give the form an `id` and submit by id:

```tsx
<HyperswitchForm id="checkout" config={config}>...</HyperswitchForm>;

import { HyperswitchPaymentMethods } from 'react-native-hyperswitch-payment-methods';
await HyperswitchPaymentMethods.submit('checkout');
```

Descendant components can also use the `useHyperswitchForm()` hook.

## The result shape

```ts
interface SubmitResult {
  status: 'success' | 'error' | 'not_ready' | 'validation_error';
  vaultType?: VaultType;
  data?: {
    tokens?: Record<string, unknown>; // vault providers
    raw?: unknown; // provider-native payload
  };
  errors?: { field?: FieldKind; code: string; message: string }[];
}
```

`submit()` never throws: if the provider hasn't finished initializing it returns
`not_ready`; failures come back as `error`/`validation_error`.

## Field state, validation & focus

Every widget accepts an `onStateChange` callback that reports live field state
(`isValid` / `isEmpty` / `isFocused` / `isDirty` / `validationErrors` / `brand`), translated
from each provider's native events:

```tsx
<CardNumberWidget
  onStateChange={(s) => setValid(s.isValid)} // s: FieldState
/>
```

(`onStateChange` is wired for VGS, Skyflow, and Basis Theory; Evervault reports validity at
the card level via its own form state.)

Widgets also expose an imperative `focus()/blur()` handle (a no-op where the provider's secure
input doesn't support programmatic focus):

```tsx
const field = useRef<WidgetHandle>(null);
<CardNumberWidget ref={field} />;
field.current?.focus();
```

## Styling

Every widget takes two style props so it matches your app's theme:

- `style` — the field's **container box** (border, background, radius, height, padding).
- `textStyle` — the secure input's **text** (color, fontSize, fontFamily).
- `placeholder` — placeholder text.

```tsx
<CardNumberWidget
  style={{ borderWidth: 1, borderColor: '#ccc', borderRadius: 8, height: 44, paddingHorizontal: 12 }}
  textStyle={{ color: '#111', fontSize: 16 }}
  placeholder="1234 5678 9012 3456"
/>
```

`textStyle` is forwarded to the provider's underlying secure input where supported (e.g. VGS
`textStyle`, Basis Theory / Evervault field style); providers that don't support text styling
ignore it.

## Custom providers

Register your own adapter (also handy in tests):

```ts
import { registerAdapter } from 'react-native-hyperswitch-payment-methods';
const off = registerAdapter(myAdapter); // off() to unregister
```

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
