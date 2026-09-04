/*
 * The host's NON-CARD confirmation input: its narrow public types, a runtime rejector for card
 * keys, and the explicit wire encoding.
 *
 * ── THREE SEPARATE GUARANTEES ──────────────────────────────────────────────────
 *
 *   1. TYPES. `hostPaymentMethodData` is a closed record of closed records. It is deliberately not
 *      an open map or a `JSON.t`, so a TypeScript caller cannot even name a card field.
 *
 *   2. RUNTIME REJECTION. Types do not bind a plain-JavaScript caller, and an object that arrives
 *      from a server response can carry anything. `validateHostData` walks the value the host
 *      actually passed — every object key at every depth, and through arrays — and rejects the
 *      whole submission if a card key appears. It fails CLOSED: nothing is stripped and silently
 *      accepted, because silently repairing a caller that is trying to hand us a PAN would hide
 *      exactly the integration bug the merchant needs to fix.
 *
 *   3. EXPLICIT ENCODING. The host object is NEVER passed through to the wire. Every field is read
 *      by name and written to its snake_case backend key by the encoders below. A field this module
 *      does not know about cannot reach the request, so a future public field cannot leak by
 *      accident and a host's stray property cannot ride along.
 *
 * ── WHERE `nickName` GOES ──────────────────────────────────────────────────────
 *
 * `nickName` names the SAVED CARD, so it belongs to the payment-method-session confirm (call 1),
 * inside the card object, and nowhere else. `encodeBilling` — the only encoder the final confirm
 * uses — has no branch that can emit it, and `nickNameOf` is the only reader. Sending it on both
 * calls would put a merchant-supplied string in two request bodies for one intent.
 */

/* ── Public narrow types ───────────────────────────────────────────────────── */

@genType
type hostBillingAddress = {
  firstName?: string,
  lastName?: string,
  line1?: string,
  line2?: string,
  line3?: string,
  city?: string,
  state?: string,
  country?: string,
  zip?: string,
}

@genType
type hostPhone = {
  number?: string,
  countryCode?: string,
}

@genType
type hostBilling = {
  address?: hostBillingAddress,
  email?: string,
  phone?: hostPhone,
}

@genType
type hostPaymentMethodData = {
  billing?: hostBilling,
  /* Names the saved card. Call 1 only — see the module note. */
  nickName?: string,
}

/* A ReScript record IS its JS object at runtime, so this is a view, not a conversion. */
external toJson: hostPaymentMethodData => JSON.t = "%identity"

/* ── 2. Runtime rejection ──────────────────────────────────────────────────── */

/*
 * Exact key names, matched case-sensitively against every object key at every depth. Both the
 * backend spelling and the camelCase spelling of each concept are listed, because a host could
 * plausibly reach for either.
 */
let forbiddenKeys = [
  "card",
  "card_number",
  "cardNumber",
  "card_cvc",
  "cvc",
  "cvv",
  "card_exp_month",
  "card_exp_year",
  "expiry",
  "expiryMonth",
  "expiryYear",
  "card_holder_name",
  "cardHolderName",
  "cardholderName",
  "bin",
  "bin_number",
  "binNumber",
  "last4",
  "last_four",
  "last4_digits",
  "card_isin",
  "card_network",
  "cardNetwork",
  "brand",
  "payment_token",
  "paymentToken",
  "vault_card",
  "vaultCard",
  "card_token",
  "cardToken",
]

let isForbiddenKey = (key: string) => forbiddenKeys->Array.some(forbidden => forbidden === key)

/*
 * Depth is bounded so a cyclic or pathologically nested value cannot hang the submit. A value that
 * exceeds the bound is rejected rather than accepted unchecked — fail closed, again.
 */
let maxDepth = 32

