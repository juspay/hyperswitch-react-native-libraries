
/*
 * Type surface for the `./host` subpath — the checkout-SDK entry (ADR-0010).
 *
 * AUDIENCE. @juspay-tech/react-native-hyperswitch-payment-methods, never merchants. The caller
 * chain is `client-core → payment-methods → this entry`. The package root publishes none of the
 * names that are unique to this file, and `scripts/verify-public-surface.mjs` keeps it that way.
 *
 * `src/host-entry.mjs` is the runtime half of this pair. tsc runs with `emitDeclarationOnly`, so
 * nothing here executes; the same script requires the exported VALUE names on both sides to be
 * identical, and requires every one of them to also be a root export — because they ARE the root's
 * objects, re-exported. Only the types differ:
 *
 *   root `VaultFormHandle`     { tokenize, reset, focus }
 *   host `HostFormHandle`      { tokenize, confirmPayment, reset, focus }
 *
 *   root provider props        no `eligibility`; `cardholderName: 'collect' | 'omit'`
 *   host provider props        the generated Props, in full
 *
 *   root state / localisation  without the eligibility verdict and message
 *   host state / localisation  the generated types, in full
 *
 *   root `SafeVaultErrorCode`  the six codes `tokenize()` can return
 *   host `SafeVaultErrorCode`  all eight, including `forbidden_card_data` and `card_not_eligible`
 *
 * Everything the two surfaces share — styles, options, appearance, brands, field states, the
 * tokenize result — is imported from `./public` and re-exported, never re-declared.
 */

import './jsx-global';
import type * as React from 'react';
import {
  make as RawCardForm,
  type Props as ProviderProps,
  type widgetHandle,
} from './CardForm.gen';
import { make as RawCardNumberWidget } from './CardNumberWidget.gen';
import { make as RawCardExpiryWidget } from './CardExpiryWidget.gen';
import { make as RawCardCVCWidget } from './CardCVCWidget.gen';
import { make as RawCardholderNameWidget } from './CardholderNameWidget.gen';
import type { fieldStyles, expiryStyles } from './CardFieldStyles.gen';
import type {
  cardNumberOptions,
  expiryOptions,
  cvcOptions,
  cardholderNameOptions,
} from './CardFieldOptions.gen';
import type { paymentConfirmInput as VaultPaymentConfirmInputInternal } from './VaultFormCoordinator.gen';
import type { safeVaultError as SafeVaultErrorInternal } from './VaultResult.gen';
import type { safeNextAction as SafeNextActionInternal } from './VaultNavigation.gen';
import type { confirmTokenMode as VaultConfirmTokenModeInternal } from './VaultConfirmBody.gen';
import type { MerchantSession as MerchantSessionInternal } from './merchantTypes';
import type {
  cardNumberState,
  expiryState,
  cvcState,
  cardholderNameState,
} from './VaultPublicState.gen';
import type { VaultField, VaultTokenizeResult } from './public';

/*
 * ── TWO OPERATIONS, NOT ONE ──────────────────────────────────────────────────
 *
 * Which function you call decides what can come back. `tokenize()` is the only route to a token;
 * `confirmPayment()` is the only route that charges anything, and its result has no `token` member
 * at all. A single `submit()` returning one union could not express that: the caller would have had
 * to reason about which arguments they passed to know whether a payment credential was in hand.
 */
export type HostFormHandle = {
  /** Flow 1 — mint a payment-method token and stop. Takes no input; charges nothing. */
  tokenize(): Promise<VaultTokenizeResult>;
  /**
   * Flows 2 and 3 — confirm the payment. `cardSource` chooses which: `'vault'` tokenizes first and
   * keeps the token internal, `'direct'` confirms with the library's own card values and mints
   * nothing. Neither returns a token.
   */
  confirmPayment(input: VaultPaymentConfirmInput): Promise<VaultPaymentResult>;
  reset(): void;
  focus(field: VaultField): void;
};

