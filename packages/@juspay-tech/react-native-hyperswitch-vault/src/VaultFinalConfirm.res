/*
 * INTERNAL. The payment-intent confirmation transport — call 2 of the two the library owns.
 *
 * Like `VaultConfirm`, this module has no genType annotations, is not re-exported from `public.ts`,
 * and has no package subpath. A merchant has no supported or physical path to call it.
 *
 * ── WHY THE LIBRARY MAKES THIS CALL ────────────────────────────────────────────
 *
 * `VaultConfirm` mints a payment-method token from the card the library owns. If the host then had
 * to make the final `/payments/{id}/confirm` call itself, the token would have to cross the public
 * boundary. Owning both calls is what lets `submit()` return a navigation decision and nothing else.
 *
 * ── THE TWO CREDENTIALS ARE NOT INTERCHANGEABLE ────────────────────────────────
 *
 * Call 1 authenticates with the VAULT credential carried inside `vault_details`. This call
 * authenticates with the PAYMENT credential the host supplies — the payment-intent
 * `sdkAuthorization`, or the legacy publishable-key + `client_secret` pair — already resolved into
 * a `VaultCredential.t` by the caller. They are different secrets with different scopes; neither is
 * ever logged, returned or re-emitted.
 *
 * ── STATUS MAPPING IS A REPRODUCTION, NOT A DESIGN ─────────────────────────────
 *
 * The outcome table below reproduces client-core's confirm-response handling
 * (`AllPaymentHooks.res`, `handleApiRes` → `handleDefaultPaymentFlows`) so a merchant migrating to
 * the vault flow sees the same navigation decisions. That behaviour was pinned first, by
 * `hyperswitch-client-core/__tests__/PaymentStatusCharacterization-test.js`, before it was
 * collapsed here.
 *
 * Two details of that reproduction are easy to get wrong and are deliberate:
 *
 *   - `next_action.type` is consulted BEFORE `status`. client-core routes `three_ds_invoke`,
 *     `third_party_sdk_session_token`, `display_bank_transfer_information` and `invoke_ddc` on the
 *     next action regardless of the status field, and only falls through to the status switch when
 *     the next action is none of those.
 *   - `cancelled` is NOT a processing status here. The redirect-RETURN site in client-core does
 *     treat it as processing, but the confirm-RESPONSE site — the one this module replaces — does
 *     not, and the characterization test records both.
 */

type nextActionType = VaultNavigation.nextActionType
type safeThreeDs = VaultNavigation.safeThreeDs
type safeDdc = VaultNavigation.safeDdc
type safeSessionToken = VaultNavigation.safeSessionToken

/*
 * A closed REASON, never a string.
 *
 * An earlier revision had `Failed` carry a message that this module had already mapped to safe
 * wording. It was safe, but only by convention: nothing stopped a later edit from putting backend
 * text in that slot, and `VaultResult` — which cannot tell one string from another — would have
 * forwarded it to the customer. Carrying a reason makes "no backend prose crosses this boundary" a
 * property of the TYPE: there is no slot for a string to travel in, and `VaultResult` owns every
 * word the merchant ever sees.
 */
type finalFailureReason =
  | GenericFailure
  | Unauthorized
  | Rejected
  | SessionAlreadyUsed
  | SessionExpired
  | MalformedResponse

type navOutcome =
  | Succeeded
  | Processing
  | RequiresAction({
      type_: nextActionType,
      redirectUrl: option<string>,
      threeDs: option<safeThreeDs>,
      ddc: option<safeDdc>,
      sessionToken: option<safeSessionToken>,
    })
  | Failed({reason: finalFailureReason})
  | UnknownOutcome

