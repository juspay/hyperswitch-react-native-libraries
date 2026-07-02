import { Fragment, useEffect, useMemo } from 'react';
import type { ComponentProps, ReactNode } from 'react';

import type { ProviderAdapter } from '../../core/ProviderAdapter';
import type { FieldKind, FieldState, SubmitResult } from '../../core/types';
import type { SkyflowVaultData } from './types';

declare const require: (moduleId: string) => unknown;

type SkyflowSdk = any;

let skyflowSdk: SkyflowSdk | null = null;
try {
  skyflowSdk = require('skyflow-react-native') as SkyflowSdk;
} catch {
  skyflowSdk = null;
}

export const skyflowSdkAvailable = skyflowSdk != null;

const {
  SkyflowProvider,
  useCollectContainer,
  CardNumberElement,
  ExpirationDateElement,
  CvvElement,
  CardHolderNameElement,
} = skyflowSdk ?? ({} as SkyflowSdk);

const VAULT_TYPE = 'skyflow' as const;

type SkyflowContainer = ComponentProps<typeof CardNumberElement>['container'];
type CollectOptions = Parameters<SkyflowContainer['collect']>[0];

interface SkyflowCollector {
  container: SkyflowContainer;
  table: string;
  columns: Record<FieldKind, string>;
}

const ELEMENTS: Record<FieldKind, typeof CardNumberElement> = {
  card_number: CardNumberElement,
  card_expiry: ExpirationDateElement,
  card_cvc: CvvElement,
  card_holder: CardHolderNameElement,
};

const DEFAULT_COLUMNS: Record<FieldKind, string> = {
  card_number: 'card_number',
  card_expiry: 'card_expiration',
  card_cvc: 'cvv',
  card_holder: 'cardholder_name',
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): SkyflowVaultData {
  if (
    !isRecord(raw) ||
    typeof raw.vault_id !== 'string' ||
    !raw.vault_id ||
    typeof raw.vault_url !== 'string' ||
    !raw.vault_url ||
    typeof raw.table !== 'string' ||
    !raw.table
  ) {
    throw new Error(
      'Skyflow vault_data requires non-empty string "vault_id", "vault_url" and "table". ' +
        'Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as SkyflowVaultData;
}

function resolveColumns(data: SkyflowVaultData): Record<FieldKind, string> {
  return { ...DEFAULT_COLUMNS, ...data.columns };
}

function extractTokens(response: unknown): Record<string, unknown> | undefined {
  if (!isRecord(response) || !Array.isArray(response.records)) return undefined;
  const tokens: Record<string, unknown> = {};
  for (const record of response.records) {
    if (isRecord(record) && isRecord(record.fields)) {
      Object.assign(tokens, record.fields);
    }
  }
  return Object.keys(tokens).length > 0 ? tokens : undefined;
}

function SkyflowBridge({
  table,
  columns,
  onReady,
  onError,
  children,
}: {
  table: string;
  columns: Record<FieldKind, string>;
  onReady: (collector: SkyflowCollector) => void;
  onError: (error: unknown) => void;
  children: ReactNode;
}) {
  const container = useCollectContainer();
  useEffect(() => {
    try {
      onReady({ container, table, columns });
    } catch (error) {
      onError(error);
    }
  }, [container, table, columns, onReady, onError]);
  return <Fragment>{children}</Fragment>;
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  children,
}) => {
  const data = vaultData as SkyflowVaultData;
  const config = useMemo<any>(
    () => ({
      vaultID: data.vault_id,
      vaultURL: data.vault_url,
      getBearerToken: () => Promise.resolve(data.bearer_token ?? ''),
      options: data.options,
    }),
    [data.vault_id, data.vault_url, data.bearer_token, data.options]
  );
  const columns = useMemo(() => resolveColumns(data), [data]);

  return (
    <SkyflowProvider config={config}>
      <SkyflowBridge
        table={data.table}
        columns={columns}
        onReady={onReady}
        onError={onError}
      >
        {children}
      </SkyflowBridge>
    </SkyflowProvider>
  );
};

function toFieldState(kind: FieldKind, state: unknown): FieldState {
  const s = (state ?? {}) as {
    isValid?: boolean;
    isEmpty?: boolean;
    isFocused?: boolean;
    selectedCardScheme?: string;
  };
  return {
    kind,
    isValid: Boolean(s.isValid),
    isEmpty: Boolean(s.isEmpty),
    isFocused: Boolean(s.isFocused),
    isDirty: !(s.isEmpty ?? true),
    validationErrors: s.isValid ? [] : ['invalid'],
    brand: s.selectedCardScheme,
  };
}

const Field: ProviderAdapter['Field'] = ({
  kind,
  collector,
  placeholder,
  onStateChange,
}) => {
  const { container, table, columns } = collector as SkyflowCollector;
  const Element = ELEMENTS[kind];
  const handler = onStateChange
    ? (state: unknown) => onStateChange(toFieldState(kind, state))
    : undefined;
  return (
    <Element
      container={container}
      table={table}
      column={columns[kind]}
      placeholder={placeholder}
      onChange={handler}
      onFocus={handler}
      onBlur={handler}
    />
  );
};

const submit: ProviderAdapter['submit'] = async (
  collector,
  providerData
): Promise<SubmitResult> => {
  const { container } = collector as SkyflowCollector;
  const overrides = isRecord(providerData) ? providerData : {};
  const options = { tokens: true, ...overrides } as CollectOptions;
  try {
    const response = await container.collect(options);
    return {
      status: 'success',
      vaultType: VAULT_TYPE,
      data: { raw: response, tokens: extractTokens(response) },
    };
  } catch (error) {
    return {
      status: 'error',
      vaultType: VAULT_TYPE,
      errors: [
        {
          code: 'collect_failed',
          message: error instanceof Error ? error.message : String(error),
        },
      ],
    };
  }
};

export const skyflowAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  Host,
  Field,
  submit,
};
