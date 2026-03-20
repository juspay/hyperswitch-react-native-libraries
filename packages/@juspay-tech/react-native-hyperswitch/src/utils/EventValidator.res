let validEventStrings = [
  "PAYMENT_METHOD_INFO_CARD",
  "PAYMENT_METHOD_STATUS",
  "FORM_STATUS",
  "PAYMENT_METHOD_INFO_ADDRESS",
]

let getValidEventsString = () => {
  validEventStrings->Array.join(", ")
}

let validateSubscribedEventStrings = (subscribedEvents: option<array<string>>): array<string> => {
  switch subscribedEvents {
  | None => []
  | Some(events) =>
    events->Array.filter(event => !(validEventStrings->Array.includes(event)))
  }
}

type unknownEventWarningPayload = {
  message: string,
  invalidEvents: array<string>,
  validEvents: array<string>,
}

let makeUnknownEventWarningPayload = (invalidEvents: array<string>): unknownEventWarningPayload => {
  let invalidEventsStr = invalidEvents->Array.join(", ")
  let validEventsStr = getValidEventsString()
  {
    message: "Unknown event(s) subscribed: [" ++ invalidEventsStr ++ "]. Valid events are: " ++ validEventsStr,
    invalidEvents,
    validEvents: validEventStrings,
  }
}
