/*
 * The saved-card submit sequence (ADR-0008): the gates, the one request, and the lifecycle rules.
 *
 *   updateSavedPaymentMethod()
 *     gates → PUT /v1/payment-method-sessions/{id}/update-saved-payment-method  [vault credential]
 *           → the token the response carries
 *
 * ── NO CACHE, ON PURPOSE ───────────────────────────────────────────────────────
 *
 * `VaultFormCoordinator` remembers a minted token because the session confirm is NOT idempotent: a
 * second confirm vaults the card again. The saved-card update is different in kind. It names an
 * EXISTING saved card by token, refreshes the CVC the backend holds under that token, and answers
 * with the same token. Calling it twice stores nothing twice; it restarts the 15-minute window the
 * CVC is kept for. So a repeat call after a settled one performs a fresh request rather than
 * replaying a remembered answer, and there is no cached result for a prop change to discard.
 *
 * ── WHAT INVALIDATES WHAT ─────────────────────────────────────────────────────
 *
 *   paymentMethodToken or session changes   abort in-flight work AND clear the CVC — it was typed
 *                                           for a different card
 *   environment or vaultEndpoint changes    abort in-flight work; the CVC is RETAINED — it describes
 *                                           the card, not the host
 *   reset()                                 abort in-flight work and clear the CVC
 *   unmount                                 abort in-flight work; nothing is set afterwards
 *   a second call while one is running      the SAME promise; never a second request
 *
 * An aborted call resolves `unknown_outcome` to whoever awaited it, and is never retried here.
 */

type machinery = {
  updateSavedPaymentMethod: unit => promise<VaultResult.vaultTokenizeResult>,
  reset: unit => unit,
  isSubmitting: bool,
}

/* One spelling of the abort-slot key, used at render time and at call time alike. */
let keyOf = (
  ~sessionState: VaultFormCoordinator.sessionState,
  ~environment: VaultConfirm.vaultEnvironment,
  ~vaultEndpoint: option<VaultEndpoint.vaultEndpointConfig>,
  ~paymentMethodToken: string,
) => {
  let sessionKey = switch sessionState {
  | VaultFormCoordinator.Ready(authorization) => authorization
  | VaultFormCoordinator.Unusable(_) => ""
  }
  let endpointKey = vaultEndpoint->Option.map(e => e.VaultEndpoint.baseUrl)->Option.getOr("")
  let identity = `${sessionKey}|${paymentMethodToken}`
  (identity, `${identity}|${environment->VaultFormCoordinator.environmentKey}|${endpointKey}`)
}

