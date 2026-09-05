@genType
let make = React.forwardRef((
  props: {
    "styles": option<CardFieldStyles.fieldStyles>,
    /*
     * Flattened field options — the web SDK's `create('cardNumber', options)` keys where the web
     * has one (`placeholder`, `cardBrandIcon`), plus this library's own.
     */
    "placeholder": option<string>,
    "label": option<string>,
    "labelBehavior": option<CardFieldOptions.labelBehavior>,
    "errorDisplay": option<CardFieldOptions.errorDisplay>,
    "accessibilityLabel": option<string>,
    "accessibilityHint": option<string>,
    "testID": option<string>,
    "cardBrandIcon": option<CardFieldOptions.brandIconMode>,
    /*
     * Strip this field to a bare `TextInput`. Absent => the provider's `unstyled`, then `false`;
     * `unstyled={false}` keeps this field's UI inside an unstyled provider.
     */
    "unstyled": option<bool>,
    /* The web's per-field events. `ready` once after mount; `change` whenever the state differs. */
    "onReady": option<VaultPublicState.fieldEvent => unit>,
    "onFocus": option<VaultPublicState.fieldEvent => unit>,
    "onBlur": option<VaultPublicState.fieldEvent => unit>,
    "onChange": option<VaultPublicState.fieldChange => unit>,
  },
  ref,
) => {
  let ctx = VaultWidgetContext.useRequired("CardNumberField")

  VaultStateEmitter.use(
    ~build=() => ctx.publicSnapshot().cardNumber,
    ~equal=VaultPublicState.fieldChangeEq,
    ~notify=props["onChange"],
  )
  VaultStateEmitter.useReady(~elementType=#cardNumber, ~notify=props["onReady"])
  let controller = ctx.controller

  React.useImperativeHandle0(ref, () => {
    CardForm.focus: () => VaultCardController.focusRef(controller.cardRef),
    blur: () => VaultCardController.blurRef(controller.cardRef),
    clear: () => controller.clearField(#cardNumber),
  })

  let options: CardFieldOptions.cardNumberOptions = {
    placeholder: ?props["placeholder"],
    label: ?props["label"],
    labelBehavior: ?props["labelBehavior"],
    errorDisplay: ?props["errorDisplay"],
    accessibilityLabel: ?props["accessibilityLabel"],
    accessibilityHint: ?props["accessibilityHint"],
    testID: ?props["testID"],
    unstyled: ?props["unstyled"],
    cardBrandIcon: ?props["cardBrandIcon"],
  }

  <BoundCardFields.Number
    ctx
    styles=?{props["styles"]}
    options
    onFocus=?{props["onFocus"]}
    onBlur=?{props["onBlur"]}
    /*
     * The accessory decides which slot this is — nothing, decoration, or a control — because a
     * co-badge chooser or a scan button can be warranted even with brand artwork turned off.
     */
    iconRight={CardNumberAccessory.iconFor(
      ~ctx,
      ~brandIconMode=CardFieldOptions.resolveBrandIconMode(
        Some(options),
        ~formWide=ctx.brandIconMode,
        ~unstyled=CardFieldOptions.unstyledFor(props["unstyled"], ~formWide=ctx.unstyled),
      ),
    )}
  />
})
