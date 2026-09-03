open ReactNative

/*
 * `HyperswitchVaultSavedCardForm` (ADR-0008): one CVC field for a card the merchant has already
 * saved, and one operation that returns a token.
 *
 * ── WHAT THIS RENDERS ──────────────────────────────────────────────────────────
 *
 * `CardFields.Cvc` — the IMPLEMENTATION the new-card form renders, pixel for pixel — fed from a
 * CVC-only controller instead of the full card controller. Not `CardCVCField`, the widget: that
 * needs `VaultWidgetContext`, which carries a whole `VaultCardController.controller`, and standing
 * up a PAN/expiry/co-badge/eligibility/scan reducer to draw one field would be the wrong trade.
 *
 * The component takes NO children. It renders its own field, so a merchant cannot mount zero CVC
 * fields or two, and there is no presence gate because there is nothing to police.
 *
 * ── WHAT IT EMITS ──────────────────────────────────────────────────────────────
 *
 * `onStateChange` carries the EXISTING `VaultCVCState`, built by the existing derivation. No new
 * type, no new callback name, no `canSubmit`: `state.valid` already answers "may I enable Pay?".
 * `VaultCVCState` structurally has no `brand` member, so the network hint cannot be reflected back,
 * and no member carries the value or its length.
 *
 * ── WHAT IT DELIBERATELY DOES NOT TAKE ─────────────────────────────────────────
 *
 * `requires_cvv`: by the time this component is on screen the merchant has read that flag off
 * `list-payment-methods` and decided to mount it. A second copy would be a second place to disagree.
 */

@genType
type savedCardHandle = {
  /* Validates, sends the CVC to the vault, resolves to the token the RESPONSE carries. */
  updateSavedPaymentMethod: unit => promise<VaultResult.vaultTokenizeResult>,
  /* Clears the CVC and abandons any request in flight. */
  reset: unit => unit,
  /* One field, so no argument. */
  focus: unit => unit,
  blur: unit => unit,
}

@genType
let make = React.forwardRef((
  props: {
    /* REQUIRED. The same session the merchant called `list-payment-methods` with. */
    "session": VaultFormOptions.vaultSession,
    /*
     * REQUIRED, and not inferable: the host comes from `VaultEndpoint.resolveVaultBaseUrl` and the
     * session carries none.
     */
    "environment": VaultFormOptions.vaultEnvironment,
    /* REQUIRED. The token of ONE entry of `customer_payment_methods[]` from that same session. */
    "paymentMethodToken": string,
    /*
     * OPTIONAL, a hint. Selects the CVC length rule only. `card_network` as `list-payment-methods`
     * spells it, or a common merchant spelling; absent or unrecognised means three OR four digits
     * are accepted, so `state.valid` becomes true one digit early on an Amex card. Pass it.
     */
    "cardNetwork": option<string>,
    /* OPTIONAL. A self-hosted vault host. Validated like every other base. */
    "vaultEndpoint": option<VaultEndpoint.vaultEndpointConfig>,
    "appearance": option<VaultFormOptions.appearance>,
    "cvcOptions": option<CardFieldOptions.cvcOptions>,
    "cvcStyles": option<CardFieldStyles.fieldStyles>,
    /* The outer box only. The field's own slots are `cvcStyles`. */
    "containerStyle": option<CardFieldStyles.viewStyleProp>,
    /*
     * Called with one snapshot on mount and again whenever it actually changes, by structural
     * comparison. Absent means nothing is derived at all.
     */
    "onStateChange": option<VaultPublicState.cvcState => unit>,
  },
  ref,
) => {
  let session = props["session"]->VaultFormOptions.sessionToJson
  let sessionState = React.useMemo1(() => session->VaultFormCoordinator.readSession, [session])

  let appearance = props["appearance"]
  let theme = React.useMemo1(() => appearance->VaultFormOptions.buildTheme, [appearance])
  let errorFontSize =
    (12. +.
    appearance
    ->Option.flatMap(a => a.VaultFormOptions.errorTextSizeAdjust)
    ->Option.getOr(0.)) *. theme.fontScale
  let errorSpacing =
    appearance->Option.flatMap(a => a.VaultFormOptions.errorMessageSpacing)->Option.getOr(4.)

  /* The library's own strings and messages: this component takes no `localisation`. */
  let labels = VaultFormOptions.defaultLabels
  let validator = React.useMemo0(() =>
    VaultFormOptions.makeCvcValidatorWith(VaultFormOptions.resolveMessages(None))
  )

  let brand = SavedCardController.normaliseNetwork(props["cardNetwork"])
  let controller = SavedCardController.use(~validator, ~brand)

  let machinery = SavedCardCoordinator.useMachinery(
    ~sessionState,
    ~environment=props["environment"],
    ~vaultEndpoint=props["vaultEndpoint"],
    ~paymentMethodToken=props["paymentMethodToken"],
    ~isValid=controller.isValidNow,
    ~cvc=controller.cvc,
    ~markSubmitAttempted=controller.markSubmitAttempted,
    ~clearLocal=controller.reset,
  )

  VaultStateEmitter.use(
    ~build=controller.publicSnapshot,
    ~equal=VaultPublicState.cvcEq,
    ~notify=props["onStateChange"],
  )

  React.useImperativeHandle0(ref, () => {
    updateSavedPaymentMethod: machinery.updateSavedPaymentMethod,
    reset: machinery.reset,
    focus: () => VaultCardController.focusRef(controller.cvcRef),
    blur: () => VaultCardController.blurRef(controller.cvcRef),
  })

  let cvcOptions = props["cvcOptions"]
  let cvcStyles = props["cvcStyles"]
  let resolved = CardFieldOptions.resolveCvc(
    cvcOptions,
    ~formWideUnstyled=CardFieldOptions.defaultUnstyled,
    ~labels,
  )

  let renderError = message =>
    <VaultWidgetContext.ErrorText
      message theme errorFontSize errorSpacing errorStyle=?{cvcStyles->CardFieldStyles.errorOf}
    />

  let common: CardFields.common = {
    theme,
    isProcessing: machinery.isSubmitting,
    editable: !machinery.isSubmitting,
    accessible: None,
  }

  /* The same glyph the new-card CVC shows, switched off by the same option. */
  let iconRight = switch CardFieldOptions.cvcIconOf(cvcOptions, ~unstyled=resolved.unstyled) {
  | #none => CardInput.NoIcon
  | #default =>
    CardInput.CustomIcon(
      <View
        style={Style.s({
          height: 46.->Style.dp,
          display: #flex,
          flexDirection: #row,
          justifyContent: #center,
          alignItems: #center,
        })}>
        <CardIcons.Cvc size=32. />
      </View>,
    )
  }

  <View
    style=?{props["containerStyle"]->Option.map(style =>
      Style.s({})->CardFieldStyles.withView(Some(style))
    )}>
    <CardFields.Cvc
      styles=?cvcStyles
      value=controller.value
      onChange=controller.onChange
      brand
      onFocus=controller.onFocus
      onBlur=controller.onBlur
      error=?controller.visibleError
      isValid=controller.fieldOk
      renderError
      options=resolved
      common
      reference=controller.cvcRef
      borderTopWidth=theme.borderWidth
      borderLeftWidth=theme.borderWidth
      borderTopLeftRadius=theme.borderRadius
      borderTopRightRadius=theme.borderRadius
      borderBottomLeftRadius=theme.borderRadius
      borderBottomRightRadius=theme.borderRadius
      borderBottomWidth=theme.borderWidth
      borderRightWidth=theme.borderWidth
      iconRight
    />
  </View>
})
