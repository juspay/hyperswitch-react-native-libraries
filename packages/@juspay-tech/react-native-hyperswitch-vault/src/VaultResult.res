/*
 * The two public results, one per operation (ADR-0003), spelled the way hyperswitch-web spells them.
 *
 * ── WHY TWO RESULTS AND NOT ONE ────────────────────────────────────────────────
 *
 *   `tokenize()`       — the merchant wants a payment-method token and will do the rest themselves.
 *                        `vaultTokenizeResult` is the ONLY public type with a `token`.
 *
 *   `confirmPayment()` — the library performs the tokenization AND the final payment confirmation.
 *                        The intermediate token never leaves the library, so `vaultPaymentResult`
 *                        has no `token` member and no way to grow one.
 *
 * ── THE WEB'S ERROR ENVELOPE ───────────────────────────────────────────────────
 *
 * A failure carries `error: {code, message, type}` — the members and the codes the web SDK's
 * `tokenize()` resolves with (`session_expired`, `session_consumed`, `tokenization_in_progress`,
 * `incomplete_field_set`, `validation_error`, `tokenization_failed`), plus the codes only this
 * library can produce, and `type` classifies the code exactly as the web does. `if (result.error)`
 * therefore works on both SDKs unchanged. The `status` discriminant is this library's addition, so
 * a TypeScript caller gets narrowing the web's untyped object cannot give.
 *
 * ── EVERY MESSAGE IS OURS ──────────────────────────────────────────────────────
 *
 * A backend error string can echo request context and is written for an operator, not a customer.
 * No mapper below forwards one: the transport maps a backend code to a fixed string of its own,
 * and that string — never the backend's — is what arrives here.
 */

@genType
type safeVaultErrorCode = [
  /* web vocabulary */
  | #validation_error
  | #incomplete_field_set
  | #session_expired
  | #session_consumed
  | #tokenization_in_progress
  | #confirm_in_progress
  | #tokenization_failed
  /* this library's additions */
  | #invalid_session
  | #unsupported_configuration
  | #unknown_outcome
  | #payment_failed
  | #forbidden_card_data
  /* The backend's eligibility step declined this card. Nothing was charged. */
  | #card_not_eligible
]