/*
 * ── WHICH CARD CREDENTIAL THE CONFIRM USES ───────────────────────────────────
 *
 * A closed union, so the two flows cannot be blurred: there is no way to ask for the vault flow
 * without a session, and no way to attach vault settings to a direct confirm. Both would otherwise
 * be silent — the first would fall back to something, the second would be ignored — and both change
 * the customer's PCI posture, which is not a thing to get wrong quietly.
 *
 * The runtime value is the generated `paymentCardSource` record (see the note in
 * `VaultCardSource.res` for why it is a record and not a ReScript `@tag` variant);
 * `scripts/verify-card-source.mjs` asserts that this declaration and that record describe the same
 * runtime shapes.
 */
export type VaultPaymentCardSource =
  | {
      readonly type_: 'vault';
      readonly session: MerchantSessionInternal;
      readonly confirmTokenMode?: VaultConfirmTokenModeInternal;
    }
  | { readonly type_: 'direct' };

/**
 * The confirm input, with `cardSource` narrowed to the union above. Every other member is the
 * generated one, so this cannot drift from what the library actually reads.
 */
export type VaultPaymentConfirmInput = Omit<VaultPaymentConfirmInputInternal, 'cardSource'> & {
  readonly cardSource: VaultPaymentCardSource;
};

/*
 * ── WHO OWNS THE CARDHOLDER NAME ─────────────────────────────────────────────
 *
 *   'collect'    the library renders its own bare input and uses what was typed. The default.
 *   'external'   the library renders NO name field; the value arrives as `cardholderName` on the
 *                confirm input. For a host that already owns the field, with its own validation,
 *                localisation and error timing.
 *   'omit'       the library renders no name field and sends no name.
 *
 * The last two look identical on screen and differ entirely in what is sent, which is why they are
 * distinct: "I will supply it" and "there is none" must not be spelled the same way.
 *
 * Supplying `cardholderName` in any mode but 'external' is a configuration error, answered with
 * `unsupported_configuration` before any request. It is never resolved by precedence, because a
 * host with two names has no way to know which one was sent.
 *
 * Omitting it in 'external' is NOT an error: it means the host's own field was optional and the
 * customer left it blank, and `card_holder_name` is simply not sent. A host whose field is required
 * blocks its own submission long before this point.
 */
export type VaultCardholderNameMode = 'collect' | 'external' | 'omit';

/*
 * ── The result, as a discriminated union ─────────────────────────────────────
 *
 * The runtime value is the generated `vaultPaymentResult` record — `{status, error?, nextAction?}`.
 * That record is what the library actually produces (see the note in `VaultResult.res` for why it
 * is a record and not a ReScript `@tag` variant), but publishing it verbatim would leave `error`
 * optional on every branch, so a caller reading `result.error.message` after a `failed` status
 * would get no help from the compiler.
 *
 * This declaration describes the SAME runtime objects with the narrowing a caller wants: checking
 * `status` proves what else is there. It is hand-written, so it could in principle drift from what
 * the library emits — `scripts/verify-result-mapping.mjs` asserts the exact member set produced for
 * every status and fails if it ever does.
 */
export type VaultPaymentResult =
  | { readonly status: 'succeeded' }
  | { readonly status: 'processing' }
  | { readonly status: 'requires_customer_action'; readonly nextAction: SafeNextActionInternal }
  | { readonly status: 'failed'; readonly error: SafeVaultErrorInternal }
  | { readonly status: 'validation_error'; readonly error: SafeVaultErrorInternal }
  | { readonly status: 'not_ready'; readonly error: SafeVaultErrorInternal };

/* ── Components: the root's objects, with the host's types ────────────────── */

export type CardFormProps = ProviderProps;

export const CardForm =
  RawCardForm as unknown as React.ForwardRefExoticComponent<
    ProviderProps & React.RefAttributes<HostFormHandle>
  >;

type VaultStyledFieldComponent<S, O, State> = React.ForwardRefExoticComponent<
  { styles?: S; onStateChange?: (state: State) => void } & O & React.RefAttributes<widgetHandle>
>;

export const CardNumberField = RawCardNumberWidget as unknown as VaultStyledFieldComponent<
  fieldStyles,
  cardNumberOptions,
  cardNumberState
>;
export const CardExpiryField = RawCardExpiryWidget as unknown as VaultStyledFieldComponent<
  expiryStyles,
  expiryOptions,
  expiryState
