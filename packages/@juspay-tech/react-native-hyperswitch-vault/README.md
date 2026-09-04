# @juspay-tech/react-native-hyperswitch-vault

Collect a card in React Native. The card details never touch your app code.

Authored in ReScript, published as JavaScript with genType-generated TypeScript declarations — you
need neither.

---

## One vocabulary with the web SDK

A merchant who integrates hyperswitch-web's separate card fields and this library meets the same
names. Where the web has a name, this library uses it; what this library adds is additive and named
so it cannot collide.

| Web SDK | This library |
|---|---|
| `cardForm.create('cardNumber' \| 'cardExpiry' \| 'cardCvc', options)` | `<CardNumberField />` `<CardExpiryField />` `<CardCVCField />` with the same options as props |
| `cardForm.tokenize()` | `tokenize()` on the `CardForm` ref, or `createCardForm().tokenize()` |
| `field.on('ready' \| 'focus' \| 'blur' \| 'change', cb)` | `onReady` `onFocus` `onBlur` `onChange` props on the field |
| `cardForm.on('ready' \| 'change', cb)` | `onReady` `onChange` props on `CardForm`, or `createCardForm().on(event, cb)` |
| `change` payload `{elementType, empty, complete, valid, brand?, error?}` | the same keys, plus `touched`, `errorCode`, `isCoBadged` |
| group `change` = `{elementType: 'cardForm', eventName: 'cardDetailsChange', payload}` | the same envelope, plus `fieldsReady`, `sessionStatus`, `canSubmit`, `fields`… |
| `placeholder`, `cardBrandIcon`, `cvcIcon`, `savedCard` | the same props |
| `appearance.variables.colorPrimary` … `appearance.labels` | the same shape |
| `locale: 'fr'` | the same option, the same sdk-utils string bundles |
| `field.focus()` `field.blur()` `field.clear()` | the same methods on the field ref |
| `{error: {code, message, type}}` with `session_expired`, `session_consumed`, `incomplete_field_set`… | the same envelope and codes, plus a `status` discriminant |

---

## The three flows

The library supports exactly three flows. **All three render the library's own card fields** — the
PAN, expiry, CVC and cardholder name are the library's in every one of them. What differs is what
the library then does with them, and therefore what crosses the public boundary.

| | Requests the library makes | What the caller receives | Operation |
|---|---|---|---|
| **Flow 1 — standalone merchant tokenization** | tokenize | a payment-method token | `tokenize()` |
| **Flow 2 — checkout-SDK payment confirmation** | tokenize, then confirm | a navigation decision, no token | `confirmPayment({cardSource: {type_: 'vault', session}})` — `./host` entry |
| **Flow 3 — vault disabled** | confirm only | a navigation decision, no token | `confirmPayment({cardSource: {type_: 'direct'}})` — `./host` entry |
| **Saved card — CVC only** | update a card you already saved | `{status: 'success', token}` — the same union as Flow 1 | one `<CardCVCField savedCard={…} />` inside `<CardForm>` + `tokenize()` |

Most standalone integrations want **Flow 1**. Start there.

The package publishes one entry per audience. The root is the merchant's: Flow 1, and nothing that
confirms a payment. Flows 2 and 3 are driven by the Hyperswitch checkout SDK through
`@juspay-tech/react-native-hyperswitch-vault/host` — the same components, typed with the wider
`HostFormHandle`. Merchants never import `./host`.

---

## Quick start (Flow 1)

**1. Install**

```sh
yarn add @juspay-tech/react-native-hyperswitch-vault
```

No native step: no native module, no `pod install`, no Codegen, no autolinking. Peers are `react`
(>=19 <20) and `react-native` (>=0.79 <0.88), and there are no runtime dependencies.

**2. Get a session from your backend**

Your server creates the payment-method session with your secret key and returns the response as-is.

```ts
const session = await fetch('https://your-backend.example/vault-session').then(r => r.json());
```

Pass it through untouched. The web SDK takes `vaultDetails` instead; this library accepts it too,
in the web's own spelling, at the cost of not knowing the session's `expires_at`:

