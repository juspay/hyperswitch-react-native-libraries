import type { ComponentType, ReactNode, Ref } from 'react';
import type { FieldStyles } from '../fields/types';
import type {
  CardDetails,
  ElementType,
  FieldChange,
  FieldEvent,
  FieldHandle,
  TokenizeResult,
  VaultType,
} from './types';

export interface ProviderHostProps<Collector = unknown, Data = unknown> {
  vaultData: Data;
  onReady: (collector: Collector) => void;
  onError: (error: unknown) => void;
  /** Card-level details a provider reports (BIN, last four, expiry parts), for `cardDetailsChange`. */
  onCardDetails?: (details: Partial<CardDetails>) => void;
  children: ReactNode;
}

export interface ProviderFieldProps<Collector = unknown> {
  elementType: ElementType;
  collector: Collector;
  styles?: FieldStyles;
  placeholder?: string;
  testID?: string;
  onChange?: (change: FieldChange) => void;
  onFocus?: (event: FieldEvent) => void;
  onBlur?: (event: FieldEvent) => void;

  fieldRef?: Ref<FieldHandle>;
}

export interface ProviderAdapter<Collector = unknown, Data = unknown> {
  readonly vaultType: VaultType;

  validateVaultData(raw: unknown): Data;

  Host: ComponentType<ProviderHostProps<Collector, Data>>;

  Field: ComponentType<ProviderFieldProps<Collector>>;

  tokenize(
    collector: Collector,
    providerData?: unknown
  ): Promise<TokenizeResult>;
}
