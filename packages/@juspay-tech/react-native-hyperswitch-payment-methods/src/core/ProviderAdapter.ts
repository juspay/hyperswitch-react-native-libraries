import type { ComponentType, ReactNode, Ref } from 'react';
import type { StyleProp, TextStyle, ViewStyle } from 'react-native';
import type {
  FieldKind,
  FieldState,
  SubmitResult,
  VaultType,
  WidgetHandle,
} from './types';

export interface ProviderHostProps<Collector = unknown, Data = unknown> {
  vaultData: Data;
  onReady: (collector: Collector) => void;
  onError: (error: unknown) => void;
  children: ReactNode;
}

export interface ProviderFieldProps<Collector = unknown> {
  kind: FieldKind;
  collector: Collector;
  style?: StyleProp<ViewStyle>;

  textStyle?: StyleProp<TextStyle>;
  placeholder?: string;
  testID?: string;
  onStateChange?: (state: FieldState) => void;

  fieldRef?: Ref<WidgetHandle>;
}

export interface ProviderAdapter<Collector = unknown, Data = unknown> {
  readonly vaultType: VaultType;

  validateVaultData(raw: unknown): Data;

  Host: ComponentType<ProviderHostProps<Collector, Data>>;

  Field: ComponentType<ProviderFieldProps<Collector>>;

  submit(collector: Collector, providerData?: unknown): Promise<SubmitResult>;
}
