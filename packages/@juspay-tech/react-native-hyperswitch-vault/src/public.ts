
/*
 * Type-only surface for the package root — THE MERCHANT ENTRY.
 *
 * tsc runs with `emitDeclarationOnly`, so nothing here executes: the runtime values come from
 * `src/standalone-entry.mjs`, which Rollup bundles into dist/{esm,cjs}/index.js. This file exists
 * to re-attach the ref types genType drops (it emits a forwardRef component as
 * `React.ComponentType<Props>`) and to name the public types.
 *
 * The two files must stay in lockstep — `scripts/verify-public-surface.mjs` fails the build if the
 * value exports here and there differ.
 *
 * ── ONE AUDIENCE PER ENTRY (ADR-0010) ────────────────────────────────────────
 *
 * The root describes exactly the integration the library is delivered for:
 *
 *     your backend hands the app a session → you place the four fields → tokenize() → a token
 *
 * The checkout SDK (hyperswitch-client-core, through payment-methods) renders the SAME components
 * but drives them with a wider contract — `confirmPayment()`, the `eligibility` prop, the
 * `'external'` cardholder-name mode, and the confirm-input / navigation types behind them. That
 * contract is published on the `./host` subpath (`src/host.ts`) and NOT here. Nothing below names
 * a payment result, a next action, a confirm input, or an eligibility verdict; the same gate that
 * keeps `./orchestration` off this surface keeps `./host` off it too.
 *
 * The runtime objects are shared: `./host` re-exports this entry's components, so a field imported
 * from one entry registers with a provider imported from the other. Only the TYPES differ. A
 * merchant who reaches `confirmPayment` through `any` has gained nothing they did not already have
 * — it needs a payment-intent credential — so the split is a contract boundary, not a security
 * boundary, and it does not claim to be one.
 */

import './jsx-global';
import type * as React from 'react';
import { make as RawHyperswitchVaultForm, type Props as FormPropsInternal } from './HyperswitchVaultForm.gen';
import {
  make as RawCardForm,
  type Props as ProviderPropsInternal,
  type widgetHandle,
} from './CardForm.gen';
import { make as RawCardNumberWidget } from './CardNumberWidget.gen';
import type {
  fieldStyles,
  expiryStyles,
  formFieldStyles,
} from './CardFieldStyles.gen';
import type {
  labelBehavior,
  errorDisplay,
  brandIconMode as fieldBrandIconMode,
  cvcIconDisplay,
  fieldOptions,
  cardNumberOptions,
  expiryOptions,
  cvcOptions,
  cardholderNameOptions,
  formFieldOptions,
  formLayout,
  fieldArrangement,
} from './CardFieldOptions.gen';
import { make as RawCardExpiryWidget } from './CardExpiryWidget.gen';
import { make as RawCardCVCWidget } from './CardCVCWidget.gen';
import { make as RawCardholderNameWidget } from './CardholderNameWidget.gen';
import {
  make as RawHyperswitchVaultSavedCardForm,
  type Props as SavedCardPropsInternal,
} from './HyperswitchVaultSavedCardForm.gen';
import type {
  localisation as LocalisationInternal,
  localisationMessages as LocalisationMessagesInternal,
} from './HyperswitchVaultForm.gen';
import type {
  cardNumberState as CardNumberStateInternal,
  expiryState,
  cvcState,
  cardholderNameState,
  vaultFormFields as VaultFormFieldsInternal,
  vaultFormState as VaultFormStateInternal,
} from './VaultPublicState.gen';

/* ── The handle ───────────────────────────────────────────────────────────── */

export type VaultField = 'cardNumber' | 'expiry' | 'cvc' | 'cardholderName';

/*
 * ── THE ONLY TOKENIZE ERROR CODES ────────────────────────────────────────────
 *
 * The library's full error vocabulary has eight codes; `tokenize()` can produce six of them.
 * `forbidden_card_data` and `card_not_eligible` belong to `confirmPayment()` on the `./host`
 * entry, so publishing them here would force every exhaustive `switch` on a tokenize result to
 * handle two branches that cannot occur. The runtime object is the generated `safeVaultError`;
 * this narrows what the compiler knows about it, and `scripts/verify-result-mapping.mjs` pins the
 * six codes against what the tokenize mapping actually emits.
 */
