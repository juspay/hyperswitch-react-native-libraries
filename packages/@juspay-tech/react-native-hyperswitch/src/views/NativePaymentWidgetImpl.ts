import { requireNativeComponent } from 'react-native';
import { isFabricEnabled } from '../utils/NewArchUtils';
import type { nativePaymentWidgetType } from '../types/NativeModuleTypes';

type NativePaymentWidgetComponent =
  React.ComponentType<nativePaymentWidgetType>;

const NativePaymentWidgetImpl: NativePaymentWidgetComponent = isFabricEnabled()
  ? (require('../specs/NativePaymentWidgetViewNativeComponent')
      .default as NativePaymentWidgetComponent)
  : (requireNativeComponent(
      'NativePaymentWidgetView'
    ) as unknown as NativePaymentWidgetComponent);

export default NativePaymentWidgetImpl;
