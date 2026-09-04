open ReactNative

let useBinding = (
  ctx: VaultWidgetContext.contextValue,
  kind: VaultCardController.widgetKind,
  /* Merchant `styles.error`, forwarded to the field's own error message. */
  ~errorStyle: option<CardFieldStyles.textStyleProp>=?,
) => {
  let register = ctx.controller.register
  React.useEffect0(() => Some(register(kind)))
  message =>
    <VaultWidgetContext.ErrorText
      message
      theme=ctx.theme
      errorFontSize=ctx.errorFontSize
      errorSpacing=ctx.errorSpacing
      ?errorStyle
    />
}

/*
 * The web's `focus` / `blur` events, fired from the same handler that updates the reducer, so the
 * merchant hears about the transition in the same tick the library acts on it.
 */
let fire = (listener: option<VaultPublicState.fieldEvent => unit>, elementType) =>
  switch listener {
  | Some(fn) => VaultStateEmitter.notifySafely(fn, {VaultPublicState.elementType: elementType})
  | None => ()
  }

let resolveArgs = (ctx: VaultWidgetContext.contextValue) => (
  ctx.unstyled,
  ctx.defaultErrorDisplay,
  ctx.defaultLabelBehavior,
)

module Number = {
  @react.component
  let make = (
    ~ctx: VaultWidgetContext.contextValue,
    ~renderError: option<string => React.element>=?,
    ~iconRight: CardInput.iconType=CardInput.NoIcon,
    ~borderBottomWidth: option<float>=?,
    ~borderBottomLeftRadius: option<float>=?,
    ~borderBottomRightRadius: option<float>=?,
    /* Merchant per-field style slots. None => byte-identical to the unstyled render. */
    ~styles: option<CardFieldStyles.fieldStyles>=?,
    /* Which visual elements exist. */
    ~options: option<CardFieldOptions.cardNumberOptions>=?,
    ~onFocus: option<VaultPublicState.fieldEvent => unit>=?,
    ~onBlur: option<VaultPublicState.fieldEvent => unit>=?,
  ) => {
    let (formWideUnstyled, formWideErrorDisplay, formWideLabelBehavior) = resolveArgs(ctx)
    let resolved = CardFieldOptions.resolveCardNumber(
      options,
      ~formWideUnstyled,
      ~formWideErrorDisplay,
      ~formWideLabelBehavior,
      ~labels=ctx.labels,
    )
    let defaultRenderError = useBinding(
      ctx,
      VaultCardController.CardNumberKind,
      ~errorStyle=?styles->CardFieldStyles.errorOf,
    )
    let controller = ctx.controller
    <CardFields.Number
      ?styles
      value=controller.values.cardNumber
      onChange=controller.onNumberChange
      currentBrand=controller.values.brand
      onFocus={() => {
        controller.onFocus(#cardNumber)
        fire(onFocus, #cardNumber)
      }}
      onBlur={() => {
        controller.onBlur(#cardNumber)
        fire(onBlur, #cardNumber)
      }}
      onBackspace={action => controller.onBackspace(#cardNumber, action)}
      error=?controller.visibleErrors.cardNumber
      isValid=controller.fieldOk.cardNumber
      renderError={renderError->Option.getOr(defaultRenderError)}
      options=resolved
      common={ctx->VaultWidgetContext.commonFor}
      onAnalytics=ctx.onAnalytics
      reference=controller.cardRef
      iconRight
      ?borderBottomWidth
      ?borderBottomLeftRadius
      ?borderBottomRightRadius
    />
  }
}

module CardholderName = {
  @react.component
  let make = (
    ~ctx: VaultWidgetContext.contextValue,
    ~renderError: option<string => React.element>=?,
    ~borderBottomWidth: option<float>=?,
    ~borderBottomLeftRadius: option<float>=?,
    ~borderBottomRightRadius: option<float>=?,
    ~styles: option<CardFieldStyles.fieldStyles>=?,
    ~options: option<CardFieldOptions.cardholderNameOptions>=?,
    ~onFocus: option<VaultPublicState.fieldEvent => unit>=?,
    ~onBlur: option<VaultPublicState.fieldEvent => unit>=?,
  ) => {
    let (formWideUnstyled, formWideErrorDisplay, formWideLabelBehavior) = resolveArgs(ctx)
    let resolved = CardFieldOptions.resolveCardholderName(
      options,
      ~formWideUnstyled,
      ~formWideErrorDisplay,
      ~formWideLabelBehavior,
      ~labels=ctx.labels,
    )
    /*
     * Registered under a kind `VaultFormHost.requiredKinds` does not list — so the presence gate
     * does not demand it and a custom layout that omits it still submits. It is registered because
     * the form state has to report whether this field exists, and in a custom layout only the
     * merchant knows.
     */
    let controller = ctx.controller
    React.useEffect0(() => Some(controller.register(VaultCardController.CardholderNameKind)))
    <CardFields.CardholderName
      ?styles
      value=controller.values.cardholderName
      onChange=controller.onCardholderNameChange
      onFocus={() => {
        controller.onFocus(#cardholderName)
        fire(onFocus, #cardholderName)
      }}
      onBlur={() => {
        controller.onBlur(#cardholderName)
        fire(onBlur, #cardholderName)
      }}
      renderError=?renderError
      options=resolved
      common={ctx->VaultWidgetContext.commonFor}
      onAnalytics=ctx.onAnalytics
      reference=controller.cardholderRef
      ?borderBottomWidth
      ?borderBottomLeftRadius
      ?borderBottomRightRadius
    />
  }
}

module Expiry = {
  @react.component
  let make = (
    ~ctx: VaultWidgetContext.contextValue,
    ~renderError: option<string => React.element>=?,
    ~borderTopWidth: option<float>=?,
    ~borderRightWidth: option<float>=?,
    ~borderTopLeftRadius: option<float>=?,
    ~borderTopRightRadius: option<float>=?,
    ~borderBottomRightRadius: option<float>=?,
    ~borderBottomWidth: option<float>=?,
    ~borderBottomLeftRadius: option<float>=?,
    /* Widened from `expiryStyles` by the caller; `accessory` is absent for this field. */
    ~styles: option<CardFieldStyles.fieldStyles>=?,
    ~options: option<CardFieldOptions.expiryOptions>=?,
    ~onFocus: option<VaultPublicState.fieldEvent => unit>=?,
    ~onBlur: option<VaultPublicState.fieldEvent => unit>=?,
  ) => {
    let (formWideUnstyled, formWideErrorDisplay, formWideLabelBehavior) = resolveArgs(ctx)
    let resolved = CardFieldOptions.resolveExpiry(
      options,
      ~formWideUnstyled,
      ~formWideErrorDisplay,
      ~formWideLabelBehavior,
      ~labels=ctx.labels,
    )
    let defaultRenderError = useBinding(
      ctx,
      VaultCardController.ExpiryKind,
      ~errorStyle=?styles->CardFieldStyles.errorOf,
    )
    let controller = ctx.controller
    <CardFields.Expiry
      ?styles
      value=controller.values.expiryDisplay
      onChange=controller.onExpiryChange
      onFocus={() => {
        controller.onFocus(#cardExpiry)
        fire(onFocus, #cardExpiry)
      }}
      onBlur={() => {
        controller.onBlur(#cardExpiry)
        fire(onBlur, #cardExpiry)
      }}
      onBackspace={action => controller.onBackspace(#cardExpiry, action)}
      error=?controller.visibleErrors.cardExpiry
      isValid=controller.fieldOk.cardExpiry
      renderError={renderError->Option.getOr(defaultRenderError)}
      options=resolved
      common={ctx->VaultWidgetContext.commonFor}
      onAnalytics=ctx.onAnalytics
      reference=controller.expiryRef
      ?borderTopWidth
      ?borderRightWidth
      ?borderTopLeftRadius
      ?borderTopRightRadius
      ?borderBottomRightRadius
      ?borderBottomWidth
      ?borderBottomLeftRadius
    />
  }
}

module Cvc = {
  @react.component
  let make = (
    ~ctx: VaultWidgetContext.contextValue,
    ~renderError: option<string => React.element>=?,
    ~borderTopWidth: option<float>=?,
    ~borderLeftWidth: option<float>=?,
    ~borderTopLeftRadius: option<float>=?,
    ~borderTopRightRadius: option<float>=?,
    ~borderBottomLeftRadius: option<float>=?,
    /* Merchant per-field style slots. None => byte-identical to the unstyled render. */
    ~styles: option<CardFieldStyles.fieldStyles>=?,
    ~options: option<CardFieldOptions.cvcOptions>=?,
    /* The web's `savedCard` create-option: turns a lone CVC field into a saved card's CVC update. */
    ~savedCard: option<CardFieldOptions.savedCard>=?,
    ~onFocus: option<VaultPublicState.fieldEvent => unit>=?,
    ~onBlur: option<VaultPublicState.fieldEvent => unit>=?,
  ) => {
    let (formWideUnstyled, formWideErrorDisplay, formWideLabelBehavior) = resolveArgs(ctx)
    let resolved = CardFieldOptions.resolveCvc(
      options,
      ~formWideUnstyled,
      ~formWideErrorDisplay,
      ~formWideLabelBehavior,
      ~labels=ctx.labels,
    )
    let defaultRenderError = useBinding(
      ctx,
      VaultCardController.CvcKind,
      ~errorStyle=?styles->CardFieldStyles.errorOf,
    )
    let controller = ctx.controller

    /*
     * The saved card rides the reducer while this field is mounted with one, keyed on its two
     * strings so a merchant passing a fresh object literal each render changes nothing. The
     * network is canonicalised here — "amex" and "American Express" select the four-digit rule —
     * and an unrecognised one is "", the accept-three-or-four default.
     */
    let present = savedCard->Option.isSome
    let token = savedCard->Option.map(CardFieldOptions.savedCardToken)->Option.getOr("")
    let network =
      savedCard
      ->Option.map(CardFieldOptions.savedCardNetwork)
      ->Option.flatMap(CardNetworkNames.normalise)
      ->Option.getOr("")
    let setSavedCard = controller.setSavedCard
    React.useEffect3(() => {
      setSavedCard(present ? Some({CardStateReducer.token: token, network}) : None)
      None
    }, (present, token, network))
    /* Cleared once, on unmount: a prop CHANGE above replaces the card in one dispatch. */
    React.useEffect0(() => Some(() => setSavedCard(None)))

    let borderTopWidth = borderTopWidth->Option.getOr(ctx.theme.borderWidth)
    let borderLeftWidth = borderLeftWidth->Option.getOr(ctx.theme.borderWidth)
    let borderTopLeftRadius = borderTopLeftRadius->Option.getOr(ctx.theme.borderRadius)
    let borderTopRightRadius = borderTopRightRadius->Option.getOr(ctx.theme.borderRadius)
    let borderBottomLeftRadius = borderBottomLeftRadius->Option.getOr(ctx.theme.borderRadius)
    <CardFields.Cvc
      ?styles
      value=controller.values.cvc
      onChange=controller.onCvcChange
      brand=controller.values.brand
      onFocus={() => {
        controller.onFocus(#cardCvc)
        fire(onFocus, #cardCvc)
      }}
      onBlur={() => {
        controller.onBlur(#cardCvc)
        fire(onBlur, #cardCvc)
      }}
      onBackspace={action => controller.onBackspace(#cardCvc, action)}
      error=?controller.visibleErrors.cardCvc
      isValid=controller.fieldOk.cardCvc
      renderError={renderError->Option.getOr(defaultRenderError)}
      options=resolved
      common={ctx->VaultWidgetContext.commonFor}
      onAnalytics=ctx.onAnalytics
      reference=controller.cvcRef
      borderTopWidth
      borderLeftWidth
      borderTopLeftRadius
      borderTopRightRadius
      borderBottomLeftRadius
      borderBottomRightRadius=ctx.theme.borderRadius
      borderBottomWidth=ctx.theme.borderWidth
      borderRightWidth=ctx.theme.borderWidth
      iconRight={switch CardFieldOptions.cvcIconOf(options, ~unstyled=resolved.unstyled) {
      | #hidden => CardInput.NoIcon
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
      }}
    />
  }
}
