/*
 * INTERNAL. The saved-card CVC transport (ADR-0008).
 *
 * Deliberately NOT part of the public surface: no genType annotation, no re-export from `public.ts`, no
 * subpath. It lives inside the root bundle because a `<CardCVCField savedCard>` cannot return a
 * token without it, and it is reachable from nowhere else — the same posture as `VaultConfirm`.
 *
 * ONE request:
 *
 *   PUT {vaultBaseUrl}/v1/payment-method-sessions/{encodedSessionId}/update-saved-payment-method
 *   Authorization: <the session's raw sdkAuthorization>
 *
 *   { "payment_method_token": "<the merchant's token>",
 *     "payment_method_data": { "card": { "card_cvc": "<internal>" } } }
 *
 * ── THE AUTHORIZATION, READ FROM THE BACKEND ──────────────────────────────────
 *
 * The route handler (`crates/router/src/routes/payment_methods.rs`,
 * `payment_method_session_update_saved_payment_method`) authenticates with the SAME combinator the
 * session confirm uses: `auth::sdk_or_client_auth(SdkAuthorizationAuth, V2ClientAuth)`. When the
 * `Authorization` header decodes as the SDK envelope the SDK path is taken; the documented
 * `publishable-key=…,client-secret=…` + `X-Profile-Id` form is the FALLBACK for a caller that has no
 * envelope. hyperswitch-web sends exactly the raw header to this route in production.
 *
 * So this transport sends the raw `sdkAuthorization` — the credential the session already carries —
 * and nothing derived from it. It never decodes the envelope to synthesise the fallback headers, and
 * it sends no `X-Profile-Id`: the SDK path does not read one. The header set is the one the confirm
 * sends and client-core puts on every backend call.
 *
 * ── WHY A BLANK TOKEN IS REFUSED HERE TOO ─────────────────────────────────────
 *
 * The backend treats an ABSENT `payment_method_token` with a CVC as a different operation: it mints
 * a brand-new token and stores the CVC under that — a `TemporaryCardToken`, which carries a CVC and
 * no payment method, and which the payment confirm then refuses (measured against sandbox on
 * 2026-09-05: the update answers 200, the confirm that follows fails with `HE_00`). The component
 * gates the token before calling this module; this module refuses a blank one again, so no future
 * caller can turn a missing merchant token into a request that comes back with a token the merchant
 * never listed and cannot charge.
 *
 * ── WHAT IS REUSED, VERBATIM ───────────────────────────────────────────────────
 *
 *   VaultConfirm.resolveSessionId       the session id, with its two closed failures
 *   VaultConfirm.appIdHeader            the x-app-id spelling
 *   VaultConfirm.decodeConfirmResponse  the ONE token path: associated_payment_methods[0]
 *                                       .payment_method_token.data — and no fallback
 *   VaultConfirm.describeHttpFailure    non-2xx → #http_error; backend prose never forwarded
 *   VaultConfirm.* externals            fetch, AbortController, timers
 *   VaultResult.tokenizeFromPmsFailure  the closed public vocabulary; nothing new is minted
 *
 * The response decoder is shared on purpose. The update and the confirm answer with the same
 * session response, and the token sits at the same path in both, so a second decoder would be a
 * second place for that path to drift. The card metadata the decoder also reads is discarded here:
 * nothing about a saved card is wanted back, and nothing is returned but the token.
 */

type updateRequest = {
  vaultBaseUrl: string,
  /* The session's credential. It resolves the session id AND authenticates the request. */
  sdkAuthorization: string,
  /* The token the merchant took from `list-payment-methods`. Never sent blank. */
  paymentMethodToken: string,
  /* Library-owned. Never logged, never returned, never part of any outcome. */
  cvc: string,
  /* Reproduces the `x-app-id` header client-core sends on every backend call. Non-card. */
  appId?: string,
  timeoutMs?: int,
  signal?: VaultConfirm.abortSignal,
}

let updateUrl = (~baseUrl, ~sessionId) =>
  `${baseUrl}/v1/payment-method-sessions/${sessionId->VaultConfirm.encodeURIComponent}/update-saved-payment-method`

/*
 * Exactly the contract's body and nothing else: no cardholder name, no nickname, no PAN, no expiry,
 * no network. The backend struct is `deny_unknown_fields`, and every one of those is either a value
 * this component does not collect or a value that would describe a card it never saw.
 */
