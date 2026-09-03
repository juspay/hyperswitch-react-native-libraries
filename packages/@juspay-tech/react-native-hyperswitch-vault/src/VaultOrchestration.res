/*
 * The ORCHESTRATION entry — the one host-facing operation this library offers to
 * @juspay-tech/react-native-hyperswitch-payment-methods, which owns the third-party vault
 * providers, parses their responses, and hands this module a canonical provider-tokenized card
 * (`VaultConfirmBody.providerTokenizedCard`).
 *
 * ── WHO MAY CALL THIS ──────────────────────────────────────────────────────────
 *
 * Not merchants. This module is published ONLY through the `./orchestration` subpath; the package
 * root re-exports none of it, and `scripts/verify-public-surface.mjs` fails the build if it ever
 * does. The intended caller chain is
 *
 *     client-core → payment-methods → this entry
 *
 * so a merchant integration never has a reason — or a documented path — to construct alias input.
 *
 * ── WHY IT IS NOT A COMPONENT ──────────────────────────────────────────────────
 *
 * The card fields for this flow are the PROVIDER's secure views; this library renders nothing and
 * holds no state. What it owns is the one `/payments/{id}/confirm` implementation: the same body
 * builder (`VaultConfirmBody`), the same transport (`VaultFinalConfirm`), the same sanitized
 * result (`VaultResult.vaultPaymentResult`) as the form flows. This module is a plain async
 * function with no React anywhere beneath it — `scripts/verify-orchestration.mjs` executes it
 * directly against a mocked fetch.
 *
 * ── FAIL BEFORE SEND ───────────────────────────────────────────────────────────
 *
 * Every refusal below happens before a request opens: blank required aliases, a blank credential,
 * an endpoint that fails validation, or a card key inside the host's non-card data. The gates are
 * the same ones the form flows use, so the two entries cannot drift apart on what is refused.
 */

@genType
type orchestrationConfirmInput = {
  tokenizedCard: VaultConfirmBody.providerTokenizedCard,
  paymentId: string,
  /*
   * The PAYMENT credential — never the vault credential; this flow has no call 1. Either shape
   * Hyperswitch accepts: the payment-intent `sdkAuthorization` (preferred), or the legacy
   * `publishableKey` + `clientSecret` pair. See `VaultCredential` for precedence.
   */
  sdkAuthorization?: string,
  publishableKey?: string,
  clientSecret?: string,
  /* The genType-visible spelling of the environment; unifies with VaultConfirm.vaultEnvironment. */
  environment: VaultFormOptions.vaultEnvironment,
  /* Where the confirm is posted. Absent means the environment's public-cloud host. */
  endpoint?: VaultEndpoint.vaultEndpointConfig,
  appId?: string,
  paymentMethodType?: VaultConfirmBody.paymentMethodType,
  /* Non-card data only — the same runtime deep-scan as the form flows rejects card keys. */
  paymentMethodData?: VaultPaymentMethodData.hostPaymentMethodData,
  customerAcceptance?: VaultConfirmBody.hostCustomerAcceptance,
  browserInfo?: VaultConfirmBody.hostBrowserInfo,
  returnUrl?: string,
  paymentType?: VaultConfirmBody.paymentType,
  email?: string,
  timeoutMs?: int,
}

let blank = (value: string) => value->String.trim->String.length === 0

@genType
let confirmTokenizedCardPayment = async (
  input: orchestrationConfirmInput,
): VaultResult.vaultPaymentResult => {
  let card = input.tokenizedCard

  if (
    blank(card.cardNumberAlias) ||
    blank(card.cardCvcAlias) ||
    blank(card.expiryMonth) ||
    blank(card.expiryYear)
  ) {
    VaultResult.invalidCardData()
  } else {
    switch VaultCredential.resolve(
      ~sdkAuthorization=input.sdkAuthorization,
      ~publishableKey=input.publishableKey,
      ~clientSecret=input.clientSecret,
    ) {
    /* Neither credential shape is complete: nothing can authenticate the request. */
    | None => VaultResult.invalidSession(VaultResult.unusableSessionMessage)
    | Some(credential) =>
      switch input.paymentMethodData->VaultPaymentMethodData.validateHostPaymentMethodData {
      | Error() => VaultResult.forbiddenCardData()
      | Ok() =>
        switch input.endpoint->VaultEndpoint.resolveBaseUrl(~environment=input.environment) {
        | Error() => VaultResult.unsupportedConfiguration()
        | Ok(baseUrl) =>
          let body = VaultConfirmBody.build(
            ~cardPayload=ExternalTokenPayload({card: card}),
            ~paymentMethodType=input.paymentMethodType,
            ~paymentMethodData=input.paymentMethodData,
            ~customerAcceptance=input.customerAcceptance,
            ~browserInfo=input.browserInfo,
            ~returnUrl=input.returnUrl,
            ~paymentType=input.paymentType,
            ~email=input.email,
            ~clientSecret=credential->VaultCredential.clientSecretForBody,
          )

          let navOutcome = await VaultFinalConfirm.confirmPayment({
            baseUrl,
            paymentId: input.paymentId,
            credential,
            appId: ?input.appId,
            body,
            timeoutMs: ?input.timeoutMs,
          })

          navOutcome->VaultResult.fromNavOutcome
        }
      }
    }
  }
}
