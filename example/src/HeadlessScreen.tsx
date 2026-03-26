import { useState, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import {
  initPaymentSession,
  type HyperInstance,
  type PaymentSession,
} from '@juspay-tech/react-native-hyperswitch';
import {
  initialBaseUrl,
  getStatus,
  getErrorMessage,
} from './utils';
import { styles } from './styles';

interface HeadlessScreenProps {
  hyperPromise: Promise<HyperInstance>;
}

interface PaymentMethod {
  paymentToken: string;
  paymentMethod: string;
  paymentMethodType: string;
  last4Digits?: string;
  scheme?: string;
  cardHolderName?: string;
  lastUsedAt: string;
  defaultPaymentMethodSet: boolean;
}

export default function HeadlessScreen({ hyperPromise }: HeadlessScreenProps) {
  const [status, setStatus] = useState<string>('');
  const [message, setMessage] = useState<string>('');
  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [clientSecret, setClientSecret] = useState<string>('');
  const [paymentSession, setPaymentSession] = useState<PaymentSession | null>(null);
  const [savedMethods, setSavedMethods] = useState<PaymentMethod[]>([]);
  const [lastUsedMethod, setLastUsedMethod] = useState<PaymentMethod | null>(null);
  const [defaultMethod, setDefaultMethod] = useState<PaymentMethod | null>(null);
  const [loading, setLoading] = useState<boolean>(false);

  const createPaymentIntent = useCallback(async (): Promise<string> => {
    const response = await fetch(`${baseURL}/create-payment-intent`);
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || 'Failed to create payment intent');
    }
    return data.clientSecret;
  }, [baseURL]);

  const initializeSession = async () => {
    try {
      setLoading(true);
      setStatus('Initializing...');
      setMessage('');

      const secret = await createPaymentIntent();
      setClientSecret(secret);


      console.log('-- HeadlessScreen:', "Initializing session with secret:", secret);
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

  const fetchSavedMethods = async () => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Please initialize session first');
      return;
    }
    console.log('-- HeadlessScreen:', "fetchSavedMethods");

    try {
      setLoading(true);
      setStatus('Fetching saved methods...');

      const result = await paymentSession.getCustomerSavedPaymentMethods();
      console.log('-- HeadlessScreen:', "Saved methods result:", result);

      if (result.status === 'success') {
        setStatus('Saved methods fetched');
        setMessage('Handler initialized. Now fetch payment methods.');
      } else {
        setStatus('Error');
        setMessage('Failed to initialize handler');
      }
    } catch (error) {
      console.error('Fetch saved methods failed:', error);
      setStatus('Error');
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

      const result = await paymentSession.getCustomerLastUsedPaymentMethodData();
      console.log('-- HeadlessScreen:', 'Last used method:', result);

      if (result.paymentMethod) {
        setLastUsedMethod(result.paymentMethod);
        setStatus('Last used method fetched');
        setMessage(`Method: ${result.paymentMethod.paymentMethod}`);
      } else if (result.error) {
        setStatus('Error');
        setMessage(result.error);
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

      const result = await paymentSession.getCustomerDefaultSavedPaymentMethodData();
      console.log('Default method:', result);

      if (result.paymentMethod) {
        setDefaultMethod(result.paymentMethod);
        setStatus('Default method fetched');
        setMessage(`Method: ${result.paymentMethod.paymentMethod}`);
      } else if (result.error) {
        setStatus('Error');
        setMessage(result.error);
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
    console.log('-- HeadlessScreen:', 'Confirm with last used method called');

    try {
      setLoading(true);
      setStatus('Confirming payment...');

      const result = await paymentSession.confirmWithCustomerLastUsedPaymentMethod();
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

      const result = await paymentSession.confirmWithCustomerDefaultPaymentMethod();
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

  const renderPaymentMethod = (method: PaymentMethod | null, label: string) => {
    if (!method) return null;

    return (
      <View style={styles.methodCard}>
        <Text style={styles.methodLabel}>{label}</Text>
        <Text style={styles.methodText}>Type: {method.paymentMethod}</Text>
        {method.last4Digits && (
          <Text style={styles.methodText}>Card: **** {method.last4Digits}</Text>
        )}
        {method.scheme && (
          <Text style={styles.methodText}>Scheme: {method.scheme}</Text>
        )}
        <Text style={styles.methodText}>Last Used: {method.lastUsedAt}</Text>
        {method.defaultPaymentMethodSet && (
          <Text style={styles.defaultBadge}>DEFAULT</Text>
        )}
      </View>
    );
  };

  return (
    <ScrollView style={styles.scrollContainer}>
      <View style={styles.container}>
        <Text style={styles.title}>Headless Mode</Text>
        
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
          onPress={fetchSavedMethods}
          disabled={loading}
        >
          <Text style={styles.buttonText}>
            {loading ? 'Fetching...' : '2. Initialize Handler'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.button, loading && styles.buttonDisabled]} 
          onPress={fetchLastUsedMethod}
          disabled={loading}
        >
          <Text style={styles.buttonText}>
            {loading ? 'Fetching...' : '3. Get Last Used Method'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.button, loading && styles.buttonDisabled]} 
          onPress={fetchDefaultMethod}
          disabled={loading}
        >
          <Text style={styles.buttonText}>
            {loading ? 'Fetching...' : '4. Get Default Method'}
          </Text>
        </TouchableOpacity>

        {renderPaymentMethod(lastUsedMethod, 'Last Used Method')}
        {renderPaymentMethod(defaultMethod, 'Default Method')}

        <TouchableOpacity 
          style={[styles.button, styles.confirmButton, loading && styles.buttonDisabled]} 
          onPress={confirmWithLastUsed}
          // disabled={loading || !lastUsedMethod}
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
      </View>
    </ScrollView>
  );
}
