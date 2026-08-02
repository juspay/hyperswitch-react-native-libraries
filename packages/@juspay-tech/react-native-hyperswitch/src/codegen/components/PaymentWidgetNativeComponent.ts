import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ViewProps } from 'react-native';
import { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';
import type { options } from '../../types/PaymentSheetConfiguration';

/**
 * Allows using types that codegen doesn't support, which will be generated
 * as mixed, but keeping the TS type for type-checking.
 *
 * Note that for some reason this only works for native components, not for turbo modules.
 */
type UnsafeMixed<T> = T;

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

export default codegenNativeComponent<NativeProps>('RCTNativePaymentWidget');