let buildUpdateBody = (~paymentMethodToken: string, ~cvc: string) =>
  [
    ("payment_method_token", paymentMethodToken->JSON.Encode.string),
    (
      "payment_method_data",
      [("card", [("card_cvc", cvc->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object)]
      ->Dict.fromArray
      ->JSON.Encode.object,
    ),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object

/* The header set the session confirm sends. Raw credential, no scheme, no profile header. */
let headersFor = (~sdkAuthorization: string, ~appId: option<string>) =>
  [
    ("Content-Type", "application/json"),
    ("Authorization", sdkAuthorization),
    ("x-app-id", appId->VaultConfirm.appIdHeader),
    ("x-redirect-uri", ""),
  ]->Dict.fromArray

let updateSavedPaymentMethod = async (
  request: updateRequest,
): VaultResult.vaultTokenizeResult =>
  /*
   * The floor every network shares: three or four digits. The component has already applied the
   * network's exact rule; this refuses what could not be a CVC for any card, before anything opens.
   */
  if !Validation.checkCardCVC(request.cvc, "") {
    VaultResult.tokenizeInvalidCardData()
  } else if request.paymentMethodToken->String.trim->String.length === 0 {
    VaultResult.tokenizeValidationError(VaultResult.missingSavedCardTokenMessage)
  } else {
    switch request.sdkAuthorization->VaultConfirm.resolveSessionId {
    | Error(VaultConfirm.Failure({error})) => VaultResult.tokenizeFromPmsFailure(error)
    /* `resolveSessionId` never fails with a Success; the arm exists for the type only. */
    | Error(VaultConfirm.Success(_)) =>
      VaultResult.tokenizeFailedWith(#invalid_session, VaultResult.unusableSessionMessage)
    | Ok(sessionId) =>
      let url = updateUrl(~baseUrl=request.vaultBaseUrl, ~sessionId)

      let controller = VaultConfirm.makeAbortController()

      request.signal->Option.forEach(callerSignal =>
        if callerSignal->VaultConfirm.signalAborted {
          controller->VaultConfirm.abort
        } else {
          callerSignal->VaultConfirm.onSignalAbort("abort", () => controller->VaultConfirm.abort)
        }
      )

      let timedOut = ref(false)
      let timer = switch request.timeoutMs {
      | Some(ms) if ms > 0 =>
        Some(
          VaultConfirm.setTimeout(() => {
            timedOut := true
            controller->VaultConfirm.abort
          }, ms),
        )
      | _ => None
      }

      let options: VaultConfirm.fetchOptions = {
        method: "PUT",
        headers: headersFor(~sdkAuthorization=request.sdkAuthorization, ~appId=request.appId),
        body: buildUpdateBody(
          ~paymentMethodToken=request.paymentMethodToken->String.trim,
          ~cvc=request.cvc,
        )->JSON.stringify,
        signal: ?Some(controller->VaultConfirm.controllerSignal),
      }

      let attempted = try {
        Ok(await VaultConfirm.fetch(url, options))
      } catch {
      | _ => Error()
      }

      timer->Option.forEach(VaultConfirm.clearTimeout)

      /*
       * Every branch below produces a `VaultConfirm.confirmOutcome`, so the public result is minted
       * by the ONE mapping `VaultResult.tokenizeFromPmsFailure` — the same one `tokenize()` uses and
       * the same one `verify-result-mapping.mjs` enumerates. No new code, no new message.
       */
      let outcome = switch attempted {
      | Error() =>
        VaultConfirm.unknownOutcomeError(
          timedOut.contents
            ? "The vault did not respond in time; the outcome is unknown."
            : "The vault request did not complete; the outcome is unknown.",
        )
      | Ok(response) =>
        let status = response->VaultConfirm.responseStatus
        let parsed = try {
          Some(await response->VaultConfirm.responseJson)
        } catch {
        | _ => None
        }

        if response->VaultConfirm.responseOk {
          switch parsed {
          | None =>
            VaultConfirm.Failure({
              error: {
                code: #malformed_response,
                message: "The vault response was not valid JSON.",
                httpStatus: status,
                retryable: false,
                unknownOutcome: false,
              },
            })
          | Some(json) => json->VaultConfirm.decodeConfirmResponse(~httpStatus=status)
          }
        } else {
          VaultConfirm.describeHttpFailure(parsed, status)
        }
      }

      switch outcome {
      | VaultConfirm.Success({result}) => VaultResult.tokenizeSuccess(result.token)
      | VaultConfirm.Failure({error}) => VaultResult.tokenizeFromPmsFailure(error)
      }
    }
  }