>;
export const CardCVCField = RawCardCVCWidget as unknown as VaultStyledFieldComponent<
  fieldStyles,
  cvcOptions,
  cvcState
>;
export const CardholderNameField = RawCardholderNameWidget as unknown as VaultStyledFieldComponent<
  fieldStyles,
  cardholderNameOptions,
  cardholderNameState
>;

/*
 * The union a host writes when one handler serves several fields. Same shape as the root's, plus
 * the eligibility verdict on the card-number branch.
 */
export type VaultFieldState = cardNumberState | expiryState | cvcState | cardholderNameState;

/* ── Host-only types ──────────────────────────────────────────────────────── */

/* The full error vocabulary and the full localisation, including the eligibility message. */
export type {
  localisation as VaultFormLocalisation,
  localisationMessages as VaultFormValidationMessages,
  safeVaultError as SafeVaultError,
  safeVaultErrorCode as SafeVaultErrorCode,
} from './HyperswitchVaultForm.gen';

export type { vaultPaymentStatus as VaultPaymentStatus } from './VaultResult.gen';

/*
 * ── Confirm input and result (ADR-0003, as corrected by ADR-0004) ────────────
 *
 * `confirmPayment(args)` runs every network call inside the library and resolves to a navigation
 * decision. Every input type below is non-card and closed: `VaultHostPaymentMethodData` names
 * `billing` and `nickName` and nothing else, so a card field cannot be expressed, let alone passed.
 */
export type { cardSourceType as VaultCardSourceType } from './VaultCardSource.gen';

/*
 * Live eligibility. Optional, and entirely non-card — it only tells the library WHERE to ask about
 * the PAN it already holds, so the "card not accepted" message can appear while the customer types
 * instead of only at confirm time.
 */
export type { eligibilityConfig as VaultEligibilityConfig } from './VaultFormOptions.gen';

export type {
  hostPaymentMethodData as VaultHostPaymentMethodData,
  hostBilling as VaultHostBilling,
  hostBillingAddress as VaultHostBillingAddress,
  hostPhone as VaultHostPhone,
} from './VaultPaymentMethodData.gen';

export type {
  confirmTokenMode as VaultConfirmTokenMode,
  paymentMethodType as VaultPaymentMethodType,
  paymentType as VaultPaymentType,
  acceptanceType as VaultAcceptanceType,
  hostBrowserInfo as VaultHostBrowserInfo,
  hostCustomerAcceptance as VaultHostCustomerAcceptance,
  hostOnlineAcceptance as VaultHostOnlineAcceptance,
} from './VaultConfirmBody.gen';

export type {
  nextActionType as VaultNextActionType,
  safeNextAction as VaultNextAction,
  safeThreeDs as VaultThreeDsData,
  safeDdc as VaultDdcData,
  safeSessionToken as VaultSessionTokenData,
} from './VaultResult.gen';

/* The generated state types in full: the card-number and form snapshots carry `eligibility`. */
export type {
  vaultEligibilityStatus as VaultEligibilityStatus,
  cardNumberState as VaultCardNumberState,
  vaultFormFields as VaultFormFields,
  vaultFormState as VaultFormState,
} from './VaultPublicState.gen';

/* ── Shared with the root, re-published so a host needs no second import ──── */

export type {
  VaultField,
  VaultTokenizeResult,
  VaultTokenizeStatus,
  VaultFieldHandle,
  WidgetHandle,
  VaultFieldStyles,
  VaultExpiryStyles,
  VaultFormFieldStyles,
  VaultLabelBehavior,
  VaultErrorDisplay,
  VaultCVCIconDisplay,
  VaultBrandIconMode,
  VaultFormBrandIconMode,
  VaultFieldOptions,
  VaultCardNumberOptions,
  VaultExpiryOptions,
  VaultCVCOptions,
  VaultCardholderNameOptions,
  VaultFormFieldOptions,
  VaultFormAppearance,
  VaultFormLabels,
  VaultEnvironment,
  VaultEndpointConfig,
  MerchantSession,
  VaultCardBrand,
  VaultFieldStatus,
  VaultFieldErrorCode,
  VaultFieldError,
  VaultSessionStatus,
  VaultExpiryState,
  VaultCVCState,
  VaultCardholderNameState,
} from './public';