export type SafeVaultErrorCode =
  | 'invalid_card_data'
  | 'not_ready'
  | 'invalid_session'
  | 'unsupported_configuration'
  | 'server_error'
  | 'unknown_outcome';

export type SafeVaultError = { readonly code: SafeVaultErrorCode; readonly message: string };

/*
 * The ONLY published type with a `token`. Deliberately permitted here, and nowhere else.
 */
export type VaultTokenizeResult =
  | { readonly status: 'success'; readonly token: string }
  | { readonly status: 'validation_error'; readonly error: SafeVaultError }
  | { readonly status: 'not_ready'; readonly error: SafeVaultError }
  | { readonly status: 'error'; readonly error: SafeVaultError };

/*
 * Three operations. `tokenize()` is the one that yields a token; it takes no input and charges
 * nothing. The payment operation — `confirmPayment()` — is not a member of this handle: it lives on
 * the `./host` entry's `HostFormHandle`, over the same runtime object.
 */
export type VaultFormHandleShape = {
  /** Mint a payment-method token and stop. Takes no input; charges nothing. */
  tokenize(): Promise<VaultTokenizeResult>;
  reset(): void;
  focus(field: VaultField): void;
};

/*
 * ── WHO OWNS THE CARDHOLDER NAME ─────────────────────────────────────────────
 *
 *   'collect'    the library renders its own bare input and uses what was typed. The default.
 *   'omit'       the library renders no name field and sends no name.
 *
 * The third mode, 'external', takes the name from the confirm input and therefore only means
 * something on `./host`; `tokenize()` takes no input, so for a merchant it would be `'omit'` under
 * another name.
 */
export type VaultCardholderNameMode = 'collect' | 'omit';

/*
 * ── Localisation, without the eligibility message ────────────────────────────
 *
 * `cardNotEligible` is the text of a `./host` eligibility denial. `tokenize()` never runs that
 * probe, so the key is absent here rather than documented as "unused".
 */
export type VaultFormValidationMessages = Omit<LocalisationMessagesInternal, 'cardNotEligible'>;
export type VaultFormLocalisation = Omit<LocalisationInternal, 'validationMessages'> & {
  readonly validationMessages?: VaultFormValidationMessages;
};

/*
 * ── Emitted state (ADR-0005), without the eligibility verdict ────────────────
 *
 * What the form and the individual fields report while the customer types. Every member is derived
 * from library-owned state and carries no card value: no PAN, no BIN, no last four, no value
 * length, no expiry month or year, no CVC, no token and no credential. The only card-derived
 * members are the detected scheme name and the localised message already on screen.
 *
 * `eligibility` is omitted from the card-number and form snapshots: on this entry it is always
 * `'unknown'`, because nothing here runs the probe. The runtime object still carries it — the
 * generated types on `./host` show it — and a structural supertype is exactly the right description
 * of an object with one inert member more.
 *
 * `scripts/verify-event-surface.mjs` gates the no-card-value claim against the PACKED declarations.
 */
export type VaultCardNumberState = Omit<CardNumberStateInternal, 'eligibility'>;
export type VaultFormFields = Omit<VaultFormFieldsInternal, 'cardNumber'> & {
  readonly cardNumber: VaultCardNumberState;
};
export type VaultFormState = Omit<VaultFormStateInternal, 'eligibility' | 'fields'> & {
  readonly fields: VaultFormFields;
};

/*
 * The union a merchant writes when one handler serves several fields. Each member is narrowed by
 * its own `field` discriminant, so `switch (state.field)` gives back the exact shape — and reading
 * `brand` is a type error anywhere but the card-number branch.
 */
export type VaultFieldState = VaultCardNumberState | expiryState | cvcState | cardholderNameState;

/* ── Props ────────────────────────────────────────────────────────────────── */

