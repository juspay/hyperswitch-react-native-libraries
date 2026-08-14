import { Fragment, useCallback, useEffect, useMemo, useRef } from 'react';

import type { ProviderAdapter } from '../../core/ProviderAdapter';
import type { FieldKind, FieldState, SubmitResult } from '../../core/types';
import type { HyperswitchSubmitOptions, HyperswitchVaultData } from './types';

declare const require: (moduleId: string) => unknown;

interface VaultSdk {
  HyperswitchVault: {
    collectValues(id: string): Promise<Record<string, any>>;
  };
  CardNumberWidget: React.ComponentType<any>;
  CardExpiryWidget: React.ComponentType<any>;
  CardCVCWidget: React.ComponentType<any>;
  CardHolderWidget: React.ComponentType<any>;
  ExpDateSeparateSerializer: new (
    monthFieldName: string,
    yearFieldName: string
  ) => unknown;
}

let vaultSdk: VaultSdk | null = null;
try {
  vaultSdk = require('@juspay-tech/react-native-hyperswitch-vault') as VaultSdk;
} catch {
  vaultSdk = null;
}

export const hyperswitchVaultSdkAvailable = vaultSdk != null;

const VAULT_TYPE = 'hyperswitch_vault' as const;

/**
 * Field keys collected from the vault SDK widgets.
 * The expiry widget serialises `expDate` into the
 * `card_exp_month` / `card_exp_year` pair used by the confirm API body.
 */
const FIELD_NAMES: Record<FieldKind, string> = {
  card_number: 'card_number',
  card_expiry: 'expDate',
  card_cvc: 'card_cvc',
  card_holder: 'card_holder_name',
};

const EXPIRY_MONTH_KEY = 'card_exp_month';
const EXPIRY_YEAR_KEY = 'card_exp_year';

