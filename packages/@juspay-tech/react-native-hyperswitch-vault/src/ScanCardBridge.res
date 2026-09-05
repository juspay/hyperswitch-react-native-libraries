/*
 * Card scanning, through the SAME optional peer package client-core uses.
 *
 * ── WHY THIS IS NOT A NEW DEPENDENCY ───────────────────────────────────────────
 *
 * `@juspay-tech/react-native-hyperswitch-scancard` is a native module. This library has no native
 * code and does not want any, so the module is resolved exactly as client-core resolves it — a
 * `require` inside a `try`, with `isAvailable` false when the package is absent. A merchant who has
 * not installed it sees no scan button and no error; a merchant who has gets the same scanner they
 * had before, now feeding the library's fields instead of client-core's.
 *
 * It is deliberately NOT declared as an optional peer dependency in package.json: doing so would
 * put a native package in the dependency graph of a JS-only library, and every install-time tool
 * that resolves optional peers would start fetching it.
 *
 * ── THE SCANNED VALUES DO NOT LEAVE ────────────────────────────────────────────
 *
 * A scan produces a PAN and an expiry. They are dispatched into the same reducer a keystroke feeds,
 * and are subject to the same rule as anything typed: no callback reports them, and no public type
 * has a slot to carry them. The scanner is an input method, not a data source with its own posture.
 */

type scanCardData = {
  pan: string,
  expiryMonth: string,
  expiryYear: string,
}

type scanCardReturnType = {
  status: string,
  data: scanCardData,
}

type outcome =
  | Succeeded(scanCardData)
  | Failed
  | Cancelled
  | NoResult

type module_ = {
  launchScanCard: (scanCardReturnType => unit) => unit,
  isAvailable: bool,
}

@val external require: string => module_ = "require"

/*
 * Resolved once, at module load. A throw here means the package is not installed, which is the
 * normal case for most merchants and not an error.
 */
let (launchScanCardMod, isAvailable) = switch try {
  Some(require("@juspay-tech/react-native-hyperswitch-scancard"))
} catch {
| _ => None
} {
| Some(mod) => (mod.launchScanCard, mod.isAvailable)
| None => (_ => (), false)
}

let readOutcome = (result: scanCardReturnType): outcome =>
  switch result.status {
  | "Succeeded" =>
    Succeeded({
      pan: result.data.pan,
      expiryMonth: result.data.expiryMonth,
      expiryYear: result.data.expiryYear,
    })
  | "Cancelled" => Cancelled
  | "Failed" => Failed
  | _ => NoResult
  }

let launch = (callback: outcome => unit) =>
  try {
    launchScanCardMod(result => callback(result->readOutcome))
  } catch {
  | _ => callback(Failed)
  }

/*
 * A scanner reports the expiry as two fields; the field state holds one display string. Building
 * `MM / YY` here and pushing it through the ordinary expiry path means the scanned value is
 * formatted and validated by exactly the code a typed value goes through — no second, subtly
 * different parse that only scans can reach.
 */
let expiryDisplay = (data: scanCardData) => {
  let month = data.expiryMonth->String.trim
  let year = data.expiryYear->String.trim
  let shortYear = {
    let length = year->String.length
    length > 2 ? year->String.sliceToEnd(~start=length - 2) : year
  }
  month->String.length === 0 && shortYear->String.length === 0
    ? ""
    : `${month} / ${shortYear}`
}
