/*
 * INTERNAL. WHICH credential authenticates the PAYMENT calls — the eligibility probe and the final
 * `/payments/{id}/confirm`. Not the vault credential: that one lives inside `vault_details` and
 * authenticates the payment-method-session confirm only (`VaultConfirm`).
 *
 * ── TWO SHAPES, ONE RESOLUTION ─────────────────────────────────────────────────
 *
 * Hyperswitch accepts two ways of authenticating an SDK payment call, and hyperswitch-client-core
 * still uses both (`Utils.getHeader`):
 *
 *   IntentAuthorization  the payment-intent `sdkAuthorization`. Sent raw as the `Authorization`
 *                        header, exactly as client-core sends it. Preferred whenever present.
 *
 *   LegacyApiKey         the merchant's publishable key as the `api-key` header, with the intent's
 *                        `client_secret` in the request BODY. This is the integration every merchant
 *                        had before `sdkAuthorization` existed, and client-core still emits it for
 *                        wallets, saved cards and retrieve whenever `sdkAuthorization` is absent.
 *
 * An earlier revision of this library knew only the first shape and refused a blank
 * `sdkAuthorization` with `invalid_session`. That turned every new-card payment for a legacy-auth
 * merchant into a deterministic failure while the rest of their checkout kept working. This module
 * is the correction: both shapes resolve here, once, and the transports take the resolved value.
 *
 * ── PRECEDENCE ─────────────────────────────────────────────────────────────────
 *
 * `sdkAuthorization` wins when it is non-blank, matching `Utils.getHeader` — a host that supplies
 * both is not asking for two credentials, it is passing through what it holds. Only when it is
 * absent or blank does the legacy pair apply, and then BOTH members must be non-blank: a
 * publishable key without a client secret authenticates nothing.
 *
 * Nothing here is logged, returned or reflected back. The variant exists so the transports cannot
 * be handed a half-credential: there is no way to construct one.
 */

type t =
  | IntentAuthorization(string)
  | LegacyApiKey({publishableKey: string, clientSecret: string})

let nonBlank = (value: string): option<string> => {
  let trimmed = value->String.trim
  trimmed->String.length > 0 ? Some(trimmed) : None
}

/*
 * `None` means NO usable credential: the host supplied neither shape completely. Callers answer
 * that before any request opens.
 */
let resolve = (
  ~sdkAuthorization: option<string>,
  ~publishableKey: option<string>,
  ~clientSecret: option<string>,
): option<t> =>
  switch sdkAuthorization->Option.flatMap(nonBlank) {
  | Some(token) => Some(IntentAuthorization(token))
  | None =>
    switch (publishableKey->Option.flatMap(nonBlank), clientSecret->Option.flatMap(nonBlank)) {
    | (Some(publishableKey), Some(clientSecret)) =>
      Some(LegacyApiKey({publishableKey, clientSecret}))
    | _ => None
    }
  }

/* Constructors for the verification scripts, which build requests from plain JavaScript. */
let intent = (token: string): t => IntentAuthorization(token)
let legacy = (~publishableKey: string, ~clientSecret: string): t =>
  LegacyApiKey({publishableKey, clientSecret})

/*
 * The one header the credential contributes. The scheme prefix is deliberately absent on both:
 * client-core's `Utils.getHeader` sends `Authorization: <token>` and `api-key: <key>` raw, and the
 * backend expects exactly that.
 */
let authHeader = (credential: t): (string, string) =>
  switch credential {
  | IntentAuthorization(token) => ("Authorization", token)
  | LegacyApiKey({publishableKey}) => ("api-key", publishableKey)
  }

/*
 * Only the legacy shape puts anything in the body. `VaultConfirmBody.build` writes this as
 * `client_secret` and omits the key entirely for the intent credential — which is exactly when
 * client-core's own `generateCardConfirmBody` omits it.
 */
let clientSecretForBody = (credential: t): option<string> =>
  switch credential {
  | IntentAuthorization(_) => None
  | LegacyApiKey({clientSecret}) => Some(clientSecret)
  }
