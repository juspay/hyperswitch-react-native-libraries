import { View } from 'react-native';
import type { ElementType } from '../core/types';
import type { FieldProps } from './types';

export function Placeholder({
  elementType,
  styles,
  testID,
}: FieldProps & { elementType: ElementType }) {
  return (
    <View
      accessibilityState={{ busy: true }}
      style={styles?.container}
      testID={testID ?? `hs-placeholder-${elementType}`}
    />
  );
}