```tsx
<CardForm
  vaultDetails={{vaultType: 'hyperswitch', vaultData: {sdkAuthorization}}}
  environment="sandbox">
```

**3. Render the fields**

```tsx
import {
  CardForm,
  CardNumberField,
  CardExpiryField,
  CardCVCField,
  type VaultFormHandle,
} from '@juspay-tech/react-native-hyperswitch-vault';

const formRef = useRef<VaultFormHandle>(null);
const [canSave, setCanSave] = useState(false);

<CardForm
  ref={formRef}
  session={session}
  environment="sandbox"
  locale="en"
  onChange={e => setCanSave(e.canSubmit)}>
  <CardNumberField />
  <View style={{flexDirection: 'row', gap: 12}}>
    <CardExpiryField />
    <CardCVCField />
  </View>
</CardForm>;
```

With no configuration a field renders a complete input: the library's placeholder, a floating
label, the brand mark on the card number, the CVC glyph, and an error tint on a field the customer
left invalid. The composed fields print no error text of their own — the message arrives on
`onChange` as `error`, for you to place — while the ready-made `HyperswitchVaultForm` prints it.

**4. Tokenize when your button is pressed**

```ts
const result = await formRef.current?.tokenize();

if (result?.status === 'success') {
  await sendTokenToYourBackend(result.token); // never store or display the token in the app
} else if (result?.error) {
  showMessage(result.error.message);         // result.error.code names the cause
}
```

`tokenize()` takes no arguments and moves no money. It exchanges the card for a token and stops.
A premature press returns `validation_error` or `incomplete_field_set` **without any network
request**. `onChange` tells you `canSubmit` as the customer types, so a Pay button never has to guess.

---

## Saved card — CVC only

The same shape as the web SDK: mount **only** `CardCVCField`, pass the stored card's token and
network, and settle with the same `tokenize()`.

```tsx
<CardForm ref={formRef} session={session} environment="sandbox" onChange={e => setReady(e.canSubmit)}>
  <CardCVCField
    savedCard={{
      paymentToken: entry.payment_method_token,
      paymentMethodData: {card: {cardNetwork: entry.payment_method_data.card.card_network}},
    }}
  />
</CardForm>;

const result = await formRef.current?.tokenize(); // success: use result.token, not the one you passed
```

Your backend lists the customer's cards with `GET /v1/payment-method-sessions/{id}/list-payment-methods`
using the **same** session, and reads `requires_cvv` off each entry. `false`: charge the listed
token directly and mount nothing. `true`: mount the field with that entry's token. The CVC is held
under the returned token for 15 minutes; confirm from your backend inside that window.

`cardNetwork` selects the CVC length rule. Pass the listing's `card_network` (case and common
aliases such as `amex` are understood); without it `valid` turns true at three digits even on an
Amex card. A CVC field mounted with `savedCard` must be the only field in the form; the token must
be present, or `tokenize()` answers `validation_error` naming the fix.

---

## Custom layout

Place the fields yourself; everything else is identical.

```tsx
<CardForm ref={formRef} session={session} environment="sandbox" appearance={{labels: 'above'}}>
  <CardholderNameField label="Name on card" />
  <CardNumberField placeholder="Card number" cardBrandIcon="standard" />
  <View style={{flexDirection: 'row', gap: 12}}>
    <CardExpiryField placeholder="MM / YY" />
    <CardCVCField placeholder="CVC" cvcIcon="default" />
  </View>
</CardForm>;
```

Exactly one card-number, one expiry and one CVC field per form (or one CVC field with `savedCard`).
`CardholderNameField` is the one field the web SDK does not have; it is optional, and blank it is
omitted from the request.

---

## Events

### On a field