@genType
type safeVaultErrorType = [#validation_error | #api_error | #card_error]

/* The web's classification of a code, member for member where the codes are shared. */
let typeOf = (code: safeVaultErrorCode): safeVaultErrorType =>
  switch code {
  | #validation_error | #incomplete_field_set | #forbidden_card_data => #validation_error
  | #card_not_eligible => #card_error
  | #session_expired
  | #session_consumed
  | #tokenization_in_progress
  | #confirm_in_progress
  | #tokenization_failed
  | #invalid_session
  | #unsupported_configuration
  | #unknown_outcome
  | #payment_failed =>
    #api_error
  }

@genType
type safeVaultError = {
  code: safeVaultErrorCode,
  /* Library-owned, customer-safe display text. Never a backend message. */
  message: string,
  @as("type") type_: safeVaultErrorType,
}

let errorOf = (code, message): safeVaultError => {code, message, type_: typeOf(code)}

@genType
type nextActionType = VaultNavigation.nextActionType

@genType
type safeThreeDs = VaultNavigation.safeThreeDs

@genType
type safeDdc = VaultNavigation.safeDdc

@genType
type safeSessionToken = VaultNavigation.safeSessionToken

@genType
type safeNextAction = VaultNavigation.safeNextAction

@genType
type vaultPaymentStatus = [
  | #succeeded
  | #processing
  | #requires_customer_action
  | #failed
  | #validation_error
]

/*
 * Tokenization uses `#success`/`#error` rather than `#succeeded`/`#failed`. The spellings differ on
 * purpose: the two results are not interchangeable, and a caller who copies a `status` comparison
 * from one flow into the other gets a compile error instead of a branch that silently never runs.
 */
@genType
type vaultTokenizeStatus = [#success | #validation_error | #error]

/*
 * Records rather than `@tag` variants: ReScript compiles a payload-less variant constructor to a
 * bare string, so `Succeeded` came out as `"succeeded"` and `result.status` was `undefined` for the
 * most common outcome. `public.ts` republishes the same runtime shapes as hand-written TypeScript
 * discriminated unions, so merchants still get narrowing.
 */
@genType
type vaultPaymentResult = {
  status: vaultPaymentStatus,
  error?: safeVaultError,
  nextAction?: safeNextAction,
}

/* The ONLY public type carrying a token. */
@genType
type vaultTokenizeResult = {
  status: vaultTokenizeStatus,
  token?: string,
  error?: safeVaultError,
}

/* ── Fixed messages ────────────────────────────────────────────────────────── */

let invalidCardMessage = "Please check your card details and try again."
let incompleteFieldSetMessage = "Mount a card-number, expiry and CVC field, or one CVC field with a saved card, before submitting."
let unusableSessionMessage = "This session can no longer be used."
let sessionExpiredMessage = "This payment method session has expired."
let sessionConsumedMessage = "This payment method session has already been used."
let tokenizationInProgressMessage = "A tokenization is already in progress for this session."
let confirmInProgressMessage = "A payment confirmation is already in progress for this session."
let unknownOutcomeMessage = "We could not confirm the payment. Please check before trying again."
let tokenizationFailedMessage = "The card could not be tokenized."
let paymentFailedMessage = "The payment could not be completed."
let unauthorizedMessage = "The payment session could not be authorized."
let rejectedMessage = "The payment details were rejected."
let sessionAlreadyUsedMessage = "This payment session has already been used."
let malformedResponseMessage = "The payment response could not be read."
let forbiddenCardDataMessage = "Card data must not be supplied by the host; the library owns the card fields."
let unsupportedConfigurationMessage = "This payment cannot be completed with the current configuration."
let cardNotEligibleMessage = "This card is not accepted for this payment."
let missingSavedCardTokenMessage = "The saved-card CVC flow requires a payment token: mount the CVC field with savedCard: {paymentToken, paymentMethodData: {card: {cardNetwork}}}."

/* ── Payment constructors (Flows 2 and 3) ─────────────────────────────────── */

let failedWith = (code, message): vaultPaymentResult => {
  status: #failed,
  error: errorOf(code, message),
}

let validationError = (message): vaultPaymentResult => {
  status: #validation_error,
  error: errorOf(#validation_error, message),
}

let invalidCardData = () => validationError(invalidCardMessage)

let incompleteFieldSet = (message): vaultPaymentResult => {
  status: #validation_error,
  error: errorOf(#incomplete_field_set, message),
}

let invalidSession = message => failedWith(#invalid_session, message)
let sessionExpired = () => failedWith(#session_expired, sessionExpiredMessage)
let sessionConsumed = () => failedWith(#session_consumed, sessionConsumedMessage)
let tokenizationInProgress = () =>
  failedWith(#tokenization_in_progress, tokenizationInProgressMessage)
let forbiddenCardData = () => failedWith(#forbidden_card_data, forbiddenCardDataMessage)
let unsupportedConfiguration = () =>
  failedWith(#unsupported_configuration, unsupportedConfigurationMessage)

/*
 * A DENIAL, not a failure to ask. `VaultEligibility` resolves a transport problem to "allowed", so
 * reaching this constructor means the backend explicitly said no — and nothing was charged.
 */
let cardNotEligible = () => failedWith(#card_not_eligible, cardNotEligibleMessage)
let unknownOutcome = () => failedWith(#unknown_outcome, unknownOutcomeMessage)

/* ── Tokenize constructors (Flow 1) ────────────────────────────────────────── */

let tokenizeSuccess = (token): vaultTokenizeResult => {status: #success, token}

let tokenizeFailedWith = (code, message): vaultTokenizeResult => {
  status: #error,
  error: errorOf(code, message),
}

let tokenizeValidationError = (message): vaultTokenizeResult => {
  status: #validation_error,
  error: errorOf(#validation_error, message),
}

let tokenizeInvalidCardData = () => tokenizeValidationError(invalidCardMessage)

let tokenizeIncompleteFieldSet = (message): vaultTokenizeResult => {
  status: #validation_error,
  error: errorOf(#incomplete_field_set, message),
}

let tokenizeSessionExpired = () => tokenizeFailedWith(#session_expired, sessionExpiredMessage)
let tokenizeSessionConsumed = () => tokenizeFailedWith(#session_consumed, sessionConsumedMessage)
let tokenizeConfirmInProgress = () =>
  tokenizeFailedWith(#confirm_in_progress, confirmInProgressMessage)

/*
 * The SAME transport failure taxonomy as the payment flow, re-tagged for this result's statuses.
 * The transport's message is forwarded: every one of them is a string the transport itself wrote
 * — including the specific "already used" / "expired" wording it derives from a backend CODE —
 * never a backend message.
 */
let tokenizeFromPmsFailure = (error: VaultConfirm.vaultError): vaultTokenizeResult =>
  switch error.code {
  | #invalid_card_data => tokenizeInvalidCardData()
  | #invalid_authorization
  | #missing_session_id =>
    tokenizeFailedWith(#invalid_session, unusableSessionMessage)
  | #unknown_outcome => tokenizeFailedWith(#unknown_outcome, unknownOutcomeMessage)
  | #http_error
  | #malformed_response
  | #missing_token =>
    tokenizeFailedWith(#tokenization_failed, error.message)
  }

/* ── Payment mappers (Flow 2) ──────────────────────────────────────────────── */

/* Call 1 (token mint) failed: nothing was charged, and no token exists. */
let fromPmsFailure = (error: VaultConfirm.vaultError): vaultPaymentResult =>
  switch error.code {
  | #invalid_card_data => invalidCardData()
  | #invalid_authorization
  | #missing_session_id =>
    invalidSession(unusableSessionMessage)
  | #unknown_outcome => unknownOutcome()
  | #http_error
  | #malformed_response
  | #missing_token =>
    failedWith(#tokenization_failed, error.message)
  }

/* Call 2 (final confirm) returned. Only navigation crosses the boundary. */
let fromNavOutcome = (outcome: VaultFinalConfirm.navOutcome): vaultPaymentResult =>
  switch outcome {
  | VaultFinalConfirm.Succeeded => {status: #succeeded}
  | VaultFinalConfirm.Processing => {status: #processing}
  | VaultFinalConfirm.RequiresAction({type_, redirectUrl, threeDs, ddc, sessionToken}) => {
      status: #requires_customer_action,
      nextAction: {
        VaultNavigation.type_,
        redirectUrl: ?redirectUrl,
        threeDs: ?threeDs,
        ddc: ?ddc,
        sessionToken: ?sessionToken,
      },
    }
  /*
   * The transport hands over a closed REASON; every word below is this module's own. There is no
   * string on that boundary for backend prose to arrive in.
   */
  | VaultFinalConfirm.Failed({reason}) =>
    switch reason {
    | VaultFinalConfirm.Unauthorized => failedWith(#payment_failed, unauthorizedMessage)
    | VaultFinalConfirm.Rejected => failedWith(#payment_failed, rejectedMessage)
    | VaultFinalConfirm.SessionAlreadyUsed => failedWith(#session_consumed, sessionAlreadyUsedMessage)
    | VaultFinalConfirm.SessionExpired => failedWith(#session_expired, sessionExpiredMessage)
    | VaultFinalConfirm.MalformedResponse => failedWith(#payment_failed, malformedResponseMessage)
    | VaultFinalConfirm.GenericFailure => failedWith(#payment_failed, paymentFailedMessage)
    }
  | VaultFinalConfirm.UnknownOutcome => failedWith(#unknown_outcome, unknownOutcomeMessage)
  }
