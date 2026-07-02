import { createContext } from 'react';
import type { ProviderAdapter } from './ProviderAdapter';
import type { FormStatus, SubmitResult, VaultType } from './types';

export interface FormContextValue {
  vaultType: VaultType;
  adapter: ProviderAdapter;
  collector: unknown | undefined;
  status: FormStatus;
  submit: (providerData?: unknown) => Promise<SubmitResult>;
}

export const FormContext = createContext<FormContextValue | null>(null);
