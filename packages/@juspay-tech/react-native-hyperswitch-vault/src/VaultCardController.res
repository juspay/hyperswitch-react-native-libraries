open ReactNative

/*
 * `CardholderNameKind` is registered but is NOT in `VaultFormHost.requiredKinds`: the cardholder
 * name is optional, and a custom layout that omits it must still submit. It is counted purely so
 * the form state can report whether the field EXISTS, which in a custom layout only the merchant
 * knows.
 */
type widgetKind = CardNumberKind | ExpiryKind | CvcKind | CardholderNameKind

let kindLabel = kind =>
  switch kind {
  | CardNumberKind => "CardNumberField"
  | ExpiryKind => "CardExpiryField"
  | CvcKind => "CardCVCField"
  | CardholderNameKind => "CardholderNameField"
  }

type controller = {
  values: CardFormTypes.cardFieldValues,
  visibleErrors: CardFormTypes.cardFieldErrors,
  fieldOk: CardFormTypes.cardFieldOk,
  /*
   * The merchant-facing snapshot. Derived, never stored: a pure function of the reducer state this
   * controller already holds, so there is no second source of truth to keep in sync and nothing new
   * is retained.
   */
  publicSnapshot: unit => VaultPublicState.controllerSnapshot,
  onNumberChange: CardFieldLogic.numberChange => unit,
  onExpiryChange: CardFieldLogic.expiryChange => unit,
  onCvcChange: CardFieldLogic.cvcChange => unit,
  onFocus: CardStateReducer.field => unit,
  onBlur: CardStateReducer.field => unit,
  onBackspace: (CardStateReducer.field, CardFieldLogic.backspaceAction) => unit,
  isValid: bool,
  isValidNow: unit => bool,
  cardDetails: unit => VaultConfirm.cardDetails,
  /* Read at submit time only; the value never leaves the library. */
  cardholderName: unit => string,
  /*
   * The network to put on the wire, present only when the customer was offered a genuine choice.
   * On a single-network card the backend can derive the brand from the PAN it already has, so
   * sending it would add a field without adding information.
   */
  cardNetwork: unit => option<string>,
  /* The customer's co-badge pick. Internal: no callback reports it, and nothing reads it back. */
  selectNetwork: string => unit,
  /* Launches the optional native scanner and feeds the result through the ordinary field path. */
  scanCard: unit => unit,
  /* Bumps on every card-value change — the coordinator's token-invalidation signal. */
  cardVersion: unit => int,
  /* Eligibility for the card currently typed. `None` until a probe has answered. */
  eligibilityVerdict: unit => option<VaultEligibility.verdict>,
  recordEligibility: VaultEligibility.verdict => unit,
  markEligibilityPending: unit => unit,
  /* What the live probe should do next, given the number as it now stands. */
  eligibilityProbe: unit => CardFieldLogic.eligibilityProbe,
  onCardholderNameChange: string => unit,
  markSubmitAttempted: unit => unit,
  reset: unit => unit,
  /* The field handle's `clear()`: one field back to mount. */
  clearField: CardStateReducer.field => unit,
  /* The CVC field's `savedCard` prop, mirrored into the reducer while the field is mounted. */
  setSavedCard: option<CardStateReducer.savedCard> => unit,
  savedCard: unit => option<CardStateReducer.savedCard>,
  focusField: VaultPublicState.elementType => unit,
  register: widgetKind => unit => unit,
  countOf: widgetKind => int,
  registryVersion: int,
  cardRef: React.ref<Nullable.t<TextInput.element>>,
  expiryRef: React.ref<Nullable.t<TextInput.element>>,
  cvcRef: React.ref<Nullable.t<TextInput.element>>,
  cardholderRef: React.ref<Nullable.t<TextInput.element>>,
  safeState: CardFormTypes.cardFieldValues => unit,
}

let focusRef = (ref: React.ref<Nullable.t<TextInput.element>>) =>
  switch ref.current->Nullable.toOption {
  | None => ()
  | Some(node) => node->TextInputElement.focus
  }

let blurRef = (ref: React.ref<Nullable.t<TextInput.element>>) =>
  switch ref.current->Nullable.toOption {
  | None => ()
  | Some(node) => node->TextInputElement.blur
  }