let useMachinery = (
  ~sessionState: VaultFormCoordinator.sessionState,
  ~environment: VaultConfirm.vaultEnvironment,
  ~vaultEndpoint: option<VaultEndpoint.vaultEndpointConfig>,
  ~paymentMethodToken: string,
  /* The raw validator verdict for the CVC as it stands now. */
  ~isValid: unit => bool,
  ~cvc: unit => string,
  ~markSubmitAttempted: unit => unit,
  ~clearLocal: unit => unit,
): machinery => {
  /*
   * Everything an operation reads at run time goes through this ref, never through the closure. The
   * imperative handle that exposes `updateSavedPaymentMethod` is created once, so a value captured
   * by closure would be the mount-time one for the life of the component — and the token in
   * particular changes when the customer picks a different saved card.
   */
  let latestRef = React.useRef((sessionState, environment, vaultEndpoint, paymentMethodToken))
  latestRef.current = (sessionState, environment, vaultEndpoint, paymentMethodToken)

  let (isSubmitting, setIsSubmitting) = React.useState(_ => false)

  let inFlightRef: React.ref<option<promise<VaultResult.vaultTokenizeResult>>> = React.useRef(None)
  let abortRef: React.ref<option<(string, VaultConfirm.abortController)>> = React.useRef(None)
  let isMountedRef = React.useRef(true)
  let generationRef = React.useRef(0)

  let abortInFlight = () => {
    abortRef.current->Option.forEach(((_, controller)) => controller->VaultConfirm.abort)
    abortRef.current = None
  }

  /* Abandon whatever is running: what it resolves to may not clear a newer slot or set state. */
  let invalidate = () => {
    generationRef.current = generationRef.current + 1
    inFlightRef.current = None
    abortInFlight()
    if isMountedRef.current {
      setIsSubmitting(_ => false)
    }
  }

  React.useEffect0(() => {
    isMountedRef.current = true
    Some(
      () => {
        isMountedRef.current = false
        generationRef.current = generationRef.current + 1
        inFlightRef.current = None
        abortInFlight()
      },
    )
  })

  let (identityKey, requestKey) = keyOf(
    ~sessionState,
    ~environment,
    ~vaultEndpoint,
    ~paymentMethodToken,
  )

  /* A change to what the request is ABOUT or WHERE it goes aborts one opened under the old key. */
  React.useEffect1(() => {
    switch abortRef.current {
    | Some((key, _)) if key !== requestKey => invalidate()
    | _ => ()
    }
    None
  }, [requestKey])

  /*
   * Only a different card or session clears the CVC. Compared against the previous key rather than
   * run unconditionally, because an effect with dependencies also runs on mount — and on a Strict
   * Mode replay — where there is nothing to clear and clearing would discard what was just typed.
   */
  let identityRef = React.useRef(identityKey)
  React.useEffect1(() => {
    if identityRef.current !== identityKey {
      identityRef.current = identityKey
      clearLocal()
    }
    None
  }, [identityKey])

  let closeRequest = controller =>
    switch abortRef.current {
    | Some((_, current)) if current === controller => abortRef.current = None
    | _ => ()
    }

  /*
   * The gates, in order, each answering BEFORE anything is sent:
   *   CVC well-formed for the network in force  → else validation_error, and the field shows why
   *   a non-blank token                          → else not_ready
   *   a usable session                           → else invalid_session
   *   a valid base URL                           → else unsupported_configuration
   * There is no presence gate: the component owns its one field, so it cannot be missing or doubled.
   */
  let run = async () => {
    let (sessionState, environment, vaultEndpoint, token) = latestRef.current

    if !isValid() {
      markSubmitAttempted()
      VaultResult.tokenizeInvalidCardData()
    } else if token->String.trim->String.length === 0 {
      VaultResult.tokenizeNotReady(VaultSavedCard.missingTokenMessage)
    } else {
      switch sessionState {
      | VaultFormCoordinator.Unusable(message) =>
        VaultResult.tokenizeFailedWith(#invalid_session, message)
      | VaultFormCoordinator.Ready(vaultAuthorization) =>
        switch vaultEndpoint->VaultEndpoint.resolveVaultBaseUrl(~environment) {
        | Error() =>
          VaultResult.tokenizeFailedWith(
            #unsupported_configuration,
            VaultResult.unsupportedConfigurationMessage,
          )
        | Ok(vaultBaseUrl) =>
          let (_, key) = keyOf(
            ~sessionState,
            ~environment,
            ~vaultEndpoint,
            ~paymentMethodToken=token,
          )
          let controller = VaultConfirm.makeAbortController()
          abortRef.current = Some((key, controller))

          let result = await VaultSavedCard.updateSavedPaymentMethod({
            vaultBaseUrl,
            sdkAuthorization: vaultAuthorization,
            paymentMethodToken: token->String.trim,
            cvc: cvc(),
            signal: controller->VaultConfirm.controllerSignal,
          })

          closeRequest(controller)
          result
        }
      }
    }
  }

  let track = (pending: promise<VaultResult.vaultTokenizeResult>) => {
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
    inFlightRef.current = Some(tracked)
    tracked
  }

  let updateSavedPaymentMethod = () =>
    switch inFlightRef.current {
    | Some(pending) => pending
    | None => track(run())
    }

  /*
   * Unlike the card form's `reset()`, which is a no-op while busy, ADR-0008 says this one aborts:
   * the customer changing their mind mid-request must not leave a CVC in flight for a card they are
   * no longer paying with.
   */
  let reset = () => {
    invalidate()
    clearLocal()
  }

  {updateSavedPaymentMethod, reset, isSubmitting}
}
