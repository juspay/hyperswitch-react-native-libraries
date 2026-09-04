@genType
let make = React.forwardRef((
  props: {
    "styles": option<CardFieldStyles.fieldStyles>,
    "placeholder": option<string>,
    "label": option<string>,
    "labelBehavior": option<CardFieldOptions.labelBehavior>,
    "errorDisplay": option<CardFieldOptions.errorDisplay>,
    "accessibilityLabel": option<string>,
    "accessibilityHint": option<string>,
    "testID": option<string>,
    "unstyled": option<bool>,
    "cvcIcon": option<CardFieldOptions.cvcIconDisplay>,
    /*
     * A card the merchant has already saved, as the web SDK's `create('cardCvc', {savedCard})`
     * takes it: `{paymentToken, paymentMethodData: {card: {cardNetwork}}}`. Mount ONLY this
     * field with it and `tokenize()` refreshes that card's CVC, resolving to the token the response
     * carries. The network selects the CVC length rule; pass the listing's `card_network`, or
     * `valid` turns true one digit early on an Amex card.
     */
    "savedCard": option<CardFieldOptions.savedCard>,
    "onReady": option<VaultPublicState.fieldEvent => unit>,
    "onFocus": option<VaultPublicState.fieldEvent => unit>,
    "onBlur": option<VaultPublicState.fieldEvent => unit>,
    "onChange": option<VaultPublicState.fieldChange => unit>,
  },
  ref,
) => {
  let ctx = VaultWidgetContext.useRequired("CardCVCField")

  VaultStateEmitter.use(
    ~build=() => ctx.publicSnapshot().cardCvc,
    ~equal=VaultPublicState.fieldChangeEq,
    ~notify=props["onChange"],
  )
  VaultStateEmitter.useReady(~elementType=#cardCvc, ~notify=props["onReady"])
  let controller = ctx.controller

  React.useImperativeHandle0(ref, () => {
    CardForm.focus: () => VaultCardController.focusRef(controller.cvcRef),
    blur: () => VaultCardController.blurRef(controller.cvcRef),
    clear: () => controller.clearField(#cardCvc),
  })

  let options: CardFieldOptions.cvcOptions = {
    placeholder: ?props["placeholder"],
    label: ?props["label"],
    labelBehavior: ?props["labelBehavior"],
    errorDisplay: ?props["errorDisplay"],
    accessibilityLabel: ?props["accessibilityLabel"],
    accessibilityHint: ?props["accessibilityHint"],
    testID: ?props["testID"],
    unstyled: ?props["unstyled"],
    cvcIcon: ?props["cvcIcon"],
  }

  <BoundCardFields.Cvc
    ctx
    styles=?{props["styles"]}
    options
    savedCard=?{props["savedCard"]}
    onFocus=?{props["onFocus"]}
    onBlur=?{props["onBlur"]}
  />
})
