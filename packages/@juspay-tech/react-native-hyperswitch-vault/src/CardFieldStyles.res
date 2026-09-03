/*
 * Merchant per-field style slots (ADR-0002 §9 layer 2) and the TypeScript -> ReScript -> React
 * Native bridge that carries them.
 *
 * THE TWO STYLE TYPES ARE IMPORTED, NOT DECLARED HERE. `@genType.opaque type styleObject =
 * ReactNative.Style.t` (see CardFormTypes.res) emits
 *
 *     export abstract class styleObject { protected opaque!: any }
 *
 * which the merchant boundary must never expose. Importing the React Native types from
 * `src/styleTypes.ts` instead makes the generated declaration reference `StyleProp<ViewStyle>` /
 * `StyleProp<TextStyle>` literally.
 *
 * ── THE COERCION, STATED HONESTLY ──────────────────────────────────────────────────────────────
 *
 * The `Unsafe` submodule below holds `%identity` externals. `%identity` is a ZERO-RUNTIME TYPE
 * REINTERPRETATION: it emits no JavaScript, but it is a localized unsafe coercion and nothing in the
 * compiler checks it. This module contains the ONLY such coercion of a merchant style in the
 * library, and `scripts/verify-style-bridge.mjs` gates that fact.
 *
 * The invariant that makes the WRITE direction valid:
 *
 *   1. TypeScript controls which values can enter. The published slot type IS React Native's own
 *      `StyleProp<ViewStyle>` / `StyleProp<TextStyle>`, so the only values a merchant can pass are
 *      values React Native itself accepts in a style prop.
 *   2. No runtime transformation is required or performed. Both representations are the same
 *      JavaScript value; there is nothing to convert, only a type to re-label.
 *   3. React Native flattens the result. `Style.array([base, merchant])` is a nested StyleProp,
 *      which every RN style prop accepts and flattens natively.
 *   4. The merchant style is appended AFTER the library style, which is what gives it precedence on
 *      conflicting keys.
 *
 * The READ direction is guarded differently: it runs only on the output of `StyleSheet.flatten`,
 * which is a plain string-keyed object by construction, and every value read from it goes through a
 * checked decoder rather than being assumed to have a type.
 *
 * Safety rests on React Native accepting the same runtime values on both sides of the relabelling.
 * That is not self-evident, so it is protected by tests: `scripts/verify-style-bridge.mjs` compiles
 * a packed consumer against the real React Native types with non-vacuous negative controls, and
 * `example/__tests__/fieldStyles.test.tsx` exercises objects, registered style IDs, arrays, nested
 * arrays, `null`, `undefined` and `false` through the rendered tree.
 *
 * Inside ReScript these values stay abstract: the library can pass them onward but cannot construct
 * one. No slot is readable back out to a merchant, and nothing on this path touches a card value.
 */

@genType.import(("./styleTypes", "VaultViewStyleProp"))
type viewStyleProp

@genType.import(("./styleTypes", "VaultTextStyleProp"))
type textStyleProp

/*
 * The full slot set. Used by the card-number and CVC fields, which both render an accessory.
 *
 * `helperText` is deliberately absent: no helper-text element is rendered anywhere yet, and a slot
 * that silently does nothing is worse than no slot at all.
 */
@genType
type fieldStyles = {
  /* the outermost wrapper, including the error slot beneath the input */
  root?: viewStyleProp,
  /* the bordered input box */
  container?: viewStyleProp,
  /* the TextInput itself */
  input?: textStyleProp,
  /* the resting placeholder text */
  placeholder?: textStyleProp,
  /* the floating label text */
  label?: textStyleProp,
  /* the validation error message */
  error?: textStyleProp,
  /* the icon container to the right of the input */
  accessory?: viewStyleProp,
}

/*
 * The expiry field renders NO accessory. `CardFields.Expiry` never passes `iconRight`, so
 * `CardInput` matches `NoIcon` and returns `React.null` — there is no element for an `accessory`
 * style to reach. Rather than accept and silently ignore the slot, or render an empty View purely to
 * make the API look uniform, the expiry type simply does not have it.
 */
@genType
type expiryStyles = {
  root?: viewStyleProp,
  container?: viewStyleProp,
  input?: textStyleProp,
  placeholder?: textStyleProp,
  label?: textStyleProp,
  error?: textStyleProp,
}

