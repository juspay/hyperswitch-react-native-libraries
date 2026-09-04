/*
 * INTERNAL. Assembly of the final `/payments/{id}/confirm` body.
 *
 * Every value on the wire is written here, by name, from a closed type. Nothing the host passes is
 * spread, merged or forwarded as an object — see `VaultPaymentMethodData` for why that matters.
 *
 * ── CLOSED UNIONS, NOT STRINGS ─────────────────────────────────────────────────
 *
 * `paymentMethodType`, `paymentType` and `acceptanceType` are closed unions rather than the bare
 * strings an earlier draft had. A bare string is a silent failure channel: `"Credit"` or
 * `"newMandate"` would typecheck, reach the backend, and come back as an opaque rejection the
 * merchant then has to debug from a generic error message. The union makes the mistake a compile
 * error in TypeScript and unrepresentable in ReScript, and the wire spellings below are the single
 * place the backend's casing is decided.
 */

@genType
type paymentMethodType = [#credit | #debit]

/* `normal` is the absence of a mandate, so it is not a member: the field is simply omitted. */
@genType
type paymentType = [#new_mandate | #setup_mandate]

@genType
type acceptanceType = [#online | #offline]

/*
 * PCI posture of the final confirm:
 *   #payment_token — the token travels top-level as `payment_token`. The default.
 *   #vault_card    — the token stands in for the card fields inside `payment_method_data.vault_card`,
 *                    for accounts whose processor expects that shape.
 */
@genType
type confirmTokenMode = [#payment_token | #vault_card]

/*
 * Scalars only. The library runs in JavaScript and has no access to device metrics, so every value
 * here is supplied by the host; none of them is card-derived.
 */
@genType
type hostBrowserInfo = {
  userAgent?: string,
  acceptHeader?: string,
  language?: string,
  colorDepth?: int,
  screenHeight?: int,
  screenWidth?: int,
  timeZone?: int,
  javaEnabled?: bool,
  javaScriptEnabled?: bool,
  deviceModel?: string,
  osType?: string,
  osVersion?: string,
}

@genType
type hostOnlineAcceptance = {userAgent?: string}

@genType
type hostCustomerAcceptance = {
  acceptanceType: acceptanceType,
  acceptedAt: string,
  online: hostOnlineAcceptance,
}

let paymentMethodTypeToWire = (value: paymentMethodType) =>
  switch value {
  | #credit => "credit"
  | #debit => "debit"
  }

let paymentTypeToWire = (value: paymentType) =>
  switch value {
  | #new_mandate => "new_mandate"
  | #setup_mandate => "setup_mandate"
  }

let acceptanceTypeToWire = (value: acceptanceType) =>
  switch value {
  | #online => "online"
  | #offline => "offline"
  }

/*
 * ── THE CARD NETWORK THAT MAY GO ON THE WIRE ───────────────────────────────────
 *
 * `card_network` is an ENUM on the backend (`common_enums::CardNetwork`), not a free string. Every
 * scheme this library can detect was checked against it: all of them match by name except `BAJAJ`
 * and `SODEXO`, which the enum has no member for.
 *
 * Sending an unmappable value would turn a payment that works today into a 400 on an enum parse —
 * a strictly worse outcome than not declaring the network at all, because the backend derives the
 * brand from the PAN regardless. So the allowlist is exhaustive and anything outside it is OMITTED,
 * not guessed at and not passed through.
 */
let backendCardNetworks = [
  "Visa",
  "Mastercard",
  "AmericanExpress",
  "JCB",
  "DinersClub",
  "Discover",
  "CartesBancaires",
  "UnionPay",
  "Interac",
  "RuPay",
  "Maestro",
  "Star",
  "Pulse",
  "Accel",
  "Nyce",
]

let cardNetworkToWire = (network: option<string>): option<string> =>
  network->Option.flatMap(name => {
    let trimmed = name->String.trim
    backendCardNetworks->Array.some(known => known === trimmed) ? Some(trimmed) : None
  })

let stringEntry = VaultPaymentMethodData.entry

let intEntry = (key: string, value: option<int>) =>
  value->Option.map(number => (key, number->Int.toFloat->JSON.Encode.float))

let boolEntry = (key: string, value: option<bool>) =>
  value->Option.map(flag => (key, flag->JSON.Encode.bool))

let encodeBrowserInfo = (info: hostBrowserInfo): option<JSON.t> =>
  VaultPaymentMethodData.objectOf([
    stringEntry("user_agent", info.userAgent),
    stringEntry("accept_header", info.acceptHeader),
    stringEntry("language", info.language),
    intEntry("color_depth", info.colorDepth),
    intEntry("screen_height", info.screenHeight),
    intEntry("screen_width", info.screenWidth),
    intEntry("time_zone", info.timeZone),
    boolEntry("java_enabled", info.javaEnabled),
    boolEntry("java_script_enabled", info.javaScriptEnabled),
    stringEntry("device_model", info.deviceModel),
    stringEntry("os_type", info.osType),
    stringEntry("os_version", info.osVersion),
  ])

let encodeCustomerAcceptance = (acceptance: hostCustomerAcceptance): JSON.t => {
  let online =
    VaultPaymentMethodData.objectOf([stringEntry("user_agent", acceptance.online.userAgent)])
    ->Option.getOr(Dict.make()->JSON.Encode.object)

  [
    ("acceptance_type", acceptance.acceptanceType->acceptanceTypeToWire->JSON.Encode.string),
    ("accepted_at", acceptance.acceptedAt->JSON.Encode.string),
    ("online", online),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
}

/*
 * The `vault_card` subtree. The minted token stands in for the PAN and CVC; the expiry and the
 * masked digits come from what call 1 reported back, never from the card fields directly.
 *
 * `bin_number` is OMITTED when call 1 did not report one — the backend field is an Option, and an
 * empty string is a value, not an absence.
 */
let vaultCardSubtree = (~token: string, ~metadata: VaultConfirm.vaultCardMetadata): JSON.t =>
  [
    ("card_cvc", token->JSON.Encode.string),
    ("card_number", token->JSON.Encode.string),
    ("card_exp_month", metadata.expiryMonth->JSON.Encode.string),
    ("card_exp_year", metadata.expiryYear->JSON.Encode.string),
    ("last_four", metadata.last4Digits->JSON.Encode.string),
  ]
  ->Array.concat(VaultConfirm.optionalEntry("bin_number", metadata.binNumber))
  ->Dict.fromArray
  ->JSON.Encode.object

/*
 * ── THE CANONICAL PROVIDER-TOKENIZED CARD ──────────────────────────────────────
 *
 * A card tokenized by an EXTERNAL vault (VGS today), parsed into this shape by
 * @juspay-tech/react-native-hyperswitch-payment-methods — the package that owns provider
 * knowledge. This library never sees a provider response and never learns which provider made the
 * aliases: the backend resolves the vault connector from the merchant profile, so no provenance
 * field exists here.
 *
 * `cardNumberAlias` / `cardCvcAlias` are the provider's stand-in strings. The library cannot
 * cryptographically prove a string is an alias rather than a PAN; the boundary is which package may
 * reach this type at all (the orchestration entry, never the merchant root).
 *
 * `lastFour` / `binNumber` are PROVIDER-REPORTED metadata or nothing. They are never derived from
 * the alias: a format-preserving alias's digits are not the card's digits, so a sliced "BIN" would
 * be fabricated data on a payment request.
 */
@genType
type providerTokenizedCard = {
  cardNumberAlias: string,
  cardCvcAlias: string,
  expiryMonth: string,
  expiryYear: string,
  cardHolderName?: string,
  cardNetwork?: string,
  lastFour?: string,
  binNumber?: string,
  nickName?: string,
}

/* "3" → "03"; already-two-digit months pass through untouched. */
let padExpiryMonth = (month: string) => {
  let trimmed = month->String.trim
  trimmed->String.length === 1 ? `0${trimmed}` : trimmed
}

/*
 * The `vault_card` subtree for an EXTERNALLY tokenized card — the same backend shape as
 * `vaultCardSubtree`, fed by provider aliases instead of a minted token. Field names match the
 * backend's `ProxyCardData` exactly; `card_network` goes through the same enum allowlist as the
 * direct flow, and every optional value is omitted when absent, never written as "".
 */
let externalCardSubtree = (~card: providerTokenizedCard): JSON.t =>
  [
    ("card_number", card.cardNumberAlias->String.trim->JSON.Encode.string),
    ("card_cvc", card.cardCvcAlias->String.trim->JSON.Encode.string),
    ("card_exp_month", card.expiryMonth->padExpiryMonth->JSON.Encode.string),
    ("card_exp_year", card.expiryYear->VaultConfirm.requestExpiryYear->JSON.Encode.string),
  ]
  ->Array.concat(VaultConfirm.optionalEntry("card_holder_name", card.cardHolderName))
  ->Array.concat(VaultConfirm.optionalEntry("card_network", card.cardNetwork->cardNetworkToWire))
  ->Array.concat(VaultConfirm.optionalEntry("last_four", card.lastFour))
  ->Array.concat(VaultConfirm.optionalEntry("bin_number", card.binNumber))
  ->Array.concat(VaultConfirm.optionalEntry("nick_name", card.nickName))
  ->Dict.fromArray
  ->JSON.Encode.object

/*
 * The `card` subtree of the DIRECT confirm (Flow 3) — the real card values, read from the
 * library's own state at submit time and written straight into the request.
 *
 * This is the only place in the library where a PAN reaches a `/payments/{id}/confirm` body, and it
 * is reached only when the caller asked for `cardSource: {type_: #direct}`. Nothing here is
 * host-supplied: `VaultPaymentMethodData` rejects a caller who so much as names a card key.
 *
 * The encoding matches call 1 exactly — `clearSpaces` on the number, `requestExpiryYear` for the
 * four-digit year, blank-is-absent for the optional text. That deliberately differs from the
 * classic client-core body in two harmless ways: it strips the display spaces from the PAN, and it
 * expands a two-digit year. Both are the canonical wire forms, and both are already proven by call
 * 1, which has always sent them.
 */
let directCardSubtree = (
  ~card: VaultConfirm.cardDetails,
  ~cardholderName: option<string>,
  ~cardNetwork: option<string>,
  ~nickName: option<string>,
): JSON.t =>
  [
    ("card_number", card.cardNumber->Validation.clearSpaces->JSON.Encode.string),
    ("card_exp_month", card.expiryMonth->JSON.Encode.string),
    ("card_exp_year", card.expiryYear->VaultConfirm.requestExpiryYear->JSON.Encode.string),
    ("card_cvc", card.cvc->JSON.Encode.string),
  ]
  ->Array.concat(VaultConfirm.optionalEntry("card_holder_name", cardholderName))
  /*
   * Present only when a co-badged card gave the customer a real choice. On a single-network card
   * the brand is derivable from the PAN the backend already has, so sending it would add a value
   * without adding information.
   */
  ->Array.concat(VaultConfirm.optionalEntry("card_network", cardNetwork->cardNetworkToWire))
  /*
   * With no payment-method-session in this flow, the card object of the payment confirm is the
   * only place the saved-card nickname can go — which is where client-core's classic body put it.
   */
  ->Array.concat(VaultConfirm.optionalEntry("nick_name", nickName))
  ->Dict.fromArray
  ->JSON.Encode.object

/*
 * WHAT STANDS IN FOR THE CARD in the final confirm. One request builder, two credentials.
 *
 * Making this a closed variant rather than a pile of optional arguments is what stops the two
 * flows blurring: there is no way to call `build` with both a token and a PAN, and no way to call
 * it with neither.
 */
type cardPayload =
  | TokenPayload({
      mode: confirmTokenMode,
      token: string,
      metadata: VaultConfirm.vaultCardMetadata,
    })
  | DirectPayload({
      card: VaultConfirm.cardDetails,
      cardholderName: option<string>,
      cardNetwork: option<string>,
      nickName: option<string>,
    })
  /*
   * A card an EXTERNAL vault tokenized, handed in through the orchestration entry (never the
   * merchant root). Carries aliases only — the closed variant still makes "a token AND a PAN" and
   * "neither" unrepresentable.
   */
  | ExternalTokenPayload({card: providerTokenizedCard})

/*
 * `client_secret` is written ONLY for the legacy publishable-key credential
 * (`VaultCredential.clientSecretForBody`), and omitted — not blanked — for the payment-intent
 * credential. That reproduces client-core's own `generateCardConfirmBody`, which emits
 * `client_secret` exactly when `sdkAuthorization` is absent.
 */
let build = (
  ~cardPayload: cardPayload,
  ~paymentMethodType: option<paymentMethodType>,
  ~paymentMethodData: option<VaultPaymentMethodData.hostPaymentMethodData>,
  ~customerAcceptance: option<hostCustomerAcceptance>,
  ~browserInfo: option<hostBrowserInfo>,
  ~returnUrl: option<string>,
  ~paymentType: option<paymentType>,
  ~email: option<string>,
  ~clientSecret: option<string>,
): JSON.t => {
  let hostData = paymentMethodData->VaultPaymentMethodData.encodeHostPaymentMethodData

  let cardSubtree = switch cardPayload {
  | TokenPayload({mode: #vault_card, token, metadata}) =>
    Some(("vault_card", vaultCardSubtree(~token, ~metadata)))
  | TokenPayload({mode: #payment_token}) => None
  | DirectPayload({card, cardholderName, cardNetwork, nickName}) =>
    Some(("card", directCardSubtree(~card, ~cardholderName, ~cardNetwork, ~nickName)))
  | ExternalTokenPayload({card}) => Some(("vault_card", externalCardSubtree(~card)))
  }

  let finalPaymentMethodData =
    VaultPaymentMethodData.buildFinalPaymentMethodData(~hostData, ~cardSubtree)

  let entries = [
    Some(("payment_method", "card"->JSON.Encode.string)),
    Some((
      "payment_method_type",
      paymentMethodType->Option.getOr(#credit)->paymentMethodTypeToWire->JSON.Encode.string,
    )),
    switch cardPayload {
    | TokenPayload({mode: #payment_token, token}) => Some(("payment_token", token->JSON.Encode.string))
    | TokenPayload({mode: #vault_card}) => None
    /* No token exists in direct mode, so there is nothing that could be sent as one. */
    | DirectPayload(_) => None
    /* The aliases live inside vault_card; nothing here is a payment_token. */
    | ExternalTokenPayload(_) => None
    },
    finalPaymentMethodData->Option.map(data => ("payment_method_data", data)),
    customerAcceptance->Option.map(acceptance => (
      "customer_acceptance",
      acceptance->encodeCustomerAcceptance,
    )),
    browserInfo->Option.flatMap(encodeBrowserInfo)->Option.map(info => ("browser_info", info)),
    stringEntry("return_url", returnUrl),
    paymentType->Option.map(value => (
      "payment_type",
      value->paymentTypeToWire->JSON.Encode.string,
    )),
    stringEntry("email", email),
    /* Legacy credential only; `None` for the payment-intent credential, so the key is absent. */
    stringEntry("client_secret", clientSecret),
  ]

  entries->Array.filterMap(item => item)->Dict.fromArray->JSON.Encode.object
}
