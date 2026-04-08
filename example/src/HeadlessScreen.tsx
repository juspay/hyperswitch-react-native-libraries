import { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import {
  initPaymentSession,
  type HyperInstance,
  type PaymentSession,
  type HeadlessResponse,
  type SavedPaymentMethod,
} from '@juspay-tech/react-native-hyperswitch';
import { initialBaseUrl, getStatus, getErrorMessage } from './utils';
import { styles } from './styles';

interface HeadlessScreenProps {
  hyperPromise: Promise<HyperInstance>;
}

export default function HeadlessScreen({ hyperPromise }: HeadlessScreenProps) {
  const [status, setStatus] = useState<string>('');
  const [message, setMessage] = useState<string>('');
  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [sdkAuthorization, setSdkAuthorization] = useState<string>('');
  const [paymentSession, setPaymentSession] = useState<PaymentSession | null>(null);
  const [lastUsedMethod, setLastUsedMethod] = useState<SavedPaymentMethod | null>(null);
  const [defaultMethod, setDefaultMethod] = useState<SavedPaymentMethod | null>(null);
  const [loading, setLoading] = useState<boolean>(false);

  const createPaymentIntent = useCallback(async (): Promise<string> => {
    const response = await fetch(`${baseURL}/create-payment-intent`);
    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to create payment intent');
    }

    return data.sdkAuthorization;
  }, [baseURL]);

  const initializeSession = async () => {
    try {
      setLoading(true);
      setStatus('Initializing...');
      setMessage('');

      const secret = await createPaymentIntent();
      setSdkAuthorization(secret);

      const session = await initPaymentSession(hyperPromise, secret);
      setPaymentSession(session);

      setStatus('Session initialized');
      setMessage('Payment session created successfully');
    } catch (error) {
      console.error('Initialization failed:', error);
      setStatus('Initialization Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  };

  const fetchLastUsedMethod = async () => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Please initialize session first');
      return;
    }

    try {
      setLoading(true);
      setStatus('Fetching last used method...');

      const result = await paymentSession.getCustomerLastUsedPaymentMethodData() as HeadlessResponse;
      console.log('-- HeadlessScreen:', 'Last used method:', result);

      if (result.status === 'succeeded' && result.data) {
        setLastUsedMethod(result.data);
        setStatus('Last used method fetched');
        setMessage(`Method: ${result.data.payment_method_str}`);
      } else {
        setLastUsedMethod(null);
        setStatus('No method found');
        setMessage(result.message || result.code || 'No saved payment method found');
      }
    } catch (error) {
      console.error('Fetch last used failed:', error);
      setStatus('Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  };

  const fetchDefaultMethod = async () => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Please initialize session first');
      return;
    }

    try {
      setLoading(true);
      setStatus('Fetching default method...');

      const result = await paymentSession.getCustomerDefaultSavedPaymentMethodData() as HeadlessResponse;
      console.log('-- HeadlessScreen:', 'Default method:', result);

      if (result.status === 'succeeded' && result.data) {
        setDefaultMethod(result.data);
        setStatus('Default method fetched');
        setMessage(`Method: ${result.data.payment_method_str}`);
      } else {
        setDefaultMethod(null);
        setStatus('No method found');
        setMessage(result.message || result.code || 'No default payment method found');
      }
    } catch (error) {
      console.error('Fetch default failed:', error);
      setStatus('Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  };

  const confirmWithLastUsed = async () => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Please initialize session first');
      return;
    }

    try {
      setLoading(true);
      setStatus('Confirming payment...');

      const result = await paymentSession.confirmWithCustomerLastUsedPaymentMethod() as HeadlessResponse;
      console.log('-- HeadlessScreen:', 'Confirm with last used method result:', result);

      setStatus(getStatus(result.status));
      setMessage(result.message || result.status);
    } catch (error) {
      console.error('Confirm payment failed:', error);
      setStatus('Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  };

  const confirmWithDefault = async () => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Please initialize session first');
      return;
    }

    try {
      setLoading(true);
      setStatus('Confirming payment...');

      const result = await paymentSession.confirmWithCustomerDefaultPaymentMethod() as HeadlessResponse;
      console.log('-- HeadlessScreen:', 'Confirm with default method result:', result);

      setStatus(getStatus(result.status));
      setMessage(result.message || result.status);
    } catch (error) {
      console.error('Confirm payment failed:', error);
      setStatus('Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  };

  const renderPaymentMethod = (method: SavedPaymentMethod | null, label: string) => {
    if (!method) return null;

    const { card } = method;

    return (
      <View style={styles.methodCard}>
        <Text style={styles.methodLabel}>{label}</Text>
        <Text style={styles.methodText}>Type: {method.payment_method_str}</Text>
        {card && (
          <>
            <Text style={styles.methodText}>Card: **** {card.last4_digits}</Text>
            <Text style={styles.methodText}>Scheme: {card.scheme}</Text>
            <Text style={styles.methodText}>Holder: {card.card_holder_name}</Text>
            <Text style={styles.methodText}>
              Expires: {card.expiry_month}/{card.expiry_year}
            </Text>
          </>
        )}
        <Text style={styles.methodText}>Last Used: {method.last_used_at}</Text>
        {method.default_payment_method_set && (
          <Text style={styles.defaultBadge}>DEFAULT</Text>
        )}
      </View>
    );
  };

  return (
    <ScrollView style={styles.scrollContainer} contentContainerStyle={styles.container}>
      <TextInput
        style={styles.textInput}
        placeholder="Enter base URL"
        value={baseURL}
        onChangeText={setBaseURL}
      />

      <TouchableOpacity
        style={[styles.button, loading && styles.buttonDisabled]}
        onPress={initializeSession}
        disabled={loading}
      >
        <Text style={styles.buttonText}>
          {loading ? 'Initializing...' : '1. Initialize Session'}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, loading && styles.buttonDisabled]}
        onPress={fetchLastUsedMethod}
        disabled={loading}
      >
        <Text style={styles.buttonText}>
          {loading ? 'Fetching...' : '2. Get Last Used Method'}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, loading && styles.buttonDisabled]}
        onPress={fetchDefaultMethod}
        disabled={loading}
      >
        <Text style={styles.buttonText}>
          {loading ? 'Fetching...' : '3. Get Default Method'}
        </Text>
      </TouchableOpacity>

      {renderPaymentMethod(lastUsedMethod, 'Last Used Method')}
      {renderPaymentMethod(defaultMethod, 'Default Method')}

      <TouchableOpacity
        style={[styles.button, styles.confirmButton, loading && styles.buttonDisabled]}
        onPress={confirmWithLastUsed}
        disabled={loading || !lastUsedMethod}
      >
        <Text style={styles.buttonText}>
          {loading ? 'Processing...' : 'Confirm with Last Used'}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, styles.confirmButton, loading && styles.buttonDisabled]}
        onPress={confirmWithDefault}
        disabled={loading || !defaultMethod}
      >
        <Text style={styles.buttonText}>
          {loading ? 'Processing...' : 'Confirm with Default'}
        </Text>
      </TouchableOpacity>

      {loading && <ActivityIndicator size="large" color="#007AFF" style={styles.loader} />}

      <View style={styles.status}>
        <Text style={styles.statusText}>{status}</Text>
        {message && <Text style={styles.messageText}>{message}</Text>}
      </View>
    </ScrollView>
  );
}
