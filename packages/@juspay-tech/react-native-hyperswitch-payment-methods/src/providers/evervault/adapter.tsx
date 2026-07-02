import { useCallback, useEffect, useRef } from 'react';
import type { ComponentProps } from 'react';
import { StyleSheet } from 'react-native';

import type { ProviderAdapter } from '../../core/ProviderAdapter';
import type { FieldKind, SubmitError, SubmitResult } from '../../core/types';
import type { EvervaultVaultData } from './types';

declare const require: (moduleId: string) => unknown;

type EvervaultSdk = any;

let evervaultSdk: EvervaultSdk | null = null;
try {
  evervaultSdk = require('@evervault/react-native') as EvervaultSdk;
} catch {
  evervaultSdk = null;
}

export const evervaultSdkAvailable = evervaultSdk != null;

const { EvervaultProvider, Card, CardNumber, CardExpiry, CardCvc, CardHolder } =
  evervaultSdk ?? ({} as EvervaultSdk);

const VAULT_TYPE = 'evervault' as const;

type InputStyle = ComponentProps<typeof CardNumber>['style'];

interface EvervaultCollector {
  getPayload: () => any | null;
}

const ERROR_FIELD: Record<string, FieldKind> = {
  name: 'card_holder',
  number: 'card_number',
  expiry: 'card_expiry',
  cvc: 'card_cvc',
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): EvervaultVaultData {
  if (
    !isRecord(raw) ||
    typeof raw.team_id !== 'string' ||
    !raw.team_id ||
    typeof raw.app_id !== 'string' ||
    !raw.app_id
  ) {
    throw new Error(
      'Evervault vault_data requires non-empty string "team_id" and "app_id". Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as EvervaultVaultData;
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  children,
}) => {
  const data = vaultData as EvervaultVaultData;
  const payloadRef = useRef<any | null>(null);

  const handleChange = useCallback((payload: any) => {
    payloadRef.current = payload;
  }, []);

  const collectorRef = useRef<EvervaultCollector | null>(null);
  if (collectorRef.current === null) {
    collectorRef.current = { getPayload: () => payloadRef.current };
  }
  const collector = collectorRef.current;

  useEffect(() => {
    onReady(collector);
  }, [collector, onReady]);

  return (
    <EvervaultProvider teamId={data.team_id} appId={data.app_id}>
      <Card onChange={handleChange} onError={onError}>
        {children}
      </Card>
    </EvervaultProvider>
  );
};

const Field: ProviderAdapter['Field'] = ({
  kind,
  placeholder,
  style,
  textStyle,
}) => {
  const inputStyle = StyleSheet.flatten([style, textStyle]) as InputStyle;
  switch (kind) {
    case 'card_number':
      return <CardNumber placeholder={placeholder} style={inputStyle} />;
    case 'card_expiry':
      return <CardExpiry placeholder={placeholder} style={inputStyle} />;
    case 'card_cvc':
      return <CardCvc placeholder={placeholder} style={inputStyle} />;
    case 'card_holder':
      return <CardHolder placeholder={placeholder} style={inputStyle} />;
  }
};

const submit: ProviderAdapter['submit'] = async (
  collector
): Promise<SubmitResult> => {
  const payload = (collector as EvervaultCollector).getPayload();

  if (!payload) {
    return {
      status: 'validation_error',
      vaultType: VAULT_TYPE,
      errors: [
        {
          code: 'empty',
          message: 'No card details have been entered yet.',
        },
      ],
    };
  }

  if (!payload.isComplete) {
    const errors: SubmitError[] = Object.entries(payload.errors ?? {}).map(
      ([field, message]) => ({
        code: 'invalid_field',
        field: ERROR_FIELD[field],
        message: String(message),
      })
    );
    return {
      status: 'validation_error',
      vaultType: VAULT_TYPE,
      errors:
        errors.length > 0
          ? errors
          : [{ code: 'incomplete', message: 'Card details are incomplete.' }],
    };
  }

  const card = payload.card;
  return {
    status: 'success',
    vaultType: VAULT_TYPE,
    data: {
      raw: card,
      tokens: {
        name: card.name,
        number: card.number,
        expiry: card.expiry,
        cvc: card.cvc,
      },
    },
  };
};

export const evervaultAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  Host,
  Field,
  submit,
};
