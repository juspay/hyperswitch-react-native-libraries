import { nativeConfirmPayment } from '../utils/NativeModuleUtils';

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

export function confirmPayment(widgetId: string): Promise<string> {
  const nativeId = widgetHashMap[widgetId];
  if (nativeId !== undefined) {
    return new Promise((resolve) => {
      nativeConfirmPayment(nativeId, (result: any) => {
        resolve(result);
      });
    });
  }
  return Promise.resolve(JSON.stringify({
    status: 'failed',
    message: `Widget ${widgetId} not found or not mounted`,
    type: undefined,
  }));
}

// export function updateIntentInitForAllWidgets(): Promise<PaymentResult[]> {
//   const promises = Object.values(widgetHashMap)
//     .filter((nativeId): nativeId is number => nativeId !== undefined)
//     .map((nativeId) => {
//       return new Promise<PaymentResult>((resolve) => {
//         updateIntentInitForWidget(nativeId, (result: PaymentResult) => {
//           resolve(result);
//         });
//       });
//     });

//   return Promise.all(promises);
// }

// export function updateIntentCompleteForAllWidgets(
//   sdkAuthorization: string
// ): Promise<PaymentResult[]> {
//   const promises = Object.values(widgetHashMap)
//     .filter((nativeId): nativeId is number => nativeId !== undefined)
//     .map((nativeId) => {
//       return new Promise<PaymentResult>((resolve) => {
//         updateIntentCompleteForWidget(
//           nativeId,
//           sdkAuthorization,
//           (result: PaymentResult) => {
//             resolve(result);
//           }
//         );
//       });
//     });

//   return Promise.all(promises);
// }
