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
 * ── THE WEB SDK'S NAMES ──────────────────────────────────────────────────────
 *
 * A merchant integrating hyperswitch-web's separate card fields and this library meets ONE
 * vocabulary. Field identifiers are `cardNumber` / `cardExpiry` / `cardCvc`; per-field events are
 * `onReady` / `onFocus` / `onBlur` / `onChange` with the web's `change` payload keys (`empty`,
 * `complete`, `valid`, `brand`, `error`); the form's `onChange` carries the web's
 * `cardDetailsChange` envelope; option names are the web's (`cardBrandIcon`, `cvcIcon`,
 * `savedCard`, `appearance.variables.*`, `appearance.labels`, `locale`); and a failed result is
 * the web's `{error: {code, message, type}}` with the web's codes. What this library adds is
 * additive, and named so it cannot collide.
 *
 * ── ONE AUDIENCE PER ENTRY (ADR-0010) ────────────────────────────────────────
 *
 * The root describes exactly the integration the library is delivered for:
 *
 *     your backend hands the app a session → you place the fields → tokenize() → a token
 *
 * The checkout SDK renders the SAME components but drives them with a wider contract —
 * `confirmPayment()`, the `eligibility` prop, the `'external'` cardholder-name mode, and the
 * confirm-input / navigation types behind them. That contract is published on the `./host` subpath
 * (`src/host.ts`) and NOT here.
 */

import './jsx-global';
import type * as React from 'react';
import { make as RawHyperswitchVaultForm, type Props as FormPropsInternal } from './HyperswitchVaultForm.gen';
import {
  make as RawCardForm,
  type Props as ProviderPropsInternal,
  type widgetHandle,
} from './CardForm.gen';
import { make as RawCardNumberField, type Props as CardNumberPropsInternal } from './CardNumberField.gen';
import { make as RawCardExpiryField, type Props as CardExpiryPropsInternal } from './CardExpiryField.gen';
import { make as RawCardCVCField, type Props as CardCvcPropsInternal } from './CardCVCField.gen';
import {
  make as RawCardholderNameField,
  type Props as CardholderNamePropsInternal,
} from './CardholderNameField.gen';
import type { fieldStyles, expiryStyles, formFieldStyles } from './CardFieldStyles.gen';
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
  savedCard,
} from './CardFieldOptions.gen';
import type {
  localisation as LocalisationInternal,
  localisationMessages as LocalisationMessagesInternal,
} from './VaultFormOptions.gen';
import type {
  fieldEvent,
  fieldChange as FieldChangeInternal,
  cardFormEvent,
  cardFormChange as CardFormChangeInternal,
  vaultFormFields as VaultFormFieldsInternal,
  cardDetails,
} from './VaultPublicState.gen';

/* ── Identity ─────────────────────────────────────────────────────────────── */

/** The web SDK's field identifiers, plus the cardholder name only this library collects. */
export type VaultField = 'cardNumber' | 'cardExpiry' | 'cardCvc' | 'cardholderName';

/* ── The result ───────────────────────────────────────────────────────────── */

export type SafeVaultErrorType = 'validation_error' | 'api_error' | 'card_error';

/*
 * The codes `tokenize()` can produce. The first six are the web SDK's own vocabulary for its
 * `tokenize()`; the last three exist only here. `forbidden_card_data`, `card_not_eligible`,
 * `payment_failed` and `tokenization_in_progress` belong to `confirmPayment()` on `./host`, so
 * publishing them here would force every exhaustive `switch` to handle branches that cannot occur.
 */
export type SafeVaultErrorCode =
  | 'validation_error'
  | 'incomplete_field_set'
  | 'session_expired'
  | 'session_consumed'
  | 'confirm_in_progress'
  | 'tokenization_failed'
  | 'invalid_session'
  | 'unsupported_configuration'
  | 'unknown_outcome';

/** The web's error envelope: `if (result.error)` reads the same way on both SDKs. */
export type SafeVaultError = {
  readonly code: SafeVaultErrorCode;
  readonly message: string;
  readonly type: SafeVaultErrorType;
};

/**
 * The card the vault stored, spelled the way `onChange` spells it, so `result.card.last4` and
 * `event.payload.last4` read the same. Present when a new card was tokenized; absent on the
 * saved-card CVC refresh, which returns nothing but the token. Never a PAN, never a CVC.
 */
export type VaultTokenizedCard = {
  readonly bin?: string;
  readonly last4: string;
  readonly brand?: string;
  readonly expiryMonth: string;
  readonly expiryYear: string;
};

