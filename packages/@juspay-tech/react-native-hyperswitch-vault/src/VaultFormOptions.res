
open ReactNative

@genType
/*
 * Declared here rather than re-exported from the internal transport. ReScript polymorphic variants
 * are structural, so this is the same type `VaultConfirm` uses — but the merchant-facing name now
 * lives in the merchant-facing module, and no public declaration points at the transport.
 */
type vaultEnvironment = [#production | #sandbox | #integration]

@genType.import(("./merchantTypes", "MerchantSession"))
type vaultSession

external sessionToJson: vaultSession => JSON.t = "%identity"

@genType
type brandIconMode = CardIcons.brandIconMode

@genType
type appearance = {
  primaryColor?: string,
  textColor?: string,
  errorColor?: string,
  placeholderColor?: string,
  backgroundColor?: string,
  borderColor?: string,
  borderRadius?: float,
  borderWidth?: float,
  fontFamily?: string,
  inputHeight?: float,

  gap?: float,

  fontScale?: float,

  placeholderTextSizeAdjust?: float,

  errorTextSizeAdjust?: float,

  errorMessageSpacing?: float,

  brandIconMode?: brandIconMode,
}

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
type vaultField = [#cardNumber | #expiry | #cvc | #cardholderName]

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
   * configure, and nothing here charges the customer.
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

let buildTheme = (appearance: option<appearance>): CardFormTypes.cardTheme => {
  let pick = (selector, fallback) => appearance->Option.flatMap(selector)->Option.getOr(fallback)

  let text = pick(a => a.textColor, "#1A1A1A")
  {
    borderWidth: pick(a => a.borderWidth, 1.),
    borderRadius: pick(a => a.borderRadius, 8.),
    gap: pick(a => a.gap, 12.),
    inputHeight: pick(a => a.inputHeight, 48.),
    fontFamily: pick(a => a.fontFamily, "System"),
    fontScale: pick(a => a.fontScale, 1.),
    placeholderTextSizeAdjust: pick(a => a.placeholderTextSizeAdjust, 0.),
    placeholderColor: pick(a => a.placeholderColor, "#6B7280"),
    primaryColor: pick(a => a.primaryColor, "#0570DE"),
    dangerColor: pick(a => a.errorColor, "#DF1B41"),
    textColor: text,
    inputBackground: pick(a => a.backgroundColor, "#FFFFFF"),
    dividerColor: pick(a => a.borderColor, "#E6E6E6"),
    errorBorderColor: pick(a => a.errorColor, "#DF1B41"),
    normalBorderColor: pick(a => a.borderColor, "#E6E6E6"),
    bgStyle: emptyStyle,
    shadowStyle: emptyStyle,
  }
}

let defaultLabels: CardFormTypes.cardLabels = {
  cardNumberPlaceholder: "Card number",
  cardNumberFloatingLabel: "Card number",
  expiryPlaceholder: "MM / YY",
  expiryFloatingLabel: "Expiry",
  cvcPlaceholder: "CVC",
  cvcFloatingLabel: "CVC",
  /* "Name on card" is the string the README already uses for this field. */
  cardholderNamePlaceholder: "Name on card",
  cardholderNameFloatingLabel: "Name on card",

  notEligibleText: LocaleDataType.defaultLocale.cardNotEligibleText,
  selectCardBrandLabel: LocaleDataType.defaultLocale.selectCardBrand,
  isRtl: false,
}

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

let resolveLabels = (localisation: option<localisation>): CardFormTypes.cardLabels => {
  let labels = localisation->Option.flatMap(l => l.labels)
  let pick = (selector, fallback) => labels->Option.flatMap(selector)->Option.getOr(fallback)
  {
    cardNumberPlaceholder: pick(l => l.cardNumberPlaceholder, defaultLabels.cardNumberPlaceholder),
    cardNumberFloatingLabel: pick(
      l => l.cardNumberFloatingLabel,
      defaultLabels.cardNumberFloatingLabel,
    ),
    expiryPlaceholder: pick(l => l.expiryPlaceholder, defaultLabels.expiryPlaceholder),
    expiryFloatingLabel: pick(l => l.expiryFloatingLabel, defaultLabels.expiryFloatingLabel),
    cvcPlaceholder: pick(l => l.cvcPlaceholder, defaultLabels.cvcPlaceholder),
    cvcFloatingLabel: pick(l => l.cvcFloatingLabel, defaultLabels.cvcFloatingLabel),
    cardholderNamePlaceholder: pick(
      l => l.cardholderNamePlaceholder,
      defaultLabels.cardholderNamePlaceholder,
    ),
    cardholderNameFloatingLabel: pick(
      l => l.cardholderNameFloatingLabel,
      defaultLabels.cardholderNameFloatingLabel,
    ),
    notEligibleText: defaultLabels.notEligibleText,
    selectCardBrandLabel: pick(l => l.selectCardBrandLabel, defaultLabels.selectCardBrandLabel),
    isRtl: localisation->Option.flatMap(l => l.isRtl)->Option.getOr(defaultLabels.isRtl),
  }
}

let resolveMessages = (localisation: option<localisation>): resolvedMessages => {
  let locale = LocaleDataType.defaultLocale
  let messages = localisation->Option.flatMap(l => l.validationMessages)
  let pick = (selector, fallback) => messages->Option.flatMap(selector)->Option.getOr(fallback)
  {
    cardNumberRequired: pick(m => m.cardNumberRequired, locale.cardNumberEmptyText),
    cardNumberInvalid: pick(m => m.cardNumberInvalid, locale.inValidCardErrorText),
    expiryRequired: pick(m => m.expiryRequired, locale.cardExpiryDateEmptyText),
    expiryInvalid: pick(m => m.expiryInvalid, locale.inValidExpiryErrorText),
    cvcRequired: pick(m => m.cvcRequired, locale.cvcNumberEmptyText),
    cvcInvalid: pick(m => m.cvcInvalid, locale.inValidCVCErrorText),
    unsupportedCard: pick(m => m.unsupportedCard, locale.unsupportedCardErrorText),
    cardNotEligible: pick(m => m.cardNotEligible, locale.cardNotEligibleText),
  }
}

/*
 * The co-badge network rule, reproducing `Validation.CardNetwork`: the network in force must be one
 * the merchant accepts.
 *
 * `None` when the merchant supplied no scheme list, which is the common case — with nothing to
 * check against, every detected brand passes, and adding a validator that can never fail would only
 * cost a comparison per keystroke.
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

  let makeExpiryValidatorWith = (messages: resolvedMessages) => (expiry: string) => (_: option<string>) =>
    if expiry->String.length === 0 {
      Some(messages.expiryRequired)
    } else if Validation.checkCardExpiry(expiry) {
      None
    } else {
      Some(messages.expiryInvalid)
    }

  let makeCvcValidatorWith = (messages: resolvedMessages) => (cardBrand: string) => (value: option<string>) => {
    let value = value->Option.getOr("")
    if value->String.length === 0 {
      Some(messages.cvcRequired)
    } else if Validation.checkCardCVC(value, cardBrand) {
      None
    } else {
      Some(messages.cvcInvalid)
    }
  }
