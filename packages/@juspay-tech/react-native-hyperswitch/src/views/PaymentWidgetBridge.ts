import { requireNativeComponent } from 'react-native';
import type { NativePaymentWidgetPropTypes } from '../types/NativeEventTypes';

declare global {
  var nativeFabricUIManager: unknown | null | undefined;
}

type NativePaymentWidgetComponent =
  React.ComponentType<NativePaymentWidgetPropTypes>;

const NativePaymentWidgetImpl: NativePaymentWidgetComponent =
  global.nativeFabricUIManager != null
    ? (require('../codegen/components/PaymentWidgetNativeComponent')
        .default as NativePaymentWidgetComponent)
    : (requireNativeComponent(
        'RCTNativePaymentWidget'
      ) as unknown as NativePaymentWidgetComponent);

export default NativePaymentWidgetImpl;
