
@genType
let make = React.forwardRef((
  props: {
    "children": option<React.element>,
    /* Expiry has no accessory element, so its slot set is one member smaller. */
    "styles": option<CardFieldStyles.expiryStyles>,
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
    /*
     * Called with one snapshot on mount and again whenever THIS field's state actually changes, by
     * structural comparison. Carries no card value — see `VaultPublicState`.
     */
    "onStateChange": option<VaultPublicState.expiryState => unit>,
    /*
     * Strip this field to a bare `TextInput`. Absent => the provider's `unstyled`, then `false`;
     * `unstyled={false}` keeps this field's UI inside an unstyled provider.
     */
    "unstyled": option<bool>,
  },
  ref,
) => {
  let ctx = VaultWidgetContext.useRequired("CardExpiryWidget")

  VaultStateEmitter.use(
    ~build=() => ctx.publicSnapshot().expiry,
    ~equal=VaultPublicState.expiryEq,
    ~notify=props["onStateChange"],
  )
  let controller = ctx.controller

  React.useImperativeHandle0(ref, () => {
    CardForm.focus: () => VaultCardController.focusRef(controller.expiryRef),
    blur: () => VaultCardController.blurRef(controller.expiryRef),
  })

  let options: CardFieldOptions.expiryOptions = {
    placeholder: ?props["placeholder"],
    label: ?props["label"],
    labelBehavior: ?props["labelBehavior"],
    errorDisplay: ?props["errorDisplay"],
    accessibilityLabel: ?props["accessibilityLabel"],
    accessibilityHint: ?props["accessibilityHint"],
    testID: ?props["testID"],
    unstyled: ?props["unstyled"],
  }

  <BoundCardFields.Expiry
    ctx
    styles=?{props["styles"]->Option.map(CardFieldStyles.widenExpiry)}
    options
  />
})
