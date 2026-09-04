/*
 * The `locale` option, resolved the way hyperswitch-web resolves it: a BCP-47-ish code selects a
 * bundle of strings. The bundles are the SAME JSON files the web SDK ships (`shared-code/assets`),
 * reduced by `localeStrings.mjs` to the fifteen strings the card fields read.
 *
 * Resolution: the exact code, then its base language ("fr-CA" → "fr"), then English. English is
 * also the compile-time default — `LocaleDataType.defaultLocale` — so a bundle is never absent.
 */

type bundle = {
  localeDirection: string,
  cardNumberLabel: string,
  validThruText: string,
  cvcTextLabel: string,
  cardHolderName: string,
  expiryPlaceholder: string,
  cardNumberEmptyText: string,
  inValidCardErrorText: string,
  cardExpiryDateEmptyText: string,
  inValidExpiryErrorText: string,
  cvcNumberEmptyText: string,
  inValidCVCErrorText: string,
  unsupportedCardErrorText: string,
  cardNotEligibleText: string,
  selectCardBrand: string,
}

@module("./localeStrings.mjs") external bundles: Dict.t<bundle> = "localeStrings"

let english: bundle = {
  let d = LocaleDataType.defaultLocale
  {
    localeDirection: d.localeDirection,
    cardNumberLabel: d.cardNumberLabel,
    validThruText: d.validThruText,
    cvcTextLabel: d.cvcTextLabel,
    cardHolderName: d.cardHolderName,
    expiryPlaceholder: d.expiryPlaceholder,
    cardNumberEmptyText: d.cardNumberEmptyText,
    inValidCardErrorText: d.inValidCardErrorText,
    cardExpiryDateEmptyText: d.cardExpiryDateEmptyText,
    inValidExpiryErrorText: d.inValidExpiryErrorText,
    cvcNumberEmptyText: d.cvcNumberEmptyText,
    inValidCVCErrorText: d.inValidCVCErrorText,
    unsupportedCardErrorText: d.unsupportedCardErrorText,
    cardNotEligibleText: d.cardNotEligibleText,
    selectCardBrand: d.selectCardBrand,
  }
}

/* English is the record above, by identity, so callers can tell it from a loaded bundle. */
let isEnglish = (bundle: bundle) => bundle === english

/*
 * The code → language decision is sdk-utils' own (`LocaleDataType.localeStringToType`), so the set
 * of accepted spellings — "fr-CA" → French, "de-AT" → German, "iw" → Hebrew — is exactly the set
 * client-core accepts. An unrecognised code is English, as it is there.
 */
let resolve = (locale: option<string>): bundle =>
  switch locale->Option.map(String.trim) {
  | None | Some("") | Some("auto") => english
  | Some(code) =>
    switch LocaleDataType.localeStringToType(code) {
    | None | Some(LocaleDataType.En) => english
    | Some(known) =>
      bundles->Dict.get(LocaleDataType.localeTypeToString(Some(known)))->Option.getOr(english)
    }
  }
