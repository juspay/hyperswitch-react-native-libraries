
/*
 * Runtime entry for the `./orchestration` subpath. The ONLY source of runtime values for it.
 *
 * This surface is for @juspay-tech/react-native-hyperswitch-payment-methods — the package that
 * owns third-party vault providers and hands this library a canonical provider-tokenized card.
 * It is NOT merchant-facing: the package root re-exports none of it, and
 * `scripts/verify-public-surface.mjs` fails the build if the two surfaces ever share a name.
 *
 * `src/orchestration.ts` is the parallel type-only surface; the same script holds the pair in
 * lockstep exactly as it does for the root entry.
 */

import { confirmTokenizedCardPayment as confirmTokenizedCardPaymentImpl } from './VaultOrchestration.bs.js';

export const confirmTokenizedCardPayment = confirmTokenizedCardPaymentImpl;
