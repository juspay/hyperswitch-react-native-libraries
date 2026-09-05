open ReactNative
open Style

/*
 * The co-badge network chooser, moved inside the library.
 *
 * ── WHY IT HAD TO MOVE ─────────────────────────────────────────────────────────
 *
 * A co-badged card carries two networks — RuPay and Visa on the same plastic is the common case —
 * and which one a payment is routed over is the CUSTOMER'S choice, with real consequences for fees
 * and for which issuer rules apply. The classic form offered that choice because it could see the
 * PAN. Now that every new-card flow is library-owned, only the library can: the decision is driven
 * entirely by which schemes the typed number matches.
 *
 * Dropping the feature was not an option that could be taken quietly. It would have silently routed
 * every co-badged card over whichever network happened to match first, for every merchant who
 * upgraded, with no error and nothing in the UI to show what had been lost.
 *
 * ── THE CHOICE STAYS INSIDE ────────────────────────────────────────────────────
 *
 * Nothing about the selection is published. There is no `onNetworkChange`, no selected-network
 * prop, and no way to read it back: the pick lands in the reducer, changes which CVC length is
 * valid, changes the artwork, and reaches `payment_method_data.card.card_network` in the direct
 * confirm. A host learns nothing about the card from any of it.
 */

module Option_ = {
  @react.component
  let make = (
    ~scheme: string,
    ~isSelected: bool,
    ~theme: CardFormTypes.cardTheme,
    ~onSelect: string => unit,
  ) =>
    <Pressable
      accessibilityRole=#button
      accessibilityLabel=scheme
      testID={CardTestIds.networkOption(scheme)}
      onPress={_ => onSelect(scheme)}
      style={_ =>
        s({
          flexDirection: #row,
          alignItems: #center,
          paddingVertical: 10.->dp,
          paddingHorizontal: 8.->dp,
          borderRadius: theme.borderRadius,
          backgroundColor: isSelected ? theme.dividerColor : "transparent",
        })}>
      {_ =>
        <>
          <CardIcons detectedScheme=scheme size=30. mode=#standard />
          <View style={s({width: 10.->dp})} />
          <Text
            style={s({
              color: theme.textColor,
              fontFamily: theme.fontFamily,
              fontSize: 14. *. theme.fontScale,
            })}>
            {React.string(scheme)}
          </Text>
        </>}
    </Pressable>
}

/*
 * The trigger sits in the card field's accessory slot, in place of the plain brand icon. It shows
 * the network in force plus a caret, so a customer can see that the artwork is a control rather
 * than a status indicator.
 */
@react.component
let make = (
  ~schemes: array<string>,
  ~selected: string,
  ~theme: CardFormTypes.cardTheme,
  ~label: string,
  ~brandIconMode: CardIcons.brandIconMode,
  ~editable: bool,
  ~onSelect: string => unit,
) => {
  let (isOpen, setIsOpen) = React.useState(() => false)

  <>
    <Pressable
      accessibilityRole=#button
      accessibilityLabel=label
      testID=CardTestIds.networkTrigger
      disabled={!editable}
      onPress={_ => setIsOpen(_ => true)}
      style={_ => s({flexDirection: #row, alignItems: #center})}>
      {_ =>
        <>
          <CardIcons detectedScheme=selected size=30. mode=brandIconMode />
          /* A glyph rather than an asset: one more PNG for a 6-pixel triangle is not worth it. */
          <Text
            style={s({
              color: theme.placeholderColor,
              fontSize: 10. *. theme.fontScale,
              marginLeft: 2.->dp,
            })}>
            {React.string(`▾`)}
          </Text>
        </>}
    </Pressable>
    <Modal
      visible=isOpen
      transparent=true
      animationType=#fade
      onRequestClose={() => setIsOpen(_ => false)}>
      /*
       * The backdrop dismisses. On a sheet the customer opened by accident this is the only way out
       * that does not require them to choose a network they did not want.
       */
      <Pressable
        accessibilityRole=#button
        accessibilityLabel=label
        testID=CardTestIds.networkBackdrop
        onPress={_ => setIsOpen(_ => false)}
        style={_ =>
          s({
            flex: 1.,
            justifyContent: #"flex-end",
            backgroundColor: "rgba(0,0,0,0.35)",
          })}>
        {_ =>
          <View
            style={s({
              backgroundColor: theme.inputBackground,
              borderTopLeftRadius: 16.,
              borderTopRightRadius: 16.,
              paddingHorizontal: 16.->dp,
              paddingTop: 16.->dp,
              paddingBottom: 24.->dp,
            })}>
            <Text
              testID=CardTestIds.networkHeading
              style={s({
                color: theme.textColor,
                fontFamily: theme.fontFamily,
                fontSize: 15. *. theme.fontScale,
                marginBottom: 8.->dp,
              })}>
              {React.string(label)}
            </Text>
            <ScrollView keyboardShouldPersistTaps=#handled>
              {schemes
              ->Array.mapWithIndex((scheme, index) =>
                <Option_
                  key={index->Int.toString}
                  scheme
                  isSelected={scheme === selected}
                  theme
                  onSelect={picked => {
                    onSelect(picked)
                    setIsOpen(_ => false)
                  }}
                />
              )
              ->React.array}
            </ScrollView>
          </View>}
      </Pressable>
    </Modal>
  </>
}
