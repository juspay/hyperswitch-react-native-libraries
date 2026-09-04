/*
 * Merchant field OPTIONS — which visual elements exist.
 *
 * This is deliberately a separate axis from `CardFieldStyles`:
 *
 *   field options → which visual elements exist
 *   field styles  → how the enabled elements look
 *   events        → safe validation state
 *   library       → sensitive values and input behaviour
 *
 * A style value must never decide whether an element exists. `styles.placeholder` says how the
 * placeholder looks; only `options.placeholder` decides whether there is one at all.
 *
 * ── WHY EVERY DEFAULT IS ON ────────────────────────────────────────────────────────────────────
 *
 * The zero-configuration field renders a complete, usable input: placeholder, floating label, brand
 * mark, CVC glyph, and the error tint (the ready-made form adds the message text). `unstyled`
 * strips all of it back to a bare `TextInput`.
 *
 * This block used to argue the opposite, and the argument was coherent: the library owns the card
 * values, the merchant owns the checkout's appearance, so inheriting a presentation nobody asked
 * for makes the merchant's job harder. What it got wrong is what a merchant meets first. A blank
 * rectangle is not a neutral starting point — it reads as a broken integration, and the README had
 * to carry a sentence explaining that `fieldOptions` "is not optional decoration, it is how you get
 * a visible form". A default that needs that sentence is the wrong default.
 *
 * The ownership argument survives intact, because it was never really about defaults: every element
 * is still individually switchable, `unstyled` still yields a plain input, and no merchant is
 * prevented from drawing their own. What changed is which of the two costs a line of code.
 *
 * Accessibility and input behaviour are not part of this decision in either direction. A field is
 * announced as "Card number", keeps its keyboard type and length limit, and masks the CVC, whether
 * or not it is drawn — see `unstyled` in `resolveWith`.
 */

@genType
/*
 * The SAME vocabulary as hyperswitch-web's `appearance.labels`: `above` sits over the box,
 * `floating` lifts on focus, `never` draws no label. A field may override the form-wide value.
 */
