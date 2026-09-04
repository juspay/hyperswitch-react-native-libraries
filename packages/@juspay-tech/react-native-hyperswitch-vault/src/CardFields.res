open ReactNative

type common = {
  theme: CardFormTypes.cardTheme,
  isProcessing: bool,
  editable: bool,
  accessible: option<bool>,
}

/*
 * `errorDisplay` governs the COLOUR too, not only the message — but the two are now separable.
 *
 * `#colorOnly` tints without printing, which is the composable default and the web SDK's
 * behaviour; `#none` still suppresses both, for a merchant who wants the field left entirely
 * alone. Only `#none` returns the plain text colour, so the tint is the DEFAULT behaviour and
 * silence is the opt-in.
 *
 * It used to govern the message alone: a merchant who configured nothing got no error text and a
 * red field anyway, because the tint read `dangerColor` straight off the theme. That made "inline
 * error rendering is OPT-IN" true of the sentence and false of the styling, and it painted a
 * judgement onto a merchant's form in a colour they never chose.
 *
 * The validity verdict is returned unchanged — only the colour is gated — so nothing downstream
 * starts believing an invalid field is valid.
 */
let inputColors = (
  ~theme: CardFormTypes.cardTheme,
  ~error: option<string>,
  ~isValid,
  ~errorDisplay: CardFieldOptions.errorDisplay,
) => {
  let ok = isValid->Option.getOr(error->Option.isNone)
  (ok, !ok && errorDisplay !== #none ? theme.dangerColor : theme.textColor)
}

/*
 * Inline error rendering is separate from the error EVENT, and the two surfaces default it
 * differently — see `CardFieldOptions.defaultErrorDisplayComposable`:
 *
 *   composable fields  #colorOnly  the box is tinted, no message is drawn
 *   ready-made forms   #inline     the message is drawn under the field
 *
 * `#none` renders nothing at all — not an empty container, not reserved space — while the same
 * safe error still reaches the merchant through the field and form state callbacks, so a merchant
 * drawing their own chrome loses no information by it.
 *
 * (This comment previously claimed `#none` was "the default", full stop. It was not: the single
 * default was `#inline` for every surface, which is what made a composed field render our message
 * underneath the merchant's own.)
 */
module ErrorSlot = {
  @react.component
  let make = (
    ~error: option<string>,
    ~renderError: option<string => React.element>,
    ~errorDisplay: CardFieldOptions.errorDisplay,
  ) =>
    switch (errorDisplay, error, renderError) {
    | (#inline, Some(message), Some(render)) => render(message)
    | _ => React.null
    }
}

module Number = {
  @react.component
  let make = (
    ~value: string,
    ~onChange: CardFieldLogic.numberChange => unit,
    ~currentBrand: string="",
    ~onFocus: unit => unit=() => (),
    ~onBlur: unit => unit=() => (),
    ~onBackspace: CardFieldLogic.backspaceAction => unit=_ => (),
    ~error: option<string>=?,
    ~isValid: bool=?,
    ~renderError: option<string => React.element>=?,
    ~options: CardFieldOptions.resolved,
    ~common: common,
    ~onAnalytics: CardFormTypes.analyticsEvent => unit=_ => (),
    ~iconRight: CardInput.iconType=CardInput.NoIcon,
    ~reference: option<React.ref<Nullable.t<TextInput.element>>>=?,
    ~borderBottomWidth: option<float>=?,
    ~borderBottomLeftRadius: option<float>=?,
    ~borderBottomRightRadius: option<float>=?,
    /* Merchant per-field style slots. None => byte-identical to the unstyled render. */
    ~styles: option<CardFieldStyles.fieldStyles>=?,
  ) => {
    let (isValid, textColor) = inputColors(
      ~theme=common.theme,
      ~error,
      ~isValid,
      ~errorDisplay=options.errorDisplay,
    )
    <View
      style=?{styles
      ->CardFieldStyles.rootOf
      ->Option.map(root => Style.s({})->CardFieldStyles.withView(Some(root)))}>
      <CardInput
        ?styles
        theme=common.theme
        isProcessing=common.isProcessing
        editable=common.editable
        onAnalytics
        fieldId=CardFormTypes.CardNumberField
        options
        reference
        state=value
        setState={text => onChange(CardFieldLogic.onCardNumberText(text, ~currentBrand))}
        keyboardType=#"number-pad"
        isValid
        maxLength=Some(23)
        ?borderBottomWidth
        ?borderBottomLeftRadius
        ?borderBottomRightRadius
        textColor
        iconRight
        onFocus
        onBlur
        onKeyPress={(ev: TextInput.KeyPressEvent.t) =>
          if ev.nativeEvent.key == "Backspace" {
            onBackspace(CardFieldLogic.onCardNumberBackspace(~value))
          }}
        accessible=?common.accessible
      />
      <ErrorSlot error={error} renderError={renderError} errorDisplay={options.errorDisplay} />
    </View>
  }
}

module Expiry = {
  @react.component
  let make = (
    ~value: string,
    ~onChange: CardFieldLogic.expiryChange => unit,
    ~onFocus: unit => unit=() => (),
    ~onBlur: unit => unit=() => (),
    ~onBackspace: CardFieldLogic.backspaceAction => unit=_ => (),
    ~error: option<string>=?,
    ~isValid: bool=?,
    ~renderError: option<string => React.element>=?,
    ~options: CardFieldOptions.resolved,
    ~common: common,
    ~onAnalytics: CardFormTypes.analyticsEvent => unit=_ => (),
    ~reference: option<React.ref<Nullable.t<TextInput.element>>>=?,
    ~borderTopWidth: option<float>=?,
    ~borderRightWidth: option<float>=?,
    ~borderTopLeftRadius: option<float>=?,
    ~borderTopRightRadius: option<float>=?,
    ~borderBottomRightRadius: option<float>=?,
    ~borderBottomWidth: option<float>=?,
    ~borderBottomLeftRadius: option<float>=?,
    /* Widened from `expiryStyles`; `accessory` is structurally absent for this field. */
    ~styles: option<CardFieldStyles.fieldStyles>=?,
  ) => {
    let (isValid, textColor) = inputColors(
      ~theme=common.theme,
      ~error,
      ~isValid,
      ~errorDisplay=options.errorDisplay,
    )
    <View
      style=?{styles
      ->CardFieldStyles.rootOf
      ->Option.map(root => Style.s({})->CardFieldStyles.withView(Some(root)))}>
      <CardInput
        ?styles
        theme=common.theme
        isProcessing=common.isProcessing
        editable=common.editable
        onAnalytics
        fieldId=CardFormTypes.ExpiryField
        options
        reference
        state=value
        setState={text => onChange(CardFieldLogic.onExpiryText(text))}
        keyboardType=#"number-pad"
        isValid
        maxLength=Some(7)
        ?borderTopWidth
        ?borderRightWidth
        ?borderTopLeftRadius
        ?borderTopRightRadius
        ?borderBottomRightRadius
        ?borderBottomWidth
        ?borderBottomLeftRadius
        textColor
        onFocus
        onBlur
        onKeyPress={(ev: TextInput.KeyPressEvent.t) =>
          if ev.nativeEvent.key == "Backspace" {
            onBackspace(CardFieldLogic.onExpiryBackspace(~display=value))
          }}
        accessible=?common.accessible
      />
      <ErrorSlot error={error} renderError={renderError} errorDisplay={options.errorDisplay} />
    </View>
  }
}

/*
 * A plain text field: no brand artwork, no CVC glyph, no auto-advance. It is not part of the
 * number → expiry → CVC focus chain, because a cardholder name has no completion signal that could
 * tell us when to move on.
 */
module CardholderName = {
  @react.component
  let make = (
    ~value: string,
    ~onChange: string => unit,
    ~onFocus: unit => unit=() => (),
    ~onBlur: unit => unit=() => (),
    ~error: option<string>=?,
    ~isValid: bool=?,
    ~renderError: option<string => React.element>=?,
    ~options: CardFieldOptions.resolved,
    ~common: common,
    ~onAnalytics: CardFormTypes.analyticsEvent => unit=_ => (),
    ~reference: option<React.ref<Nullable.t<TextInput.element>>>=?,
    ~borderBottomWidth: option<float>=?,
    ~borderBottomLeftRadius: option<float>=?,
    ~borderBottomRightRadius: option<float>=?,
    ~styles: option<CardFieldStyles.fieldStyles>=?,
  ) => {
    let (isValid, textColor) = inputColors(
      ~theme=common.theme,
      ~error,
      ~isValid,
      ~errorDisplay=options.errorDisplay,
    )
    <View
      style=?{styles
      ->CardFieldStyles.rootOf
      ->Option.map(root => Style.s({})->CardFieldStyles.withView(Some(root)))}>
      <CardInput
        ?styles
        theme=common.theme
        isProcessing=common.isProcessing
        editable=common.editable
        onAnalytics
        fieldId=CardFormTypes.CardholderNameField
        options
        reference
        state=value
        setState={text => onChange(CardFieldLogic.onCardholderNameText(text))}
        keyboardType=#default
        isValid
        maxLength=Some(255)
        ?borderBottomWidth
        ?borderBottomLeftRadius
        ?borderBottomRightRadius
        textColor
        onFocus
        onBlur
        accessible=?common.accessible
      />
      <ErrorSlot error={error} renderError={renderError} errorDisplay={options.errorDisplay} />
    </View>
  }
}

module Cvc = {
  @react.component
  let make = (
    ~value: string,
    ~onChange: CardFieldLogic.cvcChange => unit,
    ~brand: string="",
    ~onFocus: unit => unit=() => (),
    ~onBlur: unit => unit=() => (),
    ~onBackspace: CardFieldLogic.backspaceAction => unit=_ => (),
    ~error: option<string>=?,
    ~isValid: bool=?,
    ~renderError: option<string => React.element>=?,
    ~options: CardFieldOptions.resolved,
    ~common: common,
    ~onAnalytics: CardFormTypes.analyticsEvent => unit=_ => (),
    ~iconRight: CardInput.iconType=CardInput.NoIcon,
    ~reference: option<React.ref<Nullable.t<TextInput.element>>>=?,
    ~borderTopWidth: option<float>=?,
    ~borderLeftWidth: option<float>=?,
    ~borderTopLeftRadius: option<float>=?,
    ~borderTopRightRadius: option<float>=?,
    ~borderBottomLeftRadius: option<float>=?,
    ~borderBottomRightRadius: option<float>=?,
    ~borderBottomWidth: option<float>=?,
    ~borderRightWidth: option<float>=?,
    /* Merchant per-field style slots. None => byte-identical to the unstyled render. */
    ~styles: option<CardFieldStyles.fieldStyles>=?,
  ) => {
    let (isValid, textColor) = inputColors(
      ~theme=common.theme,
      ~error,
      ~isValid,
      ~errorDisplay=options.errorDisplay,
    )
    <View
      style=?{styles
      ->CardFieldStyles.rootOf
      ->Option.map(root => Style.s({})->CardFieldStyles.withView(Some(root)))}>
      <CardInput
        ?styles
        theme=common.theme
        isProcessing=common.isProcessing
        editable=common.editable
        onAnalytics
        fieldId=CardFormTypes.CvcField
        options
        reference
        secureTextEntry=true
        state=value
        setState={text => onChange(CardFieldLogic.onCvcText(text, ~brand))}
        keyboardType=#"number-pad"
        isValid
        maxLength=Some(4)
        ?borderTopWidth
        ?borderLeftWidth
        ?borderTopLeftRadius
        ?borderTopRightRadius
        ?borderBottomLeftRadius
        ?borderBottomRightRadius
        ?borderBottomWidth
        ?borderRightWidth
        textColor
        iconRight
        onFocus
        onBlur
        onKeyPress={(ev: TextInput.KeyPressEvent.t) =>
          if ev.nativeEvent.key == "Backspace" {
            onBackspace(CardFieldLogic.onCvcBackspace(~value))
          }}
        accessible=?common.accessible
      />
      <ErrorSlot error={error} renderError={renderError} errorDisplay={options.errorDisplay} />
    </View>
  }
}
