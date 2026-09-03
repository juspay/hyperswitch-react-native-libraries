/*
 * The merchant-facing state vocabulary, and the pure derivation that produces it from the
 * controller.
 *
 * ── WHY THIS MODULE EXISTS AGAIN ───────────────────────────────────────────────────────────────
 *
 * ADR-0003 removed state emission. Its argument was not that the payload was unsafe — it says the
 * opposite, in as many words: "Both were designed to be card-safe, and both were." The argument was
 * that emission was "a standing obligation with no remaining consumer", because `submit()` already
 * answers "may I submit?" without a network call.
 *
 * ADR-0005 records the consumer that argument was missing: a merchant rendering their own chrome
 * needs per-field validity WHILE the customer types, not once at submit. `submit()` cannot answer
 * that — it is a single point-in-time verdict, and calling it to poll would mint tokens.
 *
 * What does NOT change is the boundary. Everything below is derived from state the controller
 * already holds; there is no second store, no subscription and no new retention.
 *
 * ── WHAT IS DELIBERATELY NOT HERE ──────────────────────────────────────────────────────────────
 *
 * No card value reaches these records. Not the PAN, not the formatted PAN, not its length, not a
 * BIN or last four, not the expiry month or year, not the CVC or its length, not the authorization,
 * the session id or a token.
 *
 * That last exclusion is where this deliberately parts company with VGS Collect, whose per-field
 * update carries `bin` and `last4`. VGS can publish those because it is a PCI-scoped vault with a
 * different threat model; this library's boundary names them as forbidden, and a merchant who holds
 * a BIN is a merchant whose logs now contain one. The SHAPE is borrowed — per-field state, an
 * aggregate, de-duplicated updates. The payload breadth is not.
 *
 * The only card-derived values published are the detected BRAND, which is a scheme name, and the
 * localised validation MESSAGE the customer can already read on screen.
 */

/* ── Brand ─────────────────────────────────────────────────────────────────────────────────── */

@genType
type cardBrand = [
  | #visa
  | #mastercard
  | #americanExpress
  | #dinersClub
  | #discover
  | #jcb
  | #cartesBancaires
  | #interac
  | #maestro
  | #unionPay
  | #rupay
  | #sodexo
  | #bajaj
  | #unknown
]

/*
 * The detector's `issuer` strings are not uniformly cased — `CardPattern.res` carries "Visa",
 * "AmericanExpress" but also "SODEXO" and "BAJAJ" — so this is a documented TABLE, not a mechanical
 * transform. A naive lowercase-first-character rule would emit `sODEXO`. Matching is
 * case-insensitive and trimmed because `Validation.getCardBrand` (used by the scan path) returns
 * upper case where the change path returns mixed case.
 *
 * An unrecognised or absent scheme is `#unknown`. This never throws and never passes the raw
 * detector string through the typed slot.
 */
let brandOf = (detected: string): cardBrand =>
  switch detected->String.trim->String.toLowerCase {
  | "visa" => #visa
  | "mastercard" => #mastercard
  | "americanexpress" => #americanExpress
  | "dinersclub" => #dinersClub
  | "discover" => #discover
  | "jcb" => #jcb
  | "cartesbancaires" => #cartesBancaires
  | "interac" => #interac
  | "maestro" => #maestro
  | "unionpay" => #unionPay
  | "rupay" => #rupay
  | "sodexo" => #sodexo
  | "bajaj" => #bajaj
  | _ => #unknown
  }

/* ── Field state ───────────────────────────────────────────────────────────────────────────── */

