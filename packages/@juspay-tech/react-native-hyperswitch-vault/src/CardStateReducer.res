type field = [#cardNumber | #cardExpiry | #cardCvc | #cardholderName | #network]

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

/*
 * A card the merchant has ALREADY saved, whose CVC is being re-collected. Present exactly when the
 * CVC field was mounted with `savedCard`. The token names the card on the wire; the network — already
 * canonicalised, or "" for "unknown, accept three or four digits" — selects the CVC length rule.
 */
type savedCard = {token: string, network: string}

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
  savedCard: option<savedCard>,
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
  savedCard: None,
}

type action =
  | NumberChanged(CardFieldLogic.numberChange)
  | ExpiryChanged(CardFieldLogic.expiryChange)
  | CvcChanged(CardFieldLogic.cvcChange)
  | CardholderNameChanged(string)
  | NetworkSelected(string)
  | EligibilityChanged(eligibility)
  | SavedCardChanged(option<savedCard>)
  | Focused(field)
  | Blurred(field)
  /* One field's value and interaction state, back to mount — the field handle's `clear()`. */
  | Cleared(field)
  | SubmitAttempted
  | Reset

/*
 * The network actually used for CVC length rules, the brand icon and the wire. A saved card's
 * network is the merchant's hint; otherwise the customer's pick when they made one that the
 * current number still supports, the detected brand otherwise.
 *
 * The containment check is what makes re-typing safe: pick RuPay on a co-badged card, then edit the
 * number to a Visa-only PAN, and the stale pick is dropped rather than sent.
 */
let effectiveNetwork = (state: state) =>
  switch state.savedCard {
  | Some(saved) => saved.network
  | None =>
    switch state.selectedNetwork {
    | "" => state.brand
    | picked =>
      state.matchedSchemes->Array.some(scheme => scheme === picked) ? picked : state.brand
    }
  }

/*
 * Co-badge is OFFERED only when the number matches more than one scheme AND enough of it has been
 * typed to be sure of that. 16 digits reproduces client-core's threshold exactly; below it the
 * match set is still narrowing and a dropdown would appear and vanish as the customer types.
 */
let coBadgeThreshold = 16

let isCoBadged = (state: state) =>
  state.savedCard->Option.isNone &&
  state.matchedSchemes->Array.length > 1 &&
  state.cardNumber->Validation.clearSpaces->String.length >= coBadgeThreshold

let withMeta = (state, field, update) =>
  switch field {
  | #cardNumber => {...state, numberMeta: update(state.numberMeta)}
  | #cardExpiry => {...state, expiryMeta: update(state.expiryMeta)}
  | #cardCvc => {...state, cvcMeta: update(state.cvcMeta)}
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
  /*
   * A different saved card is a different request: the CVC typed for the previous one is dropped,
   * exactly as the standalone saved-card form did when its token changed.
   */
  | SavedCardChanged(saved) =>
    let sameCard = switch (state.savedCard, saved) {
    | (None, None) => true
    | (Some(a), Some(b)) => a.token === b.token
    | _ => false
    }
    switch (state.savedCard, saved) {
    | (None, None) => state
    | _ =>
      sameCard
        ? {...state, savedCard: saved}
        : {...state, savedCard: saved, cvc: "", cvcMeta: untouched, cardVersion: state.cardVersion + 1}
    }
  | Focused(field) => state->withMeta(field, meta => {...meta, active: true})
  | Blurred(field) => state->withMeta(field, _ => {touched: true, active: false})
  | Cleared(field) =>
    switch field {
    | #cardNumber => {
        ...state,
        cardNumber: "",
        brand: "",
        matchedSchemes: [],
        selectedNetwork: "",
        eligibility: Unknown,
        numberMeta: untouched,
        cardVersion: state.cardVersion + 1,
      }
    | #cardExpiry => {
        ...state,
        expiryDisplay: "",
        expiryMonth: "",
        expiryYear: "",
        expiryMeta: untouched,
        cardVersion: state.cardVersion + 1,
      }
    | #cardCvc => {...state, cvc: "", cvcMeta: untouched, cardVersion: state.cardVersion + 1}
    | #cardholderName => {
        ...state,
        cardholderName: "",
        cardholderMeta: untouched,
        cardVersion: state.cardVersion + 1,
      }
    | #network => {...state, selectedNetwork: "", networkMeta: untouched}
    }
  | SubmitAttempted => {
      ...state,
      submitAttempted: true,
      numberMeta: {...state.numberMeta, touched: true},
      expiryMeta: {...state.expiryMeta, touched: true},
      cvcMeta: {...state.cvcMeta, touched: true},
      cardholderMeta: {...state.cardholderMeta, touched: true},
      networkMeta: {...state.networkMeta, touched: true},
    }
  /* Reset counts as a card-value change: a minted token must not survive it. The saved card stays: it is a prop. */
  | Reset => {...initial, savedCard: state.savedCard, cardVersion: state.cardVersion + 1}
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