type finalConfirmRequest = {
  baseUrl: string,
  paymentId: string,
  /* Resolved by the caller; see `VaultCredential` for the two shapes and their precedence. */
  credential: VaultCredential.t,
  /* Reproduces the `x-app-id` header client-core sends on every backend call. Non-card. */
  appId?: string,
  /* Fully built by VaultConfirmBody; this module never inspects or amends it. */
  body: JSON.t,
  timeoutMs?: int,
  signal?: VaultConfirm.abortSignal,
}

/*
 * A SMALL allowlist of backend codes mapped to our own reasons. An unrecognised code becomes
 * `GenericFailure`, so an unknown backend condition can never smuggle text or detail through.
 */
let reasonForCode = (code: string) =>
  switch code {
  | "IR_00" | "IR_01" | "IR_03" => Unauthorized
  | "IR_05" | "IR_06" => Rejected
  | "IR_16" => SessionAlreadyUsed
  | "IR_24" => SessionExpired
  | _ => GenericFailure
  }

/* ── Response reading ───────────────────────────────────────────────────────── */

let stringAt = (dict, key) =>
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.string)->Option.getOr("")

let optionalStringAt = (dict, key) =>
  dict
  ->Dict.get(key)
  ->Option.flatMap(JSON.Decode.string)
  ->Option.flatMap(value => value->String.length > 0 ? Some(value) : None)

let objectAt = (dict, key) =>
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())

let intAt = (dict, key, fallback) =>
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.float)->Option.mapOr(fallback, Float.toInt)

