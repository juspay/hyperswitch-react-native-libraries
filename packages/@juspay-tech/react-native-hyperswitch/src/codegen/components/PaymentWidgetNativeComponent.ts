import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ViewProps } from 'react-native';
import { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';

export interface NativeProps extends ViewProps {
  widgetType?: string;
  sdkAuthorization?: string;
  options?: Readonly<{}>;
  onPaymentResult?: DirectEventHandler<{
    result?: string;
  }>;
  onPaymentEvent?: DirectEventHandler<{
    eventName: string;
    payload?: Readonly<{}>;
  }>;
}

export default codegenNativeComponent<NativeProps>('RCTNativePaymentWidget');
