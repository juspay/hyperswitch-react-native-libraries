/*
 * The submit sequences: session reading, the gates, and the confirmation calls for all three flows.
 *
 * ── THE THREE SEQUENCES ────────────────────────────────────────────────────────
 *
 *   Flow 1  tokenize()
 *     gates → POST /v1/payment-method-sessions/{id}/confirm  [vault credential] → a TOKEN
 *
 *   Flow 2  confirmPayment({cardSource: {type_: #vault, session}})
 *     gates → POST /v1/payment-method-sessions/{id}/confirm  [vault credential]
 *           → POST /payments/{id}/confirm                    [payment-intent credential]
 *           → a navigation union
 *
 *   Flow 3  confirmPayment({cardSource: {type_: #direct}})
 *     gates → POST /payments/{id}/confirm                    [payment-intent credential]
 *           → a navigation union
 *
 * Flow 3 makes NO payment-method-session request and mints no token: the library's own card values
 * go straight into `payment_method_data.card`. That is the whole point of the direct source — the
 * classic non-vault card confirmation, moved inside the library so that client-core stops owning a
 * PAN even when vaulting is switched off.
 *
 * The token minted by Flow 2's first call lives only inside this module. It is not returned, not
 * published, and not readable through any handle. Flow 1's token IS returned — that is the
 * operation's entire purpose, and why it is a separate operation with a separate result type.
 *
 * ── WHY A MINTED TOKEN IS CACHED (and why that is the SAFE choice) ─────────────
 *
 * The interesting failure is call 1 succeeding and call 2 failing. The obvious reaction — discard
 * everything and let the next attempt re-run both — assumes the payment-method-session confirm is
 * idempotent.
 *
 * IT IS NOT. This was checked against the backend rather than left as an open question
 * (`hyperswitch`, `crates/router/src/core/payment_methods.rs::payment_methods_session_confirm`):
 *
 *   - the route accepts no idempotency key, and neither the route nor the core handler mentions
 *     idempotency at all;
 *   - nothing refuses a confirm of a session that has already been confirmed — the only guard is
 *     that the session exists and has not expired;
 *   - each confirm creates a payment method and then OVERWRITES the session's
 *     `associated_payment_methods` with a fresh single-element vector.
 *
 * So a second confirm stores the customer's card a second time, and the session forgets the first.
 * Re-minting on retry would vault one card twice for one checkout.
 *
 * The library therefore does not re-mint. A successful call 1 is remembered for as long as it is
 * provably still valid, and a retry re-runs ONLY call 2. The cache is discarded — never reused —
 * when:
 *
 *   - any card value changes (`cardVersion`), because a token describes the card that was typed
 *     when it was minted;
 *   - the session changes, because the token belongs to that session;
 *   - `reset()` is called, or the component unmounts.
 *
 * What this does NOT solve: the cache lives in component state, so a process restart between the
 * two calls loses it, and the next attempt mints again. Closing that needs an idempotency contract
 * on the endpoint, which is a backend change — it is reported as an external blocker rather than
 * papered over here.
 *
 * An `unknown_outcome` from call 2 is still never retried automatically — that request may have
 * been processed, and there is no idempotency key on it either.
 */

type sessionState =
  | Ready(string)
  | Unusable(string)

let readSession = (session: JSON.t): sessionState => {
  let vaultDetails =
    session
    ->JSON.Decode.object
    ->Option.flatMap(root => root->Dict.get("vault_details"))
    ->Option.flatMap(JSON.Decode.object)

  switch vaultDetails {
  | None => Unusable("This session does not support saving a card.")
  | Some(details) =>
    let vaultType =
      details
      ->Dict.get("vault_type")
      ->Option.flatMap(JSON.Decode.string)
      ->Option.getOr("")
      ->String.trim
      ->String.toLowerCase

    let authorization =
      details
      ->Dict.get("vault_data")
      ->Option.flatMap(JSON.Decode.object)
      ->Option.flatMap(vaultData => vaultData->Dict.get("sdk_authorization"))
      ->Option.flatMap(JSON.Decode.string)
      ->Option.getOr("")

    switch vaultType {
    | "hyperswitch" =>
      authorization->String.trim->String.length > 0
        ? Ready(authorization)
        : Unusable("This session is missing its vault details.")
    | _ => Unusable("This session uses a card vault this component does not support.")
    }
  }
}