/*
 * The generated Props carry the host members. They are removed here by name and the three members
 * whose TYPE narrows on this entry are re-declared; everything else is the generated declaration,
 * so the merchant surface cannot drift from what the library actually reads.
 */
type MerchantProps<P> = Omit<P, 'eligibility' | 'cardholderName' | 'localisation' | 'onFormStateChange'> & {
  readonly cardholderName?: VaultCardholderNameMode;
  readonly localisation?: VaultFormLocalisation;
  readonly onFormStateChange?: (state: VaultFormState) => void;
};

export type CardFormProps = MerchantProps<ProviderPropsInternal>;
export type HyperswitchVaultFormProps = MerchantProps<FormPropsInternal>;

/* ── Component types ──────────────────────────────────────────────────────── */

type VaultFormComponent<P> = React.ForwardRefExoticComponent<
  P & React.RefAttributes<VaultFormHandleShape>
>;

/*
 * ── Per-field style slots (ADR-0002 §9 layer 2) ──────────────────────────────
 *
 * `fieldStyles` / `expiryStyles` / `formFieldStyles` are the GENERATED types from
 * CardFieldStyles.res, imported — not re-declared and not re-cast here. That is what makes this a
 * proof rather than an assertion: if genType ever emitted an opaque handle or `any`, the type-tests
 * in type-tests/consumer.tsx would stop rejecting a plainly-wrong style value, and
 * `check:generated` would show the drift.
 *
 * The bridge does contain localized zero-runtime coercions, inside `CardFieldStyles.Unsafe`. They
 * are the only ones in the library and `scripts/verify-style-bridge.mjs` gates that; see
 * docs/phase-2a-style-bridge-spike.md for the full argument and the measurements behind it.
 *
 * The expiry field takes a SMALLER slot set. It renders no accessory element — `CardFields.Expiry`
 * never passes `iconRight`, so `CardInput` matches `NoIcon` and returns nothing — and a slot with no
 * rendered target would be a silent no-op.
 *
 * Note `children` is absent from every field type: the generated Props carries it, but it has never
 * been part of the published field surface.
 */
/*
 * ── Field options: which visual elements exist ────────────────────────────────
 *
 * Separate from `styles`, which says how the enabled elements look. With no options a field renders
 * a COMPLETE UI: a floating label carrying the library's own string, the brand mark on the card
 * number, the CVC glyph, and inline validation messages. Each element is individually switchable,
 * and `unstyled` removes all of them — and the bordered box with them — leaving a plain
 * `TextInput` that keeps its accessibility label, keyboard type, length limit and CVC masking.
 *
 * The option props are FLATTENED onto the component rather than nested, because a merchant placing
 * one field writes `<CardNumberField placeholder="Card number" />`. The grouped `fieldOptions`
 * record exists on the ready-made form, where three fields are addressed at once.
 *
 * Each field's option set is its own type: only the card number has `brandIconMode`, only the CVC has
 * `cvcIcon`, and the expiry has neither — the same rule that already keeps `accessory` off the
 * expiry style type.
 */
/*
 * ── State emission (ADR-0005, superseding ADR-0003) ──────────────────────────
 *
 * A field takes styles, options, a ref, and one callback reporting its own state. The callback
 * carries validity, completeness, focus, whether the customer has touched it, and the message it is
 * currently showing — and, for the card number, the detected scheme. It carries no card value:
 * no PAN, no BIN, no last four, no length, no expiry parts, no CVC.
 *
 * The state type is a parameter rather than a union so each field publishes ITS OWN shape:
 * `brand` exists on the card-number callback and on no other, structurally rather than by comment.
 * `scripts/verify-event-surface.mjs` pins the payload member by member against the packed
 * declarations, so widening it is a build failure rather than a judgement call.
 */
type VaultStyledFieldComponent<S, O, State> = React.ForwardRefExoticComponent<
  { styles?: S; onStateChange?: (state: State) => void } & O & React.RefAttributes<widgetHandle>
>;

/* ── Existing published names — unchanged ─────────────────────────────────── */

export type HyperswitchVaultFormHandle = VaultFormHandleShape;