let rec scan = (value: JSON.t, ~depth: int): result<unit, unit> =>
  if depth > maxDepth {
    Error()
  } else {
    switch value->JSON.Decode.object {
    | Some(dict) =>
      dict
      ->Dict.toArray
      ->Array.reduce(Ok(), (acc, (key, child)) =>
        switch acc {
        | Error() => Error()
        | Ok() => isForbiddenKey(key) ? Error() : child->scan(~depth=depth + 1)
        }
      )
    | None =>
      switch value->JSON.Decode.array {
      | Some(items) =>
        items->Array.reduce(Ok(), (acc, item) =>
          switch acc {
          | Error() => Error()
          | Ok() => item->scan(~depth=depth + 1)
          }
        )
      | None => Ok()
      }
    }
  }

let validateHostData = (value: JSON.t): result<unit, unit> => value->scan(~depth=0)

let validateHostPaymentMethodData = (data: option<hostPaymentMethodData>): result<unit, unit> =>
  switch data {
  | None => Ok()
  | Some(data) => data->toJson->validateHostData
  }

/* ── 3. Explicit encoding ──────────────────────────────────────────────────── */

/* Blank and whitespace-only host text is treated as absent rather than written as "". */
let entry = (key: string, value: option<string>) =>
  switch value {
  | Some(text) if text->String.trim->String.length > 0 =>
    Some((key, text->String.trim->JSON.Encode.string))
  | _ => None
  }

let objectOf = (entries: array<option<(string, JSON.t)>>): option<JSON.t> => {
  let kept = entries->Array.filterMap(item => item)
  kept->Array.length > 0 ? Some(kept->Dict.fromArray->JSON.Encode.object) : None
}

let encodeAddress = (address: hostBillingAddress): option<JSON.t> =>
  objectOf([
    entry("first_name", address.firstName),
    entry("last_name", address.lastName),
    entry("line1", address.line1),
    entry("line2", address.line2),
    entry("line3", address.line3),
    entry("city", address.city),
    entry("state", address.state),
    entry("country", address.country),
    entry("zip", address.zip),
  ])

let encodePhone = (phone: hostPhone): option<JSON.t> =>
  objectOf([entry("number", phone.number), entry("country_code", phone.countryCode)])

let encodeBilling = (billing: hostBilling): option<JSON.t> =>
  objectOf([
    billing.address->Option.flatMap(encodeAddress)->Option.map(json => ("address", json)),
    entry("email", billing.email),
    billing.phone->Option.flatMap(encodePhone)->Option.map(json => ("phone", json)),
  ])

/*
 * The final confirm's `payment_method_data`, from host input alone. Structurally incapable of
 * emitting `nick_name` or any card key: it reads exactly one member of `hostPaymentMethodData`.
 */
let encodeHostPaymentMethodData = (data: option<hostPaymentMethodData>): option<JSON.t> =>
  data
  ->Option.flatMap(data => data.billing)
  ->Option.flatMap(encodeBilling)
  ->Option.map(billing => [("billing", billing)]->Dict.fromArray->JSON.Encode.object)

/* The only reader of `nickName`, used by call 1. */
let nickNameOf = (data: option<hostPaymentMethodData>): option<string> =>
  data
  ->Option.flatMap(data => data.nickName)
  ->Option.flatMap(name => {
    let trimmed = name->String.trim
    trimmed->String.length > 0 ? Some(trimmed) : None
  })

/*
 * Attaches the library-owned card subtree LAST, by explicit key assignment on a fresh dictionary.
 * Never a deep merge: a merge would let a host-supplied structure influence where the card subtree
 * lands, and the whole point is that the library decides that alone.
 */
let buildFinalPaymentMethodData = (
  ~hostData: option<JSON.t>,
  ~cardSubtree: option<(string, JSON.t)>,
): option<JSON.t> => {
  let out = Dict.make()
  hostData
  ->Option.flatMap(JSON.Decode.object)
  ->Option.forEach(dict => dict->Dict.toArray->Array.forEach(((key, value)) => out->Dict.set(key, value)))
  cardSubtree->Option.forEach(((key, value)) => out->Dict.set(key, value))
  out->Dict.toArray->Array.length > 0 ? Some(out->JSON.Encode.object) : None
}
