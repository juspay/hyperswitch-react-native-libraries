
open ReactNative
open Style

@react.component
let make = (
  /*
   * `layout` and `fieldArrangement` replaced the previous `splitCardFields: bool`, which conflated
   * two independent questions and could not express the new default (three stacked, separate
   * fields). There is exactly one source of truth for each.
   */
  ~layout: CardFieldOptions.formLayout=#stacked,
  ~fieldArrangement: CardFieldOptions.fieldArrangement=#separate,
  /* Grouped per-field styles for the ready-made form (ADR-0002 §9 layer 2). */
  ~fieldStyles: option<CardFieldStyles.formFieldStyles>=?,
  /* Grouped per-field options: which visual elements exist. */
  ~fieldOptions: option<CardFieldOptions.formFieldOptions>=?,
  /* Whether this form renders a cardholder-name field at all. See `cardholderNameMode`. */
  ~cardholderName: CardFieldOptions.cardholderNameMode=#collect,
) => {
  let ctx = VaultWidgetContext.useRequired("CardFormView")
  let theme = ctx.theme
  let labels = ctx.labels
  let errors = ctx.controller.visibleErrors

  let numberStyles = fieldStyles->CardFieldStyles.cardNumberOf
  let expiryStyles = fieldStyles->CardFieldStyles.expiryOf
  let cvcStyles = fieldStyles->CardFieldStyles.cvcOf

  let cardholderStyles = fieldStyles->CardFieldStyles.cardholderNameOf

  let numberOptions = fieldOptions->CardFieldOptions.cardNumberOf
  let expiryOptions = fieldOptions->CardFieldOptions.expiryOf
  let cvcOptions = fieldOptions->CardFieldOptions.cvcOf
  let cardholderOptions = fieldOptions->CardFieldOptions.cardholderNameOf

  /*
   * `fused` is the only arrangement that halves shared borders and squares inner corners, and it is
   * only meaningful when the fields are adjacent. `separate` leaves every field with its own full
   * border, which is what the blank default renders.
   */
  let fused = fieldArrangement === #fused
  let inline = layout === #inline

  /*
   * Inline errors are per-field in every layout EXCEPT the fused one, where the three fields share
   * a single bottom line — there is nowhere else to put it. A field whose `errorDisplay` is `none`
   * still contributes nothing, in either layout.
   *
   * Read off the RESOLVED options, not re-derived here. Three hand-written `Option.getOr(#none)`
   * used to sit at this spot, one per field — a second definition of a default whose only other
   * home is `CardFieldOptions.resolveWith`. They agreed by coincidence, and the coincidence was
   * load-bearing: change the default in one place and this form paints error-coloured borders
   * (`CardInput` reads the resolved value) while refusing to render the message (this decides who
   * claims the fused line). Going through the resolver makes that divergence impossible, and makes
   * the compiler drag these three call sites along whenever the resolver's signature changes.
   */
  let rendersInline = (resolved: CardFieldOptions.resolved) => resolved.errorDisplay === #inline
  let resolveInline = resolve =>
    resolve(~formWideUnstyled=ctx.unstyled, ~labels)->rendersInline
  let numberInline = resolveInline(CardFieldOptions.resolveCardNumber(numberOptions, ...))
  let expiryInline = resolveInline(CardFieldOptions.resolveExpiry(expiryOptions, ...))
  let cvcInline = resolveInline(CardFieldOptions.resolveCvc(cvcOptions, ...))


  /*
   * In the FUSED arrangement the three fields share one bottom line, so at most one message can be
   * shown. Only a field that opted IN may claim it: previously any opt-in enabled the line and the
   * card number's error was shown first regardless, so enabling inline errors on the CVC alone
   * surfaced a card-number message the merchant had not asked for.
   *
   * `separate` needs none of this — each field's own `ErrorSlot` renders its own message.
   */
  let claim = (enabled, error) => enabled ? error : None

  /*
   * FORM-LEVEL messages — the unsupported-network rule and the eligibility denial. Neither belongs
   * to a field: one is about the network in force, the other is the backend's verdict on the card
   * as a whole.
   *
   * They are ordered LAST, after every field message, reproducing client-core's precedence — a
   * malformed number is a more actionable thing to tell the customer than a routing verdict on the
   * number they have not finished typing.
   *
   * Their opt-in and their style come from the card NUMBER, the form's anchor field. That is a
   * choice, not an oversight: a form-level message needs a declared owner, and attaching it to the
   * field the customer is looking at when it appears is the only owner that reads naturally.
   */
  let formLevelError = switch errors.network {
  | Some(error) => Some(error)
  | None => errors.eligibility
  }

  let fusedFieldError = if !fused {
    None
  } else {
    switch claim(numberInline, errors.cardNumber) {
    | Some(error) => Some((numberStyles, error))
    | None =>
      switch claim(expiryInline, errors.expiry) {
      | Some(error) => Some((expiryStyles, error))
      | None =>
        switch claim(cvcInline, errors.cvc) {
        | Some(error) => Some((cvcStyles, error))
        | None => claim(numberInline, formLevelError)->Option.map(error => (numberStyles, error))
        }
      }
    }
  }

  /*
   * In the SPLIT arrangement each field already renders its own message, so the form-level ones
   * need a line of their own rather than a share of somebody else's.
   */
  let splitFormError = fused ? None : claim(numberInline, formLevelError)

  /*
   * ERROR STYLE OWNERSHIP.
   *
   * In the SPLIT layout each field renders its own error, so each one uses its own `error` slot —
   * that is handled inside BoundCardFields and needs nothing here.
   *
   * In the FUSED layout the three fields share ONE error line at the bottom of the block, so a
   * single `error` style has to be chosen. The rule: the message belongs to a field, so the style
   * comes from that field. The network error is not owned by any field, so it falls back to the
   * card-number slot — the form's anchor field — and to the library default when that is unset.
   */
  let renderErrorWith = (errorStyle, message) =>
    <VaultWidgetContext.ErrorText
      message
      theme
      errorFontSize=ctx.errorFontSize
      errorSpacing=ctx.errorSpacing
      ?errorStyle
    />

  /*
   * Same shape as before: in the split layout each field renders its own message, in the fused
   * layout each field renders nothing and the shared line below does it. The only change is that
   * the split-layout renderer now carries THAT field's own `error` slot.
   */
  let perFieldError = (styles: option<CardFieldStyles.fieldStyles>) =>
    fused
      ? Some(_ => React.null)
      : Some(message => renderErrorWith(styles->CardFieldStyles.errorOf, message))

  <React.Fragment>
    <View style={s({marginBottom: theme.gap->dp})}>
      /*
       * Cardholder name: full width, ABOVE the card number, and deliberately OUTSIDE the fused
       * group below. It is optional and has no completion signal, so joining it to the
       * number/expiry/CVC block would imply a sequence and a shared border it is not part of.
       */
      /* `#external` and `#omit` both render nothing here; they differ only at confirm time. */
      <CardRenderIf condition={cardholderName === #collect}>
        <View style={s({width: 100.->pct, marginBottom: theme.gap->dp})}>
          <BoundCardFields.CardholderName
            ctx
            styles=?cardholderStyles
            options=?cardholderOptions
            renderError=?{Some(
              message => renderErrorWith(cardholderStyles->CardFieldStyles.errorOf, message),
            )}
          />
        </View>
      </CardRenderIf>
      <View style={s({width: 100.->pct, borderRadius: theme.borderRadius})}>
        <View
          style={s({
            width: 100.->pct,
            marginBottom: ?(fused ? None : Some(theme.gap->dp)),
          })}>
          <BoundCardFields.Number
            ctx
            styles=?numberStyles
            options=?numberOptions
            renderError=?{perFieldError(numberStyles)}
            /*
             * The accessory decides which slot this is — nothing, decoration, or a control —
             * because a co-badge chooser or a scan button can be warranted even with brand artwork
             * switched off.
             */
            iconRight={CardNumberAccessory.iconFor(
              ~ctx,
              ~brandIconMode=CardFieldOptions.resolveBrandIconMode(
                numberOptions,
                ~formWide=ctx.brandIconMode,
                ~unstyled=CardFieldOptions.unstyledFor(
                  numberOptions->Option.flatMap(o => o.unstyled),
                  ~formWide=ctx.unstyled,
                ),
              ),
            )}
            borderBottomWidth=?{fused ? Some(theme.borderWidth /. 2.) : None}
            borderBottomLeftRadius=?{fused ? Some(0.) : None}
            borderBottomRightRadius=?{fused ? Some(0.) : None}
          />
        </View>
        <View
          style={s({
            flexDirection: inline
              ? labels.isRtl ? #"row-reverse" : #row
              : #column,
            gap: ?(fused ? None : Some(theme.gap->dp)),
          })}>
          <View style={s({flex: ?(inline ? Some(1.) : None)})}>
            <BoundCardFields.Expiry
              ctx
              styles=?expiryStyles
              options=?expiryOptions
              renderError=?{perFieldError(expiryStyles)}
              borderTopWidth=?{fused ? Some(theme.borderWidth /. 2.) : None}
              /*
               * Which of the expiry's edges is SHARED depends on the layout, so each one is
               * conditioned on the adjacency that actually exists:
               *   inline  — the CVC sits to its right, so the right edge is shared;
               *   stacked — the CVC sits below it, so the bottom edge is shared.
               * Only the top edge is shared in both (the card number is always above).
               */
              borderRightWidth=?{fused && inline ? Some(theme.borderWidth /. 2.) : None}
              borderBottomWidth=?{fused && !inline ? Some(theme.borderWidth /. 2.) : None}
              borderTopLeftRadius=?{fused ? Some(0.) : None}
              borderTopRightRadius=?{fused ? Some(0.) : None}
              borderBottomRightRadius=?{fused ? Some(0.) : None}
              /* Stacked-fused makes this an interior corner; inline-fused leaves it the group's. */
              borderBottomLeftRadius=?{fused && !inline ? Some(0.) : None}
            />
          </View>
          <View style={s({flex: ?(inline ? Some(1.) : None)})}>
            <BoundCardFields.Cvc
              ctx
              styles=?cvcStyles
              options=?cvcOptions
              renderError=?{perFieldError(cvcStyles)}
              borderTopWidth={fused ? theme.borderWidth /. 2. : theme.borderWidth}
              borderLeftWidth={fused && inline ? theme.borderWidth /. 2. : theme.borderWidth}
              borderTopLeftRadius={fused ? 0. : theme.borderRadius}
              borderTopRightRadius={fused ? 0. : theme.borderRadius}
              /*
               * Inline-fused puts the CVC bottom-RIGHT, so its bottom-left is shared with the
               * expiry and squares off. Stacked-fused puts it at the bottom of the column, where
               * the bottom-left is the group's own outer corner and stays rounded.
               */
              borderBottomLeftRadius={fused && inline ? 0. : theme.borderRadius}
            />
          </View>
        </View>
      </View>
      /*
       * The FUSED shared line. Its condition is the presence of an eligible message, NOT "some
       * field opted in" — the previous form used any opt-in as permission and then showed whichever
       * field errored first, so `cvc: {errorDisplay: "inline"}` alone surfaced card-number text.
       *
       * The network and eligibility messages DO appear here now, last in the chain. They were
       * previously excluded because `validators.network` was `None` at every call site and the slot
       * could never be populated — a dead branch that would only ever have rendered some other
       * field's message under a heading that did not own it. Both now have a real source (the
       * merchant's accepted-scheme list, and the backend's eligibility verdict) and a declared owner
       * (the card-number field), which is what that exclusion was waiting for.
       */
      <CardRenderIf condition={fusedFieldError->Option.isSome}>
        {switch fusedFieldError {
        | Some((styles, error)) => renderErrorWith(styles->CardFieldStyles.errorOf, error)
        | None => React.null
        }}
      </CardRenderIf>
      /* The split layout's own line for the two messages no field owns. */
      <CardRenderIf condition={splitFormError->Option.isSome}>
        {switch splitFormError {
        | Some(error) => renderErrorWith(numberStyles->CardFieldStyles.errorOf, error)
        | None => React.null
        }}
      </CardRenderIf>
    </View>
  </React.Fragment>
}