```tsx
<CardNumberField
  onReady={e => {}}   // e: {elementType: 'cardNumber'} — once, after mount
  onFocus={e => {}}   // e: {elementType}
  onBlur={e => {}}    // e: {elementType}
  onChange={e => {
    e.empty;      // nothing typed
    e.complete;   // passes validation (identical to `valid`, as on the web)
    e.valid;
    e.brand;      // 'Visa' | 'Mastercard' | 'AmericanExpress' | … — absent until detected
    e.error;      // the message currently on screen, if any (a string, as on the web)
    e.errorCode;  // 'required' | 'invalid_card_number' | 'invalid_expiry' | 'invalid_cvc'
    e.touched;    // has the customer left this field yet — should your chrome complain?
    e.isCoBadged; // card number only: a genuine choice of network is being offered
  }}
/>
```

`error` follows one rule on every field: it is present once the customer has left the field with a
problem in it, and absent while the cursor is back inside it. No field event carries a card value.

### On the form

```tsx
<CardForm
  onReady={e => {}}   // e: {elementType: 'cardForm'} — every time all required fields become complete
  onChange={e => {
    e.eventName;      // 'cardDetailsChange'
    e.payload;        // the web's payload: bin, last4, brand, expiryMonth, expiryYear,
                      // formattedExpiry, isCardNumberComplete, isCvcComplete, isExpiryComplete,
                      // isCardNumberValid, isExpiryValid — null until known
    e.canSubmit;      // fieldsReady && session usable && valid && !submitting
    e.sessionStatus;  // 'valid' | 'invalid' | 'absent' | 'expired' | 'consumed'
    e.fieldsReady; e.complete; e.valid; e.submitting; e.isCoBadged;
    e.networkError;   // present when the network is not one you accept
    e.fields;         // {cardNumber, cardExpiry, cardCvc, cardholderName?} — each a field `change`
  }}
/>
```

`payload` is built by the same sdk-utils function the web SDK uses, so `bin` appears once six digits
are typed and `last4` once the number is complete, exactly as on the web. It is the only place a
card-derived digit reaches your code; the PAN, the CVC and the token never do.

Every callback fires once after mount and again only when the snapshot actually changes, so an
inline arrow function is safe. Pass no callback and nothing is derived at all.

### The imperative spelling

```ts
const cardForm = createCardForm({session, environment: 'sandbox'});
cardForm.on('change', e => setEnabled(e.canSubmit));
cardForm.on('ready', () => {});

<cardForm.Form>
  <CardNumberField /> <CardExpiryField /> <CardCVCField />
</cardForm.Form>;

const result = await cardForm.tokenize();
cardForm.getState(); // the last `change`, or null
```

---

## The handle

```ts
/* root — merchants */
type VaultFormHandle = {
  tokenize(): Promise<VaultTokenizeResult>;
  reset(): void;
  focus(field: 'cardNumber' | 'cardExpiry' | 'cardCvc' | 'cardholderName'): void;
};

/* each field's ref */
type VaultFieldHandle = {focus(): void; blur(): void; clear(): void};

/* ./host — the checkout SDK; the same runtime object */
type HostFormHandle = VaultFormHandle & {
  confirmPayment(input: VaultPaymentConfirmInput): Promise<VaultPaymentResult>;
};
```

- Repeating the **same** operation while it is pending returns the same promise — double presses are
  harmless. The web SDK answers a second concurrent call with `tokenization_in_progress`; this
  library keeps the friendlier behaviour deliberately.
- Requesting the **other** operation mid-flight (on `./host`) returns `confirm_in_progress` /
  `tokenization_in_progress` with no request.
- `reset()` clears values, validation state and errors, and is ignored while an operation is in
  flight. `clear()` on a field ref clears that one field.

---

## Results

```ts
/* Flow 1 — the ONLY published type carrying a token. */
type VaultTokenizeResult =
  | {status: 'success';          token: string}
  | {status: 'validation_error'; error: SafeVaultError}
  | {status: 'error';            error: SafeVaultError};

type SafeVaultError = {
  code: SafeVaultErrorCode;
  message: string;                                          // library-owned, customer-safe
  type: 'validation_error' | 'api_error' | 'card_error';   // the web's classification
};
```

`if (result.error)` works exactly as it does with the web SDK. The `status` discriminant is this
library's addition so TypeScript can narrow.

