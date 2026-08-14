import { useCallback, useRef, useState } from 'react';
import {
  ActivityIndicator,
  ScrollView,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  HyperswitchForm,
  CardNumberWidget,
  CardExpiryWidget,
  CardCVCWidget,
  CardHolderWidget,
  type HyperswitchFormHandle,
  type FieldState,
  type ProviderConfig,
} from '@juspay-tech/react-native-hyperswitch-payment-methods';
import { initialBaseUrl, getErrorMessage } from './utils';
import { styles } from './styles';

const DEFAULT_VAULT_API_BASE = 'https://beta.hyperswitch.io/api';

export default function VaultScreen() {
  const formRef = useRef<HyperswitchFormHandle>(null);

  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [apiBaseUrl, setApiBaseUrl] = useState<string>(DEFAULT_VAULT_API_BASE);
  const [sdkAuthorization, setSdkAuthorization] = useState<string>('');
  const [config, setConfig] = useState<ProviderConfig | null>(null);
  const [status, setStatus] = useState<string>('');
  const [message, setMessage] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [fieldStates, setFieldStates] = useState<Record<string, FieldState>>(
    {}
  );

  const onFieldStateChange = useCallback((state: FieldState) => {
    setFieldStates((prev) => ({ ...prev, [state.kind]: state }));
  }, []);

  const createSession = useCallback(async () => {
    try {
      setLoading(true);
      setStatus('Creating session...');
      const response = await fetch(`${baseURL}/create-payment-intent`);
      const data = await response.json();
      if (!response.ok) {
        throw new Error(
          data.error || data.details?.error?.message || 'Failed to create session'
        );
      }
      setSdkAuthorization(data.sdkAuthorization);
      setConfig({
        vault_type: 'hyperswitch_vault',
        vault_data: {
          sdk_authorization: data.sdkAuthorization,
          api_base_url: apiBaseUrl || undefined,
        },
      });
      setStatus('Session ready');
      setMessage(`sdkAuthorization: ${String(data.sdkAuthorization).slice(0, 24)}…`);
    } catch (error) {
      setStatus('Session Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  }, [baseURL, apiBaseUrl]);

  const submit = useCallback(async () => {
    if (!formRef.current) {
      setStatus('Form not ready');
      return;
    }
    try {
      setLoading(true);
      setStatus('Tokenising...');
      const result = await formRef.current.submit();
      if (result.status === 'success') {
        const tokens = result.data?.tokens ?? {};
        setStatus('Tokenised');
        setMessage(JSON.stringify(tokens, null, 2));
      } else {
        setStatus(`Error: ${result.status}`);
        setMessage(
          result.errors?.map((e) => `${e.code}: ${e.message}`).join('\n') ??
            JSON.stringify(result.data?.raw ?? {})
        );
      }
    } catch (error) {
      setStatus('Submit Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  }, []);

  const fieldSummary = Object.values(fieldStates)
    .map(
      (s) =>
        `${s.kind}: ${s.isEmpty ? 'empty' : s.isValid ? 'valid' : 'invalid'}${
          s.brand ? ` (${s.brand})` : ''
        }`
    )
    .join('\n');

  return (
    <ScrollView contentContainerStyle={styles.scrollContainer}>
      <View style={styles.container}>
        <Text style={styles.title}>Vault Tokenise Flow</Text>

        <TextInput
          style={styles.textInput}
          placeholder="Mock server base URL"
          value={baseURL}
          onChangeText={setBaseURL}
          autoCapitalize="none"
        />
        <TextInput
          style={styles.textInput}
          placeholder="Hyperswitch API base URL"
          value={apiBaseUrl}
          onChangeText={setApiBaseUrl}
          autoCapitalize="none"
        />

        <TouchableOpacity
          style={[styles.button, loading && styles.buttonDisabled]}
          onPress={createSession}
          disabled={loading}
        >
          <Text style={styles.buttonText}>
            {sdkAuthorization
              ? 'Reload Vault Session'
              : 'Create Vault Session'}
          </Text>
        </TouchableOpacity>

        {config ? (
          <HyperswitchForm
            ref={formRef}
            config={config}
            onReady={() => setStatus('Form ready')}
            onError={(e) => {
              setStatus('Form Error');
              setMessage(getErrorMessage(e));
            }}
          >
            <CardNumberWidget
              placeholder="Card number"
              style={inputStyle}
              onStateChange={onFieldStateChange}
            />
            <CardExpiryWidget
              placeholder="MM/YY"
              style={inputStyle}
              onStateChange={onFieldStateChange}
            />
            <CardCVCWidget
              placeholder="CVC"
              style={inputStyle}
              onStateChange={onFieldStateChange}
            />
            <CardHolderWidget
              placeholder="Cardholder name"
              style={inputStyle}
              onStateChange={onFieldStateChange}
            />
          </HyperswitchForm>
        ) : null}

        {config ? (
          <TouchableOpacity
            style={[
              styles.button,
              styles.confirmButton,
              loading && styles.buttonDisabled,
            ]}
            onPress={submit}
            disabled={loading}
          >
            <Text style={styles.buttonText}>
              {loading ? 'Processing...' : 'Tokenise Card'}
            </Text>
          </TouchableOpacity>
        ) : null}

        {fieldSummary ? (
          <Text style={styles.methodText}>{fieldSummary}</Text>
        ) : null}

        <View style={styles.status}>
          <Text style={styles.statusText}>{status}</Text>
          {message ? <Text style={styles.messageText}>{message}</Text> : null}
        </View>

        {loading && (
          <ActivityIndicator
            size="large"
            color="#007AFF"
            style={styles.loader}
          />
        )}
      </View>
    </ScrollView>
  );
}

const inputStyle = {
  width: '100%',
  height: 50,
  borderColor: '#CCCCCC',
  borderWidth: 1,
  borderRadius: 8,
  paddingHorizontal: 12,
  backgroundColor: 'white',
} as const;
