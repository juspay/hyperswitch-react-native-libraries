
@genType
type widgetHandle = {
  focus: unit => unit,
  blur: unit => unit,
}

@genType
let make = React.forwardRef((
  props: {
    /*
     * OPTIONAL. It backs `tokenize()` only. A form mounted without one still confirms payments —
     * `confirmPayment` reads its session from `cardSource`, and the direct source needs none.
     */
    "session": option<VaultFormOptions.vaultSession>,
    "environment": VaultFormOptions.vaultEnvironment,
    "appearance": option<VaultFormOptions.appearance>,
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
     * screen here — it decides whose value the confirmation uses. `#collect` (the default) reads
     * the field the merchant placed; `#"external"` takes the value from the confirm input and the
     * merchant should place no field; `#omit` sends none.
     */
    "cardholderName": option<CardFieldOptions.cardholderNameMode>,
    /*
     * Called with one snapshot on mount and again whenever the snapshot actually changes, by
     * structural comparison. Passing an inline arrow function is safe: the callback is held in a
     * ref, so its identity changing emits nothing.
     */
    "onFormStateChange": option<VaultPublicState.vaultFormState => unit>,
    /*
     * Strip every field back to a bare `TextInput` — no border, background, fixed height,
     * placeholder, label, icon or error line. Behaviour and accessibility survive. A field may
     * override this in either direction with its own `unstyled`.
     */
    "unstyled": option<bool>,
    "children": React.element,
  },
  ref,
) => {
  let host = VaultFormHost.useHost(
    ~session=props["session"]->Option.map(VaultFormOptions.sessionToJson),
    ~environment=props["environment"],
    ~appearance=props["appearance"],
    ~localisation=props["localisation"],
    ~disabled=props["disabled"]->Option.getOr(false),
    ~accessible=props["accessible"],
    ~enabledCardSchemes=props["enabledCardSchemes"]->Option.getOr([]),
    ~eligibility=props["eligibility"],
    ~vaultEndpoint=props["vaultEndpoint"],
    ~cardholderNameMode=props["cardholderName"]->Option.getOr(#collect),
    ~onFormStateChange=props["onFormStateChange"],
    ~unstyled=props["unstyled"]->Option.getOr(CardFieldOptions.defaultUnstyled),
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
