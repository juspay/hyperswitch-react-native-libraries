import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';
import type { ReactNode } from 'react';

import { FormContext } from './FormContext';
import type { FormContextValue } from './FormContext';
import { createFormSession } from './formSession';
import type { CreateFormSessionOptions } from './formSession';
import { registerForm } from './formRegistry';
import { resolveAdapter } from '../providers/registry';
import type { ProviderAdapter } from './ProviderAdapter';
import type {
  FormId,
  FormStatus,
  HyperswitchFormHandle,
  ProviderConfig,
  SubmitResult,
  VaultType,
} from './types';

function unavailableAdapter(vaultType: VaultType): ProviderAdapter {
  return {
    vaultType,
    validateVaultData: (raw) => raw,
    Host: () => null,
    Field: () => null,
    submit: async () => ({ status: 'error', vaultType }),
  };
}

export interface HyperswitchFormProps {
  config: ProviderConfig;

  id?: FormId;

  onReady?: () => void;

  onError?: (error: unknown) => void;

  readyTimeoutMs?: number;
  children?: ReactNode;
}

type ValidatedData =
  | { ok: true; value: unknown }
  | { ok: false; error: unknown };

export const HyperswitchForm = forwardRef<
  HyperswitchFormHandle,
  HyperswitchFormProps
>(function HyperswitchFormImpl(
  { config, id, onReady, onError, readyTimeoutMs, children },
  ref
) {
  const { adapter, resolveError } = useMemo(() => {
    try {
      return {
        adapter: resolveAdapter(config.vault_type),
        resolveError: undefined as unknown,
      };
    } catch (error) {
      return {
        adapter: unavailableAdapter(config.vault_type),
        resolveError: error as unknown,
      };
    }
  }, [config.vault_type]);

  const validated = useMemo<ValidatedData>(() => {
    if (resolveError !== undefined) return { ok: false, error: resolveError };
    try {
      return { ok: true, value: adapter.validateVaultData(config.vault_data) };
    } catch (error) {
      return { ok: false, error };
    }
  }, [adapter, resolveError, config.vault_data]);

  const sessionOptions = useMemo<CreateFormSessionOptions>(
    () => (readyTimeoutMs !== undefined ? { readyTimeoutMs } : {}),
    [readyTimeoutMs]
  );

  const session = useMemo(
    () => createFormSession(adapter, sessionOptions),
    [adapter, sessionOptions]
  );

  const [collector, setCollector] = useState<unknown>(undefined);
  const [status, setStatus] = useState<FormStatus>('initializing');

  const handleReady = useCallback(
    (next: unknown) => {
      session.attachCollector(next);
      setCollector(next);
      setStatus('ready');
      onReady?.();
    },
    [session, onReady]
  );

  const handleError = useCallback(
    (error: unknown) => {
      session.fail(error);
      setStatus('error');
      onError?.(error);
    },
    [session, onError]
  );

  const submit = useCallback(
    async (providerData?: unknown): Promise<SubmitResult> => {
      const result = await session.submit(providerData);
      setStatus(session.status);
      return result;
    },
    [session]
  );

  useImperativeHandle(
    ref,
    () => ({
      submit,
      get status() {
        return status;
      },
    }),
    [submit, status]
  );

  useEffect(() => {
    if (!id) return;
    return registerForm(id, submit);
  }, [id, submit]);

  useEffect(() => {
    if (!validated.ok) handleError(validated.error);
  }, [validated, handleError]);

  const value = useMemo<FormContextValue>(
    () => ({
      vaultType: config.vault_type,
      adapter,
      collector,
      status,
      submit,
    }),
    [config.vault_type, adapter, collector, status, submit]
  );

  const Host = adapter.Host;

  return (
    <FormContext.Provider value={value}>
      {validated.ok ? (
        <Host
          vaultData={validated.value}
          onReady={handleReady}
          onError={handleError}
        >
          {children}
        </Host>
      ) : (
        children
      )}
    </FormContext.Provider>
  );
});
