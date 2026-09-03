/*
 * One emission rule, shared by the field callbacks and the aggregate form callback.
 *
 * The contract it implements:
 *
 *   - exactly one initial snapshot, taken AFTER registration has run. The snapshot is built inside
 *     the effect, not during render, because a field registers itself in a child effect and child
 *     effects run before the parent's — so a render-time snapshot would report a registry that is
 *     one commit stale;
 *   - an emission whenever the public snapshot actually differs, by STRUCTURAL comparison;
 *   - no emission when only the callback's function identity changed. The callback is held in a
 *     ref that is refreshed every render, so a parent that passes an inline arrow function causes
 *     no emission and no re-registration;
 *   - no emission after unmount. Emission is synchronous inside an effect BODY, and React never
 *     runs an effect body for an unmounted component. Nothing is scheduled, so there is no queued
 *     call to cancel. An earlier revision also cleared the callback ref in a teardown; that was
 *     removed because React 19 Strict Mode replays effects (mount, cleanup, mount) and the teardown
 *     left the ref null between the replay and the next render — a window in which a genuine
 *     emission would have been silently dropped. It protected against nothing that could happen and
 *     created a hazard that could;
 *   - no render loop: nothing here sets state.
 *
 * The effect deliberately has NO dependency array. It runs after every commit and the equality
 * check decides whether to emit — which is what makes "the final snapshot corresponds to the latest
 * controller state" true under rapid typing, where several state updates can be batched into one
 * commit. A dependency array would have to list every public member and would drift.
 */

/*
 * ── A THROWING MERCHANT CALLBACK ───────────────────────────────────────────────────────────────
 *
 * FAIL_OPEN for the form, PROPAGATE-NON-FATAL for the error.
 *
 * An exception thrown from `notify` is merchant code failing inside OUR effect. Left alone it
 * unwinds to the nearest error boundary and takes card entry down with it — a bug in an analytics
 * handler must not stop a customer paying. Swallowed silently it becomes undebuggable, and this
 * library writes nothing to the console by design, so there is no third channel to report it on.
 *
 * `ErrorUtils.reportError` is the channel that does both. It calls React Native's global handler
 * with `isFatal = false`: a LogBox entry in development, a non-fatal report to whatever crash
 * reporter the app installed in production, and the session continues.
 *
 * An earlier revision re-raised inside `setTimeout(_, 0)` instead. That is WRONG in a release
 * build, and the difference is not cosmetic: a timer callback that throws is collected by
 * `JSTimers.callTimers`, rethrown into `MessageQueue.__guard`, and reported through
 * `ErrorUtils.reportFatalError` — `isFatal = true`, which `ExceptionsManager` routes to
 * `NativeExceptionsManager.reportException`, the native fatal path. In development it looks like a
 * harmless LogBox entry, which is exactly what made the mistake easy to keep. A merchant writing
 * `s.error.message` on a field whose `error` is absent would have crashed the customer's session.
 *
 * The call is deliberately unbound (`utils.reportError(exn)` rather than a bound method): the
 * polyfill's implementation closes over its module-level handler and reads no `this`.
 *
 * If the global is absent — a bare JS test runner, a web target without the polyfill — the error is
 * dropped. That is the last resort, not the design: there is no reporting channel left to use, and
 * killing the form is the one outcome that is definitely wrong.
 */
type errorUtils = {reportError: exn => unit}

@val @scope("globalThis") external errorUtils: Nullable.t<errorUtils> = "ErrorUtils"

/*
 * ReScript wraps a JS exception as `Js.Exn.Error(payload)`, so handing the caught value straight to
 * the reporter delivers `{RE_EXN_ID: "JsError", _1: …}` — an object with no `message` and no
 * `stack`. A crash reporter receiving that records that something failed and nothing about what.
 * Unwrapping restores the merchant's original `Error`; a ReScript-native exception has no JS Error
 * to recover and is passed through as-is.
 */
external asExn: Js.Exn.t => exn = "%identity"

/*
 * The reporting call is itself inside a `try`. `Nullable.toOption` guards the OBJECT but not the
 * CALL, and two reachable shapes escaped without this: an `ErrorUtils` without a `reportError`
 * (a TypeError), and a working `reportError` whose installed global handler throws — React
 * Native's own default handler has a `throw e` path if `handleException` fails
 * (`setUpErrorHandling.js`). Either one escaped `notifySafely`, escaped the effect body, and
 * unwound the commit: precisely the outcome this module exists to prevent, arriving through the
 * machinery meant to prevent it. RN's polyfill guards its own dispatch the same way.
 *
 * If reporting fails there is nothing left to report it to, so the error is dropped.
 */
let reportNonFatal = (exn: exn) =>
  try switch errorUtils->Nullable.toOption {
  | None => ()
  | Some(utils) =>
    utils.reportError(
      switch exn {
      | Js.Exn.Error(jsError) => asExn(jsError)
      | _ => exn
      },
    )
  } catch {
  | _ => ()
  }

/*
 * `lastRef` is updated BEFORE `notify` runs, so a throwing callback still advances the
 * de-duplication cursor. Otherwise every subsequent commit would re-emit the same snapshot and
 * re-report the same error, turning one merchant bug into an unbounded stream of them.
 */
let notifySafely = (fn: 'a => unit, value: 'a) =>
  try fn(value) catch {
  | exn => reportNonFatal(exn)
  }

let use = (~build: unit => 'a, ~equal: ('a, 'a) => bool, ~notify: option<'a => unit>) => {
  let notifyRef = React.useRef(notify)
  notifyRef.current = notify

  let lastRef: React.ref<option<'a>> = React.useRef(None)
  let listeningRef = React.useRef(notify->Option.isSome)

  React.useEffectOnEveryRender(() => {
    let listening = notifyRef.current->Option.isSome
    /*
     * Attaching a callback starts a fresh conversation. Without this, a merchant who removes a
     * callback and later restores it would get NO initial snapshot — `lastRef` would still hold the
     * value from the previous attachment, and an unchanged form would compare equal and stay
     * silent. Clearing the cursor on the None -> Some edge guarantees every attachment opens with
     * exactly one snapshot, which is the same guarantee a first mount gets.
     */
    if listening && !listeningRef.current {
      lastRef.current = None
    }
    listeningRef.current = listening

    /*
     * Nothing is built when no merchant is listening. The snapshot derivation is pure and cheap,
     * but "cheap" is not "free", and a form with no callback must cost exactly what it cost before
     * this module existed — which is the honest answer to ADR-0003's objection that emission is a
     * standing obligation.
     */
    switch notifyRef.current {
    | None => ()
    | Some(fn) =>
      let next = build()
      let changed = switch lastRef.current {
      | Some(previous) => !equal(previous, next)
      | None => true
      }
      if changed {
        lastRef.current = Some(next)
        notifySafely(fn, next)
      }
    }
    None
  })
}
