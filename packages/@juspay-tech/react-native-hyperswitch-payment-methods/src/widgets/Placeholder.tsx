import { View } from 'react-native';
import type { FieldKind } from '../core/types';
import type { WidgetProps } from './types';

export function Placeholder({
  kind,
  style,
  testID,
}: WidgetProps & { kind: FieldKind }) {
  return (
    <View
      accessibilityState={{ busy: true }}
      style={style}
      testID={testID ?? `hs-placeholder-${kind}`}
    />
  );
}
