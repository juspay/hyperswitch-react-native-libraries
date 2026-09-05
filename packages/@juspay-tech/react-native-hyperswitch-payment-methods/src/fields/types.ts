import type { StyleProp, TextStyle, ViewStyle } from 'react-native';
import type { FieldChange, FieldEvent } from '../core/types';

/** Style slots, named as the Hyperswitch vault fields name them. */
export interface FieldStyles {
  /** The field's box: border, background, radius, height, padding. */
  container?: StyleProp<ViewStyle>;
  /** The secure input's text: color, size, family. Ignored by providers that cannot style text. */
  input?: StyleProp<TextStyle>;
}

export interface FieldProps {
  styles?: FieldStyles;
  placeholder?: string;
  testID?: string;

  /** The provider's input is mounted. */
  onReady?: (event: FieldEvent) => void;
  onFocus?: (event: FieldEvent) => void;
  onBlur?: (event: FieldEvent) => void;
  /** The web's `change`: `{elementType, empty, complete, valid, brand?, error?, touched}`. */
  onChange?: (change: FieldChange) => void;
}