export const HyperswitchVaultForm =
  RawHyperswitchVaultForm as unknown as VaultFormComponent<HyperswitchVaultFormProps>;

export type WidgetHandle = widgetHandle;

export const CardForm =
  RawCardForm as unknown as VaultFormComponent<CardFormProps>;

export const CardNumberWidget = RawCardNumberWidget as unknown as VaultStyledFieldComponent<
  fieldStyles,
  cardNumberOptions,
  VaultCardNumberState
>;
export const CardExpiryWidget = RawCardExpiryWidget as unknown as VaultStyledFieldComponent<
  expiryStyles,
  expiryOptions,
  expiryState
>;
export const CardCVCWidget = RawCardCVCWidget as unknown as VaultStyledFieldComponent<
  fieldStyles,
  cvcOptions,
  cvcState
>;

/*
 * The cardholder name is a LIBRARY-OWNED field like the other three: the merchant styles and
 * labels it, and has no route to read or set what was typed.
 *
 * It is optional. The ready-made form always renders it, full width above the card number; a custom
 * layout may omit it entirely and `tokenize()` still succeeds, because it is not part of the
 * presence gate. When it is left blank the field is omitted from the tokenization request altogether.
 */
export const CardholderNameWidget = RawCardholderNameWidget as unknown as VaultStyledFieldComponent<
  fieldStyles,
  cardholderNameOptions,
  cardholderNameState
>;

/*
 * ── The saved-card CVC component (ADR-0008) ──────────────────────────────────
 *
 * A customer paying with a card the merchant has ALREADY saved is often asked for the CVC again.
 * The merchant lists their saved methods (`GET …/list-payment-methods`, with the same session),
 * reads `requires_cvv` off each entry, and for a card that needs one mounts this component with
 * that entry's token. It renders the library's own CVC field — the same implementation the
 * new-card form renders — and `updateSavedPaymentMethod()` sends the CVC to the vault and resolves
 * to the token the RESPONSE carries. The merchant's backend uses that returned token for the final
 * confirmation, within the vault's 15-minute CVC window; nothing here confirms a payment.
 *
 * The result is the SAME `VaultTokenizeResult` as `tokenize()`: `token` only on success, the same
 * six codes. The emitted state is the SAME `VaultCVCState` the CVC field emits: no new type, no
 * `canSubmit`, no `brand` — `state.valid` already answers "may I enable Pay?", and the network hint
 * cannot be reflected back because the type structurally has no member for it.
 *
 * No `children`: the component owns its one field, so a merchant cannot mount zero or two. No
 * `requires_cvv`: by the time this is on screen the merchant has read that flag and decided.
 */
export type VaultSavedCardHandle = {
  /**
   * Validate the CVC, send it to the vault, and resolve to the token the response carries. Never
   * confirms a payment; never charges anything.
   */
  updateSavedPaymentMethod(): Promise<VaultTokenizeResult>;
  /** Clear the CVC and abandon any request in flight. */
  reset(): void;
  /** One field, so no argument. */
  focus(): void;
  blur(): void;
};

/*
 * The generated props, unmodified: `session`, `environment` and `paymentMethodToken` are required,
 * the rest optional. `cardNetwork` is a hint selecting the CVC length rule — pass `card_network`
 * from `list-payment-methods`, or `state.valid` turns true at three digits on an Amex card.
 */
export type HyperswitchVaultSavedCardFormProps = SavedCardPropsInternal;

export const HyperswitchVaultSavedCardForm =
  RawHyperswitchVaultSavedCardForm as unknown as React.ForwardRefExoticComponent<
    HyperswitchVaultSavedCardFormProps & React.RefAttributes<VaultSavedCardHandle>
  >;

/*
 * ── Canonical field names (ADR-0002 §1) ──────────────────────────────────────
 *
 * Aliases of the bindings above, not fresh casts of the raw imports, so the declared type is
 * literally the same type and cannot drift. The runtime counterpart in standalone-entry.mjs binds
 * the same component objects, so `CardNumberField === CardNumberWidget` holds at runtime too.
 */

