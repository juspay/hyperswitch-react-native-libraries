// ResponseHandler.res
// Native layer sends: { "status": string, "code": string?, "message": string, "data": Any? }
//
// Status normalization:
//   "succeeded" | "success" | "completed"  -> Succeeded
//   "failed"                                -> Failed
//   "cancelled"                             -> Cancelled
//   "error" | <anything else>               -> Error

let parseStatus = (raw: string): HyperTypes.responseStatus => {
  switch raw->Js.String2.toLowerCase {
  | "succeeded" | "success" | "completed" => Succeeded
  | "failed" => Failed
  | "cancelled" => Cancelled
  | _ => Error
  }
}

let parseNativeResponse = (result: 'a): HyperTypes.nativeResponse => {
  try {
    let json = switch Js.typeof(result) {
    | "string" => Js.Json.parseExn(result->Obj.magic)
    | _ => result->Obj.magic
    }
    switch Js.Json.decodeObject(json) {
    | Some(dict) =>
      let status =
        dict
        ->Js.Dict.get("status")
        ->Belt.Option.flatMap(Js.Json.decodeString)
        ->Belt.Option.getWithDefault("error")
        ->parseStatus

      let message =
        dict
        ->Js.Dict.get("message")
        ->Belt.Option.flatMap(Js.Json.decodeString)
        ->Belt.Option.getWithDefault("Unknown error")

      let code =
        dict
        ->Js.Dict.get("code")
        ->Option.flatMap(JSON.Decode.string)

      let data = dict->Js.Dict.get("data")

      switch (code, data) {
      | (Some(codeJson), Some(dataJson)) =>
        switch dataJson->Js.Json.decodeObject {
        | Some(_) => {status, message, code: codeJson, data: dataJson}
        | None => {status, message, code: codeJson, data: dataJson}
        }
      | (Some(codeJson), None) => {status, message, code: codeJson}
      | (None, Some(dataJson)) => {status, message, data: dataJson}
      | (None, None) => {status, message}
      }
    | None => {
        status: Error,
        message: "Invalid response format",
        code: "PARSE_ERROR",
      }
    }
  } catch {
  | _ => {
      status: Error,
      message: "Failed to parse response",
      code: "PARSE_ERROR",
    }
  }
}

let isSuccess = (response: HyperTypes.nativeResponse): bool => {
  switch response.status {
  | Succeeded => true
  | _ => false
  }
}

let isFailed = (response: HyperTypes.nativeResponse): bool => {
  switch response.status {
  | Failed => true
  | _ => false
  }
}

let isCancelled = (response: HyperTypes.nativeResponse): bool => {
  switch response.status {
  | Cancelled => true
  | _ => false
  }
}

let isError = (response: HyperTypes.nativeResponse): bool => {
  switch response.status {
  | Error => true
  | _ => false
  }
}

let getData = (response: HyperTypes.nativeResponse): option<Js.Json.t> => {
  response.data
}

let getCode = (response: HyperTypes.nativeResponse): option<string> => {
  response.code
}
