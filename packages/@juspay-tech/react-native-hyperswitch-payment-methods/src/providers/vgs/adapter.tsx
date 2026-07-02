import { Fragment, useEffect, useRef } from 'react';
import { StyleSheet } from 'react-native';

import type { ProviderAdapter } from '../../core/ProviderAdapter';
import type { FieldKind, FieldState, SubmitResult } from '../../core/types';
import type { VgsSubmitOptions, VgsVaultData } from './types';

declare const require: (moduleId: string) => unknown;

type VgsSdk = any;

let vgsSdk: VgsSdk | null = null;
try {
  vgsSdk = require('@vgs/collect-react-native') as VgsSdk;
} catch {
  vgsSdk = null;
}

export const vgsSdkAvailable = vgsSdk != null;

const { VGSCollect, VGSTextInput, VGSCardInput, VGSCVCInput } =
  vgsSdk ?? ({} as VgsSdk);

type VGSCollect = InstanceType<VgsSdk['VGSCollect']>;

const VAULT_TYPE = 'vgs' as const;

const FIELD_CONFIG: Record<
  FieldKind,
  { fieldName: string; type: 'card' | 'expDate' | 'cvc' | 'cardHolderName' }
> = {
  card_number: { fieldName: 'card_number', type: 'card' },
  card_expiry: { fieldName: 'expiration_date', type: 'expDate' },
  card_cvc: { fieldName: 'card_cvc', type: 'cvc' },
  card_holder: { fieldName: 'card_holder', type: 'cardHolderName' },
};

const FIELD_COMPONENT: Partial<Record<FieldKind, typeof VGSTextInput>> = {
  card_number: VGSCardInput,
  card_cvc: VGSCVCInput,
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): VgsVaultData {
  if (!isRecord(raw) || typeof raw.vault_id !== 'string' || !raw.vault_id) {
    throw new Error(
      'VGS vault_data requires a non-empty string "vault_id". Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as VgsVaultData;
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  children,
}) => {
  const data = vaultData as VgsVaultData;
  const collectorRef = useRef<VGSCollect | null>(null);

  useEffect(() => {
    try {
      const collector = new VGSCollect(data.vault_id, data.environment);
      if (data.route_id) collector.setRouteId(data.route_id);
      collectorRef.current = collector;

      if (data.cname) {
        collector
          .setCname(data.cname)
          .then(() => onReady(collector))
          .catch(onError);
      } else {
        onReady(collector);
      }
    } catch (error) {
      onError(error);
    }
  }, [
    data.vault_id,
    data.environment,
    data.route_id,
    data.cname,
    onReady,
    onError,
  ]);

  return <Fragment>{children}</Fragment>;
};

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

const Field: ProviderAdapter['Field'] = ({
  kind,
  collector,
  placeholder,
  style,
  textStyle,
  onStateChange,
}) => {
  const config = FIELD_CONFIG[kind];

  const flatStyle = StyleSheet.flatten(style) as
    | { height?: number }
    | undefined;
  const containerHeight =
    typeof flatStyle?.height === 'number' ? flatStyle.height : undefined;
  const common = {
    collector: collector as VGSCollect,
    fieldName: config.fieldName,
    placeholder,
    containerStyle: style as object,

    textStyle: textStyle as object | undefined,
    onStateChange: onStateChange
      ? (state: unknown) => onStateChange(toFieldState(kind, state))
      : undefined,
  };
  const Specialized = FIELD_COMPONENT[kind];
  return Specialized ? (
    <Specialized {...common} containerHeight={containerHeight} />
  ) : (
    <VGSTextInput {...common} type={config.type} />
  );
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

const submit: ProviderAdapter['submit'] = async (
  collector,
  providerData
): Promise<SubmitResult> => {
  const options = (providerData ?? {}) as VgsSubmitOptions;
  const vgs = collector as VGSCollect;
  try {
    const { status, response } = await vgs.submit(
      options.path ?? '/post',
      options.method ?? 'POST',
      options.extraData
    );
    const body = await readResponseBody(response);

    if (status >= 200 && status < 300) {
      return {
        status: 'success',
        vaultType: VAULT_TYPE,
        data: {
          raw: body,
          tokens: isRecord(body) ? body : undefined,
        },
      };
    }

    return {
      status: 'error',
      vaultType: VAULT_TYPE,
      errors: [
        {
          code: `http_${status}`,
          message: `VGS submit returned status ${status}.`,
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

export const vgsAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  Host,
  Field,
  submit,
};
