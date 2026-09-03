/*
 * Type surface for the `./orchestration` subpath — the host-facing orchestration entry.
 *
 * AUDIENCE. @juspay-tech/react-native-hyperswitch-payment-methods, never merchants. The intended
 * caller chain is `client-core → payment-methods → this entry`; the package root publishes none of
 * these names, and `scripts/verify-public-surface.mjs` keeps the two surfaces disjoint.
 *
 * `src/orchestration-entry.mjs` is the runtime half of this pair. tsc runs with
 * `emitDeclarationOnly`, so nothing here executes; the same script requires the exported VALUE
 * names on both sides to be identical.
 *
 * THE CONTRACT IN ONE PARAGRAPH. The caller tokenized a card with an external provider (VGS
 * today), parsed the provider's response itself, and presents the result as a canonical
 * `ProviderTokenizedCard`: the aliases verbatim, expiry, and PROVIDER-REPORTED metadata or
 * nothing — `lastFour`/`binNumber` must never be sliced out of an alias. This library then owns
 * the one `/payments/{id}/confirm` implementation and resolves to the same sanitized
 * `VaultPaymentResult` as the form flows: navigation, never a token, never a raw response.
 */

import type { orchestrationConfirmInput } from './VaultOrchestration.gen';
import type { providerTokenizedCard } from './VaultConfirmBody.gen';
import type { VaultPaymentResult } from './host';

/*
 * The canonical provider-tokenized card. `cardNumberAlias`/`cardCvcAlias` are the provider's
 * stand-in strings and are REQUIRED — the backend's `vault_data_card` shape has no optional CVC.
 * Optional members are provider-reported metadata, carried only when the provider stated them.
 */
export type ProviderTokenizedCard = providerTokenizedCard;

/*
 * The confirm input. `sdkAuthorization` is the PAYMENT-INTENT credential (this flow has no
 * payment-method-session call); `paymentMethodData` is the same closed non-card host data as the
 * form flows, with the same runtime deep-scan rejecting card keys.
 */
export type OrchestrationConfirmInput = orchestrationConfirmInput;

/*
 * Runs the final confirm and resolves to the SAME result union as `confirmPayment()` on the form:
 * every refusal (blank alias, blank credential, invalid endpoint, card key in host data) happens
 * before a request opens, and only sanitized navigation crosses back.
 */
export declare const confirmTokenizedCardPayment: (
  input: OrchestrationConfirmInput
) => Promise<VaultPaymentResult>;

/*
 * The result and its supporting types, re-published so a caller needs no second import. They are
 * the `./host` entry's types (ADR-0010): the confirm vocabulary lives there and on this entry, never
 * on the merchant root.
 */
export type {
  VaultPaymentResult,
  VaultPaymentStatus,
  SafeVaultError,
  SafeVaultErrorCode,
  VaultEnvironment,
  VaultEndpointConfig,
  VaultHostPaymentMethodData,
  VaultHostBilling,
  VaultHostBillingAddress,
  VaultHostPhone,
  VaultPaymentMethodType,
  VaultPaymentType,
  VaultAcceptanceType,
  VaultHostBrowserInfo,
  VaultHostCustomerAcceptance,
  VaultHostOnlineAcceptance,
  VaultNextActionType,
  VaultNextAction,
  VaultThreeDsData,
  VaultDdcData,
  VaultSessionTokenData,
} from './host';
