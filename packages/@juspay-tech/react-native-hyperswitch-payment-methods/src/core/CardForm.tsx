import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
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
import { errorResult, tokenizedCardOf } from './results';
import type {
  CardDetails,
  CardFormChange,
  CardFormEvent,
  CardFormHandle,
  ElementType,
  FieldChange,
  FormId,
  FormStatus,
  TokenizeResult,
  VaultDetails,
  VaultType,
} from './types';

function unavailableAdapter(vaultType: VaultType): ProviderAdapter {
  return {
    vaultType,
    validateVaultData: (raw) => raw,
    Host: () => null,
    Field: () => null,
    tokenize: async () =>
      errorResult(
        vaultType,
        'tokenization_failed',
        `No provider is available for vault type "${vaultType}".`
      ),
  };
}

export interface CardFormProps {
  /** The web SDK's `vaultDetails`: `{vaultType, vaultData}`. */
  vaultDetails: VaultDetails;

  id?: FormId;

  /** The provider's fields are mounted and usable. */
  onReady?: (event: CardFormEvent) => void;

  /** The web's `cardDetailsChange`, on every change to any field. Always on. */
  onChange?: (event: CardFormChange) => void;

  onError?: (error: unknown) => void;

  readyTimeoutMs?: number;
  children?: ReactNode;
}

type ValidatedData =
  { ok: true; value: unknown } | { ok: false; error: unknown };

const twoDigit = (value: string) => (value.length === 1 ? `0${value}` : value);

function buildChange(
  fields: Partial<Record<ElementType, FieldChange>>,
  details: Partial<CardDetails>
): CardFormChange {
  const number = fields.cardNumber;
  const expiry = fields.cardExpiry;
  const cvc = fields.cardCvc;
  const mounted = Object.values(fields).filter(
    (field): field is FieldChange => field !== undefined
  );
  const expiryMonth = details.expiryMonth ?? null;
  const expiryYear = details.expiryYear ?? null;
  const formattedExpiry =
    details.formattedExpiry ??
    (expiryMonth && expiryYear
      ? `${twoDigit(expiryMonth)} / ${expiryYear.slice(-2)}`
      : null);
  return {
    elementType: 'cardForm',
    eventName: 'cardDetailsChange',
    payload: {
      bin: details.bin ?? null,
      last4: details.last4 ?? null,
      brand: details.brand ?? number?.brand ?? null,
      expiryMonth,
      expiryYear,
      formattedExpiry,
      isCardNumberComplete: number?.complete ?? false,
      isCvcComplete: cvc?.complete ?? false,
      isExpiryComplete: expiry?.complete ?? false,
      isCardNumberValid: number?.valid ?? false,
      isExpiryValid: expiry?.valid ?? false,
    },
    complete: mounted.length > 0 && mounted.every((field) => field.complete),
    valid: mounted.length > 0 && mounted.every((field) => field.valid),
    fields: { ...fields },
  };
}

export const CardForm = forwardRef<CardFormHandle, CardFormProps>(
  function CardFormImpl(
    { vaultDetails, id, onReady, onChange, onError, readyTimeoutMs, children },
    ref
  ) {
    const { adapter, resolveError } = useMemo(() => {
      try {
        return {
          adapter: resolveAdapter(vaultDetails.vaultType),
          resolveError: undefined as unknown,
        };
      } catch (error) {
        return {
          adapter: unavailableAdapter(vaultDetails.vaultType),
          resolveError: error as unknown,
        };
      }
    }, [vaultDetails.vaultType]);

    const validated = useMemo<ValidatedData>(() => {
      if (resolveError !== undefined) return { ok: false, error: resolveError };
      try {
        return {
          ok: true,
          value: adapter.validateVaultData(vaultDetails.vaultData),
        };
      } catch (error) {
        return { ok: false, error };
      }
    }, [adapter, resolveError, vaultDetails.vaultData]);

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

    /* The merchant's callbacks, read at call time, so a new arrow per render never re-subscribes. */
    const onChangeRef = useRef(onChange);
    onChangeRef.current = onChange;
    const onReadyRef = useRef(onReady);
    onReadyRef.current = onReady;

    const fieldsRef = useRef<Partial<Record<ElementType, FieldChange>>>({});
    const detailsRef = useRef<Partial<CardDetails>>({});

    const emitChange = useCallback(() => {
      const listener = onChangeRef.current;
      if (listener)
        listener(buildChange(fieldsRef.current, detailsRef.current));
    }, []);

    const reportChange = useCallback(
      (change: FieldChange) => {
        fieldsRef.current[change.elementType] = change;
        emitChange();
      },
      [emitChange]
    );

    const forgetField = useCallback((elementType: ElementType) => {
      delete fieldsRef.current[elementType];
    }, []);

    const handleCardDetails = useCallback(
      (details: Partial<CardDetails>) => {
        detailsRef.current = { ...detailsRef.current, ...details };
        emitChange();
      },
      [emitChange]
    );

    const handleReady = useCallback(
      (next: unknown) => {
        session.attachCollector(next);
        setCollector(next);
        setStatus('ready');
        onReadyRef.current?.({ elementType: 'cardForm' });
      },
      [session]
    );

    const handleError = useCallback(
      (error: unknown) => {
        session.fail(error);
        setStatus('error');
        onError?.(error);
      },
      [session, onError]
    );

    const tokenize = useCallback(
      async (providerData?: unknown): Promise<TokenizeResult> => {
        const result = await session.tokenize(providerData);
        setStatus(session.status);
        if (result.status !== 'success') return result;
        /* The same values the form has been publishing on `cardDetailsChange`, echoed back on the
         * result so a caller that never subscribed still gets them. */
        const card = tokenizedCardOf(detailsRef.current);
        return card ? { ...result, card } : result;
      },
      [session]
    );

    useImperativeHandle(
      ref,
      () => ({
        tokenize,
        get status() {
          return status;
        },
      }),
      [tokenize, status]
    );

    useEffect(() => {
      if (!id) return;
      return registerForm(id, tokenize);
    }, [id, tokenize]);

    useEffect(() => {
      if (!validated.ok) handleError(validated.error);
    }, [validated, handleError]);

    const value = useMemo<FormContextValue>(
      () => ({
        vaultType: vaultDetails.vaultType,
        adapter,
        collector,
        status,
        tokenize,
        reportChange,
        forgetField,
      }),
      [
        vaultDetails.vaultType,
        adapter,
        collector,
        status,
        tokenize,
        reportChange,
        forgetField,
      ]
    );

    const Host = adapter.Host;

    return (
      <FormContext.Provider value={value}>
        {validated.ok ? (
          <Host
            vaultData={validated.value}
            onReady={handleReady}
            onError={handleError}
            onCardDetails={handleCardDetails}
          >
            {children}
          </Host>
        ) : (
          children
        )}
      </FormContext.Provider>
    );
  }
);
