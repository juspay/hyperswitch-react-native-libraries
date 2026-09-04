/*
 * THE ONE SPELLING TABLE for a card-network name a merchant may hand us.
 *
 * Canonical spellings are `Validation.cardPatterns[].issuer` — "Visa", "AmericanExpress", "RuPay" —
 * and every comparison the library makes (`enabledCardSchemes`, the saved-card `cardNetwork`) is
 * against those exact strings. A merchant is just as likely to write what their own screen shows
 * ("American Express", "amex", "VISA"), and hyperswitch-web compares brands case-insensitively, so
 * a spelling that differs only in case or spacing must not silently fail to match.
 *
 * Case, spaces, hyphens and underscores are ignored. An unrecognised name is `None`, never passed
 * through: a string that can match nothing would otherwise block every card without a word.
 */

let canonical = [
  "Visa",
  "Mastercard",
  "AmericanExpress",
  "DinersClub",
  "Discover",
  "JCB",
  "CartesBancaires",
  "Interac",
  "Maestro",
  "UnionPay",
  "RuPay",
  "SODEXO",
  "BAJAJ",
]

let normalise = (name: string): option<string> =>
  switch name->String.toLowerCase->String.replaceRegExp(%re("/[\s_-]+/g"), "") {
  | "visa" => Some("Visa")
  | "mastercard" => Some("Mastercard")
  | "americanexpress" | "amex" => Some("AmericanExpress")
  | "dinersclub" | "diners" => Some("DinersClub")
  | "discover" => Some("Discover")
  | "jcb" => Some("JCB")
  | "cartesbancaires" => Some("CartesBancaires")
  | "interac" => Some("Interac")
  | "maestro" => Some("Maestro")
  | "unionpay" => Some("UnionPay")
  | "rupay" => Some("RuPay")
  | "sodexo" => Some("SODEXO")
  | "bajaj" => Some("BAJAJ")
  | _ => None
  }

/*
 * `__DEV__` is React Native's development flag. Read defensively so a plain Node consumer (the
 * verification scripts) where the global is absent sees `false` rather than a ReferenceError.
 */
let isDev: bool = %raw(`typeof __DEV__ !== "undefined" && __DEV__ === true`)

/*
 * A merchant's list, canonicalised. Unknown entries are DROPPED and reported in development — the
 * same treatment hyperswitch-web gives an unknown option value (warn, then ignore) — because an
 * unmatched entry that stayed in the list would reject every card the merchant meant to accept.
 */
let normaliseList = (names: array<string>): array<string> => {
  let unknown = names->Array.filter(name => name->normalise->Option.isNone)
  if isDev && unknown->Array.length > 0 {
    Console.warn(
      `[react-native-hyperswitch-vault] enabledCardSchemes: unknown value(s) ${unknown->Array.join(
          ", ",
        )} ignored. Expected one of ${canonical->Array.join(", ")}.`,
    )
  }
  names->Array.filterMap(normalise)
}
