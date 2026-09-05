
open ReactNative

type contextValue = {
  controller: VaultCardController.controller,
  theme: CardFormTypes.cardTheme,
  labels: CardFormTypes.cardLabels,
  errorFontSize: float,
  errorSpacing: float,
  brandIconMode: CardIcons.brandIconMode,
  accessible: option<bool>,
  editable: bool,
  isProcessing: bool,
  onAnalytics: CardFormTypes.analyticsEvent => unit,
  /*
   * The form-wide `unstyled`, already defaulted. A field's own `unstyled` overrides it in either
   * direction, so `unstyled={false}` inside an unstyled provider keeps that one field's UI.
   */
  unstyled: bool,
  /*
   * The surface's error-display default: `#colorOnly` when the merchant composed the fields
   * themselves, `#inline` for the ready-made form. It rides the context for the same reason `unstyled` does —
   * a field widget is mounted by the merchant and has no other way to learn which surface it is in.
   * See `CardFieldOptions.defaultErrorDisplayComposable` for why the two differ.
   */
  defaultErrorDisplay: CardFieldOptions.errorDisplay,
  /* `appearance.labels`, already defaulted: the web's one form-level label mode, for every field. */
  defaultLabelBehavior: CardFieldOptions.labelBehavior,
  /*
   * The merchant-facing snapshot, carried so a field widget can emit its OWN state.
   *
   * A THUNK, not a record: it is invoked only inside an emitter's `build`, which runs only when a
   * merchant is listening, so a form with no callbacks derives nothing at all.
   *
   * That means up to five independent derivations per commit — one per listening field plus the
   * form — rather than the single shared one an eager record gave. They cannot disagree even so:
   * each thunk closes over the same immutable `state` and `errors` from the same render, and the
   * derivation is pure. The cost is O(listeners) on a path that runs once per commit, bounded at
   * five; the maximal configuration re-derives the whole snapshot five times and discards all but
   * its own slice.
   */
  publicSnapshot: unit => VaultPublicState.controllerSnapshot,
}

let context: React.Context.t<option<contextValue>> = React.createContext(None)

module ContextProvider = {
  let make = React.Context.provider(context)
}

let useRequired = (widgetName: string): contextValue =>
  switch React.useContext(context) {
  | Some(value) => value
  | None =>
    Js.Exn.raiseError(widgetName ++ " must be rendered inside a <CardForm>.")
  }

module ErrorText = {
  @react.component
  let make = (
    ~message: string,
    ~theme: CardFormTypes.cardTheme,
    ~errorFontSize,
    ~errorSpacing,
    /* Merchant `styles.error`. None => byte-identical to the unstyled render. */
    ~errorStyle: option<CardFieldStyles.textStyleProp>=?,
  ) =>
    <Text
      testID=CardTestIds.errorTextTestId
      style={Style.s({
        color: theme.dangerColor,
        fontFamily: theme.fontFamily,
        fontSize: errorFontSize,
        marginTop: errorSpacing->Style.dp,
      })->CardFieldStyles.withText(errorStyle)}>
      {React.string(message)}
    </Text>
}

let useRegistration = (ctx: contextValue, kind: VaultCardController.widgetKind) => {
  let register = ctx.controller.register
  React.useEffect0(() => Some(register(kind)))
  let renderError = message =>
    <ErrorText
      message
      theme=ctx.theme
      errorFontSize=ctx.errorFontSize
      errorSpacing=ctx.errorSpacing
    />
  renderError
}

let commonFor = (ctx: contextValue): CardFields.common => {
  theme: ctx.theme,
  isProcessing: ctx.isProcessing,
  editable: ctx.editable,
  accessible: ctx.accessible,
}