/* The ready-made form's grouped prop: one style record per field, all optional. */
@genType
type formFieldStyles = {
  cardNumber?: fieldStyles,
  expiry?: expiryStyles,
  cvc?: fieldStyles,
  /* Renders no accessory, but keeps the full slot set for symmetry with the other text fields. */
  cardholderName?: fieldStyles,
}

/*
 * Widening, written out by hand rather than coerced. The expiry record is a strict subset of
 * `fieldStyles`, so the internal plumbing can carry one type; `accessory` is structurally
 * unreachable for expiry because a merchant has no way to set it.
 */
let widenExpiry = (styles: expiryStyles): fieldStyles => {
  root: ?styles.root,
  container: ?styles.container,
  input: ?styles.input,
  placeholder: ?styles.placeholder,
  label: ?styles.label,
  error: ?styles.error,
}

/*
 * The single approved coercion site. Nothing outside this module may reference `Unsafe.*`; the
 * containment is gated by `scripts/verify-style-bridge.mjs`, which fails the build if a `%identity`
 * over a merchant style appears in any other ReScript module under src, or if another module names
 * `Unsafe.` from this bridge. Field components call `withView` / `withText` below instead.
 */
module Unsafe = {
  /* WRITE direction: relabel a merchant StyleProp as the internal style representation. */
  external viewStyleToStyle: viewStyleProp => ReactNative.Style.t = "%identity"
  external textStyleToStyle: textStyleProp => ReactNative.Style.t = "%identity"

  /*
   * READ direction, used ONLY on a value that StyleSheet.flatten has already returned. Flatten
   * resolves registered IDs, arrays, nested arrays and falsy entries down to a single plain object,
   * so at that point the value genuinely is a string-keyed record and reading one key off it is
   * sound. Values are typed as JSON.t so every read has to go through a checked decoder — nothing
   * here assumes a key holds a number.
   */
  external flatStyleToDict: ReactNative.Style.t => Dict.t<JSON.t> = "%identity"
  external dictToTextStyleProp: Dict.t<JSON.t> => textStyleProp = "%identity"
}

/*
 * React Native's own flattener. Bound directly rather than via rescript-react-native's
 * `StyleSheet.flatten` because that binding takes `array<Style.t>` and cannot express the value we
 * actually hold: a single StyleProp that may be an object, a registered ID, an array, a nested
 * array, null, undefined or false. RN returns undefined for every falsy form.
 */
@module("react-native") @scope("StyleSheet")
external flattenStyleProp: ReactNative.Style.t => Nullable.t<ReactNative.Style.t> = "flatten"

/*
 * Merchant style is appended AFTER the library's own style, so it wins on conflicting keys — the
 * precedence the contract states (library defaults -> form appearance -> field styles). Absent a
 * merchant style the base is returned untouched, so a field with no `styles` prop produces exactly
 * the same style value it produced before this feature existed.
 */
let withView = (base: ReactNative.Style.t, override: option<viewStyleProp>) =>
  switch override {
  | None => base
  | Some(style) => ReactNative.Style.array([base, style->Unsafe.viewStyleToStyle])
  }

let withText = (base: ReactNative.Style.t, override: option<textStyleProp>) =>
  switch override {
  | None => base
  | Some(style) => ReactNative.Style.array([base, style->Unsafe.textStyleToStyle])
  }

let empty: fieldStyles = {}

let rootOf = (styles: option<fieldStyles>) => styles->Option.flatMap(s => s.root)
let containerOf = (styles: option<fieldStyles>) => styles->Option.flatMap(s => s.container)
let inputOf = (styles: option<fieldStyles>) => styles->Option.flatMap(s => s.input)
let placeholderOf = (styles: option<fieldStyles>) => styles->Option.flatMap(s => s.placeholder)
let labelOf = (styles: option<fieldStyles>) => styles->Option.flatMap(s => s.label)
let errorOf = (styles: option<fieldStyles>) => styles->Option.flatMap(s => s.error)
let accessoryOf = (styles: option<fieldStyles>) => styles->Option.flatMap(s => s.accessory)

