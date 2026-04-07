import { useState, useEffect, useCallback, useRef } from 'react';
import { View, Text, TextInput, TouchableOpacity } from 'react-native';
import {
  PaymentWidget,
  CvcWidget,
  HyperElements,
  useWidget,
  type HyperElementsOptions,
  type HyperInstance,
  type PaymentEvent,
  type PaymentWidgetRef,
  type PaymentSession,
  type HeadlessResponse,
  type SavedPaymentMethod,
} from '@juspay-tech/react-native-hyperswitch';
import {
  initialBaseUrl,
  getCustomisationOptions,
  getCvcInputOptions,
  getStatus,
  getErrorMessage,
} from './utils';
import { styles } from './styles';

type PaymentMethod = SavedPaymentMethod;

interface UIScreenProps {
  hyperPromise: Promise<HyperInstance>;
}

function WidgetContent({ 
  onStatusUpdate 
}: { 
  onStatusUpdate: (status: string, message?: string) => void 
}) {
  const widget = useWidget();
  const [isConfirming, setIsConfirming] = useState(false);
  const widgetRef = useRef<PaymentWidgetRef | null>(null);
  const handleConfirmPayment = async () => {
    // if (!widget.isReady) {
    //   onStatusUpdate('Error', 'Widget is not ready');
    //   return;
    // }

    try {
      setIsConfirming(true);
      onStatusUpdate('Confirming...', 'Payment confirmation in progress');
      // Call confirmPayment with widgetId
      const result = await widgetRef.current?.confirmPayment();
      // Parse the result
      const status = result?.status || 'unknown';
      const message = result?.message || 'Payment confirmation completed';
      
      onStatusUpdate(getStatus(status), message);
      setIsConfirming(false);
    } catch (error) {
      onStatusUpdate('Error', getErrorMessage(error));
      setIsConfirming(false);
    }
  };

  return (
    <>
        <PaymentWidget
      ref= {widgetRef}
        widgetId="payment-widget-2"
        onPaymentResult={(result: any) => {
          if (result.errorMessage) {
            onStatusUpdate(`Payment failed: ${result.errorMessage}`);
          } else {
            onStatusUpdate(getStatus(result?.status), result?.status);
          }
        }}
        style={{ width: '100%', height: 400 }}
        options={{ 
          ...getCustomisationOptions('accordion'), 
        }}
      />
      {/* Confirm Payment Button */}
      <TouchableOpacity 
        style={[
          styles.button, 
          styles.confirmButton,
          (isConfirming) && styles.buttonDisabled
        ]} 
        onPress={handleConfirmPayment}
        disabled={ isConfirming}
      >
        <Text style={styles.buttonText}>
          {
          isConfirming ? 'Confirming...' : 
           widget.isLoading ? 'Loading...' : 
           'Confirm Payment (useWidget)'
           }
        </Text>
      </TouchableOpacity>

      {/* Widget Status */}
      {/* <View style={styles.widgetStatus}>
        <Text style={styles.widgetStatusText}>
          Widget Status: {widget.isReady ? 'Ready' : 'Initializing'}
        </Text>
        <Text style={styles.widgetStatusText}>
          Loading: {widget.isLoading ? 'Yes' : 'No'} | 
          Disabled: {widget.isConfirmDisabled ? 'Yes' : 'No'}
        </Text>
      </View> */}
    </>
  );
}

