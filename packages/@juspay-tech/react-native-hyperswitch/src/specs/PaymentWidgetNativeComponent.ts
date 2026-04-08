import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ViewProps } from 'react-native';
import { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';
import type {options} from '../types/PaymentSheetConfiguration.gen';
import { UnsafeMixed } from './utils';

export interface NativeProps extends ViewProps {
  widgetId?: string;
  widgetType?: string;
  sdkAuthorization?: string;
  options?: UnsafeMixed<options>;
  onPaymentResult?: DirectEventHandler<{
    paymentResult?: string;
    error?: string;
  }>;
  onPaymentEvent?: DirectEventHandler<{
    eventName: string;
    payload?: string;
  }>;
}

export default codegenNativeComponent<NativeProps>('NativePaymentWidget');
