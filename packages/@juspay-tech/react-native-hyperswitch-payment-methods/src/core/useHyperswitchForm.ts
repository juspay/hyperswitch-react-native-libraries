import { useContext } from 'react';
import { FormContext } from './FormContext';
import type { FormStatus, SubmitResult, VaultType } from './types';

export interface UseHyperswitchForm {
  submit: (providerData?: unknown) => Promise<SubmitResult>;
  status: FormStatus;
  vaultType: VaultType;
}

export function useHyperswitchForm(): UseHyperswitchForm {
  const ctx = useContext(FormContext);
  if (!ctx) {
    throw new Error(
      'useHyperswitchForm must be used inside a <HyperswitchForm>.'
    );
  }
  return { submit: ctx.submit, status: ctx.status, vaultType: ctx.vaultType };
}
