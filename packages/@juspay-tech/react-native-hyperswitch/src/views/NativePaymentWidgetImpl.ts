import { requireNativeComponent } from 'react-native';
import { isFabricEnabled } from '../utils/NewArchUtils';
import type { nativePaymentWidgetType } from '../types/NativeModuleTypes';

type NativePaymentWidgetComponent =
  React.ComponentType<nativePaymentWidgetType>;

let NativePaymentWidgetImpl: NativePaymentWidgetComponent;

if (isFabricEnabled()) {
  const turboPaymentWidget = require('../specs/PaymentWidgetNativeComponent')
    .default as NativePaymentWidgetComponent;
  NativePaymentWidgetImpl = turboPaymentWidget;
} else {
  NativePaymentWidgetImpl = requireNativeComponent(
    'NativePaymentWidget'
  ) as NativePaymentWidgetComponent;
}

export default NativePaymentWidgetImpl;