type labelBehavior = [#above | #floating | #never]

/*
 * THREE answers, because "show the error" is two independent decisions: tint the field, and print
 * the message.
 *
 *   #none       nothing. The field looks exactly like a valid one and no text is drawn. The
 *               merchant hears about the problem through the state event and draws it however they
 *               like — including not at all.
 *   #colorOnly  the field carries its error STATE — border and text in the merchant's `errorColor`
 *               — but no message is printed. The customer can see WHICH box is wrong; the merchant
 *               owns the words.
 *   #inline     the state AND the message, printed under the field. A complete UI.
 *
 * `#colorOnly` is the composable default, and it is what hyperswitch-web's separate card fields do.
 * There the two decisions are separate props on the same input: `isErrorHidden=true` suppresses the
 * message block, while `isValid` still drives the `Input--invalid` class that tints the box
 * (`CommonCardFieldHooks.res` passes exactly that combination on all three fields). Collapsing
 * those into a single on/off — which this union did until now — forced a merchant who wanted the
 * web's behaviour to choose between a silent field with no visual cue and a field that prints a
 * message they were already rendering themselves.
 */
@genType
type errorDisplay = [#none | #colorOnly | #inline]

/*
 * ONE brand-icon concept, not two.
 *
 * An earlier revision of this reset added `brandIcon: 'none' | 'auto'` alongside the pre-existing
 * `appearance.brandIconMode`, which already had a `hidden` member. That gave two public controls
 * over the same element and two ways to spell "off" — `brandIcon: 'none'` and
 * `cardBrandIcon: 'hidden'` — with no defined answer when they disagreed. It is reused here
 * instead: `hidden` is the "off" it always was, and the field-level option is the same union.
 */
@genType
type brandIconMode = CardIcons.brandIconMode

@genType
/* hyperswitch-web's `cvcIcon` values. */
type cvcIconDisplay = [#hidden | #default]

/*
 * `testID` is spelled the React Native way, not `testId`: a merchant reaches for the name their
 * test library already uses.
 */
@genType
type fieldOptions = {
  placeholder?: string,
  label?: string,
  labelBehavior?: labelBehavior,
  errorDisplay?: errorDisplay,
  accessibilityLabel?: string,
  accessibilityHint?: string,
  testID?: string,
  /*
   * Strip this field back to a bare `TextInput`: no border, no background, no fixed height, no
   * placeholder, label, icon or error line. What survives is behaviour and accessibility —
   * `accessibilityLabel`, `testID`, keyboard type, length limit and the CVC's masking.
   *
   * Absent => the provider's `unstyled`, and then `false`. A field may set `unstyled={false}` to
   * keep the full UI inside an unstyled provider.
   */
  unstyled?: bool,
}

@genType
type cardNumberOptions = {
  placeholder?: string,
  label?: string,
  labelBehavior?: labelBehavior,
  errorDisplay?: errorDisplay,
  accessibilityLabel?: string,
  accessibilityHint?: string,
  testID?: string,
  /*
   * Strip this field back to a bare `TextInput`: no border, no background, no fixed height, no
   * placeholder, label, icon or error line. What survives is behaviour and accessibility —
   * `accessibilityLabel`, `testID`, keyboard type, length limit and the CVC's masking.
   *
   * Absent => the provider's `unstyled`, and then `false`. A field may set `unstyled={false}` to
   * keep the full UI inside an unstyled provider.
   */
  unstyled?: bool,
  /*
   * Card number only — the expiry and CVC option types have no such member at all. Named as
   * hyperswitch-web names it. Absent => fall back to `appearance.variables.cardBrandIcon`, then to
   * `standard`.
   */
  cardBrandIcon?: brandIconMode,
}

@genType
type expiryOptions = fieldOptions

/* No brand artwork and no CVC glyph — a name field has neither. */
@genType
type cardholderNameOptions = fieldOptions

@genType
type cvcOptions = {
  placeholder?: string,
  label?: string,
  labelBehavior?: labelBehavior,
  errorDisplay?: errorDisplay,
  accessibilityLabel?: string,
  accessibilityHint?: string,
  testID?: string,
  /*
   * Strip this field back to a bare `TextInput`: no border, no background, no fixed height, no
   * placeholder, label, icon or error line. What survives is behaviour and accessibility —
   * `accessibilityLabel`, `testID`, keyboard type, length limit and the CVC's masking.
   *
   * Absent => the provider's `unstyled`, and then `false`. A field may set `unstyled={false}` to
   * keep the full UI inside an unstyled provider.
   */
  unstyled?: bool,
  /* CVC only. */
  cvcIcon?: cvcIconDisplay,
}

/* The ready-made form's grouped prop, mirroring `formFieldStyles`. */
@genType
type formFieldOptions = {
  cardNumber?: cardNumberOptions,
  cardExpiry?: expiryOptions,
  cardCvc?: cvcOptions,
  cardholderName?: cardholderNameOptions,
}

/*
 * ── A SAVED CARD, ON THE CVC FIELD ─────────────────────────────────────────────────────────────
 *
 * The SAME shape hyperswitch-web reads off `create('cardCvc', {savedCard})`: the token of the card
 * `list-payment-methods` returned, and its network under `paymentMethodData.card.cardNetwork`. A
 * CVC field mounted with this — and no card-number field beside it — turns `tokenize()` into the
 * saved-card CVC update.
 */
@genType
type savedCardData = {cardNetwork?: string}

@genType
type savedCardPaymentMethodData = {card?: savedCardData}

@genType
type savedCard = {
  paymentToken?: string,
  paymentMethodData?: savedCardPaymentMethodData,
}

let savedCardToken = (saved: savedCard) =>
  saved.paymentToken->Option.map(String.trim)->Option.getOr("")

let savedCardNetwork = (saved: savedCard) =>
  saved.paymentMethodData
  ->Option.flatMap(data => data.card)
  ->Option.flatMap(card => card.cardNetwork)
  ->Option.getOr("")

/*
 * ── FORM LAYOUT ────────────────────────────────────────────────────────────────────────────────
 *
 * These two replace the previous `splitCardFields: bool`, which conflated them: `false` meant
 * "expiry and CVC share a row AND all three borders are joined", `true` meant "share a row AND
 * borders are separate". There was no way to ask for three stacked fields, which is now the
 * default. One source of truth, two independent questions.
 */

/*
 * WHO COLLECTS THE CARDHOLDER NAME, AND WHERE ITS VALUE COMES FROM.
 *
 * Three modes, because there are genuinely three arrangements and collapsing any two of them loses
 * something:
 *
 *   #collect   The library renders its own bare input and uses what was typed into it. The default,
 *              because a merchant placing one component expects a complete card form.
 *
 *   #"external"  The library renders NO name field, and the value arrives on the confirm input as
 *              `cardholderName`. This is for a host that already owns a cardholder-name field —
 *              client-core does, with its own validation, localisation and error timing — and
 *              whose field must stay the one on screen.
 *
 *   #omit      The library renders no name field and sends no name at all. For a host whose
 *              configuration simply does not ask for one.
 *
 * `#"external"` and `#omit` look identical on screen and differ entirely in what is sent, which is
 * why they are separate: a host that means "I will supply it" and one that means "there is none"
 * must not be spelled the same way, or a missing value silently becomes an omitted one.
 *
 * Neither renders a hidden field. A `display: none` input is still mounted, still focusable, and
 * still announced by a screen reader as a second name field — which is the bug this exists to
 * prevent, not a cosmetic detail.
 */
/*
 * `#"external"` is quoted because `external` is a ReScript keyword. The quoting is syntax only —
 * the runtime value is the plain string `"external"`, which is what the published TypeScript union
 * and every caller sees.
 */
@genType
type cardholderNameMode = [#collect | #"external" | #omit]

@genType
type formLayout = [#stacked | #inline]

@genType
type fieldArrangement = [#separate | #fused]

/* ── Resolution ─────────────────────────────────────────────────────────────────────────────── */

/*
 * The resolved shape the render tree consumes. Every member is decided here, once, so no component
 * downstream has to know a default — and `resolve` is the only place a default lives.
 */
type resolved = {
  placeholder: option<string>,
  label: option<string>,
  labelBehavior: labelBehavior,
  errorDisplay: errorDisplay,
  accessibilityLabel: string,
  accessibilityHint: option<string>,
  testID: string,
  unstyled: bool,
}

/*
 * Whitespace-only merchant text is treated as absent, and surrounding whitespace is dropped rather
 * than carried into the rendered element — `testID: " foo "` should find the same node as
 * `testID: "foo"`.
 */
/*
 * Placeholder and label need THREE answers, not two, now that absent means "use the library's
 * string": inherit it, replace it, or turn it off. `trimmed` collapses `""` to `None`, which is
 * indistinguishable from absent — so a merchant who wants no placeholder would have no way to say
 * so short of `unstyled`, which removes everything else too.
 *
 * `placeholder=""` means "no placeholder". That is what a bare `<TextInput placeholder="" />` does
 * in React Native, so it needs no new type on the public surface and no second way to spell "off".
 */
type textChoice =
  | Inherit
  | Off
  | Text(string)

let merchantText = (value: option<string>): textChoice =>
  switch value {
  | None => Inherit
  | Some(text) =>
    let text = text->String.trim
    text === "" ? Off : Text(text)
  }

let trimmed = (value: option<string>) =>
  value->Option.flatMap(text => {
    let text = text->String.trim
    text === "" ? None : Some(text)
  })

/*
 * ── THE DEFAULTS, IN ONE BLOCK ─────────────────────────────────────────────────────────────────
 *
 * Every visual default the library has. `resolveWith` below claims to be "the only place a default
 * lives" and it was not true: `cvcIconOf` carried its own, and `VaultFormHost` carried the
 * form-wide brand-icon one, and `CardFormView` re-derived the error one three times. Naming them
 * here makes the claim true and makes changing the library's default presentation a single,
 * reviewable edit to four lines rather than an archaeology exercise across four files.
 */
/*
 * The form-wide label default when the merchant set no `appearance.labels`. hyperswitch-web's own
 * default is `above`; the library keeps `floating` because that is what its ready-made form has
 * always drawn, and a merchant who wants the web look sets `appearance: {labels: 'above'}` once.
 */
let defaultLabelBehavior: labelBehavior = #floating
/*
 * TWO error-display defaults, because there are two surfaces with opposite obligations.
 *
 *   composable  <CardForm> + <CardNumberField /> …  ->  #colorOnly
 *   ready-made  <HyperswitchVaultForm />            ->  #inline
 *
 * A merchant who composes fields is drawing their own chrome: they position each box, and they
 * read `error` off `onChange` to place the message where their design puts it. Rendering our
 * own line underneath means the customer sees the SAME failure twice, and there is no form-level
 * switch to turn ours off — it would have to be repeated on all four fields. So the composable
 * surface prints no message.
 *
 * It does still TINT the field. Suppressing the message is not the same as pretending the field is
 * fine: the customer needs to see which of four boxes to go back to, and that cue costs the
 * merchant nothing to keep because it is drawn in the `errorColor` they already configured. This is
 * exactly what the web SDK's separate card fields do — `isErrorHidden=true` alongside a live
 * `isValid`.
 *
 * The ready-made form is the opposite contract: it is a complete UI, chosen precisely so the
 * merchant does not have to render anything. Silently dropping its validation text would leave a
 * zero-configuration form that never tells the customer what is wrong.
 *
 * Either default is overridable per field, in both directions, so neither surface is a dead end.
 */
let defaultErrorDisplayComposable: errorDisplay = #colorOnly
let defaultErrorDisplayReadyMade: errorDisplay = #inline
let defaultBrandIconMode: brandIconMode = #standard
let defaultCvcIcon: cvcIconDisplay = #default
let defaultUnstyled: bool = false

/*
 * `~defaultAccessibilityLabel` and `~defaultTestID` are library constants per field, not merchant
 * text. They are the two things that stay on even in the zero-configuration form.
 */
let resolveWith = (
  ~placeholder,
  ~label,
  ~labelBehavior,
  ~errorDisplay,
  ~accessibilityLabel,
  ~accessibilityHint,
  ~testID,
  ~unstyled,
  ~defaultAccessibilityLabel: string,
  ~defaultTestID: string,
  /* Already `provider prop ?? defaultUnstyled` by the time it reaches here. */
  ~formWideUnstyled: bool,
  /*
   * The surface's error-display default, supplied by whoever built the context — `#colorOnly` for
   * the composable fields, `#inline` for the ready-made form. Passed in rather than read off a
   * module constant so the two surfaces cannot silently share one answer again.
   */
  ~formWideErrorDisplay: errorDisplay,
  /* `appearance.labels`, already defaulted, so one form-level setting reaches every field. */
  ~formWideLabelBehavior: labelBehavior,
  /* This field's strings, from `localisation.labels` or the library's own. */
  ~defaultPlaceholder: string,
  ~defaultLabel: string,
): resolved => {
  let unstyled = unstyled->Option.getOr(formWideUnstyled)

  /*
   * `unstyled` WINS over the per-feature options — it is not merely a different set of defaults.
   *
   * The two escape hatches answer two different asks. Per-feature props are "change the UI";
   * `unstyled` is "there is no UI, give me a text input". Letting a stray `errorDisplay` survive
   * `unstyled` would put an element inside a field that has no box to hold it, and would make the
   * rendered result depend on which of two props the reader noticed first.
   *
   * So the resolved record tells the truth: under `unstyled` every visual member reads off, and
   * nothing downstream has to re-check the flag to know what it is looking at.
   */
  let inherited = fallback => unstyled ? None : Some(fallback)
  let chrome = (explicit, fallback) => unstyled ? fallback : explicit->Option.getOr(fallback)

  {
    placeholder: unstyled
      ? None
      : switch merchantText(placeholder) {
        | Inherit => inherited(defaultPlaceholder)
        | Off => None
        | Text(text) => Some(text)
        },
    label: unstyled
      ? None
      : switch merchantText(label) {
        | Inherit => inherited(defaultLabel)
        | Off => None
        | Text(text) => Some(text)
        },
    labelBehavior: chrome(labelBehavior, unstyled ? #never : formWideLabelBehavior),
    errorDisplay: chrome(errorDisplay, unstyled ? #none : formWideErrorDisplay),
    accessibilityLabel: trimmed(accessibilityLabel)->Option.getOr(defaultAccessibilityLabel),
    accessibilityHint: trimmed(accessibilityHint),
    testID: trimmed(testID)->Option.getOr(defaultTestID),
    unstyled,
  }
}

let resolveField = (
  options: option<fieldOptions>,
  ~defaultAccessibilityLabel,
  ~defaultTestID,
  ~formWideUnstyled,
  ~formWideErrorDisplay,
  ~formWideLabelBehavior,
  ~defaultPlaceholder,
  ~defaultLabel,
) =>
  resolveWith(
    ~placeholder=options->Option.flatMap(o => o.placeholder),
    ~label=options->Option.flatMap(o => o.label),
    ~labelBehavior=options->Option.flatMap(o => o.labelBehavior),
    ~errorDisplay=options->Option.flatMap(o => o.errorDisplay),
    ~accessibilityLabel=options->Option.flatMap(o => o.accessibilityLabel),
    ~accessibilityHint=options->Option.flatMap(o => o.accessibilityHint),
    ~testID=options->Option.flatMap(o => o.testID),
    ~unstyled=options->Option.flatMap(o => o.unstyled),
    ~defaultAccessibilityLabel,
    ~defaultTestID,
    ~formWideUnstyled,
    ~formWideErrorDisplay,
    ~formWideLabelBehavior,
    ~defaultPlaceholder,
    ~defaultLabel,
  )

let resolveCardNumber = (
  options: option<cardNumberOptions>,
  ~formWideUnstyled,
  ~formWideErrorDisplay,
  ~formWideLabelBehavior,
  ~labels: CardFormTypes.cardLabels,
) =>
  resolveWith(
    ~placeholder=options->Option.flatMap(o => o.placeholder),
    ~label=options->Option.flatMap(o => o.label),
    ~labelBehavior=options->Option.flatMap(o => o.labelBehavior),
    ~errorDisplay=options->Option.flatMap(o => o.errorDisplay),
    ~accessibilityLabel=options->Option.flatMap(o => o.accessibilityLabel),
    ~accessibilityHint=options->Option.flatMap(o => o.accessibilityHint),
    ~testID=options->Option.flatMap(o => o.testID),
    ~unstyled=options->Option.flatMap(o => o.unstyled),
    ~defaultAccessibilityLabel="Card number",
    ~defaultTestID=CardTestIds.cardNumberInputTestId,
    ~formWideUnstyled,
    ~formWideErrorDisplay,
    ~formWideLabelBehavior,
    ~defaultPlaceholder=labels.cardNumberPlaceholder,
    ~defaultLabel=labels.cardNumberFloatingLabel,
  )

let resolveExpiry = (
  options: option<expiryOptions>,
  ~formWideUnstyled,
  ~formWideErrorDisplay,
  ~formWideLabelBehavior,
  ~labels: CardFormTypes.cardLabels,
) =>
  resolveField(
    options,
    ~defaultAccessibilityLabel="Expiration date",
    ~defaultTestID=CardTestIds.expiryInputTestId,
    ~formWideUnstyled,
    ~formWideErrorDisplay,
    ~formWideLabelBehavior,
    ~defaultPlaceholder=labels.expiryPlaceholder,
    ~defaultLabel=labels.expiryFloatingLabel,
  )

let resolveCardholderName = (
  options: option<cardholderNameOptions>,
  ~formWideUnstyled,
  ~formWideErrorDisplay,
  ~formWideLabelBehavior,
  ~labels: CardFormTypes.cardLabels,
) =>
  resolveField(
    options,
    ~defaultAccessibilityLabel="Cardholder name",
    ~defaultTestID=CardTestIds.cardholderNameInputTestId,
    ~formWideUnstyled,
    ~formWideErrorDisplay,
    ~formWideLabelBehavior,
    ~defaultPlaceholder=labels.cardholderNamePlaceholder,
    ~defaultLabel=labels.cardholderNameFloatingLabel,
  )

let resolveCvc = (
  options: option<cvcOptions>,
  ~formWideUnstyled,
  ~formWideErrorDisplay,
  ~formWideLabelBehavior,
  ~labels: CardFormTypes.cardLabels,
) =>
  resolveWith(
    ~placeholder=options->Option.flatMap(o => o.placeholder),
    ~label=options->Option.flatMap(o => o.label),
    ~labelBehavior=options->Option.flatMap(o => o.labelBehavior),
    ~errorDisplay=options->Option.flatMap(o => o.errorDisplay),
    ~accessibilityLabel=options->Option.flatMap(o => o.accessibilityLabel),
    ~accessibilityHint=options->Option.flatMap(o => o.accessibilityHint),
    ~testID=options->Option.flatMap(o => o.testID),
    ~unstyled=options->Option.flatMap(o => o.unstyled),
    ~defaultAccessibilityLabel="Security code",
    ~defaultTestID=CardTestIds.cvcInputTestId,
    ~formWideUnstyled,
    ~formWideErrorDisplay,
    ~formWideLabelBehavior,
    ~defaultPlaceholder=labels.cvcPlaceholder,
    ~defaultLabel=labels.cvcFloatingLabel,
  )

/*
 * THE ONE RESOLUTION POINT, and the only place a brand-icon default lives:
 *
 *   field `cardBrandIcon`  →  form-wide `appearance.variables.cardBrandIcon`  →  `standard`
 *
 * `formWide` is already defaulted when it reaches here (resolved once in `VaultFormHost`), so this
 * is a total function of two inputs with exactly one outcome per pair — there is no combination of
 * public props that leaves the result undefined or order-dependent.
 */
let resolveBrandIconMode = (
  options: option<cardNumberOptions>,
  ~formWide: brandIconMode,
  ~unstyled: bool,
): brandIconMode =>
  unstyled ? #hidden : options->Option.flatMap(o => o.cardBrandIcon)->Option.getOr(formWide)

let cvcIconOf = (options: option<cvcOptions>, ~unstyled: bool) =>
  unstyled ? #hidden : options->Option.flatMap(o => o.cvcIcon)->Option.getOr(defaultCvcIcon)

/* The field-then-form precedence for `unstyled` itself, so no caller re-derives it. */
let unstyledFor = (fieldUnstyled: option<bool>, ~formWide: bool) =>
  fieldUnstyled->Option.getOr(formWide)

let cardNumberOf = (options: option<formFieldOptions>) =>
  options->Option.flatMap(o => o.cardNumber)

let cardExpiryOf = (options: option<formFieldOptions>) => options->Option.flatMap(o => o.cardExpiry)

let cardCvcOf = (options: option<formFieldOptions>) => options->Option.flatMap(o => o.cardCvc)

let cardholderNameOf = (options: option<formFieldOptions>) =>
  options->Option.flatMap(o => o.cardholderName)
