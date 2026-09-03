type field = [#cardNumber | #expiry | #cvc | #cardholderName | #network]

type fieldMeta = {touched: bool, active: bool}

let untouched = {touched: false, active: false}

/*
 * The eligibility verdict for the card CURRENTLY typed, and how far the probe has got.
 *
 * `Unknown` and `Pending` both mean "no verdict yet"; they are distinguished only so the form can
 * avoid flashing an error while a request is in flight. Only `Denied` blocks anything.
 */
type eligibility =
  | Unknown
  | Pending
  | Allowed
  | Denied

type state = {
  cardNumber: string,
  expiryDisplay: string,
  expiryMonth: string,
  expiryYear: string,
  cvc: string,
  cardholderName: string,
  /* The first scheme the PAN matches. Detected, never chosen. */
  brand: string,
  matchedSchemes: array<string>,
  /*
   * The customer's EXPLICIT network pick on a co-badged card, or "" when they have not made one.
   * Kept apart from `brand` so that re-typing the number cannot silently preserve a choice made
   * about a different card.
   */
  selectedNetwork: string,
  eligibility: eligibility,
  numberMeta: fieldMeta,
  expiryMeta: fieldMeta,
  cvcMeta: fieldMeta,
  cardholderMeta: fieldMeta,
  networkMeta: fieldMeta,
  submitAttempted: bool,
  /*
   * Monotonic counter over CARD-VALUE changes only — focus, blur and submit attempts do not bump
   * it. The coordinator uses it to invalidate a payment-method token it already minted: a token
   * describes the card that was typed when it was minted, so if any card value has changed since,
   * reusing it would confirm a payment against the wrong card. Comparing this integer avoids
   * keeping any card-derived fingerprint around to answer the same question.
   */
  cardVersion: int,
}

let initial = {
  cardNumber: "",
  expiryDisplay: "",
  expiryMonth: "",
  expiryYear: "",
  cvc: "",
  cardholderName: "",
  brand: "",
  matchedSchemes: [],
  selectedNetwork: "",
  eligibility: Unknown,
  numberMeta: untouched,
  expiryMeta: untouched,
  cvcMeta: untouched,
  cardholderMeta: untouched,
  networkMeta: untouched,
  submitAttempted: false,
  cardVersion: 0,
}

type action =
  | NumberChanged(CardFieldLogic.numberChange)
  | ExpiryChanged(CardFieldLogic.expiryChange)
  | CvcChanged(CardFieldLogic.cvcChange)
  | CardholderNameChanged(string)
  | NetworkSelected(string)
  | EligibilityChanged(eligibility)
  | Focused(field)
  | Blurred(field)
  | SubmitAttempted
  | Reset

/*
 * The network actually used for CVC length rules, the brand icon and the wire — the customer's
 * pick when they made one that the current number still supports, the detected brand otherwise.
 *
 * The containment check is what makes re-typing safe: pick RuPay on a co-badged card, then edit the
 * number to a Visa-only PAN, and the stale pick is dropped rather than sent.
 */
let effectiveNetwork = (state: state) =>
  switch state.selectedNetwork {
  | "" => state.brand
  | picked =>
    state.matchedSchemes->Array.some(scheme => scheme === picked) ? picked : state.brand
  }

/*
 * Co-badge is OFFERED only when the number matches more than one scheme AND enough of it has been
 * typed to be sure of that. 16 digits reproduces client-core's threshold exactly; below it the
 * match set is still narrowing and a dropdown would appear and vanish as the customer types.
 */
let coBadgeThreshold = 16

let isCoBadged = (state: state) =>
  state.matchedSchemes->Array.length > 1 &&
    state.cardNumber->Validation.clearSpaces->String.length >= coBadgeThreshold

let withMeta = (state, field, update) =>
  switch field {
  | #cardNumber => {...state, numberMeta: update(state.numberMeta)}
  | #expiry => {...state, expiryMeta: update(state.expiryMeta)}
  | #cvc => {...state, cvcMeta: update(state.cvcMeta)}
  | #cardholderName => {...state, cardholderMeta: update(state.cardholderMeta)}
  | #network => {...state, networkMeta: update(state.networkMeta)}
  }

let reduce = (state: state, action: action): state =>
  switch action {
  | NumberChanged(change) =>
    let cleared = change.clearDependents
    {
      ...state,
      cardNumber: change.formatted,
      brand: change.brand,
      matchedSchemes: change.matchedSchemes,
      /* A pick belongs to the number it was made about; a changed number retires it. */
      selectedNetwork: change.matchedSchemes->Array.some(scheme => scheme === state.selectedNetwork)
        ? state.selectedNetwork
        : "",
      /* Any verdict on the wire is about the previous number. */
      eligibility: Unknown,
      expiryDisplay: cleared ? "" : state.expiryDisplay,
      expiryMonth: cleared ? "" : state.expiryMonth,
      expiryYear: cleared ? "" : state.expiryYear,
      cvc: cleared ? "" : state.cvc,
      cardVersion: state.cardVersion + 1,
    }
  | ExpiryChanged(change) => {
      ...state,
      expiryDisplay: change.display,
      expiryMonth: change.month,
      expiryYear: change.year,
      cardVersion: state.cardVersion + 1,
    }
  | CvcChanged(change) => {...state, cvc: change.formatted, cardVersion: state.cardVersion + 1}
  | CardholderNameChanged(name) => {
      ...state,
      cardholderName: name,
      cardVersion: state.cardVersion + 1,
    }
  /*
   * A network pick bumps `cardVersion`: it changes what would be sent, so a token minted before it
   * no longer describes the request. Marking the field touched is what lets its validator's message
   * appear, exactly as blurring any other field does.
   */
  | NetworkSelected(network) => {
      ...state,
      selectedNetwork: network,
      networkMeta: {...state.networkMeta, touched: true},
      cardVersion: state.cardVersion + 1,
    }
  /* Not a card-value change: the verdict is ABOUT the current values, so it must not retire them. */
  | EligibilityChanged(verdict) => {...state, eligibility: verdict}
  | Focused(field) => state->withMeta(field, meta => {...meta, active: true})
  | Blurred(field) => state->withMeta(field, meta => {touched: true, active: false})
  | SubmitAttempted => {
      ...state,
      submitAttempted: true,
      numberMeta: {...state.numberMeta, touched: true},
      expiryMeta: {...state.expiryMeta, touched: true},
      cvcMeta: {...state.cvcMeta, touched: true},
      cardholderMeta: {...state.cardholderMeta, touched: true},
      networkMeta: {...state.networkMeta, touched: true},
    }
  /* Reset counts as a card-value change: a minted token must not survive it. */
  | Reset => {...initial, cardVersion: state.cardVersion + 1}
  }

type validators = {
  cardNumber: option<string> => option<string>,
  expiry: string => option<string> => option<string>,
  cvc: string => option<string> => option<string>,
  network: option<option<string> => option<string>>,
  /* Shown when the backend denies this BIN. `None` when the merchant has no eligibility step. */
  notEligible: option<string>,
}

type errors = {
  cardNumber: option<string>,
  expiry: option<string>,
  cvc: option<string>,
  network: option<string>,
  eligibility: option<string>,
}

let errorsFor = (state: state, ~validators: validators): errors => {
  cardNumber: validators.cardNumber(Some(state.cardNumber)),
  expiry: validators.expiry(state.expiryDisplay)(Some(state.expiryYear)),
  /* CVC length depends on the network in force, so a co-badge pick changes this rule. */
  cvc: validators.cvc(state->effectiveNetwork)(Some(state.cvc)),
  network: validators.network->Option.flatMap(validate =>
    validate(Some(state->effectiveNetwork))
  ),
  eligibility: switch state.eligibility {
  | Denied => validators.notEligible
  | Unknown
  | Pending
  | Allowed => None
  },
}

/*
 * `eligibility` is deliberately NOT part of validity.
 *
 * Validity means "the values are well-formed" — something the customer can fix by typing. An
 * eligibility denial is the backend's verdict on a correctly-typed card, and folding it in here
 * would report it as `validation_error`, telling the customer to check details that are already
 * correct. It is enforced instead by the coordinator's own gate, which answers `card_not_eligible`.
 *
 * The message still renders: the denial is worth showing, it just is not a field error.
 */
let isValid = (errors: errors) =>
  errors.cardNumber->Option.isNone &&
  errors.expiry->Option.isNone &&
  errors.cvc->Option.isNone &&
  errors.network->Option.isNone

let numberError = (state, errors: errors) =>
  switch (errors.cardNumber, state.numberMeta.touched) {
  | (Some(message), true) => Some(message)
  | _ => None
  }

let expiryError = (state, errors: errors) =>
  switch (
    errors.expiry,
    (state.expiryDisplay->String.length > 0 || !state.expiryMeta.touched) &&
      (state.expiryDisplay->String.length < 7 || Validation.checkCardExpiry(state.expiryDisplay)),
  ) {
  | (Some(message), false) => Some(message)
  | _ => None
  }

let cvcError = (state, errors: errors) =>
  switch (errors.cvc, state.cvcMeta.touched, state.cvcMeta.active) {
  | (Some(message), true, false) => Some(message)
  | _ => None
  }

let networkError = (state, errors: errors) =>
  switch (errors.network, state.networkMeta.touched) {
  | (Some(message), true) => Some(message)
  | _ => None
  }

/*
 * Unconditional: a denial is a fact about the card that has already been reported, not a
 * consequence of the customer having visited a field, so it does not wait on a `touched` flag.
 * That reproduces client-core, where the eligibility message renders straight off
 * `eligibilityStatus` with no meta check.
 */
let eligibilityError = (_state, errors: errors) => errors.eligibility

let numberFieldOk = (state, errors: errors) =>
  errors.cardNumber->Option.isNone || !state.numberMeta.touched || state.numberMeta.active

let expiryFieldOk = (state, errors: errors) =>
  ((errors.expiry->Option.isNone || !state.expiryMeta.touched || state.expiryMeta.active) &&
    state.expiryDisplay->String.length < 7) ||
    (state.expiryDisplay->String.length === 7 && Validation.checkCardExpiry(state.expiryDisplay))

let cvcFieldOk = (state, errors: errors) =>
  errors.cvc->Option.isNone || !state.cvcMeta.touched || state.cvcMeta.active
