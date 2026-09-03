
@genType
let make = React.forwardRef((
  props: {
    "children": option<React.element>,
    "styles": option<CardFieldStyles.fieldStyles>,
    /*
     * Flattened field options. A merchant writes `<CardNumberField placeholder="Card number" />`
     * rather than nesting a record — the grouped `fieldOptions` shape is for the ready-made form,
     * where three fields have to be addressed at once.
     */
    "placeholder": option<string>,
    "label": option<string>,
    "labelBehavior": option<CardFieldOptions.labelBehavior>,
    "errorDisplay": option<CardFieldOptions.errorDisplay>,
    "accessibilityLabel": option<string>,
    "accessibilityHint": option<string>,
    "testID": option<string>,
    "brandIconMode": option<CardFieldOptions.brandIconMode>,
    /*
     * Called with one snapshot on mount and again whenever THIS field's state actually changes, by
     * structural comparison. Carries no card value — see `VaultPublicState`.
     */
    "onStateChange": option<VaultPublicState.cardNumberState => unit>,
    /*
     * Strip this field to a bare `TextInput`. Absent => the provider's `unstyled`, then `false`;
     * `unstyled={false}` keeps this field's UI inside an unstyled provider.
     */
    "unstyled": option<bool>,
  },
  ref,
) => {
  let ctx = VaultWidgetContext.useRequired("CardNumberWidget")

  VaultStateEmitter.use(
    ~build=() => ctx.publicSnapshot().cardNumber,
    ~equal=VaultPublicState.cardNumberEq,
    ~notify=props["onStateChange"],
  )
  let controller = ctx.controller

  React.useImperativeHandle0(ref, () => {
    CardForm.focus: () => VaultCardController.focusRef(controller.cardRef),
    blur: () => VaultCardController.blurRef(controller.cardRef),
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
    brandIconMode: ?props["brandIconMode"],
  }

  <BoundCardFields.Number
    ctx
    styles=?{props["styles"]}
    options
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