/** The ONLY published type with a `token`. Deliberately permitted here, and nowhere else. */
export type VaultTokenizeResult =
  | { readonly status: 'success'; readonly token: string; readonly card?: VaultTokenizedCard }
  | { readonly status: 'validation_error'; readonly error: SafeVaultError }
  | { readonly status: 'error'; readonly error: SafeVaultError };

/*
 * `tokenize()` is the one operation that yields a token; it takes no input and charges nothing.
 * With one `CardCVCField` mounted with `savedCard`, it refreshes that card's CVC instead and
 * resolves to the token the response carries. `confirmPayment()` lives on `./host`.
 */
export type VaultFormHandleShape = {
  /** Mint a payment-method token (or refresh a saved card's CVC) and stop. Charges nothing. */
  tokenize(): Promise<VaultTokenizeResult>;
  reset(): void;
  focus(field: VaultField): void;
};

/* ── Configuration ────────────────────────────────────────────────────────── */

/*
 * `'collect'`: the library renders its own name input and uses what was typed (the default).
 * `'omit'`: no name field, no name sent. The third mode, `'external'`, only means something on
 * `./host`.
 */
export type VaultCardholderNameMode = 'collect' | 'omit';

/** Overrides on top of the `locale` bundle. `cardNotEligible` is a `./host` message. */
export type VaultFormValidationMessages = Omit<LocalisationMessagesInternal, 'cardNotEligible'>;
export type VaultFormLocalisation = Omit<LocalisationInternal, 'validationMessages'> & {
  readonly validationMessages?: VaultFormValidationMessages;
};

/* ── Events ───────────────────────────────────────────────────────────────── */

/** `onReady`, `onFocus`, `onBlur` on a field: `{elementType}`. */
export type VaultFieldEvent = fieldEvent;

/**
 * `onChange` on a field: the web's `{elementType, empty, complete, valid, brand?, error?}` plus
 * `touched`, `errorCode` and (card number) `isCoBadged`. `eligibility` only exists on `./host`.
 * No member carries a card value.
 */
export type VaultFieldChange = Omit<FieldChangeInternal, 'eligibility'>;

export type VaultFormFields = Omit<VaultFormFieldsInternal, 'cardNumber'> & {
  readonly cardNumber: VaultFieldChange;
};

/** The web's `cardDetailsChange` payload: `bin`, `last4`, `brand`, the expiry parts and the flags. */
export type VaultCardDetails = cardDetails;

/** `onReady` on the form: `{elementType: 'cardForm'}`, on every transition to complete. */
export type VaultCardFormEvent = cardFormEvent;

/**
 * `onChange` on the form: the web's `{elementType: 'cardForm', eventName: 'cardDetailsChange',
 * payload}` envelope plus this library's `fieldsReady`, `sessionStatus`, `complete`, `valid`,
 * `submitting`, `canSubmit`, `isCoBadged`, `networkError` and per-field `fields`.
 */
export type VaultCardFormChange = Omit<CardFormChangeInternal, 'eligibility' | 'fields'> & {
  readonly fields: VaultFormFields;
};

/* ── Props ────────────────────────────────────────────────────────────────── */

type MerchantProps<P> = Omit<P, 'eligibility' | 'cardholderName' | 'localisation' | 'onChange'> & {
  readonly cardholderName?: VaultCardholderNameMode;
  readonly localisation?: VaultFormLocalisation;
  readonly onChange?: (event: VaultCardFormChange) => void;
};

export type CardFormProps = MerchantProps<ProviderPropsInternal>;
export type HyperswitchVaultFormProps = MerchantProps<FormPropsInternal>;

type FieldProps<P> = Omit<P, 'onChange'> & {
  readonly onChange?: (event: VaultFieldChange) => void;
};

export type CardNumberFieldProps = FieldProps<CardNumberPropsInternal>;
export type CardExpiryFieldProps = FieldProps<CardExpiryPropsInternal>;
export type CardCVCFieldProps = FieldProps<CardCvcPropsInternal>;
export type CardholderNameFieldProps = FieldProps<CardholderNamePropsInternal>;

/* ── Components ───────────────────────────────────────────────────────────── */

type VaultFormComponent<P> = React.ForwardRefExoticComponent<
  P & React.RefAttributes<VaultFormHandleShape>
>;

type VaultFieldComponent<P> = React.ForwardRefExoticComponent<P & React.RefAttributes<widgetHandle>>;

export type VaultFieldHandle = widgetHandle;
export type VaultFormHandle = VaultFormHandleShape;
export type HyperswitchVaultFormHandle = VaultFormHandleShape;