| `error.code` | Meaning | Request sent? |
|---|---|---|
| `validation_error` | a field is empty or malformed, or `savedCard` has no token | no |
| `incomplete_field_set` | a required field is missing or mounted twice | no |
| `session_expired` | the session's `expires_at` has passed | no |
| `session_consumed` | this session already tokenized a card | no |
| `invalid_session` | no session, an unreadable one, or another vault's | no |
| `unsupported_configuration` | an invalid endpoint, or `savedCard` beside a card-number field | no |
| `tokenization_failed` | the vault refused, or answered unreadably | yes |
| `unknown_outcome` | the request threw, timed out, or was aborted — reconcile before retrying | unknown |
| `confirm_in_progress` | `./host` only: a payment confirmation is in flight | no |

---

## Appearance, labels and locale

```tsx
<CardForm
  appearance={{
    variables: {
      colorPrimary: '#0570DE',      // the web's variable names…
      colorText: '#1A1A1A',
      colorDanger: '#DF1B41',
      colorTextPlaceholder: '#6B7280',
      colorBackground: '#FFFFFF',
      borderColor: '#E6E6E6',
      borderRadius: 8,
      fontFamily: 'System',
      inputFieldHeight: 48,
      gap: 12,                      // …plus this library's: borderWidth, gap, fontScale,
      cardBrandIcon: 'standard',    // placeholderTextSizeAdjust, errorTextSizeAdjust,
    },                              // errorMessageSpacing, cardBrandIcon
    labels: 'floating',             // 'above' | 'floating' | 'never', for every field
  }}
  locale="fr"                       // any code the web SDK accepts; the same sdk-utils bundles
  localisation={{validationMessages: {cardNumberInvalid: 'Vérifiez le numéro'}}} // overrides on top
/>
```

The web's `theme`, `rules` (CSS selectors), `innerLayout` and `fonts` are CSS concepts with no React
Native analogue. Per-field looks use `styles` slots (`root`, `container`, `input`, `placeholder`,
`label`, `error`, `accessory`) which patch the theme rather than replacing it.

## Field options

| Prop | Fields | Values | Default |
|---|---|---|---|
| `placeholder` | all | any string; `''` renders none | the locale's, or the web's `1234 1234 1234 1234` / `123` |
| `label` | all | any string; `''` renders none | the locale's |
| `labelBehavior` | all | `'above' \| 'floating' \| 'never'` | `appearance.labels`, else `'floating'` |
| `errorDisplay` | all | `'none' \| 'colorOnly' \| 'inline'` | `'colorOnly'` composed, `'inline'` ready-made |
| `cardBrandIcon` | card number | `'standard' \| 'hidden' \| 'animated' \| 'hideGeneric'` | `appearance.variables.cardBrandIcon`, else `'standard'` |
| `cvcIcon` | CVC | `'hidden' \| 'default'` | `'default'` |
| `savedCard` | CVC | `{paymentToken, paymentMethodData: {card: {cardNetwork}}}` | none |
| `unstyled` | all | boolean | the form's `unstyled` |
| `accessibilityLabel`, `accessibilityHint`, `testID` | all | string | library defaults |

`enabledCardSchemes` on the form restricts the networks you accept. Spellings are canonicalised
(`'visa'`, `'amex'`, `'American Express'` all work); an unrecognised entry is ignored and, in a
development build, warned about.

---

## Self-hosted deployments

`environment` selects a public Hyperswitch host. A self-hosted deployment overrides it with
`vaultEndpoint`, which is where `tokenize()` posts the payment-method-session confirm:

```tsx
<CardForm session={session} environment="sandbox" vaultEndpoint={{baseUrl: 'https://payments.your-company.example/api'}} />
```

The base is validated: `https` required (`http` only on a loopback host and never in production),
no credentials, no query string, no fragment. A base that fails validation returns
`unsupported_configuration` with nothing sent.

---

## Lifecycle

- **A session is single-use.** After a successful `tokenize()` it is `consumed`: `sessionStatus`
  says so, `canSubmit` turns false, and a second call answers `session_consumed` — the same rule the
  web SDK applies. Fetch a fresh session per card.
