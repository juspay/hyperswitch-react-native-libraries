/*
 * WHERE THE CARD CREDENTIAL FOR THE FINAL CONFIRM COMES FROM.
 *
 * `confirmPayment()` performs one final `/payments/{id}/confirm` in both client-core flows. What
 * differs is what stands in for the card in that request, and that is the ONLY thing this type
 * decides:
 *
 *   #vault  — mint a payment-method token first (call 1), then confirm with the token.
 *             Two requests. The token never leaves the library.
 *   #direct — no tokenization at all. Confirm with the library's own card values, written into
 *             `payment_method_data.card` by `VaultConfirmBody.buildDirect`.
 *             One request. No token exists in this flow.
 *
 * ── WHY THE SESSION LIVES HERE AND NOT ON THE COMPONENT ────────────────────────
 *
 * A vault session is meaningful only when tokenizing. Putting it inside the `#vault` member makes
 * "asked for the vault flow without a session" unrepresentable in TypeScript rather than a runtime
 * rejection, and it lets client-core mount ONE form for both of its flows — the flow is chosen at
 * confirm time, by the caller who actually knows the profile, not by which props were passed.
 *
 * The component's own `session` prop still exists and is still what Flow 1's `tokenize()` reads.
 * The two never compete: `tokenize()` never looks here, and `confirmPayment()` never looks there.
 *
 * ── WHY A RECORD AND NOT A `@tag` VARIANT ──────────────────────────────────────
 *
 * The same reason `VaultResult` is a record: ReScript compiles a payload-less variant constructor
 * to a BARE STRING, so `Direct` would have arrived as `"direct"` rather than `{type_: "direct"}`,
 * and `source.type_` would have been `undefined` for exactly the flow this correction adds.
 * `public.ts` republishes the record as a hand-written discriminated union so a merchant still gets
 * narrowing, and `verify-card-source.mjs` asserts the two describe the same runtime shapes.
 */

@genType.import(("./merchantTypes", "MerchantSession"))
type vaultSession

external sessionToJson: vaultSession => JSON.t = "%identity"

@genType
type cardSourceType = [#vault | #direct]

@genType
type paymentCardSource = {
  type_: cardSourceType,
  /* `#vault` only. Carries the vault `sdk_authorization` inside `vault_details`. */
  session?: vaultSession,
  /* `#vault` only. Chooses the PCI posture of the final confirm. Defaults to `#payment_token`. */
  confirmTokenMode?: VaultConfirmBody.confirmTokenMode,
}

/* What the coordinator switches on: every combination below is already known-good. */
type resolved =
  | VaultSource({session: JSON.t, confirmTokenMode: VaultConfirmBody.confirmTokenMode})
  | DirectSource

type rejection =
  /* `#vault` with no session, or a session that is not an object. */
  | MissingVaultSession
  /* `#direct` carrying tokenization settings — the caller believes something will be minted. */
  | ContradictorySource

/* A ReScript record IS its JS object, so this reads what a plain-JS caller actually passed. */
external asNullable: paymentCardSource => Nullable.t<paymentCardSource> = "%identity"

@get_index external unsafeField: (paymentCardSource, string) => option<unknown> = ""

/*
 * `#direct` is refused if it carries `session` or `confirmTokenMode`.
 *
 * Neither is read in direct mode, so ignoring them would "work" — and that is precisely the danger.
 * A caller who passes a vault session alongside `#direct` believes their card is being tokenized
 * and saved. It is not: the PAN goes straight to the payment confirm. Silently honouring the
 * request would give them the opposite of the posture they asked for, with no signal at all.
 */
let resolve = (source: paymentCardSource): result<resolved, rejection> =>
  switch source->asNullable->Nullable.toOption {
  | None => Error(MissingVaultSession)
  | Some(source) =>
    switch source.type_ {
    | #direct =>
      let carriesVaultSettings =
        source->unsafeField("session")->Option.isSome ||
          source->unsafeField("confirmTokenMode")->Option.isSome
      carriesVaultSettings ? Error(ContradictorySource) : Ok(DirectSource)
    | #vault =>
      switch source.session {
      | None => Error(MissingVaultSession)
      | Some(session) =>
        let json = session->sessionToJson
        switch json->JSON.Decode.object {
        | None => Error(MissingVaultSession)
        | Some(_) =>
          Ok(
            VaultSource({
              session: json,
              confirmTokenMode: source.confirmTokenMode->Option.getOr(#payment_token),
            }),
          )
        }
      }
    }
  }

/* Reported to the merchant without naming which member was wrong — both are integration errors. */
let describe = (rejection: rejection) =>
  switch rejection {
  | MissingVaultSession => #invalid_session
  | ContradictorySource => #unsupported_configuration
  }