export const CardForm = RawCardForm as unknown as VaultFormComponent<CardFormProps>;
export const HyperswitchVaultForm =
  RawHyperswitchVaultForm as unknown as VaultFormComponent<HyperswitchVaultFormProps>;

export const CardNumberField = RawCardNumberField as unknown as VaultFieldComponent<CardNumberFieldProps>;
export const CardExpiryField = RawCardExpiryField as unknown as VaultFieldComponent<CardExpiryFieldProps>;
export const CardCVCField = RawCardCVCField as unknown as VaultFieldComponent<CardCVCFieldProps>;
/**
 * A LIBRARY-OWNED field like the other three, and the one the web SDK does not have. Optional: a
 * layout may omit it and `tokenize()` still succeeds; blank, it is omitted from the request.
 */
export const CardholderNameField =
  RawCardholderNameField as unknown as VaultFieldComponent<CardholderNameFieldProps>;

/*
 * ── The imperative spelling of <CardForm> ────────────────────────────────────
 *
 * The web's `cardForm()` object model: a HANDLE, not a store. The card state stays inside the
 * mounted component, so the fields must still be rendered inside `Form`, and `tokenize()` before
 * that resolves to `incomplete_field_set` rather than throwing.
 */
export type CardFormInstance = {
  /** `<CardForm>` bound to the config this instance was built with. Props here override those. */
  readonly Form: React.ComponentType<Partial<CardFormProps> & { children: React.ReactNode }>;
  /** The only route to a token. `incomplete_field_set` while nothing is mounted. */
  tokenize(): Promise<VaultTokenizeResult>;
  reset(): void;
  focus(field: VaultField): void;
  /** The last card-free snapshot, or `null` before the form has emitted. */
  getState(): VaultCardFormChange | null;
  /** The web's `cardForm.on(event, cb)`. Returns an unsubscribe. */
  on(event: 'ready', listener: (event: VaultCardFormEvent) => void): () => void;
  on(event: 'change', listener: (event: VaultCardFormChange) => void): () => void;
};

export declare const createCardForm: (
  config?: Partial<Omit<CardFormProps, 'children'>>
) => CardFormInstance;

/* ── Style and option types ───────────────────────────────────────────────── */

export type VaultFieldStyles = fieldStyles;
export type VaultCardNumberStyles = fieldStyles;
export type VaultCardExpiryStyles = expiryStyles;
export type VaultCardCVCStyles = fieldStyles;
export type VaultFormFieldStyles = formFieldStyles;

export type VaultLabelBehavior = labelBehavior;
export type VaultErrorDisplay = errorDisplay;
export type VaultCVCIconDisplay = cvcIconDisplay;
/** `standard` · `hidden` · `animated` · `hideGeneric`, as on the web's `cardBrandIcon`. */
export type VaultCardBrandIcon = fieldBrandIconMode;

export type VaultFieldOptions = fieldOptions;
export type VaultCardNumberOptions = cardNumberOptions;
export type VaultCardExpiryOptions = expiryOptions;
export type VaultCardCVCOptions = cvcOptions;
export type VaultCardholderNameOptions = cardholderNameOptions;
export type VaultFormFieldOptions = formFieldOptions;
/** The web's `savedCard` option: `{paymentToken, paymentMethodData: {card: {cardNetwork}}}`. */
export type VaultSavedCard = savedCard;

export type VaultFormLayout = formLayout;
export type VaultFieldArrangement = fieldArrangement;

/* ── Public type re-exports ───────────────────────────────────────────────── */

export type {
  localisationLabels as VaultFormLabels,
  appearance as VaultFormAppearance,
  appearanceVariables as VaultFormAppearanceVariables,
  vaultEnvironment as VaultEnvironment,
} from './VaultFormOptions.gen';

export type { vaultTokenizeStatus as VaultTokenizeStatus } from './VaultResult.gen';

export type { vaultEndpointConfig as VaultEndpointConfig } from './VaultEndpoint.gen';

export type { MerchantSession } from './merchantTypes';
/** The web's `vaultDetails` option: `{vaultType: 'hyperswitch', vaultData: {sdkAuthorization}}`. */
export type { vaultDetails as VaultDetails, vaultData as VaultData } from './VaultDetails.gen';

export type {
  elementType as VaultElementType,
  cardBrand as VaultCardBrand,
  vaultFieldErrorCode as VaultFieldErrorCode,
  vaultFieldError as VaultFieldError,
  vaultSessionStatus as VaultSessionStatus,
} from './VaultPublicState.gen';
