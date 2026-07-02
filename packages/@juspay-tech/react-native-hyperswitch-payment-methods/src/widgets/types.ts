import type { StyleProp, TextStyle, ViewStyle } from 'react-native';
import type { FieldState } from '../core/types';

export interface WidgetProps {
  style?: StyleProp<ViewStyle>;

  textStyle?: StyleProp<TextStyle>;
  placeholder?: string;
  testID?: string;

  onStateChange?: (state: FieldState) => void;
}
