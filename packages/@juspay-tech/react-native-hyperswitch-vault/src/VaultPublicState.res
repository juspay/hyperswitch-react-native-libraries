/*
 * The merchant-facing event vocabulary, and the pure derivation that produces it from the
 * controller.
 *
 * ── THE SAME NAMES AS HYPERSWITCH-WEB ──────────────────────────────────────────────────────────
 *
 * A merchant integrating the web SDK's separate card fields and this library should meet one
 * vocabulary. Every field is `cardNumber` / `cardExpiry` / `cardCvc`; every per-field event is
 * `ready` / `focus` / `blur` / `change`; the `change` payload carries the web's `empty`, `complete`,
 * `valid`, `brand` and `error` under the web's names; and the form-level `change` carries the web's
 * `cardDetailsChange` envelope — `{elementType: 'cardForm', eventName: 'cardDetailsChange',
 * payload}` — with `payload` built by the SAME sdk-utils function the web uses
 * (`PaymentEventData.buildCardInfo`), so the two SDKs cannot disagree about a card's BIN, last four
 * or expiry parts.
 *
 * What this library adds on top is additive and named so it cannot collide: `touched`, `errorCode`,
 * `isCoBadged`, `eligibility` on a field; `fieldsReady`, `sessionStatus`, `canSubmit`,
 * `submitting`, `networkError` and `fields` on the form. Nothing here carries a PAN, a CVC, a
 * token or a credential.
 */

/* ── Identity ──────────────────────────────────────────────────────────────────────────────── */

