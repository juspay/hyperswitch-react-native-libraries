// ResponseHandler.res
// Utility module for handling standardized responses from native layer

// Parse JSON string response into headlessResponse type
// Handles both string JSON and object inputs from native SDK
let parseResponse = (result: 'a): HyperTypes.headlessResponse => {
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

      let message =
        dict
        ->Js.Dict.get("message")
        ->Belt.Option.flatMap(Js.Json.decodeString)
        ->Belt.Option.getWithDefault("Unknown error")

      let code = dict->Js.Dict.get("code")

      let data = dict->Js.Dict.get("data")

      // Build the record - optional fields need special handling
      switch (code, data) {
      | (Some(codeJson), Some(dataJson)) =>
        switch (Js.Json.decodeString(codeJson), Js.Json.decodeObject(dataJson)) {
        | (Some(codeStr), Some(_)) => {status, message, code: codeStr, data: dataJson}
        | (Some(codeStr), None) => {status, message, code: codeStr, data: dataJson}
        | (None, Some(_)) => {status, message, data: dataJson}
        | (None, None) => {status, message, data: dataJson}
        }
      | (Some(codeJson), None) =>
        switch Js.Json.decodeString(codeJson) {
        | Some(codeStr) => {status, message, code: codeStr}
        | None => {status, message}
        }
      | (None, Some(dataJson)) => {status, message, data: dataJson}
      | (None, None) => {status, message}
      }
    | None => {
        status: "error",
        message: "Invalid response format",
        code: "PARSE_ERROR",
      }
    }
  } catch {
  | _ => {
      status: "error",
      message: "Failed to parse response",
      code: "PARSE_ERROR",
    }
  }
}

// Check if response is successful
let isSuccess = (response: HyperTypes.headlessResponse): bool => {
  response.status == "success"
}

// Check if response indicates failure
let isFailed = (response: HyperTypes.headlessResponse): bool => {
  response.status == "failed"
}

// Check if response indicates cancellation
let isCancelled = (response: HyperTypes.headlessResponse): bool => {
  response.status == "cancelled"
}

// Check if response indicates an error
let isError = (response: HyperTypes.headlessResponse): bool => {
  response.status == "error"
}

// Get data from response with type safety
let getData = (response: HyperTypes.headlessResponse): option<Js.Json.t> => {
  response.data
}

// Get code from response with type safety
let getCode = (response: HyperTypes.headlessResponse): option<string> => {
  response.code
}
