
@genType
type vaultEnvironment = VaultFormOptions.vaultEnvironment

@genType
type vaultSession = VaultFormOptions.vaultSession

@genType
type brandIconMode = VaultFormOptions.brandIconMode

@genType
type appearance = VaultFormOptions.appearance

@genType
type localisationLabels = VaultFormOptions.localisationLabels

@genType
type localisationMessages = VaultFormOptions.localisationMessages

@genType
type localisation = VaultFormOptions.localisation

@genType
type safeVaultErrorCode = VaultResult.safeVaultErrorCode

@genType
type safeVaultError = VaultResult.safeVaultError

@genType
type vaultPaymentResult = VaultResult.vaultPaymentResult

@genType
type vaultTokenizeResult = VaultResult.vaultTokenizeResult

@genType
type vaultFormHandle = VaultFormOptions.vaultFormHandle

@genType
type fieldStyles = CardFieldStyles.fieldStyles

@genType
type expiryStyles = CardFieldStyles.expiryStyles

@genType
type formFieldStyles = CardFieldStyles.formFieldStyles

@genType
type formFieldOptions = CardFieldOptions.formFieldOptions

@genType
type formLayout = CardFieldOptions.formLayout

@genType
type fieldArrangement = CardFieldOptions.fieldArrangement

@genType
type cardholderNameMode = CardFieldOptions.cardholderNameMode

@genType
type eligibilityConfig = VaultFormOptions.eligibilityConfig

@genType
type paymentCardSource = VaultCardSource.paymentCardSource

@genType
type cardSourceType = VaultCardSource.cardSourceType

@genType
let make = React.forwardRef((
  props: {
    /*
     * OPTIONAL. It backs `tokenize()` only. A form mounted without one still confirms payments —
     * `confirmPayment` reads its session from `cardSource`, and the direct source needs none.
     */
    "session": option<vaultSession>,
    "sdkAuthorization": option<string>,
    /* The web SDK's `vaultDetails` option: `{vaultType, vaultData: {sdkAuthorization}}`. */
    "vaultDetails": option<VaultDetails.vaultDetails>,
    "environment": vaultEnvironment,
    "appearance": option<appearance>,
    "locale": option<string>,
    "disabled": option<bool>,

    /*
     * `layout` and `fieldArrangement` replaced `splitCardFields: bool`. That boolean conflated
     * "do expiry and CVC share a row" with "are the borders joined", and could not express the
     * new default of three stacked, separately-bordered fields.
     */
    "layout": option<formLayout>,
    "fieldArrangement": option<fieldArrangement>,
    "localisation": option<localisation>,
    "accessible": option<bool>,
    "fieldStyles": option<formFieldStyles>,
    "fieldOptions": option<formFieldOptions>,
    /*
     * The card networks this merchant accepts. Used for the co-badge chooser and for the
     * "unsupported card" rule; empty or absent means no restriction is stated.
     */
    "enabledCardSchemes": option<array<string>>,
    "eligibility": option<eligibilityConfig>,
    /*
     * Where `tokenize()` posts the payment-method-session confirm. A self-hosted deployment sets
     * it; absent means the public-cloud host of `environment`. Validated like every other base.
     */
    "vaultEndpoint": option<VaultEndpoint.vaultEndpointConfig>,
    /*
     * `#collect` (the default, unchanged for existing merchants), `#external` when the host owns
     * the field and supplies the value on the confirm input, or `#omit` when there is no name.
     */
    "cardholderName": option<cardholderNameMode>,
    /*
     * Called with one snapshot on mount and again whenever the snapshot actually changes, by
     * structural comparison. Passing an inline arrow function is safe: the callback is held in a
     * ref, so its identity changing emits nothing.
     */
    /*
     * Strip every field back to a bare `TextInput` — no border, background, fixed height,
     * placeholder, label, icon or error line. Behaviour and accessibility survive. A field may
     * override this in either direction with its own `unstyled`.
     */
    "unstyled": option<bool>,
    "onReady": option<VaultPublicState.cardFormEvent => unit>,
    "onChange": option<VaultPublicState.cardFormChange => unit>,
  },
  ref,
) => {
  let host = VaultFormHost.useHost(
    ~session=props["session"]->Option.map(VaultFormOptions.sessionToJson),
    ~sdkAuthorization=props["sdkAuthorization"],
    ~vaultDetails=props["vaultDetails"],
    ~environment=props["environment"],
    ~appearance=props["appearance"],
    ~locale=props["locale"],
    ~localisation=props["localisation"],
    ~disabled=props["disabled"]->Option.getOr(false),
    ~accessible=props["accessible"],
    ~enabledCardSchemes=props["enabledCardSchemes"]->Option.getOr([]),
    ~eligibility=props["eligibility"],
    ~vaultEndpoint=props["vaultEndpoint"],
    ~cardholderNameMode=props["cardholderName"]->Option.getOr(#collect),
    ~onReady=props["onReady"],
    ~onChange=props["onChange"],
    ~unstyled=props["unstyled"]->Option.getOr(CardFieldOptions.defaultUnstyled),
    /*
     * A complete UI: the merchant renders nothing, so this form must show the customer what is
     * wrong. Unchanged behaviour — the composable surface is the one that changed.
     */
    ~defaultErrorDisplay=CardFieldOptions.defaultErrorDisplayReadyMade,
  )

  React.useImperativeHandle0(ref, () => {
    VaultFormOptions.tokenize: host.machinery.tokenize,
    confirmPayment: host.machinery.confirmPayment,

    reset: host.machinery.reset,
    focus: host.focusField,
  })

  <VaultWidgetContext.ContextProvider value={Some(host.contextValue)}>
    <CardFormView
      cardholderName=?{props["cardholderName"]}
      layout=?{props["layout"]}
      fieldArrangement=?{props["fieldArrangement"]}
      fieldStyles=?{props["fieldStyles"]}
      fieldOptions=?{props["fieldOptions"]}
    />
  </VaultWidgetContext.ContextProvider>
})