let environmentKey = (environment: VaultConfirm.vaultEnvironment) =>
  switch environment {
  | #production => "production"
  | #sandbox => "sandbox"
  | #integration => "integration"
  }

/* ── Public confirm-payment input (Flows 2 and 3) ──────────────────────────── */

/*
 * All NON-CARD. The PAYMENT credential used by the eligibility probe and the final confirm arrives
 * in one of the two shapes Hyperswitch accepts — `sdkAuthorization`, or the legacy `publishableKey`
 * + `clientSecret` pair (see `VaultCredential`). The vault credential lives inside
 * `cardSource.session` and is never named separately.
 *
 * `tokenize()` takes NO input at all: Flow 1 stops after the vault call, so none of these payment
 * fields have anything to act on. Keeping them off that signature is what stops a merchant
 * accidentally believing a tokenize call charged anything.
 */
@genType
type paymentConfirmInput = {
  /*
   * WHICH FLOW. `{type_: #vault, session}` tokenizes first; `{type_: #direct}` confirms with the
   * library's own card values and makes no vault request at all. Required, because there is no
   * defensible default: guessing would mean choosing a customer's PCI posture for them.
   */
  cardSource: VaultCardSource.paymentCardSource,
  paymentId: string,
  /*
   * ── THE PAYMENT CREDENTIAL, IN EITHER SHAPE ──────────────────────────────
   *
   * `sdkAuthorization` is the payment-intent credential and wins whenever it is non-blank. The
   * legacy pair — the merchant's `publishableKey` as the `api-key` header plus the intent's
   * `clientSecret` in the body — is what every integration used before `sdkAuthorization` existed,
   * and hyperswitch-client-core still emits it for wallets, saved cards and retrieve when the
   * intent credential is absent. A confirm with neither shape complete is refused before any
   * request opens.
   */
  sdkAuthorization?: string,
  publishableKey?: string,
  clientSecret?: string,
  /*
   * ── THE ONE CARD VALUE A HOST MAY SUPPLY ──────────────────────────────────
   *
   * Accepted ONLY in `#"external"` mode, where the host owns the cardholder-name field and its
   * validation. It is deliberately a member of its own rather than something reachable through
   * `paymentMethodData`: that record stays non-card and keeps rejecting `card`,
   * `card_holder_name`, `cardHolderName` and every other card key at any depth, so this is a
   * single, named, auditable exception rather than a hole in a general-purpose object.
   *
   * The library attaches it internally — to `payment_method_data.card.card_holder_name` on a direct
   * confirm, and to the card object of the payment-method-session confirm on a vault one. It is
   * never returned, emitted, logged or reflected back.
   */
  cardholderName?: string,
  paymentMethodType?: VaultConfirmBody.paymentMethodType,
  paymentMethodData?: VaultPaymentMethodData.hostPaymentMethodData,
  customerAcceptance?: VaultConfirmBody.hostCustomerAcceptance,
  browserInfo?: VaultConfirmBody.hostBrowserInfo,
  returnUrl?: string,
  paymentType?: VaultConfirmBody.paymentType,
  email?: string,
  /*
   * The host declaring that this payment has a backend eligibility step. The library performs that
   * check itself, with the PAN it already owns, before it confirms anything — see
   * `VaultEligibility` for the contract and for why a transport failure resolves to "allowed".
   */
  eligibilityRequired?: bool,
  /* Reproduces the `x-app-id` header client-core sends on the eligibility call. Non-card. */
  appId?: string,
  /* Base for the payment calls: eligibility and the final `/payments/{id}/confirm`. */
  endpoint?: VaultEndpoint.vaultEndpointConfig,
  /*
   * Base for the payment-method-session confirm (Flow 2's call 1). Falls back to the component's
   * `vaultEndpoint` prop, then to the environment host. Kept separate from `endpoint` because a
   * deployment may front the vault on a different host; client-core passes the same base for both.
   */
  vaultEndpoint?: VaultEndpoint.vaultEndpointConfig,
}

