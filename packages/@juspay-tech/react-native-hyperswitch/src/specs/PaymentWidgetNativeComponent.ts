import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ViewProps } from 'react-native';
import { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';
import type { options } from '../types/PaymentSheetConfiguration';
import { UnsafeMixed } from './utils';

export interface NativeProps extends ViewProps {
  widgetType?: string;
  sdkAuthorization?: string;
  options?: UnsafeMixed<options>;
  onPaymentResult?: DirectEventHandler<{
    result?: string;
  }>;
  onPaymentEvent?: DirectEventHandler<{
    eventName: string;
    payload?: UnsafeMixed<Record<string, any>>;
  }>;
}

export default codegenNativeComponent<NativeProps>('NativePaymentWidget');
