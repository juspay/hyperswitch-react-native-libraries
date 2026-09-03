/*
 * INTERNAL. Validation for a host-supplied base URL.
 *
 * ── THE HOST OWNS THE ENDPOINT ─────────────────────────────────────────────────
 * The host that mounts the form is the authority on where its backend lives: client-core resolves
 * `hyperswitchConfig.customEndpoints` or its build-time environment host, and a standalone merchant
 * may run a self-hosted deployment. Every request the library sends therefore takes its base from
 * the host, and only falls back to the public-cloud host of the selected environment when the host
 * says nothing at all.
 *
 * Rejected: non-https (except loopback outside production); userinfo; query; fragment; unparseable.
 * A PATH PREFIX IS ACCEPTED (`https://checkout.hyperswitch.io/api`), normalised (trailing slashes
 * removed) and returned as part of the base; the library still appends its own route after it.
 *
 * Two bases exist because two backends MAY exist: `resolveBaseUrl` serves the payment calls
 * (eligibility, final confirm) and `resolveVaultBaseUrl` the payment-method-session confirm.
 */

@genType
type vaultEndpointConfig = {baseUrl: string}

type parsedUrl

@val @scope("globalThis") external urlConstructor: Nullable.t<'a> = "URL"
@new external makeUrl: string => parsedUrl = "URL"
@get external urlProtocol: parsedUrl => string = "protocol"
@get external urlHostname: parsedUrl => string = "hostname"
@get external urlUsername: parsedUrl => string = "username"
@get external urlPassword: parsedUrl => string = "password"
@get external urlPathname: parsedUrl => string = "pathname"
@get external urlSearch: parsedUrl => string = "search"
@get external urlHash: parsedUrl => string = "hash"
@get external urlOrigin: parsedUrl => string = "origin"

let loopbackHosts = ["localhost", "127.0.0.1", "10.0.2.2"]

let allowsCleartext = (environment: VaultConfirm.vaultEnvironment) =>
  switch environment {
  | #sandbox | #integration => true
  | #production => false
  }

/* `/api/` → `/api`, `/` → ``. The parser has already normalised dot segments and encoding. */
let normalisePath = (path: string) => path->String.replaceRegExp(%re("/\/+$/"), "")

let validateEndpoint = (
  endpoint: option<vaultEndpointConfig>,
  ~environment: VaultConfirm.vaultEnvironment,
): result<option<string>, unit> =>
  switch endpoint {
  | None => Ok(None)
  | Some({baseUrl}) =>
    let trimmed = baseUrl->String.trim
    if trimmed->String.length === 0 {
      Error()
    } else {
      switch urlConstructor->Nullable.toOption {
      | None => Error()
      | Some(_) =>
        switch try {Some(makeUrl(trimmed))} catch {
        | _ => None
        } {
        | None => Error()
        | Some(url) =>
          let protocol = url->urlProtocol
          let hostname = url->urlHostname
          let isLoopback = loopbackHosts->Array.some(host => host === hostname)
          let schemeOk =
            protocol === "https:" ||
              (protocol === "http:" && isLoopback && environment->allowsCleartext)
          let hasCredentials =
            url->urlUsername->String.length > 0 || url->urlPassword->String.length > 0
          let hasQuery = url->urlSearch->String.length > 0
          let hasHash = url->urlHash->String.length > 0

          if schemeOk && !hasCredentials && !hasQuery && !hasHash {
            Ok(Some(url->urlOrigin ++ url->urlPathname->normalisePath))
          } else {
            Error()
          }
        }
      }
    }
  }

let defaultBaseUrl = (environment: VaultConfirm.vaultEnvironment) =>
  switch environment {
  | #production => "https://checkout.hyperswitch.io/api"
  | #integration => "https://dev.hyperswitch.io/api"
  | #sandbox => "https://beta.hyperswitch.io/api"
  }

let resolveBaseUrl = (endpoint, ~environment: VaultConfirm.vaultEnvironment): result<string, unit> =>
  switch endpoint->validateEndpoint(~environment) {
  | Error() => Error()
  | Ok(None) => Ok(environment->defaultBaseUrl)
  | Ok(Some(base)) => Ok(base)
  }

/* The payment-method-session confirm base. Same validation; its own default. */
let resolveVaultBaseUrl = (endpoint, ~environment: VaultConfirm.vaultEnvironment): result<
  string,
  unit,
> =>
  switch endpoint->validateEndpoint(~environment) {
  | Error() => Error()
  | Ok(None) => Ok(environment->VaultConfirm.vaultBaseUrl)
  | Ok(Some(base)) => Ok(base)
  }
