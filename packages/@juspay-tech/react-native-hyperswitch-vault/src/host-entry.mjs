
/*
 * Runtime entry for the `./host` subpath. The ONLY source of runtime values for it.
 *
 * AUDIENCE. @juspay-tech/react-native-hyperswitch-payment-methods, never merchants. The checkout
 * SDK (hyperswitch-client-core → payment-methods) renders the same provider and the same four
 * fields a merchant does, but it drives them with a wider handle — `confirmPayment()` — and two
 * props the merchant integration has no use for (`eligibility`, `cardholderName: 'external'`).
 * That wider TYPE surface lives in `src/host.ts`; this file exists only so the subpath resolves to
 * a runtime.
 *
 * SAME OBJECTS. Every export below is the root entry's component, re-exported — not a copy and not
 * a second bundle. Rollup keeps `./standalone-entry.mjs` external and rewrites it to `./index.js`,
 * so `dist/esm/host.js` is a handful of re-export lines over `dist/esm/index.js`. That is what makes
 * `require(PKG + '/host').CardNumberField === require(PKG).CardNumberField` hold, and it is what
 * keeps a single `VaultWidgetContext` in the app: a field imported from one entry registers with a
 * provider imported from the other. `scripts/verify-consumers.mjs` asserts the identity against the
 * packed tarball; `scripts/verify-public-surface.mjs` asserts this file is a pure re-export.
 *
 * Deliberately absent: the ready-made `HyperswitchVaultForm`, the `HyperswitchVault` namespace and
 * the legacy `*Widget` spellings. The checkout SDK composes fields itself and has never used them.
 */

export {
  CardForm,
  CardNumberField,
  CardExpiryField,
  CardCVCField,
  CardholderNameField,
} from './standalone-entry.mjs';
