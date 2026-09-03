/*
 * The two public results, one per operation (ADR-0003).
 *
 * ── WHY TWO RESULTS AND NOT ONE ────────────────────────────────────────────────
 *
 * There are two genuinely different jobs, and an earlier revision collapsed them into a single
 * `submit()` returning one union. That was wrong in the direction that matters: a caller could not
 * tell from the type whether a token might come back, so "does a payment credential cross this
 * boundary?" became a question about which arguments were passed rather than which function was
 * called.
 *
 *   `tokenize()`       — the merchant wants a payment-method token and will do the rest themselves.
 *                        `vaultTokenizeResult` is the ONLY public type with a `token`, and it is
 *                        deliberately permitted here.
 *
 *   `confirmPayment()` — the library performs the tokenization AND the final payment confirmation.
 *                        The intermediate token never leaves the library, so `vaultPaymentResult`
 *                        has no `token` member and no way to grow one.
 *
 * The separation is the safety property: choosing the operation chooses the exposure, and the two
 * results have disjoint shapes so neither can be mistaken for the other.
 *
 * ── EVERY MESSAGE IS OURS ──────────────────────────────────────────────────────
 *
 * A backend error string can echo request context and is written for an operator, not a customer.
 * No mapper below forwards one: each maps a code to a fixed string declared in this module, and an
 * unrecognised code becomes `#server_error` with the generic message.
 */

@genType
type safeVaultErrorCode = [
  | #invalid_session
  | #invalid_card_data
  | #not_ready
  | #forbidden_card_data
  | #unsupported_configuration
  /* The backend's eligibility step declined this card. Nothing was charged. */
  | #card_not_eligible
  | #server_error
  | #unknown_outcome
]

@genType
type safeVaultError = {
  code: safeVaultErrorCode,
  /* Library-owned, customer-safe display text. Never a backend message. */
  message: string,
}

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
  | #not_ready
]

/*
 * Tokenization uses `#success`/`#error` rather than `#succeeded`/`#failed`. The spellings differ on
 * purpose: the two results are not interchangeable, and a caller who copies a `status` comparison
 * from one flow into the other gets a compile error instead of a branch that silently never runs.
 */