type machinery = {
  tokenize: unit => promise<VaultResult.vaultTokenizeResult>,
  confirmPayment: paymentConfirmInput => promise<VaultResult.vaultPaymentResult>,
  reset: unit => unit,
  isSubmitting: bool,
}

/* A record is its JS object, so this is how we ask "did the caller pass anything at all?". */
external argsAsNullable: paymentConfirmInput => Nullable.t<paymentConfirmInput> = "%identity"

/* Which operation currently owns the single in-flight slot. */
type inFlight =
  | TokenizeInFlight(promise<VaultResult.vaultTokenizeResult>)
  | ConfirmInFlight(promise<VaultResult.vaultPaymentResult>)

/* Remembered across a failed call 2. Never leaves this module. */
type mintedToken = {
  sessionKey: string,
  cardVersion: int,
  token: string,
  metadata: VaultConfirm.vaultCardMetadata,
}

let useMachinery = (
  ~sessionState: sessionState,
  ~environment: VaultConfirm.vaultEnvironment,
  ~isValid: unit => bool,
  ~cardDetails: unit => VaultConfirm.cardDetails,
  ~cardholderName: unit => string,
  /* Which arrangement this form is in. Decides whose cardholder name, if any, is used. */
  ~cardholderNameMode: CardFieldOptions.cardholderNameMode,
  /* Where `tokenize()` posts call 1; also the fallback for a confirm input without `vaultEndpoint`. */
  ~vaultEndpoint: option<VaultEndpoint.vaultEndpointConfig>,
  /* The co-badge pick, present only when the customer was actually offered one. */
  ~cardNetwork: unit => option<string>,
  ~cardVersion: unit => int,
  /* The verdict for the card currently typed, if the live probe already has one. */
  ~eligibilityVerdict: unit => option<VaultEligibility.verdict>,
  ~recordEligibility: VaultEligibility.verdict => unit,
  ~markSubmitAttempted: unit => unit,
  ~presenceGate: unit => option<VaultResult.vaultPaymentResult>,
  ~clearLocal: unit => unit,
): machinery => {
  /*
   * Everything an operation reads at run time goes through this ref, never through the closure.
   * The imperative handle that exposes `tokenize`/`confirmPayment` is created once, so a value
   * captured by closure would be the mount-time value for the life of the component — and the
   * cardholder-name mode in particular changes when the host's field set changes.
   */
  let latestRef = React.useRef((sessionState, environment, cardholderNameMode, vaultEndpoint))
  latestRef.current = (sessionState, environment, cardholderNameMode, vaultEndpoint)
  let currentCardholderNameMode = () => {
    let (_, _, mode, _) = latestRef.current
    mode
  }

  let (isSubmitting, setIsSubmitting) = React.useState(_ => false)

  let inFlightRef: React.ref<option<inFlight>> = React.useRef(None)
  let abortRef: React.ref<option<(string, VaultConfirm.abortController)>> = React.useRef(None)
  let isMountedRef = React.useRef(true)
  let generationRef = React.useRef(0)
  let mintedRef: React.ref<option<mintedToken>> = React.useRef(None)

  let abortInFlight = () => {
    abortRef.current->Option.forEach(((_, controller)) => controller->VaultConfirm.abort)
    abortRef.current = None
  }

  React.useEffect0(() => {
    isMountedRef.current = true
    Some(
      () => {
        isMountedRef.current = false
        generationRef.current = generationRef.current + 1
        inFlightRef.current = None
        mintedRef.current = None
        abortInFlight()
      },
    )
  })

  let sessionKey = switch sessionState {
  | Ready(authorization) => authorization
  | Unusable(_) => ""
  }
  let requestKey = `${sessionKey}|${environment->environmentKey}`
  React.useEffect1(() => {
    /* A different session invalidates any token minted under the previous one. */
    mintedRef.current = None
    switch abortRef.current {
    | Some((key, _)) if key !== requestKey =>
      generationRef.current = generationRef.current + 1
      inFlightRef.current = None
      abortInFlight()
      if isMountedRef.current {
        setIsSubmitting(_ => false)
      }
    | _ => ()
    }
    None
  }, [requestKey])

  /*
   * ── WHOSE CARDHOLDER NAME, AND WHETHER ONE IS ALLOWED ────────────────────────
   *
   * One resolver for every request that carries a card, so the three modes cannot mean different
   * things on the two calls.
   *
   *   #collect   the library's own field is the source; a supplied value is a contradiction
   *   #"external"  the supplied value is the source; the library has no field to read
   *   #omit      there is no name; a supplied value is a contradiction
   *
   * A contradiction is REFUSED rather than resolved by precedence. A host that supplies a name to a
   * form which is collecting its own has two names and no way to know which was sent — and picking
   * one silently is how a customer's typed name gets replaced by a stale one from a previous
   * screen. `Error()` becomes `unsupported_configuration`, before any request.
   *
   * Whitespace is trimmed HERE, at the point the request is built, and never while the customer is
   * typing: trimming per keystroke deletes the space between a first and last name as it is typed.
   */
  let nonBlank = (value: string) => {
    let trimmed = value->String.trim
    trimmed->String.length > 0 ? Some(trimmed) : None
  }

  let resolveCardholderName = (~supplied: option<string>): result<option<string>, unit> =>
    switch currentCardholderNameMode() {
    | #collect => supplied->Option.isSome ? Error() : Ok(cardholderName()->nonBlank)
    | #"external" => Ok(supplied->Option.flatMap(nonBlank))
    | #omit => supplied->Option.isSome ? Error() : Ok(None)
    }

  /*
   * ── THE ONE TOKENIZER ────────────────────────────────────────────────────────
   *
   * Both public operations mint through here. `confirmPayment()` calls this DIRECTLY rather than
   * calling the public `tokenize()`, which matters for two reasons: the public operation would
   * wrap the token in a public result — the exact value Flow 2 must not produce — and it would take
   * the in-flight slot that the payment sequence is already holding.
   *
   * Returns the token and the metadata call 2 needs, or the raw transport error for each caller to
   * map into its own result vocabulary.
   */
  let mintToken = async (
    ~vaultAuthorization: string,
    ~vaultBaseUrl: string,
    ~appId: option<string>,
    ~nickName: option<string>,
    /* Already resolved against the mode by the caller; this function never reads the field. */
    ~cardholderName: option<string>,
    ~signal: VaultConfirm.abortSignal,
  ): result<(string, VaultConfirm.vaultCardMetadata), VaultConfirm.vaultError> => {
    let currentVersion = cardVersion()
    let reusable = switch mintedRef.current {
    | Some(minted)
      if minted.sessionKey === vaultAuthorization && minted.cardVersion === currentVersion =>
      Some((minted.token, minted.metadata))
    | _ => None
    }

    switch reusable {
    | Some(pair) => Ok(pair)
    | None =>
      let outcome = await VaultConfirm.confirmPaymentMethodSession({
        sdkAuthorization: vaultAuthorization,
        vaultBaseUrl,
        appId: ?appId,
        card: cardDetails(),
        cardholderName: ?cardholderName,
        /*
         * The co-badge choice goes to the VAULT too, not only to the payment confirm. Offering a
         * customer a network and then storing their card without it would make the selector a
         * control that changes nothing — which is worse than not offering one.
         */
        cardNetwork: ?VaultConfirmBody.cardNetworkToWire(cardNetwork()),
        nickName: ?nickName,
        signal,
      })
      switch outcome {
      | VaultConfirm.Success({result}) =>
        mintedRef.current = Some({
          sessionKey: vaultAuthorization,
          cardVersion: currentVersion,
          token: result.token,
          metadata: result.card,
        })
        Ok((result.token, result.card))
      | VaultConfirm.Failure({error}) => Error(error)
      }
    }
  }

  /* Shared local gates. Neither performs a network request. */
  let localGate = () =>
    switch presenceGate() {
    | Some(blocked) => Some(blocked)
    | None =>
      if !isValid() {
        markSubmitAttempted()
        Some(VaultResult.invalidCardData())
      } else {
        None
      }
    }

  let openRequest = (~vaultAuthorization, ~environment) => {
    let controller = VaultConfirm.makeAbortController()
    abortRef.current = Some((`${vaultAuthorization}|${environment->environmentKey}`, controller))
    (controller, controller->VaultConfirm.controllerSignal)
  }

  let closeRequest = controller =>
    switch abortRef.current {
    | Some((_, current)) if current === controller => abortRef.current = None
    | _ => ()
    }

  /* ── Flow 1 — tokenize only ─────────────────────────────────────────────── */

  let runTokenize = async () => {
    let (sessionState, environment, cardholderNameMode, vaultEndpoint) = latestRef.current

    switch localGate() {
    | Some(blocked) =>
      /* Re-tagged into the tokenize vocabulary; the same gate, a different result type. */
      switch blocked.status {
      | #not_ready =>
        VaultResult.tokenizeNotReady(
          blocked.error->Option.mapOr(VaultResult.notReadyMessage, e => e.message),
        )
      | _ => VaultResult.tokenizeInvalidCardData()
      }
    | None =>
      switch sessionState {
      | Unusable(message) => VaultResult.tokenizeFailedWith(#invalid_session, message)
      | Ready(vaultAuthorization) =>
        switch vaultEndpoint->VaultEndpoint.resolveVaultBaseUrl(~environment) {
        | Error() =>
          VaultResult.tokenizeFailedWith(
            #unsupported_configuration,
            VaultResult.unsupportedConfigurationMessage,
          )
        | Ok(vaultBaseUrl) =>
        let (controller, signal) = openRequest(~vaultAuthorization, ~environment)
        let minted = await mintToken(
          ~vaultAuthorization,
          ~vaultBaseUrl,
          /* Flow 1 has no host input, so there is no app id to attach. */
          ~appId=None,
          /* Flow 1 takes no input, so there is no host nickname to attach. */
          ~nickName=None,
          /*
           * …and no host cardholder name either. Only `#collect` has a source `tokenize()` can
           * read; in the other two modes the field is not rendered and no value was passed, so no
           * name is sent. `#"external"` is for the confirmation flows, which do have an input.
           */
          ~cardholderName=switch cardholderNameMode {
          | #collect => cardholderName()->nonBlank
          | #"external" | #omit => None
          },
          ~signal,
        )
        closeRequest(controller)
        switch minted {
        | Ok((token, _metadata)) => VaultResult.tokenizeSuccess(token)
        | Error(error) => VaultResult.tokenizeFromPmsFailure(error)
        }
        }
      }
    }
  }

  /* ── The eligibility gate, shared by both confirmation flows ───────────── */

  /*
   * Runs only when the host says this payment has an eligibility step. The live probe usually has a
   * verdict already — it fires as the number completes — and re-asking would put a second request
   * on the wire for one answer, so a cached verdict for the CURRENT card is reused. The reducer
   * clears that cache whenever the number changes, so "current" is a fact rather than a hope.
   */
  let eligibilityGate = async (~args: paymentConfirmInput, ~credential, ~baseUrl, ~signal) =>
    if !(args.eligibilityRequired->Option.getOr(false)) {
      Ok()
    } else {
      let verdict = switch eligibilityVerdict() {
      | Some(known) => known
      | None =>
        let fresh = await VaultEligibility.check({
          baseUrl,
          paymentId: args.paymentId,
          credential,
          appId: args.appId,
          cardNumber: cardDetails().cardNumber,
          signal,
        })
        recordEligibility(fresh)
        fresh
      }
      switch verdict {
      | VaultEligibility.Denied => Error()
      | VaultEligibility.Allowed => Ok()
      }
    }

  /* ── Flows 2 and 3 — confirm the payment ────────────────────────────────── */

  let runConfirmPayment = async (args: paymentConfirmInput) => {
    /*
     * Read through `latestRef`, not the closure. `sessionState` is consulted below to refuse a
     * direct confirm on a vaulting form, and that decision must be made against the session the
     * component holds NOW — not the one it held when this closure happened to be created.
     */
    let (sessionState, environment, _, propVaultEndpoint) = latestRef.current

    /*
     * A JavaScript caller can reach `confirmPayment()` with no argument at all — TypeScript does not
     * bind them. Reading a field off `undefined` would throw a TypeError out of a promise the
     * contract says never throws for a documented outcome, so the missing-input case is answered
     * like any other missing credential.
     */
    if args->argsAsNullable->Nullable.toOption->Option.isNone {
      VaultResult.invalidSession(VaultResult.unusableSessionMessage)
    } else {
      switch localGate() {
      | Some(blocked) => blocked
      | None =>
        if (
          args.paymentMethodData->VaultPaymentMethodData.validateHostPaymentMethodData->Result.isError
        ) {
          VaultResult.forbiddenCardData()
        } else if args.paymentId->String.trim->String.length === 0 {
          VaultResult.invalidSession(VaultResult.unusableSessionMessage)
        } else {
          /*
           * The payment credential is resolved first, from whichever of the two shapes the host
           * supplied. Neither shape complete means nothing can authenticate the request, and the
           * refusal costs zero requests.
           */
          switch VaultCredential.resolve(
            ~sdkAuthorization=args.sdkAuthorization,
            ~publishableKey=args.publishableKey,
            ~clientSecret=args.clientSecret,
          ) {
          | None => VaultResult.invalidSession(VaultResult.unusableSessionMessage)
          | Some(credential) =>
          /*
           * The source is resolved BEFORE anything is opened or sent. A contradictory or incomplete
           * source is a configuration error, and answering it here means it costs zero requests.
           */
          /*
           * Resolved with the other configuration gates — before the source, before the endpoint,
           * before anything is opened. A mode/value contradiction costs zero requests.
           */
          switch resolveCardholderName(~supplied=args.cardholderName) {
          | Error() => VaultResult.unsupportedConfiguration()
          | Ok(resolvedCardholderName) =>
          switch args.cardSource->VaultCardSource.resolve {
          | Error(rejection) =>
            switch rejection->VaultCardSource.describe {
            | #invalid_session => VaultResult.invalidSession(VaultResult.unusableSessionMessage)
            | #unsupported_configuration => VaultResult.unsupportedConfiguration()
            }
          | Ok(source) =>
            switch args.endpoint->VaultEndpoint.resolveBaseUrl(~environment) {
            | Error() => VaultResult.unsupportedConfiguration()
            | Ok(baseUrl) =>
              /*
               * `resolve` proved the SHAPE of the source; this proves its CONTENT — that a vault
               * source's session actually carries a supported vault authorization. Both happen
               * before any request is opened.
               *
               * The abort slot is keyed by the credential in play. Direct mode has no vault
               * credential, so it keys on the payment intent instead: the key exists only so that a
               * request opened under one configuration is not closed under another.
               */
              let prepared = switch source {
              /*
               * ── THE MOUNT AND THE OPERATION MUST AGREE ──────────────────────
               *
               * A form mounted WITH a usable vault session has declared that this card is to be
               * tokenized. Confirming it directly instead would send the PAN to the payment
               * confirm and save nothing — the opposite posture, chosen by nobody, and invisible
               * on screen because the form looks identical either way.
               *
               * So it is refused rather than honoured. This is the mirror of the rule that a
               * direct `cardSource` may not carry a session: the two together mean a caller can
               * neither smuggle a vault session into a direct confirm nor quietly downgrade a
               * vaulting form into one.
               *
               * A form mounted with NO session, or with one this build cannot use, is a direct
               * form and confirms directly — which is exactly how client-core mounts it for a
               * merchant profile set to Skip.
               */
              | VaultCardSource.DirectSource =>
                switch sessionState {
                | Ready(_) => Error(VaultResult.unsupportedConfigurationMessage)
                | Unusable(_) => Ok((None, args.paymentId))
                }
              | VaultCardSource.VaultSource({confirmTokenMode, session}) =>
                switch session->readSession {
                | Ready(authorization) => Ok((Some(confirmTokenMode), authorization))
                | Unusable(message) => Error(message)
                }
              }

              switch prepared {
              | Error(message) if message === VaultResult.unsupportedConfigurationMessage =>
                VaultResult.unsupportedConfiguration()
              | Error(message) => VaultResult.invalidSession(message)
              | Ok((tokenMode, identity)) =>
                /*
                 * The vault base is resolved only when call 1 will happen, and — like every other
                 * configuration gate — before anything is opened or sent.
                 */
                let vaultBase = switch tokenMode {
                | None => Ok("")
                | Some(_) =>
                  switch args.vaultEndpoint {
                  | Some(_) => args.vaultEndpoint
                  | None => propVaultEndpoint
                  }->VaultEndpoint.resolveVaultBaseUrl(~environment)
                }
                switch vaultBase {
                | Error() => VaultResult.unsupportedConfiguration()
                | Ok(vaultBaseUrl) =>
                let (controller, signal) = openRequest(
                  ~vaultAuthorization=identity,
                  ~environment,
                )

                let outcome = switch await eligibilityGate(~args, ~credential, ~baseUrl, ~signal) {
                | Error() => VaultResult.cardNotEligible()
                | Ok() =>
                  switch tokenMode {
                  /* ── Flow 3 — no tokenization, no token, one request. ── */
                  | None =>
                    let body = VaultConfirmBody.build(
                      ~cardPayload=DirectPayload({
                        card: cardDetails(),
                        cardholderName: resolvedCardholderName,
                        cardNetwork: cardNetwork(),
                        nickName: VaultPaymentMethodData.nickNameOf(args.paymentMethodData),
                      }),
                      ~paymentMethodType=args.paymentMethodType,
                      ~paymentMethodData=args.paymentMethodData,
                      ~customerAcceptance=args.customerAcceptance,
                      ~browserInfo=args.browserInfo,
                      ~returnUrl=args.returnUrl,
                      ~paymentType=args.paymentType,
                      ~email=args.email,
                      ~clientSecret=credential->VaultCredential.clientSecretForBody,
                    )

                    let navOutcome = await VaultFinalConfirm.confirmPayment({
                      baseUrl,
                      paymentId: args.paymentId,
                      credential,
                      appId: ?args.appId,
                      body,
                      signal,
                    })
                    navOutcome->VaultResult.fromNavOutcome

                  /* ── Flow 2 — mint internally, then confirm with the token. ── */
                  | Some(confirmTokenMode) =>
                    let minted = await mintToken(
                      ~vaultAuthorization=identity,
                      ~vaultBaseUrl,
                      ~appId=args.appId,
                      ~nickName=VaultPaymentMethodData.nickNameOf(args.paymentMethodData),
                      /* Attached to the PMS-confirm card object, so a vaulted card records it. */
                      ~cardholderName=resolvedCardholderName,
                      ~signal,
                    )

                    switch minted {
                    | Error(error) => VaultResult.fromPmsFailure(error)
                    | Ok((token, metadata)) =>
                      let body = VaultConfirmBody.build(
                        ~cardPayload=TokenPayload({
                          mode: confirmTokenMode,
                          token,
                          metadata,
                        }),
                        ~paymentMethodType=args.paymentMethodType,
                        ~paymentMethodData=args.paymentMethodData,
                        ~customerAcceptance=args.customerAcceptance,
                        ~browserInfo=args.browserInfo,
                        ~returnUrl=args.returnUrl,
                        ~paymentType=args.paymentType,
                        ~email=args.email,
                        ~clientSecret=credential->VaultCredential.clientSecretForBody,
                      )

                      let navOutcome = await VaultFinalConfirm.confirmPayment({
                        baseUrl,
                        paymentId: args.paymentId,
                        credential,
                        appId: ?args.appId,
                        body,
                        signal,
                      })
                      navOutcome->VaultResult.fromNavOutcome
                    }
                  }
                }

                closeRequest(controller)
                outcome
                }
              }
            }
          }
          }
          }
        }
      }
    }
  }

  /*
   * ── ONE IN-FLIGHT OPERATION, REMEMBERED BY KIND ──────────────────────────────
   *
   * The two operations share a single slot rather than one each: they drive the same card state and
   * the same session, so letting a tokenize and a payment confirm run concurrently would mint
   * against one card while the customer edits it.
   *
   * The slot remembers WHICH operation is running, and that is not bookkeeping for its own sake. A
   * single untyped slot forces a cast on the way out, and a cast is wrong precisely when the two
   * operations overlap: `tokenize()` during a pending `confirmPayment()` would hand back a payment
   * result relabelled as a tokenize result — `.token` undefined, `status` a value the tokenize union
   * does not even contain. Repeating the SAME operation returns the same promise, which is what
   * makes double-submission harmless; requesting the OTHER one is refused as `not_ready` without a
   * request, because there is no honest answer to give it while the first is still running.
   */
  let busyTokenizeMessage = "Another card operation is already in progress."

  let trackTokenize = (pending: promise<VaultResult.vaultTokenizeResult>) => {
    let generation = generationRef.current
    setIsSubmitting(_ => true)
    let tracked = pending->Promise.then(result => {
      if generationRef.current === generation {
        inFlightRef.current = None
        if isMountedRef.current {
          setIsSubmitting(_ => false)
        }
      }
      Promise.resolve(result)
    })
    inFlightRef.current = Some(TokenizeInFlight(tracked))
    tracked
  }

  let trackConfirm = (pending: promise<VaultResult.vaultPaymentResult>) => {
    let generation = generationRef.current
    setIsSubmitting(_ => true)
    let tracked = pending->Promise.then(result => {
      if generationRef.current === generation {
        inFlightRef.current = None
        if isMountedRef.current {
          setIsSubmitting(_ => false)
        }
      }
      Promise.resolve(result)
    })
    inFlightRef.current = Some(ConfirmInFlight(tracked))
    tracked
  }

  let tokenize = () =>
    switch inFlightRef.current {
    | Some(TokenizeInFlight(pending)) => pending
    | Some(ConfirmInFlight(_)) =>
      Promise.resolve(VaultResult.tokenizeNotReady(busyTokenizeMessage))
    | None => trackTokenize(runTokenize())
    }

  let confirmPayment = (args: paymentConfirmInput) =>
    switch inFlightRef.current {
    | Some(ConfirmInFlight(pending)) => pending
    | Some(TokenizeInFlight(_)) =>
      Promise.resolve(VaultResult.notReadyWithMessage(busyTokenizeMessage))
    | None => trackConfirm(runConfirmPayment(args))
    }

  let reset = () =>
    switch inFlightRef.current {
    | Some(_) => ()
    | None =>
      mintedRef.current = None
      clearLocal()
    }

  {tokenize, confirmPayment, reset, isSubmitting}
}
