import { createRef, useEffect, useRef } from 'react';
import type { RefObject } from 'react';
import { StyleSheet } from 'react-native';

import type { ProviderAdapter } from '../../core/ProviderAdapter';
import type { FieldKind, FieldState, SubmitResult } from '../../core/types';
import type { BasisTheoryVaultData } from './types';

declare const require: (moduleId: string) => unknown;

type BasisTheorySdk = any;

let basisTheorySdk: BasisTheorySdk | null = null;
try {
  basisTheorySdk =
    require('@basis-theory/react-native-elements') as BasisTheorySdk;
} catch {
  basisTheorySdk = null;
}

export const basisTheorySdkAvailable = basisTheorySdk != null;

const {
  BasisTheoryProvider,
  useBasisTheory,
  CardNumberElement,
  CardExpirationDateElement,
  CardVerificationCodeElement,
  TextElement,
} = basisTheorySdk ?? ({} as BasisTheorySdk);

const VAULT_TYPE = 'basis_theory' as const;

interface BtRefs {
  card_number: RefObject<any | null>;
  card_expiry: RefObject<any | null>;
  card_cvc: RefObject<any | null>;
  card_holder: RefObject<any | null>;
}

interface BtInstance {
  tokens: {
    create: (
      token: { type: string; data: Record<string, unknown> },
      options?: unknown
    ) => Promise<unknown>;
  };
}

interface BtCollector {
  bt: BtInstance;
  refs: BtRefs;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): BasisTheoryVaultData {
  if (!isRecord(raw) || typeof raw.api_key !== 'string' || !raw.api_key) {
    throw new Error(
      'Basis Theory vault_data requires a non-empty string "api_key". Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as BasisTheoryVaultData;
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  children,
}) => {
  const data = vaultData as BasisTheoryVaultData;
  const { bt, error } = useBasisTheory(
    data.api_key,
    data.base_url ? { apiBaseUrl: data.base_url } : undefined
  );

  const refsRef = useRef<BtRefs | null>(null);
  if (refsRef.current === null) {
    refsRef.current = {
      card_number: createRef<any>(),
      card_expiry: createRef<any>(),
      card_cvc: createRef<any>(),
      card_holder: createRef<any>(),
    };
  }
  const refs = refsRef.current;

  useEffect(() => {
    if (error) {
      onError(error);
      return;
    }
    if (bt) {
      onReady({ bt: bt as unknown as BtInstance, refs });
    }
  }, [bt, error, refs, onReady, onError]);

  return <BasisTheoryProvider bt={bt}>{children}</BasisTheoryProvider>;
};

function toFieldState(kind: FieldKind, event: unknown): FieldState {
  const e = (event ?? {}) as {
    empty?: boolean;
    valid?: boolean;
    errors?: Array<{ type: string }>;
    brand?: string;
  };
  return {
    kind,
    isValid: Boolean(e.valid),
    isEmpty: Boolean(e.empty),
    isFocused: false,
    isDirty: !(e.empty ?? true),
    validationErrors: (e.errors ?? []).map((err) => err.type),
    brand: e.brand,
  };
}

const Field: ProviderAdapter['Field'] = ({
  kind,
  collector,
  placeholder,
  style,
  textStyle,
  onStateChange,
}) => {
  const { refs } = collector as BtCollector;

  const mergedStyle = StyleSheet.flatten([style, textStyle]);
  const onChange = onStateChange
    ? (event: unknown) => onStateChange(toFieldState(kind, event))
    : undefined;
  switch (kind) {
    case 'card_number':
      return (
        <CardNumberElement
          btRef={refs.card_number}
          placeholder={placeholder}
          style={mergedStyle}
          onChange={onChange}
        />
      );
    case 'card_expiry':
      return (
        <CardExpirationDateElement
          btRef={refs.card_expiry}
          placeholder={placeholder}
          style={mergedStyle}
          onChange={onChange}
        />
      );
    case 'card_cvc':
      return (
        <CardVerificationCodeElement
          btRef={refs.card_cvc}
          placeholder={placeholder}
          style={mergedStyle}
          onChange={onChange}
        />
      );
    case 'card_holder':
      return (
        <TextElement
          btRef={refs.card_holder}
          placeholder={placeholder}
          style={mergedStyle}
          onChange={onChange}
        />
      );
  }
};

const submit: ProviderAdapter['submit'] = async (
  collector,
  providerData
): Promise<SubmitResult> => {
  const { bt, refs } = collector as BtCollector;
  const expiry = refs.card_expiry.current;
  const data: Record<string, unknown> = {
    number: refs.card_number.current,
    expiration_month: expiry ? expiry.month() : undefined,
    expiration_year: expiry ? expiry.year() : undefined,
    cvc: refs.card_cvc.current,
    cardholder_name: refs.card_holder.current,
  };

  try {
    const token = await bt.tokens.create(
      { type: 'card', data, ...(isRecord(providerData) ? providerData : {}) },
      undefined
    );
    if (!token) {
      return {
        status: 'error',
        vaultType: VAULT_TYPE,
        errors: [
          { code: 'no_token', message: 'Basis Theory returned no token.' },
        ],
      };
    }
    const id = isRecord(token) ? token.id : undefined;
    return {
      status: 'success',
      vaultType: VAULT_TYPE,
      data: { raw: token, tokens: id ? { id } : undefined },
    };
  } catch (error) {
    return {
      status: 'error',
      vaultType: VAULT_TYPE,
      errors: [
        {
          code: 'token_create_failed',
          message: error instanceof Error ? error.message : String(error),
        },
      ],
    };
  }
};

export const basisTheoryAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  Host,
  Field,
  submit,
};
