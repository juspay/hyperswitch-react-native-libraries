import { requireNativeComponent, type ViewProps } from 'react-native';

interface NativeProps extends ViewProps {
  buttonColor?: string;
  buttonLabel?: string;
  buttonSize?: string;
  borderRadius?: number;
}

export default requireNativeComponent<NativeProps>('PaypalButton');