/*
 * In saved-card mode only the CVC is collected, so only the CVC is judged: the number and expiry
 * belong to a card the merchant already holds, and a rule that demanded them would block a form
 * that cannot show them.
 */
let errorsFor = (state: state, ~validators: validators): errors => {
  let savedMode = state.savedCard->Option.isSome
  {
    cardNumber: savedMode ? None : validators.cardNumber(Some(state.cardNumber)),
    expiry: savedMode ? None : validators.expiry(state.expiryDisplay)(Some(state.expiryYear)),
    /* CVC length depends on the network in force, so a co-badge pick changes this rule. */
    cvc: validators.cvc(state->effectiveNetwork)(Some(state.cvc)),
    network: savedMode
      ? None
      : validators.network->Option.flatMap(validate => validate(Some(state->effectiveNetwork))),
    eligibility: switch state.eligibility {
    | Denied => validators.notEligible
    | Unknown
    | Pending
    | Allowed => None
    },
  }
}

/*
 * `eligibility` is deliberately NOT part of validity.
 *
 * Validity means "the values are well-formed" — something the customer can fix by typing. An
 * eligibility denial is the backend's verdict on a correctly-typed card, and folding it in here
 * would report it as a validation failure, telling the customer to check details that are already
 * correct. It is enforced instead by the coordinator's own gate, which answers `card_not_eligible`.
 *
 * The message still renders: the denial is worth showing, it just is not a field error.
 */
let isValid = (errors: errors) =>
  errors.cardNumber->Option.isNone &&
  errors.expiry->Option.isNone &&
  errors.cvc->Option.isNone &&
  errors.network->Option.isNone

/*
 * ── ONE TIMING RULE FOR EVERY FIELD ──────────────────────────────────────────────────────────
 *
 * A message is shown, and a box is tinted, once the customer has LEFT the field with a problem in
 * it, and neither is shown while the cursor is back inside it. This is the rule hyperswitch-web's
 * separate card fields apply to all three inputs (focus resets validity; blur re-judges), and it
 * is the rule the CVC always had here.
 *
 * It used to differ per field, reproducing client-core's original element: the number and the
 * expiry kept their message while refocused, and a complete but invalid expiry stayed tinted while
 * the customer was correcting it. Because the same functions feed the merchant's `change` event,
 * that per-field difference was a difference in the public contract, and merchants drawing their
 * own chrome from `error` got a stuck red number box next to a CVC box that cleared. One rule ends
 * that.
 */
let shownFor = (meta: fieldMeta, error: option<string>) =>
  meta.touched && !meta.active ? error : None

let okFor = (meta: fieldMeta, error: option<string>) =>
  error->Option.isNone || !meta.touched || meta.active

let numberError = (state, errors: errors) => shownFor(state.numberMeta, errors.cardNumber)
let expiryError = (state, errors: errors) => shownFor(state.expiryMeta, errors.expiry)
let cvcError = (state, errors: errors) => shownFor(state.cvcMeta, errors.cvc)

/* The network chooser is not a text field; its message waits only on the pick having been made. */
let networkError = (state, errors: errors) =>
  state.networkMeta.touched ? errors.network : None

/*
 * Unconditional: a denial is a fact about the card that has already been reported, not a
 * consequence of the customer having visited a field, so it does not wait on a `touched` flag.
 * That reproduces client-core, where the eligibility message renders straight off
 * `eligibilityStatus` with no meta check.
 */
let eligibilityError = (_state, errors: errors) => errors.eligibility

let numberFieldOk = (state, errors: errors) => okFor(state.numberMeta, errors.cardNumber)
let expiryFieldOk = (state, errors: errors) => okFor(state.expiryMeta, errors.expiry)
let cvcFieldOk = (state, errors: errors) => okFor(state.cvcMeta, errors.cvc)
