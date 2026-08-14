export interface HyperswitchVaultData {
  /**
   * Base64-encoded SDK authorization token from the sessions response
   * (`vault_details.vault_data.sdk_authorization`; the example reuses the
   * payment `sdk_authorization`). Sent as the `Authorization` header of the
   * confirm call. The `payment_method_session_id` is embedded inside this
   * token and decoded automatically.
   */
  sdk_authorization: string;

  /**
   * Optional explicit `payment_method_session_id` used in the confirm path
   * `/v1/payment-method-sessions/{id}/confirm`. When omitted, it is decoded
   * from the base64 payload of `sdk_authorization`.
   */
  payment_method_session_id?: string;

  /**
   * Explicit Hyperswitch app-backend base URL (no trailing slash) used for
   * the confirm call, e.g. `https://sandbox.hyperswitch.io/api`. When omitted
   * it is resolved from `environment`:
   *   live/prod → https://checkout.hyperswitch.io/api
   *   integ/dev → https://dev.hyperswitch.io/api
   *   sandbox   → https://beta.hyperswitch.io/api
   */
  api_base_url?: string;

  /**
   * Environment hint for resolving the default app-backend host.
   * Defaults to `sandbox`.
   */
  environment?: string;
}

export interface HyperswitchSubmitOptions {
  /**
   * HTTP method for the confirm call. Defaults to `POST`.
   */
  method?: string;

  /**
   * Extra non-sensitive payload merged at the top level of the request body
   * (alongside `payment_method_type` / `payment_method_data`).
   */
  extraData?: Record<string, unknown>;

  /**
   * Additional headers merged into the confirm request.
   */
  headers?: Record<string, string>;
}
