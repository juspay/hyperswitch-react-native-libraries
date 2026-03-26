// index.tsx
// Main entry point for the React Native Hyperswitch SDK

// Hyper.init - Initialize the SDK with publishable key and profile id
export {
  init as HyperInit,
} from './core/Hyper.gen';

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

export type {
  hyperElementsContextData as HyperElementsContextData,
  widgetController as WidgetController,
} from './types/HyperTypes.gen';

export type {
  options as PaymentSheetOptions,
} from './types/PaymentSheetConfiguration.gen';

export type {
  hyperElementsOptions as HyperElementsOptions,
} from './core/HyperElements.gen';

export type {
  hyperInstance as HyperInstance,
} from './core/Hyper.gen';


