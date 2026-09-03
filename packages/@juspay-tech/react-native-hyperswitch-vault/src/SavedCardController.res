open ReactNative

/*
 * The CVC-only controller behind `HyperswitchVaultSavedCardForm` (ADR-0008).
 *
 * A deliberately tiny reducer: one value, its focus and touched meta, a submit-attempted flag and a
 * version counter. PAN, expiry, cardholder name, co-badge, eligibility and scan are ABSENT. The saved
 * card already has all of them, and a reducer that could hold them would be a reducer that could
 * leak them.
 *
 * The rules that decide what the customer SEES are copied from `CardStateReducer.cvcError` and
 * `CardStateReducer.cvcFieldOk`, so this field behaves exactly as the new-card CVC does: a message
 * appears only once the field has been touched and only while it is not focused, and the border
 * turns red under the same condition. The public snapshot is built by the existing
 * `VaultPublicState.cvcStateOf`, never by hand, so it cannot grow a member this module invents.
 */

type state = {
  cvc: string,
  touched: bool,
  focused: bool,
  submitAttempted: bool,
  /* Bumps on every CVC change — the invalidation signal, mirroring `cardVersion`. */
  cvcVersion: int,
}

let initial = {cvc: "", touched: false, focused: false, submitAttempted: false, cvcVersion: 0}

type action =
  | CvcChanged(CardFieldLogic.cvcChange)
  | Focused
  | Blurred
  | SubmitAttempted
  | Reset

let reduce = (state: state, action: action): state =>
  switch action {
  | CvcChanged(change) => {...state, cvc: change.formatted, cvcVersion: state.cvcVersion + 1}
  | Focused => {...state, focused: true}
  | Blurred => {...state, touched: true, focused: false}
  | SubmitAttempted => {...state, submitAttempted: true, touched: true}
  /* Reset counts as a value change, so nothing minted before it can describe what follows. */
  | Reset => {...initial, cvcVersion: state.cvcVersion + 1}
  }

/*
 * ── THE NETWORK HINT ───────────────────────────────────────────────────────────
 *
 * `list-payment-methods` spells networks the backend's way — "Visa", "AmericanExpress" — and a
 * merchant is just as likely to pass what their own screen shows ("American Express", "amex"). The
 * validator matches `Validation.cardPatterns[].issuer` EXACTLY, so any other spelling would fall
 * through to the default rule silently, and an Amex CVC would be accepted at three digits without
 * anyone being told why. This table is the one place the mapping lives.
 *
 * Case, spaces, hyphens and underscores are ignored. Unrecognised or absent ⇒ "" ⇒
 * `Validation.defaultCardPattern` ⇒ three OR four digits accepted (ADR-0008: defaulting strictly to
 * three would reject every valid Amex CVC).
 */
let normaliseNetwork = (hint: option<string>): string =>
  switch hint
  ->Option.getOr("")
  ->String.toLowerCase
  ->String.replaceRegExp(%re("/[\s_-]+/g"), "") {
  | "visa" => "Visa"
  | "mastercard" => "Mastercard"
  | "americanexpress" | "amex" => "AmericanExpress"
  | "dinersclub" | "diners" => "DinersClub"
  | "discover" => "Discover"
  | "jcb" => "JCB"
  | "cartesbancaires" => "CartesBancaires"
  | "interac" => "Interac"
  | "maestro" => "Maestro"
  | "unionpay" => "UnionPay"
  | "rupay" => "RuPay"
  | "sodexo" => "SODEXO"
  | "bajaj" => "BAJAJ"
  | _ => ""
  }

type controller = {
  value: string,
  /* The message the customer is being shown NOW: touched, and not focused. */
  visibleError: option<string>,
  /* Whether the field is drawn as acceptable. */
  fieldOk: bool,
  /*
   * A THUNK, invoked only inside the emitter's `build`, so a component with no listener builds no
   * snapshot at all. It calls the existing `VaultPublicState.cvcStateOf`, which structurally has no
   * member for the value, its length, or a brand.
   */
  publicSnapshot: unit => VaultPublicState.cvcState,
  onChange: CardFieldLogic.cvcChange => unit,
  onFocus: unit => unit,
  onBlur: unit => unit,
  markSubmitAttempted: unit => unit,
  reset: unit => unit,
  /* Read at call time through a ref: the imperative handle is created once and never rebuilt. */
  cvc: unit => string,
  isValidNow: unit => bool,
  cvcVersion: unit => int,
  cvcRef: React.ref<Nullable.t<TextInput.element>>,
}

let use = (
  /* `VaultFormOptions.makeCvcValidatorWith(messages)`: brand first, then the value. */
  ~validator: string => option<string> => option<string>,
  /* The normalised network hint, or "" for the three-or-four default. */
  ~brand: string,
): controller => {
  let (state, dispatch) = React.useReducer(reduce, initial)
  let cvcRef = React.useRef(Nullable.null)

  /*
   * Re-derived every render from the brand IN FORCE, so a `cardNetwork` change re-validates without
   * a keystroke — `valid` can flip in either direction, which is what the ADR says must happen.
   */
  let error = validator(brand)(Some(state.cvc))

  let latestRef = React.useRef((state, error))
  latestRef.current = (state, error)

  let visibleError = switch (error, state.touched, state.focused) {
  | (Some(message), true, false) => Some(message)
  | _ => None
  }
  let fieldOk = error->Option.isNone || !state.touched || state.focused

  let publicSnapshot = () =>
    VaultPublicState.cvcStateOf({
      value: state.cvc,
      accepted: error->Option.isNone,
      touched: state.touched,
      focused: state.focused,
      visibleError,
    })

  {
    value: state.cvc,
    visibleError,
    fieldOk,
    publicSnapshot,
    onChange: change => dispatch(CvcChanged(change)),
    onFocus: () => dispatch(Focused),
    onBlur: () => dispatch(Blurred),
    markSubmitAttempted: () => dispatch(SubmitAttempted),
    reset: () => dispatch(Reset),
    cvc: () => {
      let (latest, _) = latestRef.current
      latest.cvc
    },
    isValidNow: () => {
      let (_, latestError) = latestRef.current
      latestError->Option.isNone
    },
    cvcVersion: () => {
      let (latest, _) = latestRef.current
      latest.cvcVersion
    },
    cvcRef,
  }
}
