import { requireNativeComponent } from 'react-native';
import { isFabricEnabled } from '../utils/NewArchUtils';
import type { nativePaymentWidgetType } from '../types/NativeModuleTypes';

type NativePaymentWidgetComponent =
  React.ComponentType<nativePaymentWidgetType>;

const NativePaymentWidgetImpl: NativePaymentWidgetComponent =
  isFabricEnabled()
    ? (require('../specs/PaymentElementNativeComponent')
        .default as NativePaymentWidgetComponent)
    : (requireNativeComponent(
        'NativePaymentWidget'
      ) as NativePaymentWidgetComponent);

export default NativePaymentWidgetImpl;