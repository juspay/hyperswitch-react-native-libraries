/**
 * Tracks whether the Hyperswitch SDK is currently initialising (or re-initialising
 * after a reload).  presentPaymentSheet should be blocked while this flag is true
 * so the native SDK is not asked to open a sheet before it is ready.
 *
 * Also tracks whether a payment sheet is currently presented so that a hot-reload
 * (or any other code path) cannot stack a second sheet on top of an open one.
 */

let _isInitializing = false;

export function setInitializing(value: boolean): void {
  _isInitializing = value;
}

export function isInitializing(): boolean {
  return _isInitializing;
}

let _isSheetPresented = false;

export function setSheetPresented(value: boolean): void {
  _isSheetPresented = value;
}

export function isSheetPresented(): boolean {
  return _isSheetPresented;
}