export const CardNumberField = CardNumberWidget;
export const CardExpiryField = CardExpiryWidget;
export const CardCVCField = CardCVCWidget;
export const CardholderNameField = CardholderNameWidget;

/*
 * ── Handle type aliases (ADR-0002 §3) ────────────────────────────────────────
 *
 * Aliases, never re-declarations: writing the members out again would let the two drift silently.
 */

export type VaultFieldHandle = WidgetHandle;
export type VaultFormHandle = HyperswitchVaultFormHandle;

/*
 * ── Style types (ADR-0002 §9 layer 2) ────────────────────────────────────────
 *
 * `VaultFieldStyles` is the full slot set and the base every field type derives from.
 * `VaultExpiryStyles` is the same minus `accessory`, because the expiry field renders none.
 */
export type VaultFieldStyles = fieldStyles;
export type VaultCardNumberStyles = fieldStyles;
export type VaultExpiryStyles = expiryStyles;
export type VaultCVCStyles = fieldStyles;
export type VaultFormFieldStyles = formFieldStyles;

/*
 * ── Field option types ───────────────────────────────────────────────────────
 *
 * All generated from CardFieldOptions.res — imported, never re-declared, so the published shape
 * cannot drift from what the library actually reads. Every union is closed and literal.
 */
export type VaultLabelBehavior = labelBehavior;
export type VaultErrorDisplay = errorDisplay;
export type VaultCVCIconDisplay = cvcIconDisplay;

/*
 * ONE brand-icon control. `VaultBrandIconMode` is the same union `appearance.brandIconMode` has
 * always used — it already had a `hidden` member, so a second on/off type would have been a second
 * way to spell "off". It is published under both names because `VaultFormBrandIconMode` is the
 * existing appearance-level spelling and merchants may already reference it.
 *
 * Precedence, resolved in exactly one place:
 *   fieldOptions.cardNumber.brandIconMode  →  appearance.brandIconMode  →  'standard'
 */
export type VaultBrandIconMode = fieldBrandIconMode;

export type VaultFieldOptions = fieldOptions;
export type VaultCardNumberOptions = cardNumberOptions;
export type VaultExpiryOptions = expiryOptions;
export type VaultCVCOptions = cvcOptions;
export type VaultCardholderNameOptions = cardholderNameOptions;
export type VaultFormFieldOptions = formFieldOptions;

export type VaultFormLayout = formLayout;
export type VaultFieldArrangement = fieldArrangement;

/*
 * ── Convenience namespace (ADR-0002 §2) ──────────────────────────────────────
 *
 * Declared, not constructed — the object itself lives in standalone-entry.mjs. `useForm` is
 * deliberately absent: `useHyperswitchVaultForm` belongs to a later phase.
 */

export declare const HyperswitchVault: {
  readonly CardForm: typeof HyperswitchVaultForm;
  readonly Form: typeof CardForm;
  readonly CardNumber: typeof CardNumberField;
  readonly Expiry: typeof CardExpiryField;
  readonly CVC: typeof CardCVCField;
  readonly CardholderName: typeof CardholderNameField;
};

/* ── Public type re-exports ───────────────────────────────────────────────── */

export type {
  brandIconMode as VaultFormBrandIconMode,
  localisationLabels as VaultFormLabels,
  appearance as VaultFormAppearance,
  vaultEnvironment as VaultEnvironment,
} from './HyperswitchVaultForm.gen';

export type { vaultTokenizeStatus as VaultTokenizeStatus } from './VaultResult.gen';

export type { vaultEndpointConfig as VaultEndpointConfig } from './VaultEndpoint.gen';

export type { MerchantSession } from './merchantTypes';

export type {
  cardBrand as VaultCardBrand,
  vaultFieldStatus as VaultFieldStatus,
  vaultFieldErrorCode as VaultFieldErrorCode,
  vaultFieldError as VaultFieldError,
  vaultSessionStatus as VaultSessionStatus,
  expiryState as VaultExpiryState,
  cvcState as VaultCVCState,
  cardholderNameState as VaultCardholderNameState,
} from './VaultPublicState.gen';