let use = (~validators: CardStateReducer.validators, ~enabledCardSchemes: array<string>) => {
  let (state, dispatch) = React.useReducer(CardStateReducer.reduce, CardStateReducer.initial)

  let cardRef = React.useRef(Nullable.null)
  let expiryRef = React.useRef(Nullable.null)
  let cvcRef = React.useRef(Nullable.null)
  let cardholderRef = React.useRef(Nullable.null)

  let registryRef: React.ref<Map.t<int, widgetKind>> = React.useRef(Map.make())
  let nextIdRef = React.useRef(0)
  let (registryVersion, setRegistryVersion) = React.useState(() => 0)

  let register = kind => {
    nextIdRef.current = nextIdRef.current + 1
    let id = nextIdRef.current
    registryRef.current->Map.set(id, kind)
    setRegistryVersion(version => version + 1)
    () => {
      registryRef.current->Map.delete(id)->ignore
      setRegistryVersion(version => version + 1)
    }
  }

  let countOf = kind => {
    let count = ref(0)
    registryRef.current->Map.forEach(entry =>
      if entry === kind {
        count := count.contents + 1
      }
    )
    count.contents
  }

  let errors = state->CardStateReducer.errorsFor(~validators)

  let latestRef = React.useRef((state, errors))
  latestRef.current = (state, errors)

  let onNumberChange = (change: CardFieldLogic.numberChange) => {
    dispatch(NumberChanged(change))
    if change.advanceFocus {
      focusRef(expiryRef)
    }
  }

  let onExpiryChange = (change: CardFieldLogic.expiryChange) => {
    dispatch(ExpiryChanged(change))
    if change.advanceFocus {
      focusRef(cvcRef)
    }
  }

  let onCvcChange = (change: CardFieldLogic.cvcChange) => {
    dispatch(CvcChanged(change))
  }

  let onBackspace = (_field, action: CardFieldLogic.backspaceAction) =>
    switch action {
    | #blurSelf => blurRef(cardRef)
    | #focusCardNumber => focusRef(cardRef)
    | #focusExpiry => focusRef(expiryRef)
    | #none => ()
    }

  /*
   * The schemes the customer may pick between: what the number matches, narrowed to what the
   * merchant accepts. An empty merchant list means "no restriction stated", not "nothing allowed" —
   * the same reading `makeNetworkValidator` takes.
   */
  let eligibleSchemes =
    enabledCardSchemes->Array.length === 0
      ? state.matchedSchemes
      : state.matchedSchemes->Array.filter(scheme =>
          enabledCardSchemes->Array.some(enabled => enabled === scheme)
        )

  let eligibilityStatus: VaultPublicState.vaultEligibilityStatus = switch state.eligibility {
  | Unknown => #unknown
  | Pending => #pending
  | Allowed => #allowed
  | Denied => #denied
  }

  let networkInForce = state->CardStateReducer.effectiveNetwork
  let isCoBadged = state->CardStateReducer.isCoBadged && eligibleSchemes->Array.length > 1

  /*
   * `accepted` is the RAW validator verdict and `visibleError` is the already-filtered message the
   * UI is rendering. Publishing both keeps "is this field done?" and "is the customer being shown a
   * problem?" as the separate questions they are, and stops a merchant's chrome disagreeing with
   * the library's.
   */
  let publicSnapshot = (): VaultPublicState.controllerSnapshot => {
    let brand = VaultPublicState.brandOf(networkInForce)
    {
      cardNumber: VaultPublicState.fieldChangeOf(
        {
          value: state.cardNumber,
          accepted: errors.cardNumber->Option.isNone,
          touched: state.numberMeta.touched,
          visibleError: CardStateReducer.numberError(state, errors),
          invalidCode: #invalid_card_number,
        },
        ~elementType=#cardNumber,
        ~brand,
        ~isCoBadged=Some(isCoBadged),
        ~eligibility=Some(eligibilityStatus),
      ),
      cardExpiry: VaultPublicState.fieldChangeOf(
        {
          value: state.expiryDisplay,
          accepted: errors.expiry->Option.isNone,
          touched: state.expiryMeta.touched,
          visibleError: CardStateReducer.expiryError(state, errors),
          invalidCode: #invalid_expiry,
        },
        ~elementType=#cardExpiry,
      ),
      /* The CVC carries the network in force, as the web relays the detected brand to its CVC field. */
      cardCvc: VaultPublicState.fieldChangeOf(
        {
          value: state.cvc,
          accepted: errors.cvc->Option.isNone,
          touched: state.cvcMeta.touched,
          visibleError: CardStateReducer.cvcError(state, errors),
          invalidCode: #invalid_cvc,
        },
        ~elementType=#cardCvc,
        ~brand,
      ),
      cardholderName: VaultPublicState.cardholderNameChangeOf(
        ~value=state.cardholderName,
        ~touched=state.cardholderMeta.touched,
      ),
      /*
       * The RAW verdict, not `CardStateReducer.networkError`'s touched-filtered one: `localGate`
       * asks `isValid`, which consults the raw `errors.network`, and `canSubmit` must agree with it.
       */
      networkError: errors.network->Option.map((
        message,
      ): VaultPublicState.vaultFieldError => {code: #unsupported_network, message}),
      eligibility: eligibilityStatus,
      /* The web's `cardDetailsChange` payload, by the web's own function. */
      cardDetails: VaultPublicState.cardDetailsOf(
        PaymentEventData.buildCardInfo(
          ~cardNumber=state.cardNumber,
          ~expiry=state.expiryDisplay,
          ~cvc=state.cvc,
          ~brand=networkInForce,
        ),
      ),
    }
  }

  {
    publicSnapshot,
    values: {
      cardNumber: state.cardNumber,
      expiryDisplay: state.expiryDisplay,
      cvc: state.cvc,
      cardholderName: state.cardholderName,
      brand: networkInForce,
      eligibleSchemes,
      /* Offered only when the narrowed set still leaves a real choice. */
      isCoBadged,
      savedCard: state.savedCard,
    },
    visibleErrors: {
      cardNumber: ?CardStateReducer.numberError(state, errors),
      cardExpiry: ?CardStateReducer.expiryError(state, errors),
      cardCvc: ?CardStateReducer.cvcError(state, errors),
      network: ?CardStateReducer.networkError(state, errors),
      eligibility: ?CardStateReducer.eligibilityError(state, errors),
    },
    fieldOk: {
      cardNumber: CardStateReducer.numberFieldOk(state, errors),
      cardExpiry: CardStateReducer.expiryFieldOk(state, errors),
      cardCvc: CardStateReducer.cvcFieldOk(state, errors),
    },
    onNumberChange,
    onExpiryChange,
    onCvcChange,
    onFocus: field => dispatch(Focused(field)),
    onBlur: field => dispatch(Blurred(field)),
    onBackspace,
    isValid: CardStateReducer.isValid(errors),
    isValidNow: () => {
      let (_, latestErrors) = latestRef.current
      CardStateReducer.isValid(latestErrors)
    },
    cardDetails: () => {
      let (latest, _) = latestRef.current
      {
        VaultConfirm.cardNumber: latest.cardNumber,
        expiryMonth: latest.expiryMonth,
        expiryYear: latest.expiryYear,
        cvc: latest.cvc,
      }
    },
    cardholderName: () => {
      let (latest, _) = latestRef.current
      latest.cardholderName
    },
    cardNetwork: () => {
      let (latest, _) = latestRef.current
      /*
       * `matchedSchemes`, not the merchant-narrowed set: the question is whether this CARD carries
       * more than one network, which is what makes the value informative.
       */
      if latest.matchedSchemes->Array.length > 1 {
        let network = latest->CardStateReducer.effectiveNetwork
        network->String.length > 0 ? Some(network) : None
      } else {
        None
      }
    },
    selectNetwork: network => dispatch(NetworkSelected(network)),
    /*
     * A scan replaces the number and expiry outright, then lands the customer on the CVC — the one
     * value a scanner cannot read. Both values go through `CardFieldLogic`, the same functions a
     * keystroke uses, so a scanned card is formatted and validated identically to a typed one.
     */
    scanCard: () =>
      ScanCardBridge.launch(outcome =>
        switch outcome {
        | ScanCardBridge.Succeeded(data) =>
          dispatch(NumberChanged(CardFieldLogic.onCardNumberText(data.pan, ~currentBrand="")))
          let display = data->ScanCardBridge.expiryDisplay
          if display->String.length > 0 {
            dispatch(ExpiryChanged(CardFieldLogic.onExpiryText(display)))
          }
          focusRef(cvcRef)
        | ScanCardBridge.Failed
        | ScanCardBridge.Cancelled
        | ScanCardBridge.NoResult => ()
        }
      ),
    cardVersion: () => {
      let (latest, _) = latestRef.current
      latest.cardVersion
    },
    eligibilityVerdict: () => {
      let (latest, _) = latestRef.current
      switch latest.eligibility {
      | Allowed => Some(VaultEligibility.Allowed)
      | Denied => Some(VaultEligibility.Denied)
      | Pending
      | Unknown => None
      }
    },
    recordEligibility: verdict =>
      dispatch(
        EligibilityChanged(
          switch verdict {
          | VaultEligibility.Allowed => Allowed
          | VaultEligibility.Denied => Denied
          },
        ),
      ),
    markEligibilityPending: () => dispatch(EligibilityChanged(Pending)),
    eligibilityProbe: () => {
      let (latest, _) = latestRef.current
      CardFieldLogic.eligibilityFor(
        ~cardNumber=latest.cardNumber,
        ~brand=latest->CardStateReducer.effectiveNetwork,
        ~alreadyAllowed=latest.eligibility === Allowed,
      )
    },
    onCardholderNameChange: name => dispatch(CardholderNameChanged(name)),
    markSubmitAttempted: () => dispatch(SubmitAttempted),
    reset: () => dispatch(Reset),
    clearField: field => dispatch(Cleared(field)),
    setSavedCard: saved => dispatch(SavedCardChanged(saved)),
    savedCard: () => {
      let (latest, _) = latestRef.current
      latest.savedCard
    },
    focusField: field =>
      switch field {
      | #cardNumber => focusRef(cardRef)
      | #cardExpiry => focusRef(expiryRef)
      | #cardCvc => focusRef(cvcRef)
      | #cardholderName => focusRef(cardholderRef)
      },
    register,
    countOf,
    registryVersion,
    cardRef,
    expiryRef,
    cvcRef,
    cardholderRef,
    safeState: _ => (),
  }
}
