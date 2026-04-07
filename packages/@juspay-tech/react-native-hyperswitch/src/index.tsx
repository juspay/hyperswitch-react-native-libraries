// index.tsx
// Main entry point for the React Native Hyperswitch SDK

// Hyper.init - Initialize the SDK with publishable key and profile id
export {
  init as HyperInit,
  initPaymentSession,
} from './core/Hyper.gen';

// PaymentSession type
export type {
  paymentSession as PaymentSession,
} from './types/HyperTypes.gen';

// HyperElements - Context provider component
export {
  make as HyperElements,
} from './core/HyperElements.gen';

// useWidget - Hook for accessing widget methods within HyperElements
export {
  useWidget,
} from './hooks/useWidget.gen';

// PaymentWidget - The payment widget component
export {
  make as PaymentWidget,
} from './views/PaymentWidget.gen';

export type {
  initPaymentSessionParams as InitPaymentSessionParams,
  initPaymentSessionResult as InitPaymentSessionResult,
  presentPaymentSheetParams as PresentPaymentSheetParams,
  presentPaymentSheetResult as PresentPaymentSheetResult,
  paymentResult as PaymentResult,
} from './modules/NativeHyperswitchSdk.gen';

export type { subscriptionEvent as PaymentEventName } from './types/PaymentSheetConfiguration.gen';

export type { cvcAppearance as CvcAppearance } from './types/PaymentSheetConfiguration.gen';

export type { cvcWidgetOptions as CvcInputOptions } from './types/PaymentSheetConfiguration.gen';

export type PaymentEvent = {
  eventName: string;
  payload?: Record<string, unknown>;
};

export {
  registerCallback,
  unregisterCallback,
} from './utils/PaymentSheetEventManager.res.js';

export type {
  widgetController as WidgetController,
} from './types/HyperTypes.gen';

export type {
  options as PaymentSheetOptions,
} from './types/PaymentSheetConfiguration.gen';

export type {
  hyperElementsOptions as HyperElementsOptions,
} from './core/HyperElements.gen';

export type { hyperInstance as HyperInstance } from './types/HyperTypes.gen';

export { make as CvcWidget } from './views/CvcWidget.gen';

// Headless Payment Response Types
export type {
  headlessResponse as HeadlessResponse,
  headlessResponseStatus as HeadlessResponseStatus,
  cardDetails as CardDetails,
  savedPaymentMethod as SavedPaymentMethod,
} from './modules/NativeHyperswitchSdk.gen';

