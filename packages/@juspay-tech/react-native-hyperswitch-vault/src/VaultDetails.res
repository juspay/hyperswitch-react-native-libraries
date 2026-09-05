/*
 * The web SDK's `vaultDetails` option, in its camelCase spelling:
 *
 *   {vaultType: 'hyperswitch', vaultData: {sdkAuthorization}}
 *
 * A merchant who holds the session's vault details but not the whole session response passes this
 * — with or without the top-level `sdkAuthorization` — exactly as `hyper.paymentMethodsSession`
 * takes it. The snake_case `session` prop (the backend response, verbatim) remains the other way in,
 * and the only one that carries `expires_at`.
 */
@genType
type vaultData = {
  sdkAuthorization?: string,
  /* VGS members the web's shape also carries. Accepted so the shape is the web's; unused here. */
  vaultId?: string,
  environment?: string,
}

@genType
type vaultDetails = {
  vaultType?: string,
  vaultData?: vaultData,
}
