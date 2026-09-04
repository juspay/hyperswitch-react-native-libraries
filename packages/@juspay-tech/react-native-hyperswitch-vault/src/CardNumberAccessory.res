open ReactNative
open Style

/*
 * What sits at the right-hand end of the card-number field.
 *
 * This is the single place that decides between the three things that can appear there, reproducing
 * client-core's `CardBrandAndScanCardIcon`:
 *
 *   - the co-badge CHOOSER, when the typed number matches more than one network the merchant
 *     accepts. It replaces the plain artwork, because the artwork is then a control;
 *   - the plain brand ARTWORK otherwise, subject to the merchant's `cardBrandIcon`;
 *   - the SCAN button, while the field is still empty and the optional scanner package is
 *     installed. It disappears once there is a number to scan over — the same rule client-core
 *     used, and the reason a customer never sees a scan button covering their own input.
 *
 * A merchant who has turned artwork off (`cardBrandIcon: 'hidden'`) still gets the chooser when one
 * is warranted: hiding decoration is a styling choice, and silently removing the customer's network
 * choice with it would be a routing change dressed up as a theme.
 *
 * ── WHY `iconFor` RETURNS THE SLOT AND NOT AN ELEMENT ──────────────────────────
 *
 * The field must render NOTHING — no wrapper, no reserved width, no extra node — when there is no
 * accessory. A component that returns `React.null` cannot achieve that: its container is already in
 * the tree by the time it decides. So the decision is made here, as a value, and the call sites pass
 * `NoIcon` when it comes out empty. `CustomIcon` and `InteractiveIcon` differ in accessibility:
 * decoration is hidden from screen readers, controls are not.
 */

/*
 * The camera glyph and the hairline before it, reproducing client-core's `ScanCardButton`: a
 * divider in the border colour, then a 26pt camera filled with `primaryColor`.
 *
 * It read the word "Scan" until now, which was a placeholder from when the artwork was parked —
 * a text control in a row of icons, in English only, and not what client-core's customers saw.
 * `accessibilityLabel` keeps the word for screen readers, which is the one place it belonged.
 */
module ScanButton = {
  @react.component
  let make = (~theme: CardFormTypes.cardTheme, ~editable: bool, ~onPress: unit => unit) =>
    <>
      <View
        style={s({
          backgroundColor: theme.dividerColor,
          marginHorizontal: 6.->dp,
          height: 60.->pct,
          width: 1.->dp,
        })}
      />
      <Pressable
        accessibilityRole=#button
        accessibilityLabel="Scan card"
        testID=CardTestIds.scanCardButton
        disabled={!editable}
        onPress={_ => onPress()}
        style={_ => s({paddingHorizontal: 2.->dp, justifyContent: #center})}>
        {_ => <CardIcons.Camera size={20. *. theme.fontScale} color=theme.primaryColor />}
      </Pressable>
    </>
}

/*
 * Nested so that `iconFor` below can render it. A `@react.component` at module top level produces
 * a `make` that JSX cannot address from inside its own file — `<make />` parses as a DOM tag.
 */
module Body = {
  @react.component
  let make = (
    ~ctx: VaultWidgetContext.contextValue,
    ~brandIconMode: CardFieldOptions.brandIconMode,
    ~showScan: bool,
  ) => {
    let controller = ctx.controller
    let values = controller.values

    let brandElement = if values.isCoBadged {
      <CardNetworkChooser
        schemes=values.eligibleSchemes
        selected=values.brand
        theme=ctx.theme
        label=ctx.labels.selectCardBrandLabel
        brandIconMode={switch brandIconMode {
        /* The trigger must be visible even when decorative artwork is off. */
        | #hidden => #standard
        | mode => mode
        }}
        editable=ctx.editable
        onSelect=controller.selectNetwork
      />
    } else {
      switch brandIconMode {
      | #hidden => React.null
      | mode => <CardIcons detectedScheme=values.brand mode />
      }
    }

    <View style={s({flexDirection: #row, alignItems: #center})}>
      brandElement
      {showScan
        ? <ScanButton theme=ctx.theme editable=ctx.editable onPress=controller.scanCard />
        : React.null}
    </View>
  }
}

/*
 * The scanner is offered only while the field is EMPTY, matching client-core: once there is a
 * number, a scan would replace what the customer typed, and the button would sit on top of it.
 */
let scanOffered = (ctx: VaultWidgetContext.contextValue) =>
  ScanCardBridge.isAvailable && ctx.controller.values.cardNumber->String.length === 0

let iconFor = (
  ~ctx: VaultWidgetContext.contextValue,
  ~brandIconMode: CardFieldOptions.brandIconMode,
): CardInput.iconType => {
  let showScan = ctx->scanOffered
  let isCoBadged = ctx.controller.values.isCoBadged

  if isCoBadged || showScan {
    CardInput.InteractiveIcon(<Body ctx brandIconMode showScan />)
  } else {
    switch brandIconMode {
    /*
     * Byte-identical to what this slot rendered before the accessory existed: the same element, in
     * the same decorative container. A merchant who has no co-badged cards and no scanner installed
     * sees no change at all.
     */
    | #hidden => CardInput.NoIcon
    | mode => CardInput.CustomIcon(<CardIcons detectedScheme=ctx.controller.values.brand mode />)
    }
  }
}