@genType
type vaultFieldStatus = [#empty | #incomplete | #complete]

@genType
type vaultFieldErrorCode = [
  | #required
  | #invalid_card_number
  | #invalid_expiry
  | #invalid_cvc
  | #unsupported_network
]

@genType
type vaultFieldError = {
  code: vaultFieldErrorCode,
  message: string,
}

/*
 * The eligibility verdict for the card currently typed. `#unknown` and `#pending` both mean "no
 * verdict yet" and are distinguished only so a merchant can avoid flashing chrome while a probe is
 * in flight. Only `#denied` blocks a payment, and it is NOT a validation failure: it is the
 * backend's verdict on a correctly-typed card, which is why it travels beside `error` and not
 * inside it.
 */
@genType
type vaultEligibilityStatus = [#unknown | #pending | #allowed | #denied]

/*
 * Narrowed records rather than one shape with optional members. The card number's `brand` is
 * REQUIRED and the other fields have no `brand` member at all, so a merchant cannot read one where
 * none exists. `public.ts` publishes their union under `VaultFieldState`.
 *
 * Every field carries the same four questions, which are genuinely different questions:
 *
 *   status   how far along is this field?            (#empty / #incomplete / #complete)
 *   valid    would it pass submission right now?     — the direct answer to "valid or invalid"
 *   touched  has the customer interacted with it?    — decides whether YOUR chrome should complain
 *   focused  is the cursor in it?
 *   error    what is the customer being shown NOW?   — already-filtered, never the raw verdict
 *
 * `valid` and `status === #complete` agree today. Both are published because they answer different
 * questions and a future rule (an optional field, say) could separate them; a merchant binding to
 * `valid` should not have to track that.
 */
@genType
type cardNumberState = {
  field: [#cardNumber],
  status: vaultFieldStatus,
  valid: bool,
  touched: bool,
  focused: bool,
  brand: cardBrand,
  /* Whether the customer is being offered a genuine choice of network for this PAN. */
  isCoBadged: bool,
  eligibility: vaultEligibilityStatus,
  error?: vaultFieldError,
}

@genType
type expiryState = {
  field: [#expiry],
  status: vaultFieldStatus,
  valid: bool,
  touched: bool,
  focused: bool,
  error?: vaultFieldError,
}

@genType
type cvcState = {
  field: [#cvc],
  status: vaultFieldStatus,
  valid: bool,
  touched: bool,
  focused: bool,
  error?: vaultFieldError,
}

@genType
type cardholderNameState = {
  field: [#cardholderName],
  status: vaultFieldStatus,
  valid: bool,
  touched: bool,
  focused: bool,
  error?: vaultFieldError,
}

/*
 * What the CONTROLLER hands upward. Not published: the host assembles `vaultFormFields` and
 * `vaultFormState` from it, because whether a cardholder-name field exists at all is a host-level
 * decision (`cardholderName: "collect"`) that the controller does not know.
 */
type controllerSnapshot = {
  cardNumber: cardNumberState,
  expiry: expiryState,
  cvc: cvcState,
  cardholderName: cardholderNameState,
  /*
   * A rejected co-badge pick. Form-level, not field-level: it belongs to no input the customer can
   * retype, so it has no slot on the card-number field.
   */
  networkError: option<vaultFieldError>,
  eligibility: vaultEligibilityStatus,
}

/* ── Form state ────────────────────────────────────────────────────────────────────────────── */

/*
 * `#absent` is not `#invalid`. A form mounted with no session at all is a legitimate Flow 3 form —
 * client-core mounts exactly that when the merchant profile says Skip — and reporting it as
 * `#invalid` would have merchants render a fault where there is none.
 */
@genType
type vaultSessionStatus = [#valid | #invalid | #absent]

@genType
type vaultFormFields = {
  cardNumber: cardNumberState,
  expiry: expiryState,
  cvc: cvcState,
  /* Present only when this form owns the field (`cardholderName: "collect"`). */
  cardholderName?: cardholderNameState,
}

@genType
type vaultFormState = {
  /*
   * FIELD REGISTRATION ONLY: exactly one card-number, one expiry and one CVC field is mounted.
   * Deliberately NOT named `ready` — a merchant reading `state.ready` reasonably assumes "ready to
   * submit", which is what `canSubmit` means. A member that needs a disclaimer to be read correctly
   * is misnamed.
   */
  fieldsReady: bool,
  sessionStatus: vaultSessionStatus,
  complete: bool,
  valid: bool,
  submitting: bool,
  canSubmit: bool,
  brand: cardBrand,
  isCoBadged: bool,
  eligibility: vaultEligibilityStatus,
  /*
   * Present when the network in force is not one the merchant accepts. Form-level because it
   * belongs to no input the customer can retype, and it is the reason `valid` and `canSubmit` are
   * false — without it a merchant sees a disabled button and cannot say why. This is the only
   * producer of `#unsupported_network`, which was declared but unreachable while the fault stayed
   * internal.
   *
   * NOTE the one deliberate asymmetry in this module: every field-level `error` answers "what is
   * the customer being shown NOW" and is filtered on `touched`. This one answers "why is the form
   * blocked", which is a different question and must be answerable before the customer has touched
   * anything — otherwise the merchant cannot explain their own disabled button. It is gated on the
   * card number being complete instead, so it is never premature.
   */
  networkError?: vaultFieldError,
  fields: vaultFormFields,
}

/* ── Derivation ────────────────────────────────────────────────────────────────────────────── */

/*
 * `empty` uses the SAME emptiness test the validators use (`String.length === 0`), so a field can
 * never be reported empty while the validator is rejecting it as malformed. A single space is
 * length 1: it is `incomplete`, not `empty`.
 *
 * `accepted` is the raw validator verdict, not the "paint it red" predicate. The two are different
 * questions and both are published: `status` answers "is this field done?", `error` answers "is the
 * customer currently being shown a problem?".
 */
let statusOf = (~value: string, ~accepted: bool) =>
  if value->String.length === 0 {
    #empty
  } else if accepted {
    #complete
  } else {
    #incomplete
  }

/*
 * The error CODE is read off the branch the validator actually took, not re-derived. Every one of
 * `makeCardNumberValidator`, `makeExpiryValidatorWith` and `makeCvcValidatorWith` tests
 * `String.length === 0` first and returns its `*Required` message, falling through to its
 * `*Invalid` message otherwise — so emptiness is exactly the required/invalid discriminator.
 *
 * `visible` is the controller's already-filtered error: the message the UI is currently rendering.
 * Passing the unfiltered validator result here would show a merchant a failure the customer cannot
 * see.
 */
let errorOf = (~value: string, ~visible: option<string>, ~invalidCode: vaultFieldErrorCode) =>
  visible->Option.map((message): vaultFieldError => {
    code: value->String.length === 0 ? #required : invalidCode,
    message,
  })

type fieldInputs = {
  value: string,
  accepted: bool,
  touched: bool,
  focused: bool,
  visibleError: option<string>,
}

let cardNumberStateOf = (
  inputs: fieldInputs,
  ~brand: string,
  ~isCoBadged: bool,
  ~eligibility: vaultEligibilityStatus,
): cardNumberState => {
  field: #cardNumber,
  status: statusOf(~value=inputs.value, ~accepted=inputs.accepted),
  valid: inputs.accepted && inputs.value->String.length > 0,
  touched: inputs.touched,
  focused: inputs.focused,
  brand: brandOf(brand),
  isCoBadged,
  eligibility,
  error: ?errorOf(
    ~value=inputs.value,
    ~visible=inputs.visibleError,
    ~invalidCode=#invalid_card_number,
  ),
}

let expiryStateOf = (inputs: fieldInputs): expiryState => {
  field: #expiry,
  status: statusOf(~value=inputs.value, ~accepted=inputs.accepted),
  valid: inputs.accepted && inputs.value->String.length > 0,
  touched: inputs.touched,
  focused: inputs.focused,
  error: ?errorOf(~value=inputs.value, ~visible=inputs.visibleError, ~invalidCode=#invalid_expiry),
}

let cvcStateOf = (inputs: fieldInputs): cvcState => {
  field: #cvc,
  status: statusOf(~value=inputs.value, ~accepted=inputs.accepted),
  valid: inputs.accepted && inputs.value->String.length > 0,
  touched: inputs.touched,
  focused: inputs.focused,
  error: ?errorOf(~value=inputs.value, ~visible=inputs.visibleError, ~invalidCode=#invalid_cvc),
}

/*
 * The cardholder name has no validator of its own in this library, so it is never `#incomplete`:
 * any non-empty value is complete. It is published for focus/typing chrome, not for a verdict the
 * library does not form.
 */
let cardholderNameStateOf = (inputs: fieldInputs): cardholderNameState => {
  field: #cardholderName,
  status: inputs.value->String.length === 0 ? #empty : #complete,
  /*
   * ALWAYS true, including when empty. `valid` is published as "would this field pass submission
   * right now", and the cardholder name is optional — `localGate` never inspects it and an empty
   * one is simply omitted from the request. Reporting `false` for empty would contradict the
   * documented meaning and, worse, permanently disable the Pay button of any merchant who ANDs the
   * four field `valid` flags. `status` still distinguishes `#empty` from `#complete` for chrome
   * that wants to know whether anything was typed.
   */
  valid: true,
  touched: inputs.touched,
  focused: inputs.focused,
  error: ?errorOf(~value=inputs.value, ~visible=inputs.visibleError, ~invalidCode=#required),
}

let formStateOf = (
  ~fieldsReady: bool,
  ~sessionStatus: vaultSessionStatus,
  ~submitting: bool,
  ~brand: string,
  ~isCoBadged: bool,
  ~eligibility: vaultEligibilityStatus,
  ~networkError: option<vaultFieldError>,
  ~fields: vaultFormFields,
): vaultFormState => {
  let complete =
    fields.cardNumber.status === #complete &&
    fields.expiry.status === #complete &&
    fields.cvc.status === #complete
  /*
   * The network verdict is withheld until the NUMBER itself is well-formed.
   *
   * Detection fires on the first digit — `4` alone resolves to Visa — so a merchant who accepts
   * only Mastercard and renders `networkError` would print "card not supported" on keystroke one,
   * while the library's own chrome stayed silent (it filters on `networkMeta.touched`). Gating on
   * the card number's own completeness is the honest threshold: before that the match set is still
   * narrowing and the verdict is about a card nobody has finished typing.
   *
   * `valid` is unchanged by this. It already requires `complete`, which implies the number is
   * complete, so on every input where `valid` could have been true the gate is transparent — and
   * `valid` stays exactly `CardStateReducer.isValid`, which is what makes `canSubmit` agree with
   * the submit gate.
   */
  let networkFault = fields.cardNumber.status === #complete ? networkError : None
  let valid = complete && networkFault->Option.isNone
  {
    fieldsReady,
    sessionStatus,
    complete,
    valid,
    submitting,
    /*
     * The one member that answers "can I submit right now?". It consults every gate, so a merchant
     * binding a Pay button to it cannot be wrong; the individual members exist so they can explain
     * WHY it is false.
     *
     * `#absent` passes: a sessionless form is a valid direct-confirmation form. Eligibility does
     * NOT gate it — a denial is enforced by the coordinator, which answers `card_not_eligible`, and
     * folding it in here would leave a merchant unable to distinguish "still typing" from "this
     * card was refused".
     */
    canSubmit: fieldsReady && sessionStatus !== #invalid && valid && !submitting,
    brand: brandOf(brand),
    isCoBadged,
    eligibility,
    networkError: ?networkFault,
    fields,
  }
}

/* ── Structural equality, for emission de-duplication ──────────────────────────────────────── */

/*
 * Field-by-field comparison. NOT JSON.stringify: that allocates two strings on every render, is
 * sensitive to key order, and would silently start comparing anything new that gets added. These
 * functions stop compiling if a member is added and not handled.
 */
let errorEq = (a: option<vaultFieldError>, b: option<vaultFieldError>) =>
  switch (a, b) {
  | (None, None) => true
  | (Some(x), Some(y)) => x.code === y.code && x.message === y.message
  | _ => false
  }

let cardNumberEq = (a: cardNumberState, b: cardNumberState) =>
  a.status === b.status &&
  a.valid === b.valid &&
  a.touched === b.touched &&
  a.focused === b.focused &&
  a.brand === b.brand &&
  a.isCoBadged === b.isCoBadged &&
  a.eligibility === b.eligibility &&
  errorEq(a.error, b.error)

let expiryEq = (a: expiryState, b: expiryState) =>
  a.status === b.status &&
  a.valid === b.valid &&
  a.touched === b.touched &&
  a.focused === b.focused &&
  errorEq(a.error, b.error)

let cvcEq = (a: cvcState, b: cvcState) =>
  a.status === b.status &&
  a.valid === b.valid &&
  a.touched === b.touched &&
  a.focused === b.focused &&
  errorEq(a.error, b.error)

let cardholderNameEq = (a: cardholderNameState, b: cardholderNameState) =>
  a.status === b.status &&
  a.valid === b.valid &&
  a.touched === b.touched &&
  a.focused === b.focused &&
  errorEq(a.error, b.error)

let optionalCardholderEq = (
  a: option<cardholderNameState>,
  b: option<cardholderNameState>,
) =>
  switch (a, b) {
  | (None, None) => true
  | (Some(x), Some(y)) => cardholderNameEq(x, y)
  | _ => false
  }

let fieldsEq = (a: vaultFormFields, b: vaultFormFields) =>
  cardNumberEq(a.cardNumber, b.cardNumber) &&
  expiryEq(a.expiry, b.expiry) &&
  cvcEq(a.cvc, b.cvc) &&
  optionalCardholderEq(a.cardholderName, b.cardholderName)

let formEq = (a: vaultFormState, b: vaultFormState) =>
  a.fieldsReady === b.fieldsReady &&
  a.sessionStatus === b.sessionStatus &&
  a.complete === b.complete &&
  a.valid === b.valid &&
  a.submitting === b.submitting &&
  a.canSubmit === b.canSubmit &&
  a.brand === b.brand &&
  a.isCoBadged === b.isCoBadged &&
  a.eligibility === b.eligibility &&
  errorEq(a.networkError, b.networkError) &&
  fieldsEq(a.fields, b.fields)