let nextActionTypeOf = (raw: string): option<nextActionType> =>
  switch raw {
  | "three_ds_invoke" => Some(#three_ds_invoke)
  | "third_party_sdk_session_token" => Some(#third_party_sdk_session_token)
  | "display_bank_transfer_information" => Some(#display_bank_transfer_information)
  | "invoke_ddc" => Some(#invoke_ddc)
  | "redirect_to_url" => Some(#redirect_to_url)
  | _ => None
  }

/*
 * Only allowlisted NAVIGATION fields are lifted out of the next action. A response that carries
 * `payment_method_data.card.*` — which a confirm response legitimately can — is simply never read
 * here, so there is no path by which card metadata could reach the outcome.
 */
let readNextAction = (root: Dict.t<JSON.t>, ~type_: nextActionType) => {
  let nextAction = root->objectAt("next_action")

  let threeDsDict = nextAction->objectAt("three_ds_data")
  let pollDict = threeDsDict->objectAt("poll_config")
  let threeDs = switch type_ {
  | #three_ds_invoke =>
    Some({
      VaultNavigation.authenticationUrl: threeDsDict->stringAt("three_ds_authentication_url"),
      authorizeUrl: threeDsDict->stringAt("three_ds_authorize_url"),
      messageVersion: threeDsDict->stringAt("message_version"),
      directoryServerId: threeDsDict->stringAt("directory_server_id"),
      pollId: pollDict->stringAt("poll_id"),
      delayInSecs: pollDict->intAt("delay_in_secs", 0),
      frequency: pollDict->intAt("frequency", 0),
    })
  | _ => None
  }

  let ddc = switch type_ {
  | #invoke_ddc =>
    let ddcDict = nextAction->objectAt("ddc_data")
    Some({
      VaultNavigation.iframeUrl: ddcDict->stringAt("iframe_url"),
      timeoutMs: ddcDict->intAt("timeout_ms", 30000),
    })
  | _ => None
  }

  let sessionToken = switch type_ {
  | #third_party_sdk_session_token =>
    let tokenDict = nextAction->objectAt("session_token")
    Some({
      VaultNavigation.walletName: tokenDict->stringAt("wallet_name"),
      openBankingSessionToken: tokenDict->stringAt("open_banking_session_token"),
    })
  | _ => None
  }

  RequiresAction({
    type_,
    redirectUrl: nextAction->optionalStringAt("redirect_to_url"),
    threeDs,
    ddc,
    sessionToken,
  })
}

/*
 * The reproduction of client-core's `handleApiRes`. The next-action check comes first, exactly as it
 * does there; the status switch is the fall-through.
 */
let decodeConfirmResponse = (json: JSON.t): navOutcome =>
  switch json->JSON.Decode.object {
  | None => Failed({reason: MalformedResponse})
  | Some(root) =>
    let status = root->stringAt("status")
    let actionType = root->objectAt("next_action")->stringAt("type")->nextActionTypeOf

    switch actionType {
    | Some(#three_ds_invoke as t)
    | Some(#third_party_sdk_session_token as t)
    | Some(#display_bank_transfer_information as t)
    | Some(#invoke_ddc as t) =>
      root->readNextAction(~type_=t)
    | _ =>
      switch status {
      | "succeeded" => Succeeded
      | "requires_capture"
      | "processing"
      | "requires_confirmation"
      | "requires_merchant_action" => Processing
      | "requires_customer_action" => root->readNextAction(~type_=#redirect_to_url)
      | _ => Failed({reason: GenericFailure})
      }
    }
  }

let describeHttpFailure = (parsed: option<JSON.t>, _status: int): navOutcome => {
  let backendCode =
    parsed
    ->Option.flatMap(JSON.Decode.object)
    ->Option.flatMap(root => root->objectAt("error")->optionalStringAt("code"))

  Failed({reason: backendCode->Option.mapOr(GenericFailure, reasonForCode)})
}

@val external encodeURIComponent: string => string = "encodeURIComponent"

let confirmUrl = (~baseUrl, ~paymentId) =>
  `${baseUrl}/payments/${paymentId->encodeURIComponent}/confirm`

let confirmPayment = async (request: finalConfirmRequest): navOutcome => {
  let url = confirmUrl(~baseUrl=request.baseUrl, ~paymentId=request.paymentId)

  let controller = VaultConfirm.makeAbortController()

  request.signal->Option.forEach(callerSignal =>
    if callerSignal->VaultConfirm.signalAborted {
      controller->VaultConfirm.abort
    } else {
      callerSignal->VaultConfirm.onSignalAbort("abort", () => controller->VaultConfirm.abort)
    }
  )

  let timer = switch request.timeoutMs {
  | Some(ms) if ms > 0 => Some(VaultConfirm.setTimeout(() => controller->VaultConfirm.abort, ms))
  | _ => None
  }

  let options: VaultConfirm.fetchOptions = {
    method: "POST",
    /*
     * Raw credential, no scheme — matching client-core's `Utils.getHeader`: `Authorization` for the
     * payment-intent credential, `api-key` for the legacy publishable key. The legacy pair's
     * `client_secret` is already in the body, written by `VaultConfirmBody.build`.
     */
    headers: [
      ("Content-Type", "application/json"),
      request.credential->VaultCredential.authHeader,
      ("x-app-id", request.appId->VaultConfirm.appIdHeader),
      ("x-redirect-uri", ""),
    ]->Dict.fromArray,
    body: request.body->JSON.stringify,
    signal: ?Some(controller->VaultConfirm.controllerSignal),
  }

  let attempted = try {
    Ok(await VaultConfirm.fetch(url, options))
  } catch {
  | _ => Error()
  }

  timer->Option.forEach(VaultConfirm.clearTimeout)

  switch attempted {
  | Error() =>
    /*
     * A thrown fetch, a timeout and an abort are indistinguishable from a request the backend
     * already processed. There is no idempotency key on this endpoint, so the outcome is genuinely
     * unknown and the library never retries it.
     */
    UnknownOutcome
  | Ok(response) =>
    let status = response->VaultConfirm.responseStatus
    let parsed = try {
      Some(await response->VaultConfirm.responseJson)
    } catch {
    | _ => None
    }

    if response->VaultConfirm.responseOk {
      switch parsed {
      | None => Failed({reason: MalformedResponse})
      | Some(json) => json->decodeConfirmResponse
      }
    } else {
      describeHttpFailure(parsed, status)
    }
  }
}
