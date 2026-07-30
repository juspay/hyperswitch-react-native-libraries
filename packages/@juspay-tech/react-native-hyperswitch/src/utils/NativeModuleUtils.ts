import NativePaymentElementModule from '../codegen/modules/NativeWidgetHelperModule';

export const nativeConfirmPayment = (id: number, callback: (result: any) => void) => {
  NativePaymentElementModule.confirmPayment(id, (result: any) => {
    callback(result);
  });
};
