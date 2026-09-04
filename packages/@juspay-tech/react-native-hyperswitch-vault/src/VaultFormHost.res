let missingMessage = missing => {
  let names = missing->Array.map(VaultCardController.kindLabel)->Array.join(", ")
  `${names} must be mounted inside <CardForm> before submitting.`
}
let duplicateMessage = (kind, count) =>
  `Only one ${VaultCardController.kindLabel(
      kind,
    )} may be mounted per <CardForm>; found ${count->Int.toString}.`

let savedCardWithNumberMessage = "A CardCVCField carrying savedCard must be the only field mounted; remove the card-number and expiry fields to update a saved card."

let requiredKinds = [
  VaultCardController.CardNumberKind,
  VaultCardController.ExpiryKind,
  VaultCardController.CvcKind,
]

type host = {
  contextValue: VaultWidgetContext.contextValue,
  machinery: VaultFormCoordinator.machinery,
  focusField: VaultPublicState.elementType => unit,
}

let useHost = (
  ~session: option<JSON.t>,
  /* The web SDK's spelling of the same credential: accepted in place of `session`. */
  ~sdkAuthorization: option<string>,
  /* The web SDK's `vaultDetails` option, accepted in place of `session` too. */
  ~vaultDetails: option<VaultDetails.vaultDetails>,
  ~environment: VaultFormOptions.vaultEnvironment,
  ~appearance: option<VaultFormOptions.appearance>,
  ~locale: option<string>,
  ~localisation: option<VaultFormOptions.localisation>,
  ~disabled: bool,
  ~accessible: option<bool>,
  ~enabledCardSchemes: array<string>,
  ~eligibility: option<VaultFormOptions.eligibilityConfig>,
  /* Where `tokenize()` posts the payment-method-session confirm. Absent means the environment host. */
  ~vaultEndpoint: option<VaultEndpoint.vaultEndpointConfig>,
  /*
   * Which arrangement the cardholder name is in. The VIEW uses it to decide whether to render a
   * field; the COORDINATOR uses it to decide whose value goes on the wire and whether a supplied
   * one is even allowed. One prop, read in both places, so the two cannot disagree.
   */
  ~cardholderNameMode: CardFieldOptions.cardholderNameMode,
  /* The web's group events. Absent means no merchant is listening, and nothing is derived. */
  ~onReady: option<VaultPublicState.cardFormEvent => unit>,
  ~onChange: option<VaultPublicState.cardFormChange => unit>,
  /* Form-wide default for every field's `unstyled`. */
  ~unstyled: bool,
  /*
   * Form-wide default for every field's `errorDisplay`. The two callers disagree on purpose:
   * `CardForm` passes the composable default, `HyperswitchVaultForm` the ready-made one.
   */
  ~defaultErrorDisplay: CardFieldOptions.errorDisplay,
): host => {
  /*
   * The component's session backs `tokenize()` ONLY. A confirmation reads its session from
   * `cardSource`, so a form mounted with no session at all is a valid Flow 3 form, which is
   * exactly how client-core mounts it when the merchant profile says Skip.
   */
  let sessionState = React.useMemo3(
    () =>
      switch (session, vaultDetails, sdkAuthorization) {
      | (Some(session), _, _) => session->VaultFormCoordinator.readSession
      | (None, Some(details), _) =>
        VaultFormCoordinator.sessionFromVaultDetails(~details, ~sdkAuthorization)
      | (None, None, Some(authorization)) =>
        VaultFormCoordinator.sessionFromAuthorization(authorization)
      | (None, None, None) => VaultFormCoordinator.Unusable("No card-vault session was supplied.")
      },
    (session, vaultDetails, sdkAuthorization),
  )
  let theme = React.useMemo1(() => appearance->VaultFormOptions.buildTheme, [appearance])
  let bundle = React.useMemo1(() => LocaleBundles.resolve(locale), [locale])
  let labels = React.useMemo2(
    () => localisation->VaultFormOptions.resolveLabels(~bundle),
    (localisation, bundle),
  )
  let messages = React.useMemo2(
    () => localisation->VaultFormOptions.resolveMessages(~bundle),
    (localisation, bundle),
  )
  let errorFontSize =
    (12. +. VaultFormOptions.errorTextSizeAdjustOf(appearance)) *. theme.fontScale
  let errorSpacing = VaultFormOptions.errorMessageSpacingOf(appearance)
  let brandIconMode = VaultFormOptions.cardBrandIconOf(appearance)
  let defaultLabelBehavior = VaultFormOptions.labelsModeOf(appearance)

  /*
   * Canonicalised once per distinct list, keyed on its contents rather than its identity so a
   * merchant passing an inline array literal does not re-run (and, in development, re-warn) on
   * every render.
   */
  let schemesKey = enabledCardSchemes->Array.join(" ")
  let acceptedSchemes = React.useMemo1(
    () => CardNetworkNames.normaliseList(enabledCardSchemes),
    [schemesKey],
  )

  let validators: CardStateReducer.validators = {
    cardNumber: VaultFormOptions.makeCardNumberValidator(messages),
    expiry: VaultFormOptions.makeExpiryValidatorWith(messages),
    cvc: VaultFormOptions.makeCvcValidatorWith(messages),
    network: VaultFormOptions.makeNetworkValidator(~enabledCardSchemes=acceptedSchemes, messages),
    notEligible: Some(messages.cardNotEligible),
  }

  let controller = VaultCardController.use(~validators, ~enabledCardSchemes=acceptedSchemes)

  let countOf = controller.countOf

  /*
   * WHICH SUBMISSION the mounted fields describe: decided from the registry the way the web SDK
   * decides it from which fields were created. A card-number field means a new card, and then all
   * three are required exactly once. A lone CVC field means a saved card's CVC: the token it needs
   * comes from the field's `savedCard`, and a lone CVC field mounted WITHOUT one is still that
   * flow, refused later with the message that names the fix.
   */
  let presenceGate = (): result<VaultFormCoordinator.submitFlow, string> => {
    let numbers = countOf(VaultCardController.CardNumberKind)
    let expiries = countOf(VaultCardController.ExpiryKind)
    let cvcs = countOf(VaultCardController.CvcKind)
    if numbers === 0 && expiries === 0 && cvcs === 1 {
      Ok(
        VaultFormCoordinator.SavedCardCvc(
          controller.savedCard()->Option.getOr({CardStateReducer.token: "", network: ""}),
        ),
      )
    } else if numbers === 0 && expiries === 0 && cvcs === 0 {
      Error(VaultResult.incompleteFieldSetMessage)
    } else if controller.savedCard()->Option.isSome {
      /* A saved card has a number already; a number field beside it is a contradiction, not a new card. */
      Error(savedCardWithNumberMessage)
    } else {
      let missing = requiredKinds->Array.filter(kind => countOf(kind) == 0)
      if missing->Array.length > 0 {
        Error(missingMessage(missing))
      } else {
        switch requiredKinds->Array.find(kind => countOf(kind) > 1) {
        | Some(kind) => Error(duplicateMessage(kind, countOf(kind)))
        | None => Ok(VaultFormCoordinator.NewCard)
        }
      }
    }
  }

  /*
   * THE LIVE ELIGIBILITY PROBE.
   *
   * Fires as the number completes, so the "card not accepted" message appears while the customer is
   * still looking at the field. A verdict is recorded only if the number has not changed since the
   * request went out.
   */
  let probeGenerationRef = React.useRef(0)
  let probeMountedRef = React.useRef(true)
  React.useEffect0(() => {
    probeMountedRef.current = true
    Some(
      () => {
        probeMountedRef.current = false
        probeGenerationRef.current = probeGenerationRef.current + 1
      },
    )
  })

  let probeKey = `${controller.values.cardNumber}|${controller.values.brand}`
  React.useEffect2(() => {
    switch eligibility {
    | None => ()
    | Some(config) =>
      switch controller.eligibilityProbe() {
      | #idle => ()
      | #reset => controller.recordEligibility(VaultEligibility.Allowed)
      | #check(digits) =>
        let credential = VaultCredential.resolve(
          ~sdkAuthorization=config.sdkAuthorization,
          ~publishableKey=config.publishableKey,
          ~clientSecret=config.clientSecret,
        )
        switch (config.endpoint->VaultEndpoint.resolveBaseUrl(~environment), credential) {
        | (Error(), _) => ()
        | (_, None) => ()
        | (Ok(baseUrl), Some(credential)) =>
          probeGenerationRef.current = probeGenerationRef.current + 1
          let generation = probeGenerationRef.current
          controller.markEligibilityPending()
          VaultEligibility.check({
            baseUrl,
            paymentId: config.paymentId,
            credential,
            appId: config.appId,
            cardNumber: digits,
          })
          ->Promise.then(verdict => {
            if probeMountedRef.current && probeGenerationRef.current === generation {
              controller.recordEligibility(verdict)
            }
            Promise.resolve()
          })
          ->ignore
        }
      }
    }
    None
  }, (probeKey, eligibility))

  let machinery = VaultFormCoordinator.useMachinery(
    ~sessionState,
    ~environment,
    ~isValid=controller.isValidNow,
    ~cardDetails=controller.cardDetails,
    ~cardholderName=controller.cardholderName,
    ~cardholderNameMode,
    ~vaultEndpoint,
    ~cardNetwork=controller.cardNetwork,
    ~cardVersion=controller.cardVersion,
    ~eligibilityVerdict=controller.eligibilityVerdict,
    ~recordEligibility=controller.recordEligibility,
    ~markSubmitAttempted=controller.markSubmitAttempted,
    ~presenceGate,
    ~clearLocal=controller.reset,
    ~savedCardKey=controller.values.savedCard->Option.mapOr("", saved => saved.token),
  )

  /*
   * `#absent` is not `#invalid`: a form mounted with no session at all is a legitimate Flow 3 form.
   * `#expired` and `#consumed` are the two lifecycle states the web SDK reports.
   */
  let sessionStatus: VaultPublicState.vaultSessionStatus = switch sessionState {
  | Unusable(_) =>
    session->Option.isNone && vaultDetails->Option.isNone && sdkAuthorization->Option.isNone
      ? #absent
      : #invalid
  | Ready(ready) =>
    if machinery.isConsumed {
      #consumed
    } else if VaultFormCoordinator.isExpired(ready) {
      #expired
    } else {
      #valid
    }
  }

  let isSubmitting = machinery.isSubmitting

  /*
   * `fieldsReady` is derived from the SAME registry `presenceGate` uses to refuse a submit, so a
   * merchant's disabled Pay button and the library's own gate cannot disagree. The snapshot is
   * built inside the emitter's effect rather than during render: each field registers itself in a
   * child effect, and child effects run before the parent's.
   */
  let buildFormChange = () => {
    let snapshot = controller.publicSnapshot()
    let savedCardMode = controller.values.savedCard->Option.isSome
    VaultPublicState.formChangeOf(
      ~fieldsReady=presenceGate()->Result.isOk,
      ~sessionStatus,
      ~submitting=isSubmitting,
      ~isCoBadged=controller.values.isCoBadged,
      ~eligibility=snapshot.eligibility,
      ~networkError=snapshot.networkError,
      ~payload=snapshot.cardDetails,
      ~fields={
        cardNumber: snapshot.cardNumber,
        cardExpiry: snapshot.cardExpiry,
        cardCvc: snapshot.cardCvc,
        /* Present exactly when the field IS MOUNTED, not when the mode says it ought to be. */
        cardholderName: ?(
          countOf(VaultCardController.CardholderNameKind) > 0
            ? Some(snapshot.cardholderName)
            : None
        ),
      },
      ~savedCardMode,
    )
  }

  VaultStateEmitter.use(
    ~build=buildFormChange,
    ~equal=VaultPublicState.formChangeEq,
    ~notify=onChange,
  )

  /*
   * The web's group `ready`: fired on every transition INTO "all required fields complete", which
   * is how the payments group reports it (its flag resets when the form stops being complete).
   */
  VaultStateEmitter.use(
    ~build=() => buildFormChange().complete,
    ~equal=(a, b) => a === b,
    ~notify=onReady->Option.map(fn => complete =>
      if complete {
        fn({VaultPublicState.elementType: #cardForm})
      }
    ),
  )

  {
    contextValue: {
      controller,
      publicSnapshot: controller.publicSnapshot,
      theme,
      labels,
      errorFontSize,
      errorSpacing,
      brandIconMode,
      accessible,
      editable: !machinery.isSubmitting && !disabled,
      isProcessing: machinery.isSubmitting || disabled,
      onAnalytics: _ => (),
      unstyled,
      defaultErrorDisplay,
      defaultLabelBehavior,
    },
    machinery,
    focusField: controller.focusField,
  }
}