- **`expires_at` is honoured** when the session response is passed through; `sessionStatus` reports
  `expired` and `tokenize()` answers `session_expired` without a request.
- **Replacing the `session` prop** aborts in-flight work and starts a fresh conversation.
- **A minted token is never re-minted.** On `./host`, if tokenization succeeds and the payment
  confirm then fails, a retry re-runs only the confirm.

---

## Security

- Secret API key: **server only.** Never in the app, an app `.env`, or version control.
- Never log or display the session, the `sdk_authorization`, or anything decoded from it. This
  library contains no logging at all, deliberately, beyond a development-only warning for an
  unrecognised `enabledCardSchemes` entry.
- The payment-method token belongs on your backend, not in your app and not in your logs.

The boundary, stated exactly:

> PAN, expiry and CVC never cross the library's supported public API. They remain in library-owned
> state and are transmitted only by the library's internal tokenization transport. The merchant
> receives the web SDK's card-details payload (BIN, last four, expiry parts), safe UI state, and the
> resulting token.

That is an API and data-flow guarantee — **not** native-process isolation, **not** memory
zeroization, **not** a claim of PCI DSS compliance, and **not** protection from malicious code
executing inside your own application process. Only your own assessor can determine your scope.

---

## Troubleshooting

| Symptom | Cause |
|---|---|
| `invalid_session` immediately, nothing sent | the session has no `vault_details`, an unsupported `vault_type`, or a blank authorization. Check your server returned the response *verbatim*. |
| `incomplete_field_set` | a required field is not mounted, or is mounted twice. |
| `session_consumed` | this session already tokenized a card. Fetch a new one. |
| `validation_error` with a message about `savedCard` | the lone CVC field has no `paymentToken`. |
| every card reports `networkError` | `enabledCardSchemes` contains no recognised network. Check the development warning. |
| `Cannot read properties of null (reading 'useMemo')` at render | two copies of React in the bundle. Alias `react`, `react-dom` and `react-native` to single absolute paths. |

---

## Migrating from 0.8

| 0.8 | 0.9 |
|---|---|
| `CardCVCField`, `CardCVCWidget`, `CardNumberWidget`, `CardExpiryWidget`, `CardholderNameWidget`, `HyperswitchVault.*` | `CardCVCField`, `CardNumberField`, `CardExpiryField`, `CardholderNameField` |
| `'expiry'`, `'cvc'` (in `focus()`, `state.field`, `fields.*`, `fieldOptions.*`, `fieldStyles.*`) | `'cardExpiry'`, `'cardCvc'` |
| `onStateChange` / `onFormStateChange` | `onChange` (+ `onReady`, `onFocus`, `onBlur`) |
| `state.status`, `state.focused`, `state.error.code` | `empty`/`complete`, focus/blur events, `errorCode` |
| `brand: 'visa' \| 'americanExpress' \| … \| 'unknown'` | `brand: 'Visa' \| 'AmericanExpress' \| …`, absent when unknown |
| `brandIconMode` | `cardBrandIcon` |
| `cvcIcon: 'none'` | `cvcIcon: 'hidden'` |
| `labelBehavior: 'static' \| 'none'` | `'above' \| 'never'` (and form-wide `appearance.labels`) |
| `appearance.primaryColor`, `textColor`, `errorColor`, `placeholderColor`, `backgroundColor`, `inputHeight`, `brandIconMode` | `appearance.variables.colorPrimary`, `colorText`, `colorDanger`, `colorTextPlaceholder`, `colorBackground`, `inputFieldHeight`, `cardBrandIcon` |
| `HyperswitchVaultSavedCardForm` + `updateSavedPaymentMethod()` | `<CardCVCField savedCard={…} />` inside `<CardForm>` + `tokenize()` |
| `invalid_card_data`, `not_ready`, `server_error` | `validation_error`, `incomplete_field_set`, `tokenization_failed` |
| `createCardForm().subscribe(cb)` | `createCardForm().on('change', cb)` |

## Example app

`example/` is a runnable React Native app and `example-server/` a dependency-free merchant backend.
They are separate directories on purpose — **the secret API key belongs only on the server.**