export default function UIScreen({ hyperPromise }: UIScreenProps) {
  const [status, setStatus] = useState<string | null | undefined>(null);
  const [message, setMessage] = useState<string | null | undefined>(null);
  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [clientSecret, setClientSecret] = useState<string | null | undefined>(null);
  const [sdkAuthorisation, setSdkAuthorisation] = useState<string | null | undefined>(null);
  const [paymentSession, setPaymentSession] = useState<PaymentSession | null>(null);
  const [lastUsedMethod, setLastUsedMethod] = useState<PaymentMethod | null>(null);
  const [defaultMethod, setDefaultMethod] = useState<PaymentMethod | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [sessionInitializing, setSessionInitializing] = useState<boolean>(false);

  // Guard against double-initialization from React strict mode / fast re-renders
  const sessionInitRef = useRef(false);

  const createPaymentIntent = useCallback(async (): Promise<string> => {
    const response = await fetch(`${baseURL}/create-payment-intent`);
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || 'Failed to create payment intent');
    }
    setClientSecret(data.clientSecret);
    setSdkAuthorisation(data.sdkAuthorisation);
    return data.clientSecret;
  }, [baseURL]);

  const setup = useCallback(async (): Promise<void> => {
    try {
      // Reset session init guard so the useEffect can fire again
      sessionInitRef.current = false;
      await createPaymentIntent();
      setPaymentSession(null);
      setLastUsedMethod(null);
      setDefaultMethod(null);
      setStatus('Ready to checkout');
      setMessage(null);
    } catch (error) {
      console.error('Setup failed:', error);
      setStatus('Setup Error:');
      setMessage(getErrorMessage(error));
    }
  }, [createPaymentIntent]);

  const checkout = async (): Promise<void> => {
    setStatus('Info');
    setMessage('Use the "Confirm Payment" button below to trigger payment via useWidget hook');
  };

  const handleStatusUpdate = (newStatus: string, newMessage?: string) => {
    setStatus(newStatus);
    setMessage(newMessage || null);
  };

  useEffect(() => {
    if (!clientSecret) return;
    if (sessionInitRef.current) return; // already initializing / initialized
    sessionInitRef.current = true;

    const initAndFetch = async () => {
      try {
        setSessionInitializing(true);
        setStatus('Auto-initializing session...');
        setMessage('');

        // Step 1: Initialize session
        const session = await initPaymentSession(hyperPromise, clientSecret);
        setPaymentSession(session);
        setStatus('Session initialized — fetching saved methods...');

        // Step 2: Immediately fetch both saved payment methods (race condition test)
        const [lastUsedResult, defaultResult] = await Promise.all([
          session.getCustomerLastUsedPaymentMethodData() as Promise<HeadlessResponse>,
          session.getCustomerDefaultSavedPaymentMethodData() as Promise<HeadlessResponse>,
        ]);

        // Process last-used result
        if (lastUsedResult.status === 'success' && lastUsedResult.data) {
          setLastUsedMethod(lastUsedResult.data);
        } else {
          setLastUsedMethod(null);
          console.log('No last-used method:', lastUsedResult.message || lastUsedResult.code);
        }

        // Process default result
        if (defaultResult.status === 'success' && defaultResult.data) {
          setDefaultMethod(defaultResult.data);
        } else {
          setDefaultMethod(null);
          console.log('No default method:', defaultResult.message || defaultResult.code);
        }

        setStatus('Ready — saved methods loaded');
        setMessage('Session + saved methods initialized automatically');
      } catch (error) {
        console.error('Auto-init failed:', error);
        setStatus('Auto-init Error');
        setMessage(getErrorMessage(error));
      } finally {
        setSessionInitializing(false);
      }
    };

    initAndFetch();
  }, [clientSecret, hyperPromise]);

  // Manual refresh for saved methods (in case merchant wants to re-fetch)
  const refreshSavedMethods = async () => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Session not initialized yet');
      return;
    }

    try {
      setLoading(true);
      setStatus('Refreshing saved methods...');

      const [lastUsedResult, defaultResult] = await Promise.all([
        paymentSession.getCustomerLastUsedPaymentMethodData() as Promise<HeadlessResponse>,
        paymentSession.getCustomerDefaultSavedPaymentMethodData() as Promise<HeadlessResponse>,
      ]);

      if (lastUsedResult.status === 'success' && lastUsedResult.data) {
        setLastUsedMethod(lastUsedResult.data);
      } else {
        setLastUsedMethod(null);
      }

      if (defaultResult.status === 'success' && defaultResult.data) {
        setDefaultMethod(defaultResult.data);
      } else {
        setDefaultMethod(null);
      }

      setStatus('Saved methods refreshed');
      setMessage('Last-used and default methods re-fetched');
    } catch (error) {
      console.error('Refresh failed:', error);
      setStatus('Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  };

  const confirmWithLastUsed = async () => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Please wait for session to initialize');
      return;
    }

    try {
      setLoading(true);
      setStatus('Confirming with CVC (last used)...');

      const result = await paymentSession.confirmWithCustomerLastUsedPaymentMethod('last-used-card') as HeadlessResponse;
      console.log('Confirm with last used (CVC) result:', result);

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
      setMessage('Please wait for session to initialize');
      return;
    }

    try {
      setLoading(true);
      setStatus('Confirming with CVC (default)...');

      const result = await paymentSession.confirmWithCustomerDefaultPaymentMethod('default-card') as HeadlessResponse;
      console.log('Confirm with default (CVC) result:', result);

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

    const cardDetails = method.card;

    return (
      <View style={styles.methodCard}>
        <Text style={styles.methodLabel}>{label}</Text>
        <Text style={styles.methodText}>Type: {method.payment_method_str}</Text>
        {cardDetails && (
          <>
            <Text style={styles.methodText}>
              Card: **** {cardDetails.last4_digits}
            </Text>
            <Text style={styles.methodText}>Scheme: {cardDetails.scheme}</Text>
            <Text style={styles.methodText}>
              Holder: {cardDetails.card_holder_name}
            </Text>
            <Text style={styles.methodText}>
              Expires: {cardDetails.expiry_month}/{cardDetails.expiry_year}
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

  useEffect(() => {
    setup();
  }, [setup]);

  const hyperElementsOptions: HyperElementsOptions = {
    clientSecret: clientSecret ?? undefined,
    sdkAuthorisation: sdkAuthorisation ?? undefined,
  };

  const isLoading = loading || sessionInitializing;

  return (
    <ScrollView >
    <HyperElements hyper={hyperPromise} options={hyperElementsOptions}>
      <ScrollView style={styles.scrollContainer} contentContainerStyle={styles.container}>
        <TextInput
          style={styles.textInput}
          placeholder="Enter base URL"
          value={baseURL}
          onChangeText={(text) => setBaseURL(text)}
        />
        <TouchableOpacity style={styles.button} onPress={setup}>
          <Text style={styles.buttonText}>Reload client Secret</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={checkout}>
          <Text style={styles.buttonText}>Checkout</Text>
        </TouchableOpacity>
        <View style={styles.status}>
          <Text style={styles.statusText}>{status}</Text>
          {message && <Text style={styles.messageText}>{message}</Text>}
        </View>
        <PaymentWidget
          widgetId="payment-widget"
          onPaymentResult={(result: any) => {
            console.log('Payment Result from Widget:', result);
            if (result.errorMessage) {
              setStatus(`Payment failed: ${result.errorMessage}`);
              setMessage(null);
            } else {
              setStatus(getStatus(result?.status));
              setMessage(result?.status);
            }
          }}
          style={{ width: '100%', height: 400 }}
          options={{ 
            ...getCustomisationOptions('accordion'), 
          }}
        />
      </View>
    </HyperElements>
    </ScrollView>
  );
}
