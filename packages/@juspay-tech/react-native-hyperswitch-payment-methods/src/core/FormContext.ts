import { createContext } from 'react';
import type { ProviderAdapter } from './ProviderAdapter';
import type {
  ElementType,
  FieldChange,
  FormStatus,
  TokenizeResult,
  VaultType,
} from './types';

export interface FormContextValue {
  vaultType: VaultType;
  adapter: ProviderAdapter;
  collector: unknown | undefined;
  status: FormStatus;
  tokenize: (providerData?: unknown) => Promise<TokenizeResult>;
  /** A field's latest change, folded into the form's `cardDetailsChange`. Stable. */
  reportChange: (change: FieldChange) => void;
  /** Called when a field unmounts, so the form stops counting it. Stable. */
  forgetField: (elementType: ElementType) => void;
}

export const FormContext = createContext<FormContextValue | null>(null);