interface HyperswitchCollector {
  formId: string;
  data: HyperswitchVaultData;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): HyperswitchVaultData {
  if (
    !isRecord(raw) ||
    typeof raw.sdk_authorization !== 'string' ||
    !raw.sdk_authorization
  ) {
    throw new Error(
      'Hyperswitch vault_data requires a non-empty string "sdk_authorization". ' +
        'Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as HyperswitchVaultData;
}

/**
 * Decodes `payment_method_session_id` from the base64 payload of
 * `sdk_authorization`. Mirrors `getSdkAuthorizationData` in hyperswitch-web:
 * the payload is a comma-separated list of `key=value` pairs.
 */
function decodeSdkAuthorization(sdkAuthorization: string): {
  paymentMethodSessionId?: string;
} {
  try {
    let decoded: string | undefined;
    const atobFn = (globalThis as Record<string, unknown>).atob;
    if (typeof atobFn === 'function') {
      decoded = (atobFn as (input: string) => string)(sdkAuthorization);
    } else {
      const bufferCtor = (globalThis as Record<string, any>).Buffer;
      if (bufferCtor) {
        decoded = bufferCtor.from(sdkAuthorization, 'base64').toString('utf-8');
      }
    }
    if (!decoded) return {};
    for (const pair of decoded.split(',')) {
      if (pair.startsWith('payment_method_session_id=')) {
        const value = pair.slice('payment_method_session_id='.length);
        return value ? { paymentMethodSessionId: value } : {};
      }
    }
  } catch {
    // fall through — session id may be provided explicitly
  }
  return {};
}

/**
 * Resolves the Hyperswitch app-backend host used by the tokenise
 * (confirm) call — the same host family as hyperswitch-web's
 * `getApiEndPoint` / `hyperswitchVaultEndPoint`.
 */
function resolveApiBaseUrl(data: HyperswitchVaultData): string {
  if (data.api_base_url) {
    return data.api_base_url.replace(/\/+$/, '');
  }
  const env = (data.environment ?? 'sandbox').toLowerCase();
  if (env === 'live' || env === 'production' || env.startsWith('prod')) {
    return 'https://checkout.hyperswitch.io/api';
  }
  if (env === 'integ' || env === 'dev') {
    return 'https://dev.hyperswitch.io/api';
  }
  return 'https://beta.hyperswitch.io/api';
}

function toFieldState(kind: FieldKind, state: unknown): FieldState {
  const s = (state ?? {}) as {
    isValid?: boolean;
    isEmpty?: boolean;
    isFocused?: boolean;
    isDirty?: boolean;
    validationErrors?: string[];
    cardBrand?: string;
  };
  return {
    kind,
    isValid: Boolean(s.isValid),
    isEmpty: Boolean(s.isEmpty),
    isFocused: Boolean(s.isFocused),
    isDirty: Boolean(s.isDirty),
    validationErrors: s.validationErrors ?? [],
    brand: s.cardBrand,
  };
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  children,
}) => {
  const data = vaultData as HyperswitchVaultData;
  // Stable form id so the vault SDK widgets register under one vault form.
  const formId = useMemo(
    () => `hs-pm-form-${Math.random().toString(36).slice(2, 10)}`,
    []
  );
  const readyRef = useRef(false);

  useEffect(() => {
    if (readyRef.current) return;
    readyRef.current = true;
    try {
      onReady({ formId, data } satisfies HyperswitchCollector);
    } catch (error) {
      onError(error);
    }
  }, [formId, data, onReady, onError]);

  return <Fragment>{children}</Fragment>;
};

const Field: ProviderAdapter['Field'] = ({
  kind,
  collector,
  placeholder,
  style,
  textStyle,
  testID,
  onStateChange,
  fieldRef,
}) => {
  const { formId } = collector as HyperswitchCollector;

  const onVaultStateChange = useCallback(
    (state: unknown) => onStateChange?.(toFieldState(kind, state)),
    [kind, onStateChange]
  );

  if (!vaultSdk) return null;

  const common: Record<string, unknown> = {
    id: formId,
    fieldName: FIELD_NAMES[kind],
    placeholder,
    containerStyle: style as object,
    textStyle: textStyle as object | undefined,
    testID,
    onStateChange: onStateChange ? onVaultStateChange : undefined,
    ref: fieldRef,
  };

  switch (kind) {
    case 'card_number':
      return <vaultSdk.CardNumberWidget {...common} />;
    case 'card_cvc':
      return <vaultSdk.CardCVCWidget {...common} />;
    case 'card_holder':
      return <vaultSdk.CardHolderWidget {...common} />;
    case 'card_expiry':
      // Serialise `expDate` into the month/year keys used by the
      // tokenise (confirm) API body.
      return (
        <vaultSdk.CardExpiryWidget
          {...common}
          serializers={[
            new vaultSdk.ExpDateSeparateSerializer(
              EXPIRY_MONTH_KEY,
              EXPIRY_YEAR_KEY
            ),
          ]}
        />
      );
  }
};

async function readResponseBody(response: any): Promise<unknown> {
  if (response && typeof response.json === 'function') {
    try {
      return await response.json();
    } catch {
      if (typeof response.text === 'function') {
        try {
          return await response.text();
        } catch {
          return undefined;
        }
      }
      return undefined;
    }
  }
  return response;
}

/**
 * Extracts the vault response token data as decoded by the web SDK
 * (`decodeVaultTokenData` in hyperswitch-web PR #1615):
 *   token       ← associated_payment_methods[0].payment_method_token.data
 *   last_four   ← payment_method_data.card.last4_digits
 *   bin_number  ← payment_method_data.card.card_isin (may be null)
 */
function extractVaultTokens(
  body: unknown
): Record<string, unknown> | undefined {
  if (!isRecord(body)) return undefined;
  const associated = body.associated_payment_methods;
  if (Array.isArray(associated) && associated.length > 0) {
    const first = associated[0];
    if (isRecord(first) && isRecord(first.payment_method_token)) {
      const card = isRecord(body.payment_method_data)
        ? (body.payment_method_data.card as Record<string, unknown>)
        : undefined;
      return {
        token: first.payment_method_token.data,
        last_four: card?.last4_digits,
        bin_number: card?.card_isin,
      };
    }
  }
  return undefined;
}

const submit: ProviderAdapter['submit'] = async (
  collector,
  providerData
): Promise<SubmitResult> => {
  const { formId, data } = collector as HyperswitchCollector;
  const options = (providerData ?? {}) as HyperswitchSubmitOptions;

  if (!vaultSdk) {
    return {
      status: 'error',
      vaultType: VAULT_TYPE,
      errors: [
        {
          code: 'sdk_missing',
          message:
            'Hyperswitch vault SDK is not available. Install ' +
            '@juspay-tech/react-native-hyperswitch-vault and rebuild.',
        },
      ],
    };
  }

  const pmSessionId =
    data.payment_method_session_id ??
    decodeSdkAuthorization(data.sdk_authorization).paymentMethodSessionId;

  if (!pmSessionId) {
    return {
      status: 'validation_error',
      vaultType: VAULT_TYPE,
      errors: [
        {
          code: 'missing_pm_session_id',
          message:
            'Hyperswitch vault: could not resolve "payment_method_session_id" ' +
            'from sdk_authorization; pass it explicitly in vault_data.',
        },
      ],
    };
  }

  try {
    // Collect (and validate) the raw card values from the vault SDK fields.
    // Serialized fields (expiry) arrive pre-split into month/year keys.
    const values = await vaultSdk.HyperswitchVault.collectValues(formId);

    // Tokenise flow from hyperswitch-web PR #1615:
    // POST {apiBase}/v1/payment-method-sessions/{pmSessionId}/confirm
    // with `Authorization: <sdk_authorization>`.
    const url = `${resolveApiBaseUrl(data)}/v1/payment-method-sessions/${pmSessionId}/confirm`;
    const response = await fetch(url, {
      method: options.method ?? 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': data.sdk_authorization,
        ...options.headers,
      },
      body: JSON.stringify({
        payment_method_type: 'card',
        payment_method_data: {
          card: {
            card_number: values[FIELD_NAMES.card_number] ?? '',
            card_exp_month: values[EXPIRY_MONTH_KEY] ?? '',
            card_exp_year: values[EXPIRY_YEAR_KEY] ?? '',
            card_cvc: values[FIELD_NAMES.card_cvc] ?? '',
            card_holder_name: values[FIELD_NAMES.card_holder] ?? '',
          },
        },
        ...options.extraData,
      }),
    });
    const body = await readResponseBody(response);

    if (response.status >= 200 && response.status < 300) {
      return {
        status: 'success',
        vaultType: VAULT_TYPE,
        data: {
          raw: body,
          tokens: extractVaultTokens(body),
        },
      };
    }

    return {
      status: 'error',
      vaultType: VAULT_TYPE,
      data: { raw: body },
      errors: [
        {
          code: `http_${response.status}`,
          message: `Hyperswitch vault confirm returned status ${response.status}.`,
        },
      ],
    };
  } catch (error) {
    return {
      status: 'error',
      vaultType: VAULT_TYPE,
      errors: [
        {
          code: 'submit_failed',
          message: error instanceof Error ? error.message : String(error),
        },
      ],
    };
  }
};

export const hyperswitchVaultAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  Host,
  Field,
  submit,
};