@genType
type vaultTokenizeStatus = [#success | #validation_error | #not_ready | #error]

/*
 * ── WHY THIS IS A RECORD AND NOT A `@tag` VARIANT ──────────────────────────────
 *
 * The obvious spelling is a tagged variant: `@tag("status") | @as("succeeded") Succeeded | ...`.
 * It was written that way first, and it is WRONG here, because ReScript compiles a variant
 * constructor with NO payload to a bare string. `Succeeded` came out as the string `"succeeded"`,
 * not `{status: "succeeded"}` — so `result.status` was `undefined` for the single most common
 * outcome, while the payload-carrying branches were objects. Consumers would have had to write
 * `typeof result === 'string'` before they could read a status at all, and the obvious
 * `result.status === 'succeeded'` would have silently never matched.
 *
 * A record makes every branch an object with a `status`, which is the shape the documentation, the
 * host binding and every consumer expect. The closed status unions keep the sets exhaustive.
 *
 * The cost is that `error`, `nextAction` and `token` are optional on the records, so ReScript no
 * longer proves "failed implies error". That invariant is enforced two other ways instead: every
 * value is built by the constructors below, and `scripts/verify-result-mapping.mjs` asserts the
 * exact member set for each status at runtime. `public.ts` republishes the same runtime shapes as
 * hand-written TypeScript discriminated unions, so merchants still get narrowing — and the same
 * gate fails if the two ever drift.
 */
@genType
type vaultPaymentResult = {
  status: vaultPaymentStatus,
  error?: safeVaultError,
  nextAction?: safeNextAction,
}

/*
 * The ONLY public type carrying a token. `vaultPaymentResult` above has no `token` member, which is
 * what makes "the intermediate token never leaves the library" a property of the type rather than a
 * promise in prose.
 */
@genType
type vaultTokenizeResult = {
  status: vaultTokenizeStatus,
  token?: string,
  error?: safeVaultError,
}

/* ── Fixed messages ────────────────────────────────────────────────────────── */

let invalidCardMessage = "Please check your card details and try again."
let notReadyMessage = "The card form is not ready yet."
let unusableSessionMessage = "This session can no longer be used."
let unknownOutcomeMessage = "We could not confirm the payment. Please check before trying again."
let serverErrorMessage = "The payment could not be completed."
let unauthorizedMessage = "The payment session could not be authorized."
let rejectedMessage = "The payment details were rejected."
let sessionAlreadyUsedMessage = "This payment session has already been used."
let sessionExpiredMessage = "This payment session has expired."
let malformedResponseMessage = "The payment response could not be read."
let forbiddenCardDataMessage = "Card data must not be supplied by the host; the library owns the card fields."
let unsupportedConfigurationMessage = "This payment cannot be completed with the current configuration."
let cardNotEligibleMessage = "This card is not accepted for this payment."

/* ── Constructors ──────────────────────────────────────────────────────────── */

let failedWith = (code, message): vaultPaymentResult => {
  status: #failed,
  error: {code, message},
}

let invalidCardData = (): vaultPaymentResult => {
  status: #validation_error,
  error: {code: #invalid_card_data, message: invalidCardMessage},
}

let notReady = (): vaultPaymentResult => {
  status: #not_ready,
  error: {code: #not_ready, message: notReadyMessage},
}

let notReadyWithMessage = (message): vaultPaymentResult => {
  status: #not_ready,
  error: {code: #not_ready, message},
}

let invalidSession = message => failedWith(#invalid_session, message)

let forbiddenCardData = () => failedWith(#forbidden_card_data, forbiddenCardDataMessage)

let unsupportedConfiguration = () =>
  failedWith(#unsupported_configuration, unsupportedConfigurationMessage)

/*
 * A DENIAL, not a failure to ask. `VaultEligibility` resolves a transport problem to "allowed", so
 * reaching this constructor means the backend explicitly said no — and nothing was charged.
 */
let cardNotEligible = () => failedWith(#card_not_eligible, cardNotEligibleMessage)

let serverError = () => failedWith(#server_error, serverErrorMessage)

let unknownOutcome = () => failedWith(#unknown_outcome, unknownOutcomeMessage)

/* ── Tokenize constructors (Flow 1) ────────────────────────────────────────── */

let tokenizeSuccess = (token): vaultTokenizeResult => {status: #success, token}

let tokenizeFailedWith = (code, message): vaultTokenizeResult => {
  status: #error,
  error: {code, message},
}

let tokenizeInvalidCardData = (): vaultTokenizeResult => {
  status: #validation_error,
  error: {code: #invalid_card_data, message: invalidCardMessage},
}

let tokenizeNotReady = (message): vaultTokenizeResult => {
  status: #not_ready,
  error: {code: #not_ready, message},
}

/*
 * The SAME transport failure taxonomy as the payment flow, re-tagged for this result's statuses.
 * There is one mapping of `VaultConfirm.vaultErrorCode` per public result, and both are enumerated
 * by the gate, so a new transport code cannot be handled in one flow and forgotten in the other.
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
    tokenizeFailedWith(#server_error, serverErrorMessage)
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
    serverError()
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
    | VaultFinalConfirm.Unauthorized => failedWith(#server_error, unauthorizedMessage)
    | VaultFinalConfirm.Rejected => failedWith(#server_error, rejectedMessage)
    | VaultFinalConfirm.SessionAlreadyUsed => failedWith(#server_error, sessionAlreadyUsedMessage)
    | VaultFinalConfirm.SessionExpired => failedWith(#server_error, sessionExpiredMessage)
    | VaultFinalConfirm.MalformedResponse => failedWith(#server_error, malformedResponseMessage)
    | VaultFinalConfirm.GenericFailure => failedWith(#server_error, serverErrorMessage)
    }
  | VaultFinalConfirm.UnknownOutcome => failedWith(#unknown_outcome, unknownOutcomeMessage)
  }
