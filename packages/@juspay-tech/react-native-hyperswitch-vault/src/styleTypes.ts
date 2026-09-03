/*
 * React Native style types, named so genType can import them by name.
 *
 * `@genType.import` takes a (module, exportedTypeName) pair, so it cannot reference a type
 * APPLICATION like `StyleProp<ViewStyle>` directly. Naming each application here gives genType
 * something to import, and makes the emitted declaration reference React Native's own types rather
 * than an opaque handle.
 *
 * This is the same mechanism `src/merchantTypes.ts` uses for `MerchantSession`.
 */
import type {StyleProp, ViewStyle, TextStyle} from 'react-native';

export type VaultViewStyleProp = StyleProp<ViewStyle>;
export type VaultTextStyleProp = StyleProp<TextStyle>;
