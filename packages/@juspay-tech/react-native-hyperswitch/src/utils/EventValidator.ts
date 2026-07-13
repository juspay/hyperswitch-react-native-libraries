const validEventStrings = [
  'PAYMENT_METHOD_INFO_CARD',
  'PAYMENT_METHOD_STATUS',
  'FORM_STATUS',
  'PAYMENT_METHOD_INFO_ADDRESS',
  'CVC_STATUS',
];

export function getValidEventsString(): string {
  return validEventStrings.join(', ');
}

export function validateSubscribedEventStrings(
  subscribedEvents: string[] | undefined
): string[] {
  if (!subscribedEvents) {
    return [];
  }
  return subscribedEvents.filter((event) => !validEventStrings.includes(event));
}

export type UnknownEventWarningPayload = {
  message: string;
  invalidEvents: string[];
  validEvents: string[];
};

export function makeUnknownEventWarningPayload(
  invalidEvents: string[]
): UnknownEventWarningPayload {
  const invalidEventsStr = invalidEvents.join(', ');
  const validEventsStr = getValidEventsString();
  return {
    message: `Unknown event(s) subscribed: [${invalidEventsStr}]. Valid events are: ${validEventsStr}`,
    invalidEvents,
    validEvents: validEventStrings,
  };
}
