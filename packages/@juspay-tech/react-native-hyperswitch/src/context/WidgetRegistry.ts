import {
  confirmPayment as nativeConfirmPayment,
  updateIntentInitForWidget,
  updateIntentCompleteForWidget,
} from '../modules/NativeHyperswitchSdk';
import type { paymentResult } from '../modules/NativeHyperswitchSdk';

const widgetHashMap: Record<string, number | undefined> = {};

export function registerWidget(widgetId: string, nativeViewId: number): void {
  widgetHashMap[widgetId] = nativeViewId;
}

export function getWidget(widgetId: string): number | undefined {
  return widgetHashMap[widgetId];
}

export function unregisterWidget(widgetId: string): void {
  delete widgetHashMap[widgetId];
}

export function confirmPayment(widgetId: string): Promise<paymentResult> {
  const nativeId = widgetHashMap[widgetId];
  if (nativeId !== undefined) {
    return new Promise((resolve) => {
      nativeConfirmPayment(nativeId, (result: paymentResult) => {
        resolve({
          status: result.status,
          message: result.message,
          type: result.type,
        });
      });
    });
  }
  return Promise.resolve({
    status: 'failed',
    message: `Widget ${widgetId} not found or not mounted`,
    type: undefined,
  });
}

export function updateIntentInitForAllWidgets(): Promise<paymentResult[]> {
  const promises = Object.values(widgetHashMap)
    .filter((nativeId): nativeId is number => nativeId !== undefined)
    .map((nativeId) => {
      return new Promise<paymentResult>((resolve) => {
        updateIntentInitForWidget(nativeId, (result: paymentResult) => {
          resolve(result);
        });
      });
    });

  return Promise.all(promises);
}

export function updateIntentCompleteForAllWidgets(
  sdkAuthorization: string
): Promise<paymentResult[]> {
  const promises = Object.values(widgetHashMap)
    .filter((nativeId): nativeId is number => nativeId !== undefined)
    .map((nativeId) => {
      return new Promise<paymentResult>((resolve) => {
        updateIntentCompleteForWidget(
          nativeId,
          sdkAuthorization,
          (result: paymentResult) => {
            resolve(result);
          }
        );
      });
    });

  return Promise.all(promises);
}