let cardNumberOf = (styles: option<formFieldStyles>) => styles->Option.flatMap(s => s.cardNumber)
let expiryOf = (styles: option<formFieldStyles>) =>
  styles->Option.flatMap(s => s.expiry)->Option.map(widenExpiry)
let cvcOf = (styles: option<formFieldStyles>) => styles->Option.flatMap(s => s.cvc)
let cardholderNameOf = (styles: option<formFieldStyles>) =>
  styles->Option.flatMap(s => s.cardholderName)

/*
 * THE RUNTIME DEFENCE FOR THE ANIMATED LABEL.
 *
 * `fontSize` is the only animated key on the floating-label element. A static value in that slot
 * shadows the interpolation, which collapses AnimatedStyle and leaks an unresolved AnimatedNode to
 * the host — measured, see docs/phase-2a-style-bridge-spike.md. A TypeScript type cannot prevent
 * this: a `TextStyle`-annotated variable, a registered style, an array, a type assertion and any
 * JavaScript consumer all get through. So the value is taken away at runtime instead.
 *
 * The merchant's `fontSize` is not discarded — it becomes the ANIMATION ENDPOINT for that state,
 * which is what a merchant writing `placeholder: {fontSize: 18}` means. What is forwarded onward is
 * the rest of their style with `fontSize` removed, so nothing can shadow the interpolation.
 */
type animatedTextSlot = {
  fontSize: option<float>,
  rest: option<textStyleProp>,
}

let emptySlot: animatedTextSlot = {fontSize: None, rest: None}

/*
 * A font size is usable as an animation endpoint only when it is a finite, strictly positive
 * number. Everything else — a string from an untyped JavaScript consumer, NaN, ±Infinity, a
 * negative value, and ZERO — is stripped from the forwarded style but never becomes an endpoint.
 *
 * Zero is treated as invalid deliberately. React Native accepts `fontSize: 0` on a static text, but
 * as an animation endpoint it means the label shrinks to nothing at one end of the float, which is
 * a mistake far more often than an intention, and platforms disagree about how they lay out a
 * zero-size text node. A merchant who genuinely wants no label should not render one.
 */
let usableFontSize = (value: float) => Float.isFinite(value) && value > 0. ? Some(value) : None

/*
 * HORIZONTAL ALIGNMENT, read off the merchant's `input` slot.
 *
 * React Native's native placeholder inherits the TextInput's `textAlign`; the library-rendered
 * placeholder overlay is a separate element, so it has to be told. Without this a merchant who sets
 * `styles.input: {textAlign: "center"}` gets a centred value and a left-aligned placeholder, and
 * the text jumps sideways the moment they start typing.
 *
 * READ direction, so it goes through `flattenStyleProp` first — see Unsafe. An unrecognised value
 * (including one from an untyped JavaScript consumer) yields None and the default alignment.
 */
let textAlignOf = (slot: option<textStyleProp>): option<
  [#auto | #left | #right | #center | #justify],
> =>
  slot->Option.flatMap(style =>
    switch style->Unsafe.textStyleToStyle->flattenStyleProp->Nullable.toOption {
    | None => None
    | Some(flat) =>
      switch flat
      ->Unsafe.flatStyleToDict
      ->Dict.get("textAlign")
      ->Option.flatMap(JSON.Decode.string) {
      | Some("auto") => Some(#auto)
      | Some("left") => Some(#left)
      | Some("right") => Some(#right)
      | Some("center") => Some(#center)
      | Some("justify") => Some(#justify)
      | _ => None
      }
    }
  )

let splitAnimatedText = (slot: option<textStyleProp>): animatedTextSlot =>
  switch slot {
  | None => emptySlot
  | Some(style) =>
    switch style->Unsafe.textStyleToStyle->flattenStyleProp->Nullable.toOption {
    | None => emptySlot
    | Some(flat) =>
      let dict = flat->Unsafe.flatStyleToDict
      let fontSize =
        dict->Dict.get("fontSize")->Option.flatMap(JSON.Decode.float)->Option.flatMap(usableFontSize)
      let rest = dict->Dict.toArray->Array.filter(((key, _)) => key !== "fontSize")
      {
        fontSize,
        rest: rest->Array.length === 0
          ? None
          : Some(rest->Dict.fromArray->Unsafe.dictToTextStyleProp),
      }
    }
  }
