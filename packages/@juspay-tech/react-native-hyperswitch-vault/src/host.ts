/*
 * Type surface for the `./host` subpath — the checkout-SDK entry (ADR-0010).
 *
 * AUDIENCE. The checkout SDK, never merchants. The package root publishes none of the names that
 * are unique to this file, and `scripts/verify-public-surface.mjs` keeps it that way.
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
 *   root events / localisation without the eligibility verdict and message
 *   host events / localisation the generated types, in full
 *
 *   root `SafeVaultErrorCode`  the nine codes `tokenize()` can return
 *   host `SafeVaultErrorCode`  all thirteen
 *
 * Everything the two surfaces share — styles, options, appearance, brands, events, the tokenize
 * result — is imported from `./public` and re-exported, never re-declared.
 */

import './jsx-global';
import type * as React from 'react';
import {
  make as RawCardForm,
  type Props as ProviderProps,
  type widgetHandle,
} from './CardForm.gen';
import { make as RawCardNumberField, type Props as CardNumberProps } from './CardNumberField.gen';
import { make as RawCardExpiryField, type Props as CardExpiryProps } from './CardExpiryField.gen';
import { make as RawCardCVCField, type Props as CardCvcProps } from './CardCVCField.gen';
import {
  make as RawCardholderNameField,
  type Props as CardholderNameProps,
} from './CardholderNameField.gen';
import type { paymentConfirmInput as VaultPaymentConfirmInputInternal } from './VaultFormCoordinator.gen';
import type { safeVaultError as SafeVaultErrorInternal } from './VaultResult.gen';
import type { safeNextAction as SafeNextActionInternal } from './VaultNavigation.gen';
import type { confirmTokenMode as VaultConfirmTokenModeInternal } from './VaultConfirmBody.gen';
import type { MerchantSession as MerchantSessionInternal } from './merchantTypes';
import type { VaultField, VaultTokenizeResult } from './public';

/*
 * ── TWO OPERATIONS, NOT ONE ──────────────────────────────────────────────────
 *
 * Which function you call decides what can come back. `tokenize()` is the only route to a token;
 * `confirmPayment()` is the only route that charges anything, and its result has no `token` member
 * at all.
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
 * without a session, and no way to attach vault settings to a direct confirm.
 */
export type VaultPaymentCardSource =
  | {
      readonly type_: 'vault';
      readonly session: MerchantSessionInternal;
      readonly confirmTokenMode?: VaultConfirmTokenModeInternal;
    }
  | { readonly type_: 'direct' };

/** The confirm input, with `cardSource` narrowed to the union above. */
export type VaultPaymentConfirmInput = Omit<VaultPaymentConfirmInputInternal, 'cardSource'> & {
  readonly cardSource: VaultPaymentCardSource;
};

/*
 * `'collect'` the library renders its own name input. `'external'` the host owns the field and
 * supplies the value on the confirm input. `'omit'` no name field, no name sent.
 */
export type VaultCardholderNameMode = 'collect' | 'external' | 'omit';

/*
 * The result, as a discriminated union over the same runtime objects the library produces
 * (`{status, error?, nextAction?}`). `scripts/verify-result-mapping.mjs` asserts the member set
 * produced for every status.
 */
export type VaultPaymentResult =
  | { readonly status: 'succeeded' }
  | { readonly status: 'processing' }
  | { readonly status: 'requires_customer_action'; readonly nextAction: SafeNextActionInternal }
  | { readonly status: 'failed'; readonly error: SafeVaultErrorInternal }
  | { readonly status: 'validation_error'; readonly error: SafeVaultErrorInternal };

/* ── Components: the root's objects, with the host's types ────────────────── */

export type CardFormProps = ProviderProps;

export const CardForm =
  RawCardForm as unknown as React.ForwardRefExoticComponent<
    ProviderProps & React.RefAttributes<HostFormHandle>
  >;

type VaultFieldComponent<P> = React.ForwardRefExoticComponent<P & React.RefAttributes<widgetHandle>>;

export const CardNumberField = RawCardNumberField as unknown as VaultFieldComponent<CardNumberProps>;
export const CardExpiryField = RawCardExpiryField as unknown as VaultFieldComponent<CardExpiryProps>;
export const CardCVCField = RawCardCVCField as unknown as VaultFieldComponent<CardCvcProps>;
export const CardholderNameField =
  RawCardholderNameField as unknown as VaultFieldComponent<CardholderNameProps>;

/* ── Host-only types ──────────────────────────────────────────────────────── */

/* The full error vocabulary and the full localisation, including the eligibility message. */
export type {
  localisation as VaultFormLocalisation,
  localisationMessages as VaultFormValidationMessages,
  safeVaultError as SafeVaultError,
  safeVaultErrorCode as SafeVaultErrorCode,
} from './VaultFormOptions.gen';

export type { vaultPaymentStatus as VaultPaymentStatus, safeVaultErrorType as SafeVaultErrorType } from './VaultResult.gen';

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

/* The generated event types in full: the card-number and form events carry `eligibility`. */
export type {
  vaultEligibilityStatus as VaultEligibilityStatus,
  fieldChange as VaultFieldChange,
  vaultFormFields as VaultFormFields,
  cardFormChange as VaultCardFormChange,
} from './VaultPublicState.gen';

/* ── Shared with the root, re-published so a host needs no second import ──── */

export type {
  VaultField,
  VaultTokenizeResult,
  VaultTokenizedCard,
  VaultTokenizeStatus,
  VaultFieldHandle,
  VaultFieldEvent,
  VaultCardFormEvent,
  VaultCardDetails,
  VaultFieldStyles,
  VaultCardExpiryStyles,
  VaultFormFieldStyles,
  VaultLabelBehavior,
  VaultErrorDisplay,
  VaultCVCIconDisplay,
  VaultCardBrandIcon,
  VaultFieldOptions,
  VaultCardNumberOptions,
  VaultCardExpiryOptions,
  VaultCardCVCOptions,
  VaultCardholderNameOptions,
  VaultFormFieldOptions,
  VaultSavedCard,
  VaultFormAppearance,
  VaultFormAppearanceVariables,
  VaultFormLabels,
  VaultEnvironment,
  VaultEndpointConfig,
  MerchantSession,
  VaultDetails,
  VaultData,
  VaultElementType,
  VaultCardBrand,
  VaultFieldErrorCode,
  VaultFieldError,
  VaultSessionStatus,
} from './public';
