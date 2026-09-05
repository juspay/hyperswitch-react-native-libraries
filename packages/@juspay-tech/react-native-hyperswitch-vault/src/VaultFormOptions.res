open ReactNative

@genType
/*
 * Declared here rather than re-exported from the internal transport. ReScript polymorphic variants
 * are structural, so this is the same type `VaultConfirm` uses — but the merchant-facing name now
 * lives in the merchant-facing module, and no public declaration points at the transport.
 */
type vaultEnvironment = [#production | #sandbox | #integ]

@genType.import(("./merchantTypes", "MerchantSession"))
type vaultSession

external sessionToJson: vaultSession => JSON.t = "%identity"

@genType
type brandIconMode = CardIcons.brandIconMode

/*
 * ── APPEARANCE, IN HYPERSWITCH-WEB'S SHAPE ───────────────────────────────────
 *
 * `appearance.variables.*` carries the web's variable names where the web has one — `colorPrimary`,
 * `colorText`, `colorDanger`, `colorTextPlaceholder`, `colorBackground`, `borderColor`,
 * `borderRadius`, `fontFamily`, `inputFieldHeight` — typed for this platform (a number of points
 * where the web takes a CSS string). The members after them have no web equivalent and are this
 * library's own. `appearance.labels` is the web's label mode, applied to every field.
 *
 * The web's `theme`, `rules` (CSS selectors), `innerLayout` and `fonts` are CSS concepts with no
 * React Native analogue and are deliberately absent.
 */
@genType
type appearanceVariables = {
  colorPrimary?: string,
  colorText?: string,
  colorDanger?: string,
  colorTextPlaceholder?: string,
  colorBackground?: string,
  borderColor?: string,
  borderRadius?: float,
  fontFamily?: string,
  inputFieldHeight?: float,
  /* This library's additions. */
  borderWidth?: float,
  gap?: float,
  fontScale?: float,
  placeholderTextSizeAdjust?: float,
  errorTextSizeAdjust?: float,
  errorMessageSpacing?: float,
  /* The form-wide brand-icon default; a card-number field's own `cardBrandIcon` overrides it. */
  cardBrandIcon?: brandIconMode,
}

@genType
type appearance = {
  variables?: appearanceVariables,
  /* `above` | `floating` | `never`, as on the web. Absent => `floating`. */
  labels?: CardFieldOptions.labelBehavior,
}

/*
 * ── LOCALISATION ──────────────────────────────────────────────────────────────
 *
 * `locale` (on the form) selects one of the sdk-utils bundles the web SDK also ships — the same
 * strings, in the same languages. `localisation` is this library's override layer on top of it:
 * a merchant may replace any label, placeholder or validation message, and force the direction.
 */
@genType
type localisationLabels = {
  cardNumberPlaceholder?: string,
  cardNumberFloatingLabel?: string,
  expiryPlaceholder?: string,
  expiryFloatingLabel?: string,
  cvcPlaceholder?: string,
  cvcFloatingLabel?: string,
  cardholderNamePlaceholder?: string,
  cardholderNameFloatingLabel?: string,
  /* Heading of the co-badge network chooser. */
  selectCardBrandLabel?: string,
}

@genType
type localisationMessages = {
  cardNumberRequired?: string,
  cardNumberInvalid?: string,
  expiryRequired?: string,
  expiryInvalid?: string,
  cvcRequired?: string,
  cvcInvalid?: string,
  /* The chosen or detected network is not one the merchant accepts. */
  unsupportedCard?: string,
  /* The backend's eligibility step declined this card. */
  cardNotEligible?: string,
}

@genType
type localisation = {
  labels?: localisationLabels,
  validationMessages?: localisationMessages,
  isRtl?: bool,
}

@genType
type safeVaultErrorCode = VaultResult.safeVaultErrorCode

@genType
type safeVaultError = VaultResult.safeVaultError

@genType
type vaultPaymentResult = VaultResult.vaultPaymentResult

@genType
type vaultTokenizeResult = VaultResult.vaultTokenizeResult

@genType
type paymentConfirmInput = VaultFormCoordinator.paymentConfirmInput

@genType
type vaultField = VaultPublicState.elementType

/*
 * ── LIVE ELIGIBILITY (optional) ──────────────────────────────────────────────
 *
 * Eligibility asks the backend whether a BIN is accepted for this payment, so the request needs the
 * PAN — which now only the library has. Supplying this prop lets the library run that check AS THE
 * CUSTOMER TYPES and show the "card not accepted" message inline, which is what the classic form
 * did.
 *
 * It is optional and purely about WHEN the check happens. `confirmPayment` re-checks before it
 * confirms whether or not this prop was given, so omitting it costs the inline message, never the
 * enforcement.
 *
 * Every field is non-card. The credential is the same PAYMENT credential the final confirm uses,
 * in either of the two shapes Hyperswitch accepts: the payment-intent `sdkAuthorization`
 * (preferred), or the legacy `publishableKey` + `clientSecret` pair. `sdkAuthorization` wins when
 * both are given; with neither shape complete the probe simply does not run.
 */
@genType
type eligibilityConfig = {
  paymentId: string,
  sdkAuthorization?: string,
  publishableKey?: string,
  clientSecret?: string,
  appId?: string,
  endpoint?: VaultEndpoint.vaultEndpointConfig,
}

/*
 * TWO explicit operations, not one ambiguous `submit()`. Which one you call decides what can come
 * back: `tokenize` is the only route to a token, and `confirmPayment` is the only route that
 * charges anything. Neither throws for a documented outcome.
 */
@genType
type vaultFormHandle = {
  /*
   * Flow 1 — mint a payment-method token and stop. Takes no input: there is no payment to
   * configure, and nothing here charges the customer. With one CVC field mounted with `savedCard`,
   * it updates that saved card's CVC instead and resolves to the token the response carries.
   */
  tokenize: unit => promise<vaultTokenizeResult>,
  /*
   * Flow 2 — mint a token internally, then confirm the payment with it. Takes NON-CARD inputs only
   * and resolves to a navigation decision. The intermediate token is never returned.
   */
  confirmPayment: paymentConfirmInput => promise<vaultPaymentResult>,
  reset: unit => unit,
  focus: vaultField => unit,
}

let emptyStyle = Style.s({})

let variablesOf = (appearance: option<appearance>) =>
  appearance->Option.flatMap(a => a.variables)

let buildTheme = (appearance: option<appearance>): CardFormTypes.cardTheme => {
  let variables = variablesOf(appearance)
  let pick = (selector, fallback) => variables->Option.flatMap(selector)->Option.getOr(fallback)

  let text = pick(v => v.colorText, "#1A1A1A")
  {
    borderWidth: pick(v => v.borderWidth, 1.),
    borderRadius: pick(v => v.borderRadius, 8.),
    gap: pick(v => v.gap, 12.),
    inputHeight: pick(v => v.inputFieldHeight, 48.),
    fontFamily: pick(v => v.fontFamily, "System"),
    fontScale: pick(v => v.fontScale, 1.),
    placeholderTextSizeAdjust: pick(v => v.placeholderTextSizeAdjust, 0.),
    placeholderColor: pick(v => v.colorTextPlaceholder, "#6B7280"),
    primaryColor: pick(v => v.colorPrimary, "#0570DE"),
    dangerColor: pick(v => v.colorDanger, "#DF1B41"),
    textColor: text,
    inputBackground: pick(v => v.colorBackground, "#FFFFFF"),
    dividerColor: pick(v => v.borderColor, "#E6E6E6"),
    errorBorderColor: pick(v => v.colorDanger, "#DF1B41"),
    normalBorderColor: pick(v => v.borderColor, "#E6E6E6"),
    bgStyle: emptyStyle,
    shadowStyle: emptyStyle,
  }
}

let errorTextSizeAdjustOf = (appearance: option<appearance>) =>
  variablesOf(appearance)->Option.flatMap(v => v.errorTextSizeAdjust)->Option.getOr(0.)

let errorMessageSpacingOf = (appearance: option<appearance>) =>
  variablesOf(appearance)->Option.flatMap(v => v.errorMessageSpacing)->Option.getOr(4.)

let cardBrandIconOf = (appearance: option<appearance>): brandIconMode =>
  variablesOf(appearance)
  ->Option.flatMap(v => v.cardBrandIcon)
  ->Option.getOr(CardFieldOptions.defaultBrandIconMode)

let labelsModeOf = (appearance: option<appearance>): CardFieldOptions.labelBehavior =>
  appearance->Option.flatMap(a => a.labels)->Option.getOr(CardFieldOptions.defaultLabelBehavior)

/*
 * The library's strings. English keeps the strings this library has always shown — a merchant who
 * set nothing sees exactly what they saw before `locale` existed. Any other locale reads the
 * sdk-utils bundle the web SDK also ships, so `locale: "fr"` on both SDKs reads the same French.
 */
let englishLabels: CardFormTypes.cardLabels = {
  cardNumberPlaceholder: "Card number",
  cardNumberFloatingLabel: "Card number",
  expiryPlaceholder: "MM / YY",
  expiryFloatingLabel: "Expiry",
  cvcPlaceholder: "CVC",
  cvcFloatingLabel: "CVC",
  cardholderNamePlaceholder: "Name on card",
  cardholderNameFloatingLabel: "Name on card",
  notEligibleText: LocaleBundles.english.cardNotEligibleText,
  selectCardBrandLabel: LocaleBundles.english.selectCardBrand,
  isRtl: false,
}

let labelsFromBundle = (bundle: LocaleBundles.bundle): CardFormTypes.cardLabels =>
  LocaleBundles.isEnglish(bundle)
    ? englishLabels
    : {
        cardNumberPlaceholder: bundle.cardNumberLabel,
        cardNumberFloatingLabel: bundle.cardNumberLabel,
        expiryPlaceholder: bundle.expiryPlaceholder,
        expiryFloatingLabel: bundle.validThruText,
        cvcPlaceholder: bundle.cvcTextLabel,
        cvcFloatingLabel: bundle.cvcTextLabel,
        cardholderNamePlaceholder: bundle.cardHolderName,
        cardholderNameFloatingLabel: bundle.cardHolderName,
        notEligibleText: bundle.cardNotEligibleText,
        selectCardBrandLabel: bundle.selectCardBrand,
        isRtl: bundle.localeDirection === "rtl",
      }

let defaultLabels = englishLabels

type resolvedMessages = {
  cardNumberRequired: string,
  cardNumberInvalid: string,
  expiryRequired: string,
  expiryInvalid: string,
  cvcRequired: string,
  cvcInvalid: string,
  unsupportedCard: string,
  cardNotEligible: string,
}

let resolveLabels = (
  localisation: option<localisation>,
  ~bundle: LocaleBundles.bundle,
): CardFormTypes.cardLabels => {
  let base = labelsFromBundle(bundle)
  let labels = localisation->Option.flatMap(l => l.labels)
  let pick = (selector, fallback) => labels->Option.flatMap(selector)->Option.getOr(fallback)
  {
    cardNumberPlaceholder: pick(l => l.cardNumberPlaceholder, base.cardNumberPlaceholder),
    cardNumberFloatingLabel: pick(l => l.cardNumberFloatingLabel, base.cardNumberFloatingLabel),
    expiryPlaceholder: pick(l => l.expiryPlaceholder, base.expiryPlaceholder),
    expiryFloatingLabel: pick(l => l.expiryFloatingLabel, base.expiryFloatingLabel),
    cvcPlaceholder: pick(l => l.cvcPlaceholder, base.cvcPlaceholder),
    cvcFloatingLabel: pick(l => l.cvcFloatingLabel, base.cvcFloatingLabel),
    cardholderNamePlaceholder: pick(
      l => l.cardholderNamePlaceholder,
      base.cardholderNamePlaceholder,
    ),
    cardholderNameFloatingLabel: pick(
      l => l.cardholderNameFloatingLabel,
      base.cardholderNameFloatingLabel,
    ),
    notEligibleText: base.notEligibleText,
    selectCardBrandLabel: pick(l => l.selectCardBrandLabel, base.selectCardBrandLabel),
    isRtl: localisation->Option.flatMap(l => l.isRtl)->Option.getOr(base.isRtl),
  }
}

let resolveMessages = (
  localisation: option<localisation>,
  ~bundle: LocaleBundles.bundle,
): resolvedMessages => {
  let messages = localisation->Option.flatMap(l => l.validationMessages)
  let pick = (selector, fallback) => messages->Option.flatMap(selector)->Option.getOr(fallback)
  {
    cardNumberRequired: pick(m => m.cardNumberRequired, bundle.cardNumberEmptyText),
    cardNumberInvalid: pick(m => m.cardNumberInvalid, bundle.inValidCardErrorText),
    expiryRequired: pick(m => m.expiryRequired, bundle.cardExpiryDateEmptyText),
    expiryInvalid: pick(m => m.expiryInvalid, bundle.inValidExpiryErrorText),
    cvcRequired: pick(m => m.cvcRequired, bundle.cvcNumberEmptyText),
    cvcInvalid: pick(m => m.cvcInvalid, bundle.inValidCVCErrorText),
    unsupportedCard: pick(m => m.unsupportedCard, bundle.unsupportedCardErrorText),
    cardNotEligible: pick(m => m.cardNotEligible, bundle.cardNotEligibleText),
  }
}

/*
 * The co-badge network rule, reproducing `Validation.CardNetwork`: the network in force must be one
 * the merchant accepts. `None` when the merchant supplied no scheme list, which is the common case.
 * The list arrives already canonicalised (`CardNetworkNames.normaliseList`).
 */
let makeNetworkValidator = (
  ~enabledCardSchemes: array<string>,
  messages: resolvedMessages,
): option<option<string> => option<string>> =>
  enabledCardSchemes->Array.length === 0
    ? None
    : Some(
        (value: option<string>) => {
          let network = value->Option.getOr("")
          /*
           * An empty network is "not detected yet", not "unsupported" — the card-number validator
           * already owns the empty and malformed cases, and reporting both would show the customer
           * two errors for one blank field.
           */
          network->String.length === 0 ||
          enabledCardSchemes->Array.some(scheme => scheme === network)
            ? None
            : Some(messages.unsupportedCard)
        },
      )

let makeCardNumberValidator = (messages: resolvedMessages) => (value: option<string>) => {
  let value = value->Option.getOr("")
  if value->String.length === 0 {
    Some(messages.cardNumberRequired)
  } else {
    let cardBrand = value->Validation.getCardBrand
    let formattedNumber = Validation.formatCardNumber(value, cardBrand->Validation.cardType)
    Validation.cardValid(formattedNumber, cardBrand) ? None : Some(messages.cardNumberInvalid)
  }
}

let makeExpiryValidatorWith = (messages: resolvedMessages) => (expiry: string) => (
  _: option<string>,
) =>
  if expiry->String.length === 0 {
    Some(messages.expiryRequired)
  } else if Validation.checkCardExpiry(expiry) {
    None
  } else {
    Some(messages.expiryInvalid)
  }

let makeCvcValidatorWith = (messages: resolvedMessages) => (cardBrand: string) => (
  value: option<string>,
) => {
  let value = value->Option.getOr("")
  if value->String.length === 0 {
    Some(messages.cvcRequired)
  } else if Validation.checkCardCVC(value, cardBrand) {
    None
  } else {
    Some(messages.cvcInvalid)
  }
}
