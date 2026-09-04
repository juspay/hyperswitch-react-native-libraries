open ReactNative
open Style

type iconType =
  | NoIcon
  /* Decoration. Rendered inside a non-interactive container and hidden from the a11y tree. */
  | CustomIcon(React.element)
  /*
   * An accessory that CONTAINS CONTROLS — the co-badge network chooser, the scan-card button.
   * It renders in the same slot but must stay reachable: hiding it the way decoration is hidden
   * would leave a screen-reader user unable to choose their card's network at all.
   */
  | InteractiveIcon(React.element)

let fontSize = 16.

@react.component
let make = (
  ~theme: CardFormTypes.cardTheme,
  ~isProcessing: bool,
  ~onAnalytics: CardFormTypes.analyticsEvent => unit,
  ~fieldId: CardFormTypes.cardFieldId,
  ~state,
  ~setState,
  /* Which visual elements exist, already resolved — see CardFieldOptions.res. */
  ~options: CardFieldOptions.resolved,
  ~keyboardType,
  ~maxLength=None,
  ~isValid=true,
  ~textColor,
  ~secureTextEntry=false,
  ~editable=true,
  ~iconRight: iconType=NoIcon,
  ~reference=None,
  ~onKeyPress=?,
  ~onFocus=() => (),
  ~onBlur=() => (),
  ~accessible=?,
  ~borderTopWidth=?,
  ~borderBottomWidth=?,
  ~borderLeftWidth=?,
  ~borderRightWidth=?,
  ~borderTopLeftRadius=?,
  ~borderTopRightRadius=?,
  ~borderBottomLeftRadius=?,
  ~borderBottomRightRadius=?,
  /* Merchant per-field style slots. None => byte-identical to the unstyled render. */
  ~styles: option<CardFieldStyles.fieldStyles>=?,
) => {
  let (isFocused, setIsFocused) = React.useState(_ => false)
  let animatedValue = CardAnimatedValue.useAnimatedValue(0.)

  /*
   * The floating label is the only mode that renders an animated element, and only when there is
   * something to animate. `labelBehavior="floating"` with neither `placeholder` nor `label` text
   * renders nothing rather than inventing a display string.
   */
  let floating = options.labelBehavior === #floating
  let floatingResting = options.placeholder->Option.orElse(options.label)
  let floatingLifted = options.label->Option.orElse(options.placeholder)
  let showFloating = floating && (floatingResting->Option.isSome || floatingLifted->Option.isSome)

  /* A static label is an ordinary text element above the input, with no animation. */
  let staticLabel = options.labelBehavior === #above ? options.label : None

  /*
   * The placeholder in `never` and `above` is a library-rendered overlay `Text`, NOT React Native's
   * native `placeholder` prop.
   *
   * The published contract is `styles.placeholder?: StyleProp<TextStyle>`. A native placeholder
   * honours only `placeholderTextColor` — font family, size, line height and alignment all come
   * from the TextInput — so over a native placeholder that slot was a silent no-op in exactly the
   * two modes that used it, which is the thing the styling contract forbids. An overlay `Text` can
   * honour the whole TextStyle, so the declaration stops being a promise the implementation cannot
   * keep.
   *
   * It is shown while the value is empty, focused or not, which is what a native placeholder does.
   * It is never the TextInput's value: `state` is the only thing that reaches validation and
   * tokenization, and this element cannot write to it.
   */
  let showOverlayPlaceholder = !floating && state === "" && options.placeholder->Option.isSome

  /*
   * The overlay is a separate element from the TextInput, so the input's own horizontal alignment
   * does not reach it the way a native placeholder's would. Read it across, and let
   * `styles.placeholder` override it afterwards like any other TextStyle key.
   */
  let inputTextAlign = React.useMemo1(
    () => styles->CardFieldStyles.inputOf->CardFieldStyles.textAlignOf,
    [styles->CardFieldStyles.inputOf],
  )

  /*
   * The floating label's ONLY animated key is `fontSize`, so a static merchant value there would
   * shadow the interpolation and collapse AnimatedStyle. Take it away instead:
   * `splitAnimatedText` returns the merchant's font size (to use as the animation endpoint for that
   * state) and the REST of their style with `fontSize` removed. Memoised on the raw slot value so a
   * merchant passing a stable style object does not re-flatten every render.
   */
  let placeholderSlot = React.useMemo1(
    () => styles->CardFieldStyles.placeholderOf->CardFieldStyles.splitAnimatedText,
    [styles->CardFieldStyles.placeholderOf],
  )
  let labelSlot = React.useMemo1(
    () => styles->CardFieldStyles.labelOf->CardFieldStyles.splitAnimatedText,
    [styles->CardFieldStyles.labelOf],
  )

  /*
   * The two ends of the float animation. A merchant font size REPLACES the endpoint for its own
   * state and leaves the other one alone, so `placeholder: {fontSize: 20}` still animates — down to
   * the library's floating size. The merchant's number is taken literally: it is not multiplied by
   * `theme.fontScale`, because an explicit size means that size.
   */
  let restingFontSize =
    placeholderSlot.fontSize->Option.getOr(
      (fontSize +. theme.placeholderTextSizeAdjust) *. theme.fontScale,
    )
  let floatingFontSize =
    labelSlot.fontSize->Option.getOr(fontSize +. theme.placeholderTextSizeAdjust -. 5.)

  /*
   * `animatedValue` is read in exactly one place: the `showFloating` branch below. With the default
   * `labelBehavior="never"` that branch is `React.null`, so driving the value animates nothing —
   * but a JS-driven `Animated.timing` still spins a requestAnimationFrame loop for 200 ms, three
   * times per form, on mount and again on every focus change and every keystroke. Both effects are
   * therefore gated on the element existing.
   */
  React.useEffect2(() => {
    if showFloating {
      animatedValue->Animated.Value.setValue(state === "" ? 0. : 1.)
    }
    None
  }, (showFloating, state))

  /*
   * ── ANIMATE ON THE TRANSITION, NOT ON EVERY KEYSTROKE ────────────────────────────────────────
   *
   * The label's position is a function of one BOOLEAN — is the field focused or non-empty — but
   * this effect used to depend on `state`, the string. So it restarted a 200 ms JS-driven timing on
   * every character: four fields times sixteen PAN digits is sixty-four restarted rAF loops to type
   * one card, each interpolating `fontSize` and `height` across the bridge. That was tolerable
   * while floating labels were opt-in. They are the default now, so it is everyone's cost.
   *
   * Depending on `lifted` instead runs it twice per field per session — down and up — with an
   * identical visual result.
   *
   * The ref suppresses the MOUNT animation. Without it a form animates all four labels on first
   * paint, from a value the effect above has just set to the same target, which is both wrong to
   * look at and (with the default bezier easing) the thing that makes a plain `mount()` in a test
   * environment schedule a timer it does not expect.
   *
   * NOT a candidate for `useNativeDriver: true`: the animated properties are `fontSize` and
   * `height`, neither of which the native driver supports — it would throw at runtime. The loop can
   * be run less often; it cannot be moved off the JS thread.
   */
  let lifted = isFocused || state !== ""
  let liftedRef = React.useRef(lifted)

  React.useEffect2(() => {
    if showFloating && liftedRef.current !== lifted {
      Animated.timing(
        animatedValue,
        {
          toValue: lifted
            ? 1.->Animated.Value.Timing.fromRawValue
            : 0.->Animated.Value.Timing.fromRawValue,
          duration: 200.,
          useNativeDriver: false,
        },
      )->Animated.start
    }
    liftedRef.current = lifted

    None
  }, (showFloating, lifted))

  /*
   * The input itself, extracted so `unstyled` can render it with no wrappers at all.
   *
   * `unstyled` means the chrome is NOT RENDERED, never styled flat — ADR-0004 makes that
   * distinction binding, and a zeroed-out `View` is still a node in the tree. So the bordered box,
   * the inner flex container, the static label and the accessory slot all cease to exist, and what
   * is left is a `TextInput` the merchant positions themselves.
   *
   * Height is the one property that cannot simply be dropped: the styled tree gives the input
   * `height: 100%` of a fixed-height box, and `100%` of an auto-height parent collapses to nothing.
   * Unstyled therefore lets the platform size the field, which is what a plain `TextInput` does.
   */
  let inputElement = (~unstyled: bool) =>
        <TextInput
          ref=?{reference->Option.map(ref => ref->ReactNative.Ref.value)}
          style={array([
            s({
              fontStyle: #normal,
              color: textColor,
              opacity: isProcessing ? 0.5 : 1.,
              fontFamily: theme.fontFamily,
              fontSize: (fontSize +. theme.placeholderTextSizeAdjust) *. theme.fontScale,
            }),
            s({
              padding: 0.->dp,
              /*
               * Floating mode keeps the 70% box: the label needs the remaining 30% at the top.
               * `never` and `above` fill the container instead, so a single line is centred by the
               * platform inside the full height — and the touch target is the whole field rather
               * than the lower two thirds of it.
               */
              height: unstyled
                ? Style.auto
                : showFloating ? (theme.inputHeight *. 0.7)->dp : 100.->pct,
              width: 100.->pct,
              /*
               * Android only; iOS centres a single-line field's text itself. This is an alignment
               * property, not a pixel offset — it does not encode any particular height or font.
               */
              textAlignVertical: showFloating ? #auto : #center,
            }),
          ])->CardFieldStyles.withText(styles->CardFieldStyles.inputOf)}
          testID={options.testID}
          accessibilityLabel={options.accessibilityLabel}
          accessibilityHint=?{options.accessibilityHint}
          secureTextEntry
          autoCapitalize=#none
          multiline={false}
          autoCorrect={false}
          clearTextOnFocus={false}
          ?maxLength
          placeholderTextColor={theme.placeholderColor}
          value={state}
          ?onKeyPress
          onChangeText={text => setState(text)}
          keyboardType
          autoFocus={false}
          autoComplete={#off}
          textContentType={#oneTimeCode}
          onFocus={_ => {
            setIsFocused(_ => true)
            onFocus()
            onAnalytics(FieldFocused(fieldId))
          }}
          onBlur={_ => {
            state->String.trim == "" ? setState("") : ()
            onBlur()
            setIsFocused(_ => false)
            onAnalytics(FieldBlurred(fieldId))
          }}
          editable
          pointerEvents=#auto
          ?accessible
        />

  if options.unstyled {
    inputElement(~unstyled=true)
  } else {
    <View style={s({width: 100.->pct})}>
      {switch staticLabel {
      | None => React.null
      | Some(text) =>
        <Text
          style={s({
            fontFamily: theme.fontFamily,
            fontSize: (fontSize +. theme.placeholderTextSizeAdjust -. 3.) *. theme.fontScale,
            color: theme.placeholderColor,
            marginBottom: 4.->dp,
          })->CardFieldStyles.withText(styles->CardFieldStyles.labelOf)}>
          {React.string(text)}
        </Text>
      }}
      <View
        style={array([
          theme.bgStyle,
          s({
            backgroundColor: theme.inputBackground,
            borderTopWidth: borderTopWidth->Option.getOr(theme.borderWidth),
            borderBottomWidth: borderBottomWidth->Option.getOr(theme.borderWidth),
            borderLeftWidth: borderLeftWidth->Option.getOr(theme.borderWidth),
            borderRightWidth: borderRightWidth->Option.getOr(theme.borderWidth),
            borderTopLeftRadius: borderTopLeftRadius->Option.getOr(theme.borderRadius),
            borderTopRightRadius: borderTopRightRadius->Option.getOr(theme.borderRadius),
            borderBottomLeftRadius: borderBottomLeftRadius->Option.getOr(theme.borderRadius),
            borderBottomRightRadius: borderBottomRightRadius->Option.getOr(theme.borderRadius),
            height: theme.inputHeight->dp,
            flexDirection: #row,
            /*
             * The error BORDER follows the error STATE, not the message.
             *
             * `#colorOnly` — the composable default — and `#inline` both paint it, in the
             * merchant's own `errorColor`. Only `#none` leaves an invalid field bordered exactly
             * like a valid one, focused or not, for a merchant who wants to draw every cue
             * themselves off the state event.
             *
             * This is the same split hyperswitch-web's separate card fields make: the message block
             * is suppressed with `isErrorHidden`, while `isValid` still drives the `Input--invalid`
             * class that colours the box.
             */
            borderColor: isValid || options.errorDisplay === #none
              ? isFocused ? theme.primaryColor : theme.normalBorderColor
              : theme.errorBorderColor,
            width: 100.->pct,
            paddingHorizontal: 13.->dp,
            alignItems: #center,
            justifyContent: #center,
          }),
          theme.shadowStyle,
        ])->CardFieldStyles.withView(styles->CardFieldStyles.containerOf)}>
        <View
          style={s({
            flex: 1.,
            position: #relative,
            height: 100.->pct,
            /*
             * `flex-end` ONLY in floating mode. The floating label is absolutely positioned at
             * `top: 0` and interpolates its height, so the input has to sit at the bottom to leave
             * it room. In `never` and `above` there is no such element, and pushing the input down
             * left the free space asymmetric — all of it above, none below — which is what put the
             * placeholder and the typed text visibly below the centre of the box.
             */
            justifyContent: showFloating ? #"flex-end" : #center,
          })}>
          {showFloating
            ? <Animated.View
                pointerEvents=#none
                style={s({
                  top: 0.->dp,
                  position: #absolute,
                  height: animatedValue
                  ->Animated.Interpolation.interpolate({
                    inputRange: [0., 1.],
                    outputRange: [
                      "100%",
                      `${((theme.inputHeight +. 10.) /. 1.4)->Float.toString}%`,
                    ]->Animated.Interpolation.fromStringArray,
                  })
                  ->Animated.StyleProp.size,
                  justifyContent: #center,
                })}>
                <Animated.Text
                  style={array([
                    s({
                      fontFamily: theme.fontFamily,
                      fontWeight: isFocused || state != "" ? #500 : #normal,
                      fontSize: animatedValue
                      ->Animated.Interpolation.interpolate({
                        inputRange: [0., 1.],
                        outputRange: [
                          restingFontSize,
                          floatingFontSize,
                        ]->Animated.Interpolation.fromFloatArray,
                      })
                      ->Animated.StyleProp.float,
                      color: theme.placeholderColor,
                    }),
                  ])->CardFieldStyles.withText(
                    isFocused || state != "" ? labelSlot.rest : placeholderSlot.rest,
                  )}>
                  {React.string(
                    (
                      isFocused || state != "" ? floatingLifted : floatingResting
                    )->Option.getOr(""),
                  )}
                </Animated.Text>
              </Animated.View>
            : React.null}
        {inputElement(~unstyled=false)}
          {showOverlayPlaceholder
            ? <View
                pointerEvents=#none
                /*
                 * Hidden from assistive technology. The TextInput carries its own
                 * `accessibilityLabel` (and optional hint), so announcing this too would repeat it.
                 */
                accessible={false}
                accessibilityElementsHidden={true}
                importantForAccessibility={#"no-hide-descendants"}
                style={s({
                  position: #absolute,
                  top: 0.->dp,
                  left: 0.->dp,
                  right: 0.->dp,
                  bottom: 0.->dp,
                  /*
                   * Centred by LAYOUT. The overlay covers exactly the box the TextInput fills, and
                   * both centre their single line inside it, so the placeholder and the typed text
                   * share one vertical centre at any height, font size or font scale — with no
                   * offset, transform or platform constant involved.
                   *
                   * It is rendered AFTER the TextInput so it paints on top: a merchant may put a
                   * `backgroundColor` in `styles.input`, and as an earlier sibling the placeholder
                   * would have been painted underneath it and disappeared. It only exists while the
                   * value is empty, so it can never cover typed text, and `pointerEvents="none"`
                   * keeps taps and the caret going to the input beneath.
                   */
                  justifyContent: #center,
                })}>
                <Text
                  numberOfLines={1}
                  style={s({
                    fontFamily: theme.fontFamily,
                    fontSize: (fontSize +. theme.placeholderTextSizeAdjust) *. theme.fontScale,
                    color: theme.placeholderColor,
                    /* Inherited from `styles.input`, then overridable by `styles.placeholder`. */
                    textAlign: ?inputTextAlign,
                    /* Dim with the field it belongs to while a submission is in flight. */
                    opacity: isProcessing ? 0.5 : 1.,
                  })->CardFieldStyles.withText(styles->CardFieldStyles.placeholderOf)}>
                  {React.string(options.placeholder->Option.getOr(""))}
                </Text>
              </View>
            : React.null}
        </View>
        {switch iconRight {
        | NoIcon => React.null
        | CustomIcon(element) =>
          /*
           * A NON-INTERACTIVE container.
           *
           * A decorative accessory has no action: `CardIcons` and `CardIcons.Cvc` render an `Image`
           * and nothing else. It used to be wrapped in a `Pressable` anyway, which made it a touch
           * responder and put a pressable in the tree for something that does not respond to a press.
           * A plain `View` is what it is.
           *
           * `accessibilityElementsHidden` / `importantForAccessibility` keep it out of the
           * accessibility tree entirely: it duplicates information the field's own
           * `accessibilityLabel` already carries, and announcing decoration is noise.
           *
           * An accessory that carries CONTROLS uses `InteractiveIcon` below and gets none of this.
           */
          <View
            accessible={false}
            accessibilityElementsHidden={true}
            importantForAccessibility={#"no-hide-descendants"}
            style={s({})->CardFieldStyles.withView(styles->CardFieldStyles.accessoryOf)}>
            element
          </View>
        | InteractiveIcon(element) =>
          /* Same slot, same merchant style hook — but reachable, focusable and announced. */
          <View style={s({})->CardFieldStyles.withView(styles->CardFieldStyles.accessoryOf)}>
            element
          </View>
        }}
      </View>
    </View>
  }
}
