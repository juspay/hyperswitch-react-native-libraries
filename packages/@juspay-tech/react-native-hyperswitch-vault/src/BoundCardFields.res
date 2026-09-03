
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
    /* Which visual elements exist. Absent => the blank default field. */
    ~options: option<CardFieldOptions.cardNumberOptions>=?,
  ) => {
    let resolved = CardFieldOptions.resolveCardNumber(options, ~formWideUnstyled=ctx.unstyled, ~labels=ctx.labels)
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
      onFocus={() => controller.onFocus(#cardNumber)}
      onBlur={() => controller.onBlur(#cardNumber)}
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
  ) => {
    let resolved = CardFieldOptions.resolveCardholderName(options, ~formWideUnstyled=ctx.unstyled, ~labels=ctx.labels)
    /*
     * Registered, but under a kind `VaultFormHost.requiredKinds` does not list — so the presence
     * gate still does not demand it and a custom layout that omits it still submits, which is what
     * the previous "deliberately NOT registered" arrangement was protecting.
     *
     * It is registered because the FORM STATE has to report whether this field exists, and in a
     * custom layout only the merchant knows: they place the widgets. `cardholderNameMode` used to
     * stand in for that and was wrong here — it defaults to `#collect`, so a layout with only
     * number/expiry/CVC reported a `fields.cardholderName` that was not on screen.
     */
    let controller = ctx.controller
    React.useEffect0(() => Some(controller.register(VaultCardController.CardholderNameKind)))
    <CardFields.CardholderName
      ?styles
      value=controller.values.cardholderName
      onChange=controller.onCardholderNameChange
      onFocus={() => controller.onFocus(#cardholderName)}
      onBlur={() => controller.onBlur(#cardholderName)}
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
    /* Which visual elements exist. Absent => the blank default field. */
    ~options: option<CardFieldOptions.expiryOptions>=?,
  ) => {
    let resolved = CardFieldOptions.resolveExpiry(options, ~formWideUnstyled=ctx.unstyled, ~labels=ctx.labels)
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
      onFocus={() => controller.onFocus(#expiry)}
      onBlur={() => controller.onBlur(#expiry)}
      onBackspace={action => controller.onBackspace(#expiry, action)}
      error=?controller.visibleErrors.expiry
      isValid=controller.fieldOk.expiry
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
    /* Which visual elements exist. Absent => the blank default field. */
    ~options: option<CardFieldOptions.cvcOptions>=?,
  ) => {
    let resolved = CardFieldOptions.resolveCvc(options, ~formWideUnstyled=ctx.unstyled, ~labels=ctx.labels)
    let defaultRenderError = useBinding(
      ctx,
      VaultCardController.CvcKind,
      ~errorStyle=?styles->CardFieldStyles.errorOf,
    )
    let controller = ctx.controller
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
      onFocus={() => controller.onFocus(#cvc)}
      onBlur={() => controller.onBlur(#cvc)}
      onBackspace={action => controller.onBackspace(#cvc, action)}
      error=?controller.visibleErrors.cvc
      isValid=controller.fieldOk.cvc
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
      }}
    />
  }
}
