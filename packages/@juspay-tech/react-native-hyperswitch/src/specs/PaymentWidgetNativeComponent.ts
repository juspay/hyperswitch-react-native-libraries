import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ViewProps } from 'react-native';
import { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';

export interface NativeProps extends ViewProps {
  widgetId?: string;
  widgetType?: string;
  clientSecret?: string;
  options?: string;
  onPaymentResult?: DirectEventHandler<{
    paymentResult?: string;
    error?: string;
  }>;
}

export default codegenNativeComponent<NativeProps>('NativePaymentWidget');
