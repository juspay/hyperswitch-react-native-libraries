/*
 * The navigation vocabulary: what the host must do next, and nothing else.
 *
 * These types are declared HERE rather than inside `VaultFinalConfirm` for the same reason
 * `VaultFormOptions` declares `vaultEnvironment` itself: the transport modules carry no genType
 * annotations, so no published declaration may point at one. The merchant-facing names live in a
 * merchant-facing module, and the transport imports them rather than the other way round.
 *
 * Everything here is an allowlist. A confirm response can legitimately carry
 * `payment_method_data.card.*`; none of these records has a place to put it, so the decision about
 * what the host may observe is made by the SHAPE, not by remembering to filter at each call site.
 */

@genType
type nextActionType = [
  | #three_ds_invoke
  | #third_party_sdk_session_token
  | #display_bank_transfer_information
  | #invoke_ddc
  | #redirect_to_url
]

@genType
type safeThreeDs = {
  authenticationUrl: string,
  authorizeUrl: string,
  messageVersion: string,
  directoryServerId: string,
  pollId: string,
  delayInSecs: int,
  frequency: int,
}

@genType
type safeDdc = {
  iframeUrl: string,
  timeoutMs: int,
}

@genType
type safeSessionToken = {
  walletName: string,
  openBankingSessionToken: string,
}

@genType
type safeNextAction = {
  type_: nextActionType,
  redirectUrl?: string,
  threeDs?: safeThreeDs,
  ddc?: safeDdc,
  sessionToken?: safeSessionToken,
}
