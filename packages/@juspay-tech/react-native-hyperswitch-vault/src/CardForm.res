@genType
type widgetHandle = {
  focus: unit => unit,
  blur: unit => unit,
  /* The web's `field.clear()`: this field's value and interaction state, back to mount. */
  clear: unit => unit,
}

@genType
let make = React.forwardRef((
  props: {
    /*
     * OPTIONAL. It backs `tokenize()` only. A form mounted without one still confirms payments:
     * `confirmPayment` reads its session from `cardSource`, and the direct source needs none.
     * `sdkAuthorization` is the web SDK's spelling of the same credential and is accepted instead.
     */
    "session": option<VaultFormOptions.vaultSession>,
    "sdkAuthorization": option<string>,
    /* The web SDK's `vaultDetails` option: `{vaultType, vaultData: {sdkAuthorization}}`. */
    "vaultDetails": option<VaultDetails.vaultDetails>,
    "environment": VaultFormOptions.vaultEnvironment,
    "appearance": option<VaultFormOptions.appearance>,
    /* A locale code, as on the web: selects the sdk-utils string bundle. */
    "locale": option<string>,
    "localisation": option<VaultFormOptions.localisation>,
    "disabled": option<bool>,
    "accessible": option<bool>,
    "enabledCardSchemes": option<array<string>>,
    "eligibility": option<VaultFormOptions.eligibilityConfig>,
    /*
     * Where `tokenize()` posts the payment-method-session confirm. A self-hosted deployment sets
     * it; absent means the public-cloud host of `environment`. Validated like every other base.
     */
    "vaultEndpoint": option<VaultEndpoint.vaultEndpointConfig>,
    /*
     * A custom layout renders `<CardholderNameField />` itself, so this does not decide what is on
     * screen here: it decides whose value the confirmation uses.
     */
    "cardholderName": option<CardFieldOptions.cardholderNameMode>,
    /*
     * The web's group events. `ready` fires whenever every required field becomes complete;
     * `change` fires once after mount and again whenever the snapshot actually changes, by
     * structural comparison. Passing an inline arrow function is safe.
     */
    "onReady": option<VaultPublicState.cardFormEvent => unit>,
    "onChange": option<VaultPublicState.cardFormChange => unit>,
    /*
     * Strip every field back to a bare `TextInput`. Behaviour and accessibility survive. A field
     * may override this in either direction with its own `unstyled`.
     */
    "unstyled": option<bool>,
    "children": React.element,
  },
  ref,
) => {
  let host = VaultFormHost.useHost(
    ~session=props["session"]->Option.map(VaultFormOptions.sessionToJson),
    ~sdkAuthorization=props["sdkAuthorization"],
    ~vaultDetails=props["vaultDetails"],
    ~environment=props["environment"],
    ~appearance=props["appearance"],
    ~locale=props["locale"],
    ~localisation=props["localisation"],
    ~disabled=props["disabled"]->Option.getOr(false),
    ~accessible=props["accessible"],
    ~enabledCardSchemes=props["enabledCardSchemes"]->Option.getOr([]),
    ~eligibility=props["eligibility"],
    ~vaultEndpoint=props["vaultEndpoint"],
    ~cardholderNameMode=props["cardholderName"]->Option.getOr(#collect),
    ~onReady=props["onReady"],
    ~onChange=props["onChange"],
    ~unstyled=props["unstyled"]->Option.getOr(CardFieldOptions.defaultUnstyled),
    /*
     * The merchant placed these fields and draws their own chrome, so the library tints an invalid
     * field and reports the message on `change`, printing none itself. A field can still opt in
     * with `errorDisplay="inline"`.
     */
    ~defaultErrorDisplay=CardFieldOptions.defaultErrorDisplayComposable,
  )

  React.useImperativeHandle0(ref, () => {
    VaultFormOptions.tokenize: host.machinery.tokenize,
    confirmPayment: host.machinery.confirmPayment,
    reset: host.machinery.reset,
    focus: host.focusField,
  })

  <VaultWidgetContext.ContextProvider value={Some(host.contextValue)}>
    {props["children"]}
  </VaultWidgetContext.ContextProvider>
})
