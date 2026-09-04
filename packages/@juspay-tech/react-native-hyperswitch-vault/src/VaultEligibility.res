/*
 * INTERNAL. The PAN-dependent eligibility probe, moved inside the library.
 *
 * ── WHY THIS MODULE HAD TO EXIST ───────────────────────────────────────────────
 *
 * Eligibility asks the backend whether a specific BIN may be used for this payment. The request
 * body carries the card number. While client-core owned the card fields it could build that body
 * itself; now that every new-card flow is library-owned, client-core has no PAN to send — so
 * either the library performs the check, or the feature dies.
 *
 * Refusing to confirm whenever eligibility is configured (the previous behaviour, `fail closed with
 * unsupported_configuration`) was the right answer while the library could not make this call. It
 * is the wrong answer now: it would break every merchant who has eligibility enabled, for no
 * security gain, because the library holds the PAN already.
 *
 * ── THE CONTRACT IS A REPRODUCTION ─────────────────────────────────────────────
 *
 * Endpoint, body shape and verdict reading reproduce client-core's `useEligibilityCheckHook`
 * (`AllPaymentHooks.res`) and its caller `PaymentMethod.res:checkEligibility`:
 *
 *   POST {baseUrl}/payments/{paymentId}/eligibility
 *   {"payment_method_type": "card",
 *    "payment_method_data": {"card": {"card_number": "<digits>"}}}
 *
 * A verdict of `deny` — as the bare string `sdk_next_action.next_action`, or as a `deny` key on
 * that object — means DENIED. Everything else means allowed.
 *
 * ── FAIL OPEN, AND THAT IS THE PRODUCT CONTRACT ────────────────────────────────
 *
 * Anything that is not an explicit `deny` resolves to ALLOWED: a transport failure, a 5xx, an
 * unreadable body, a missing `sdk_next_action`, an unrecognised action.
 *
 * This is not an accident inherited from a `.catch` nobody looked at. It is the behaviour
 * client-core was deliberately changed TO, and the repository says so twice:
 *
 *   hyperswitch-client-core 4d1f420  "feat(api): eligibility check (#470)"
 *     introduced the check, with a `.catch` that sets `Allowed` — a transport failure has never
 *     blocked a payment.
 *
 *   hyperswitch-client-core 94b89ee  "fix: allowing the payment for all the cases and blocking
 *                                     for deny (#474)"
 *     changed the RESPONSE decoding from fail-closed to fail-open. The diff replaces
 *     `Some(_) => Denied | None => Denied` with "denied only when the action is `deny`". It is
 *     titled a fix because failing closed was rejecting payments the merchant wanted taken.
 *
 * The reasoning behind that fix holds here: eligibility is a merchant ROUTING preference, not an
 * authorization control, and the backend still refuses an ineligible card at confirm time. Turning
 * a dropped packet into a declined checkout costs payments and protects nothing.
 *
 * This is the one place in the library that fails open. It is spelled out here, asserted by
 * `scripts/verify-eligibility.mjs`, and recorded in ADR-0004, so that it stays a decision rather
 * than becoming a discovery.
 */

type verdict =
  | Allowed
  | Denied

/*
 * Non-card, host-supplied. `credential` is the payment credential already resolved by the caller
 * (see `VaultCredential`); `appId` only reproduces the `x-app-id` header client-core sends.
 */
type eligibilityRequest = {
  baseUrl: string,
  paymentId: string,
  credential: VaultCredential.t,
  appId: option<string>,
  cardNumber: string,
  signal?: VaultConfirm.abortSignal,
}

@val external encodeURIComponent: string => string = "encodeURIComponent"

let eligibilityUrl = (~baseUrl, ~paymentId) =>
  `${baseUrl}/payments/${paymentId->encodeURIComponent}/eligibility`

let appIdHeader = VaultConfirm.appIdHeader

let buildBody = (~cardNumber: string): string =>
  [
    ("payment_method_type", "card"->JSON.Encode.string),
    (
      "payment_method_data",
      [
        (
          "card",
          [("card_number", cardNumber->Validation.clearSpaces->JSON.Encode.string)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object,
    ),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
  ->JSON.stringify

/*
 * `sdk_next_action.next_action` is read in both the shapes client-core accepts: the string "deny",
 * and an object carrying a `deny` key. Anything else — including a missing field — is allowed.
 */
let readVerdict = (json: JSON.t): verdict => {
  let nextAction =
    json
    ->JSON.Decode.object
    ->Option.flatMap(root => root->Dict.get("sdk_next_action"))
    ->Option.flatMap(JSON.Decode.object)
    ->Option.flatMap(action => action->Dict.get("next_action"))

  switch nextAction {
  | None => Allowed
  | Some(value) =>
    switch value->JSON.Decode.string {
    | Some("deny") => Denied
    | Some(_) => Allowed
    | None =>
      value
      ->JSON.Decode.object
      ->Option.flatMap(dict => dict->Dict.get("deny"))
      ->Option.isSome
        ? Denied
        : Allowed
    }
  }
}

let check = async (request: eligibilityRequest): verdict => {
  let options: VaultConfirm.fetchOptions = {
    method: "POST",
    headers: [
      ("Content-Type", "application/json"),
      request.credential->VaultCredential.authHeader,
      ("x-app-id", request.appId->appIdHeader),
      ("x-redirect-uri", ""),
    ]->Dict.fromArray,
    body: buildBody(~cardNumber=request.cardNumber),
    signal: ?request.signal,
  }

  let attempted = try {
    Ok(
      await VaultConfirm.fetch(
        eligibilityUrl(~baseUrl=request.baseUrl, ~paymentId=request.paymentId),
        options,
      ),
    )
  } catch {
  | _ => Error()
  }

  switch attempted {
  | Error() => Allowed
  | Ok(response) =>
    if response->VaultConfirm.responseOk {
      let parsed = try {
        Some(await response->VaultConfirm.responseJson)
      } catch {
      | _ => None
      }
      switch parsed {
      | Some(json) => json->readVerdict
      | None => Allowed
      }
    } else {
      Allowed
    }
  }
}