@genType
type elementType = [#cardNumber | #cardExpiry | #cardCvc | #cardholderName]

/*
 * The detector's issuer names, exactly as `Validation.cardPatterns[].issuer` spells them and exactly
 * as the web SDK's `change.brand` carries them. Absent — never "unknown" — when nothing matched,
 * which is also the web's behaviour.
 */
@genType
type cardBrand = [
  | #Visa
  | #Mastercard
  | #AmericanExpress
  | #DinersClub
  | #Discover
  | #JCB
  | #CartesBancaires
  | #Interac
  | #Maestro
  | #UnionPay
  | #RuPay
  | #SODEXO
  | #BAJAJ
]

let brandOf = (detected: string): option<cardBrand> =>
  switch CardNetworkNames.normalise(detected) {
  | Some("Visa") => Some(#Visa)
  | Some("Mastercard") => Some(#Mastercard)
  | Some("AmericanExpress") => Some(#AmericanExpress)
  | Some("DinersClub") => Some(#DinersClub)
  | Some("Discover") => Some(#Discover)
  | Some("JCB") => Some(#JCB)
  | Some("CartesBancaires") => Some(#CartesBancaires)
  | Some("Interac") => Some(#Interac)
  | Some("Maestro") => Some(#Maestro)
  | Some("UnionPay") => Some(#UnionPay)
  | Some("RuPay") => Some(#RuPay)
  | Some("SODEXO") => Some(#SODEXO)
  | Some("BAJAJ") => Some(#BAJAJ)
  | _ => None
  }

/* ── Field events ──────────────────────────────────────────────────────────────────────────── */

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

/* `ready`, `focus` and `blur`: the web's payload minus its iframe id, which has no meaning here. */
@genType
type fieldEvent = {elementType: elementType}

/*
 * `change`. The first five members are the web's, with the web's meaning:
 *
 *   empty     nothing typed
 *   complete  the value passes validation (identical to `valid`, as on the web)
 *   valid     the value passes validation
 *   brand     the detected network, when one is
 *   error     the message the customer is being shown NOW — already filtered on touched/focused
 *
 * The rest only this library can answer.
 */
@genType
type fieldChange = {
  elementType: elementType,
  empty: bool,
  complete: bool,
  valid: bool,
  brand?: cardBrand,
  error?: string,
  /* Which rule `error` came from. */
  errorCode?: vaultFieldErrorCode,
  /* Has the customer left this field at least once? Decides whether YOUR chrome should complain. */
  touched: bool,
  /* Card number only: the customer is being offered a genuine choice of network for this PAN. */
  isCoBadged?: bool,
  /* Card number only, `./host` only: the backend eligibility verdict. */
  eligibility?: vaultEligibilityStatus,
}

/* ── Form events ───────────────────────────────────────────────────────────────────────────── */

/*
 * `#absent` is not `#invalid`. A form mounted with no session at all is a legitimate Flow 3 form —
 * client-core mounts exactly that when the merchant profile says Skip — and reporting it as
 * `#invalid` would have merchants render a fault where there is none. `#expired` and `#consumed`
 * are the two lifecycle states the web SDK reports; `tokenize()` refuses in both.
 */
@genType
type vaultSessionStatus = [#valid | #invalid | #absent | #expired | #consumed]

@genType
type vaultFormFields = {
  cardNumber: fieldChange,
  cardExpiry: fieldChange,
  cardCvc: fieldChange,
  /* Present only when a cardholder-name field is mounted. */
  cardholderName?: fieldChange,
}

/*
 * The web's `cardDetailsChange` payload, member for member and null for null. Built by
 * `PaymentEventData.buildCardInfo` from sdk-utils — the function the web SDK calls — so a BIN is
 * the first six digits once six are typed, the last four appear once the number is complete, and
 * the expiry parts appear as they are recognised.
 */
@genType
type cardDetails = {
  bin: Js.Nullable.t<string>,
  last4: Js.Nullable.t<string>,
  brand: Js.Nullable.t<string>,
  expiryMonth: Js.Nullable.t<string>,
  expiryYear: Js.Nullable.t<string>,
  formattedExpiry: Js.Nullable.t<string>,
  isCardNumberComplete: bool,
  isCvcComplete: bool,
  isExpiryComplete: bool,
  isCardNumberValid: bool,
  isExpiryValid: bool,
}

/* `null` for an absent value, never `undefined`: byte-for-byte what the web's `cardInfoToJson` emits. */
let nullable = (value: option<string>): Js.Nullable.t<string> =>
  switch value {
  | Some(text) => Js.Nullable.return(text)
  | None => Js.Nullable.null
  }

let cardDetailsOf = (info: PaymentEventData.cardInfo): cardDetails => {
  bin: info.bin->nullable,
  last4: info.last4->nullable,
  brand: info.brand->nullable,
  expiryMonth: info.expiryMonth->nullable,
  expiryYear: info.expiryYear->nullable,
  formattedExpiry: info.formattedExpiry->nullable,
  isCardNumberComplete: info.isCardNumberComplete,
  isCvcComplete: info.isCvcComplete,
  isExpiryComplete: info.isExpiryComplete,
  isCardNumberValid: info.isCardNumberValid,
  isExpiryValid: info.isExpiryValid,
}

/* The form's `ready` event: every required field is mounted and complete. */
@genType
type cardFormEvent = {elementType: [#cardForm]}

/*
 * The form's `change` event. The envelope — `elementType`, `eventName`, `payload` — is the web's
 * `cardDetailsChange`; everything after it is this library's, so a merchant reading `e.payload.bin`
 * from web documentation reads the same thing here.
 */
@genType
type cardFormChange = {
  elementType: [#cardForm],
  eventName: [#cardDetailsChange],
  payload: cardDetails,
  /*
   * FIELD REGISTRATION ONLY: exactly one card-number, one expiry and one CVC field is mounted (or
   * one CVC field carrying a saved card). Deliberately NOT named `ready` — a merchant reading
   * `state.ready` reasonably assumes "ready to submit", which is what `canSubmit` means.
   */
  fieldsReady: bool,
  sessionStatus: vaultSessionStatus,
  complete: bool,
  valid: bool,
  submitting: bool,
  canSubmit: bool,
  isCoBadged: bool,
  eligibility: vaultEligibilityStatus,
  /*
   * Present when the network in force is not one the merchant accepts. Form-level because it
   * belongs to no input the customer can retype, and it is the reason `valid` and `canSubmit` are
   * false — without it a merchant sees a disabled button and cannot say why. Gated on the card
   * number being complete, so it is never premature.
   */
  networkError?: vaultFieldError,
  fields: vaultFormFields,
}

/* What the CONTROLLER hands upward. Not published. */
type controllerSnapshot = {
  cardNumber: fieldChange,
  cardExpiry: fieldChange,
  cardCvc: fieldChange,
  cardholderName: fieldChange,
  networkError: option<vaultFieldError>,
  eligibility: vaultEligibilityStatus,
  cardDetails: cardDetails,
}

/* ── Derivation ────────────────────────────────────────────────────────────────────────────── */

type fieldInputs = {
  value: string,
  /* The RAW validator verdict. */
  accepted: bool,
  touched: bool,
  /* The already-filtered message the UI is rendering. */
  visibleError: option<string>,
  invalidCode: vaultFieldErrorCode,
}

/*
 * The error CODE is read off the branch the validator actually took, not re-derived. Every
 * validator tests `String.length === 0` first and returns its `*Required` message, falling through
 * to its `*Invalid` message otherwise — so emptiness is exactly the required/invalid discriminator.
 */
let fieldChangeOf = (
  inputs: fieldInputs,
  ~elementType: elementType,
  ~brand: option<cardBrand>=None,
  ~isCoBadged: option<bool>=None,
  ~eligibility: option<vaultEligibilityStatus>=None,
): fieldChange => {
  let empty = inputs.value->String.length === 0
  let valid = inputs.accepted && !empty
  {
    elementType,
    empty,
    complete: valid,
    valid,
    brand: ?brand,
    error: ?inputs.visibleError,
    errorCode: ?inputs.visibleError->Option.map(_ => empty ? #required : inputs.invalidCode),
    touched: inputs.touched,
    isCoBadged: ?isCoBadged,
    eligibility: ?eligibility,
  }
}

/*
 * The cardholder name has no validator of its own in this library: any non-empty value is
 * complete, and it is ALWAYS valid, including when empty — the field is optional, the submit gate
 * never inspects it, and an empty one is simply omitted from the request. Reporting `false` for
 * empty would permanently disable the Pay button of any merchant who ANDs the field `valid` flags.
 */
let cardholderNameChangeOf = (~value: string, ~touched: bool): fieldChange => {
  let empty = value->String.length === 0
  {elementType: #cardholderName, empty, complete: !empty, valid: true, touched}
}

let formChangeOf = (
  ~fieldsReady: bool,
  ~sessionStatus: vaultSessionStatus,
  ~submitting: bool,
  ~isCoBadged: bool,
  ~eligibility: vaultEligibilityStatus,
  ~networkError: option<vaultFieldError>,
  ~payload: cardDetails,
  ~fields: vaultFormFields,
  /* In saved-card mode only the CVC is collected, so only the CVC decides completeness. */
  ~savedCardMode: bool,
): cardFormChange => {
  let complete = savedCardMode
    ? fields.cardCvc.complete
    : fields.cardNumber.complete && fields.cardExpiry.complete && fields.cardCvc.complete
  /*
   * The network verdict is withheld until the NUMBER itself is well-formed: detection fires on the
   * first digit, and a merchant who accepts only Mastercard would otherwise see "card not supported"
   * on keystroke one.
   */
  let networkFault = fields.cardNumber.complete ? networkError : None
  let valid = complete && networkFault->Option.isNone
  let sessionUsable = switch sessionStatus {
  | #valid | #absent => true
  | #invalid | #expired | #consumed => false
  }
  {
    elementType: #cardForm,
    eventName: #cardDetailsChange,
    payload,
    fieldsReady,
    sessionStatus,
    complete,
    valid,
    submitting,
    /*
     * The one member that answers "can I submit right now?". It consults every gate, so a merchant
     * binding a Pay button to it cannot be wrong; the individual members exist so they can explain
     * WHY it is false. `#absent` passes: a sessionless form is a valid direct-confirmation form.
     * Eligibility does NOT gate it — a denial is enforced by the coordinator, which answers
     * `card_not_eligible`.
     */
    canSubmit: fieldsReady && sessionUsable && valid && !submitting,
    isCoBadged,
    eligibility,
    networkError: ?networkFault,
    fields,
  }
}

/* ── Structural equality, for emission de-duplication ──────────────────────────────────────── */

let errorEq = (a: option<vaultFieldError>, b: option<vaultFieldError>) =>
  switch (a, b) {
  | (None, None) => true
  | (Some(x), Some(y)) => x.code === y.code && x.message === y.message
  | _ => false
  }

let fieldChangeEq = (a: fieldChange, b: fieldChange) =>
  a.elementType === b.elementType &&
  a.empty === b.empty &&
  a.complete === b.complete &&
  a.valid === b.valid &&
  a.brand === b.brand &&
  a.error === b.error &&
  a.errorCode === b.errorCode &&
  a.touched === b.touched &&
  a.isCoBadged === b.isCoBadged &&
  a.eligibility === b.eligibility

let optionalFieldEq = (a: option<fieldChange>, b: option<fieldChange>) =>
  switch (a, b) {
  | (None, None) => true
  | (Some(x), Some(y)) => fieldChangeEq(x, y)
  | _ => false
  }

let fieldsEq = (a: vaultFormFields, b: vaultFormFields) =>
  fieldChangeEq(a.cardNumber, b.cardNumber) &&
  fieldChangeEq(a.cardExpiry, b.cardExpiry) &&
  fieldChangeEq(a.cardCvc, b.cardCvc) &&
  optionalFieldEq(a.cardholderName, b.cardholderName)

/* Records of strings, nulls and bools: structural equality is exact here. */
let cardDetailsEq = (a: cardDetails, b: cardDetails) => a == b

let formChangeEq = (a: cardFormChange, b: cardFormChange) =>
  cardDetailsEq(a.payload, b.payload) &&
  a.fieldsReady === b.fieldsReady &&
  a.sessionStatus === b.sessionStatus &&
  a.complete === b.complete &&
  a.valid === b.valid &&
  a.submitting === b.submitting &&
  a.canSubmit === b.canSubmit &&
  a.isCoBadged === b.isCoBadged &&
  a.eligibility === b.eligibility &&
  errorEq(a.networkError, b.networkError) &&
  fieldsEq(a.fields, b.fields)
