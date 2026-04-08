import { useState, useEffect, useCallback, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import {
  PaymentWidget,
  CvcWidget,
  HyperElements,
  initPaymentSession,
  useWidget,
  type HyperElementsOptions,
  type HyperInstance,
  type PaymentEvent,
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

interface UIScreenProps {
  hyperPromise: Promise<HyperInstance>;
}

export default function UIScreen({ hyperPromise }: UIScreenProps) {
  const [status, setStatus] = useState<string>('');
  const [message, setMessage] = useState<string>('');
  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [clientSecret, setClientSecret] = useState<string>('');
  const [sdkAuthorisation, setSdkAuthorisation] = useState<string>('');
  const [paymentSession, setPaymentSession] = useState<PaymentSession | null>(
    null
  );
  const [lastUsedMethod, setLastUsedMethod] =
    useState<SavedPaymentMethod | null>(null);
  const [defaultMethod, setDefaultMethod] = useState<SavedPaymentMethod | null>(
    null
  );
  const [loading, setLoading] = useState<boolean>(false);
  const [sessionInitializing, setSessionInitializing] =
    useState<boolean>(false);
  const [paymentCompleted, setPaymentCompleted] = useState<boolean>(false);
  const [showWidget, setShowWidget] = useState<boolean>(true);

  const widget = useWidget();
  const sessionInitRef = useRef(false);

  const createPaymentIntent = useCallback(async (): Promise<{
    clientSecret: string;
    sdkAuthorization: string;
  }> => {
    const response = await fetch(`${baseURL}/create-payment-intent`);
    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to create payment intent');
    }

    return {
      clientSecret: data.clientSecret,
      sdkAuthorization: data.sdkAuthorization,
    };
  }, [baseURL]);

  const updateIntent = useCallback(async (): Promise<void> => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Payment session not initialized');
      return;
    }

    try {
      setLoading(true);
      const callBack = async () => {
        const { sdkAuthorization } = await createPaymentIntent();
        return sdkAuthorization;
      };
      const result = await paymentSession.updateIntent(callBack);
      console.log('Update Intent result:', result);

      setStatus(getStatus(result?.status));
      setMessage(result?.message || result?.status);
    } catch (error) {
      console.error('Update Intent failed:', error);
      setStatus('Update Intent Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  }, [paymentSession, createPaymentIntent]);

  const checkout = useCallback(async (): Promise<void> => {
    if (!paymentSession) {
      setStatus('Error');
      setMessage('Payment session not initialized');
      return;
    }

    try {
      setLoading(true);
      const result = await paymentSession.presentPaymentSheet(
        getCustomisationOptions(),
        // (event) => {
        //   console.log('PaymentSheet Event:', event);
        // }
      );
      console.log('Checkout result:', result);

      setStatus(getStatus(result?.status));
      setMessage(result?.message || result?.status);
    } catch (error) {
      console.error('Checkout failed:', error);
      setStatus('Checkout Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  }, [paymentSession, clientSecret]);

  const setup = useCallback(async (): Promise<void> => {
    try {
      sessionInitRef.current = false;
      const { clientSecret, sdkAuthorisation } = await createPaymentIntent();

      setClientSecret(clientSecret);
      setSdkAuthorisation(sdkAuthorisation);
      setPaymentSession(null);
      setLastUsedMethod(null);
      setDefaultMethod(null);
      setPaymentCompleted(false);
      setShowWidget(true);
      setStatus('Ready to checkout');
      setMessage('');
    } catch (error) {
      console.error('Setup failed:', error);
      setStatus('Setup Error');
      setMessage(getErrorMessage(error));
    }
  }, [createPaymentIntent]);

  const hideWidgetWithDelay = useCallback(() => {
    setPaymentCompleted(true);
    setTimeout(() => {
      setShowWidget(false);
    }, 500);
  }, []);

  const confirmPayment = async (): Promise<void> => {
    try {
      setLoading(true);
      const result = await widget.confirmPayment('payment-widget');
      console.log('Payment result:', result);

      setStatus(getStatus(result?.status));
      setMessage(result?.message || result?.status);
      if (result?.status === 'succeeded' || result?.status === 'failed') {
        hideWidgetWithDelay();
      }
    } catch (error) {
      console.error('Payment failed:', error);
      setStatus('Payment Error');
      setMessage(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!clientSecret || sessionInitRef.current) return;

    sessionInitRef.current = true;

    const initAndFetch = async () => {
      try {
        setSessionInitializing(true);
        setStatus('Auto-initializing session...');
        setMessage('');

        const session = await initPaymentSession(hyperPromise, clientSecret);
        setPaymentSession(session);
        setStatus('Session initialized — fetching saved methods...');

        const [lastUsedResult, defaultResult] = await Promise.all([
          session.getCustomerLastUsedPaymentMethodData() as Promise<HeadlessResponse>,
          session.getCustomerDefaultSavedPaymentMethodData() as Promise<HeadlessResponse>,
        ]);

        if (lastUsedResult.status === 'succeeded' && lastUsedResult.data) {
          setLastUsedMethod(lastUsedResult.data);
        } else {
          setLastUsedMethod(null);
          console.log(
            'No last-used method:',
            lastUsedResult.message || lastUsedResult.code
          );
        }

        if (defaultResult.status === 'succeeded' && defaultResult.data) {
          setDefaultMethod(defaultResult.data);
        } else {
          setDefaultMethod(null);
          console.log(
            'No default method:',
            defaultResult.message || defaultResult.code
          );
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

  useEffect(() => {
    setup();
  }, [setup]);

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

      if (lastUsedResult.status === 'succeeded' && lastUsedResult.data) {
        setLastUsedMethod(lastUsedResult.data);
      } else {
        setLastUsedMethod(null);
      }

      if (defaultResult.status === 'succeeded' && defaultResult.data) {
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
      // setLoading(true);
      setStatus('Confirming with CVC (last used)...');

      const result =
        (await paymentSession.confirmWithCustomerLastUsedPaymentMethod(
          'last-used-card'
        )) as HeadlessResponse;
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
      // setLoading(true);
      setStatus('Confirming with CVC (default)...');

      const result =
        (await paymentSession.confirmWithCustomerDefaultPaymentMethod(
          'default-card'
        )) as HeadlessResponse;
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

  const renderPaymentMethod = (
    method: SavedPaymentMethod | null,
    label: string
  ) => {
    if (!method) return null;

    const { card } = method;

    return (
      <View style={styles.methodCard}>
        <Text style={styles.methodLabel}>{label}</Text>
        <Text style={styles.methodText}>Type: {method.payment_method_str}</Text>
        {card && (
          <>
            <Text style={styles.methodText}>
              Card: **** {card.last4_digits}
            </Text>
            <Text style={styles.methodText}>Scheme: {card.scheme}</Text>
            <Text style={styles.methodText}>
              Holder: {card.card_holder_name}
            </Text>
            <Text style={styles.methodText}>
              Expires: {card.expiry_month}/{card.expiry_year}
            </Text>
          </>
        )}
        <Text style={styles.methodText}>Last Used: {method.last_used_at}</Text>
        <Text style={styles.methodText}>
          Payment Token: {method.payment_token}
        </Text>
        {method.default_payment_method_set && (
          <Text style={styles.defaultBadge}>DEFAULT</Text>
        )}
      </View>
    );
  };

  const handlePaymentResult = (result: any) => {
    console.log('Payment Result from Widget:', result);
    if (result.errorMessage) {
      setStatus(`Payment failed: ${result.errorMessage}`);
      setMessage('');
      hideWidgetWithDelay();
    } else {
      setStatus(getStatus(result?.status));
      setMessage(result?.status);
      hideWidgetWithDelay();
    }
  };

  const handlePaymentEvent = (event: PaymentEvent) => {
    console.log('PaymentWidget Event:', event.eventName, event.payload);
  };

  const handleCvcEvent = (widgetId: string) => (event: PaymentEvent) => {
    console.log(
      `CvcWidget [${widgetId}] Event:`,
      event.eventName,
      event.payload
    );
  };

  const hyperElementsOptions: HyperElementsOptions = {
    clientSecret: clientSecret || undefined,
    sdkAuthorisation: sdkAuthorisation || undefined,
  };

  const isLoading = loading || sessionInitializing;

  return (
    <ScrollView contentContainerStyle={styles.scrollContainer}>
      <HyperElements hyper={hyperPromise} options={hyperElementsOptions}>
        <View style={styles.container}>
          <Text style={styles.title}>UI Mode</Text>

          <TextInput
            style={styles.textInput}
            placeholder="Enter base URL"
            value={baseURL}
            onChangeText={setBaseURL}
          />

          <TouchableOpacity style={styles.button} onPress={setup}>
            <Text style={styles.buttonText}>Reload Client Secret</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.button} onPress={checkout}>
            <Text style={styles.buttonText}>Checkout</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.button} onPress={updateIntent}>
            <Text style={styles.buttonText}>Update Intent</Text>
          </TouchableOpacity>

          <View style={styles.status}>
            <Text style={styles.statusText}>{status}</Text>
            {message && <Text style={styles.messageText}>{message}</Text>}
          </View>

          {showWidget && (
            <PaymentWidget
              widgetId="payment-widget"
              onPaymentResult={handlePaymentResult}
              style={{ width: '100%', height: 400 }}
              options={getCustomisationOptions('accordion')}
              onPaymentEvent={handlePaymentEvent}
            />
          )}

          {showWidget && (
            <TouchableOpacity
              style={[
                styles.button,
                styles.confirmButton,
                loading && styles.buttonDisabled,
              ]}
              onPress={confirmPayment}
              disabled={loading}
            >
              <Text style={styles.buttonText}>
                {loading ? 'Processing...' : 'Confirm Payment'}
              </Text>
            </TouchableOpacity>
          )}

          <Text style={styles.title}>CVC Widget + Headless</Text>

          {sessionInitializing && (
            <View style={styles.status}>
              <ActivityIndicator size="small" color="#007AFF" />
              <Text style={styles.statusText}>
                Auto-initializing session & fetching saved methods...
              </Text>
            </View>
          )}

          <Text style={styles.statusText}>CVC Widget — Default Card:</Text>
          {clientSecret && (
            <CvcWidget
              options={{
                ...getCvcInputOptions(),
                clientSecret,
                widgetId: 'default-card',
                placeholder: '123',
              }}
              style={{ width: '30%', height: 80 }}
              onChange={handleCvcEvent('default-card')}
              onFocus={() => console.log('CvcWidget [default-card] Focus')}
              onBlur={() => console.log('CvcWidget [default-card] Blur')}
            />
          )}

          <Text style={styles.statusText}>CVC Widget — Last Used Card:</Text>
          {clientSecret && lastUsedMethod && (
            <CvcWidget
              options={{
                ...getCvcInputOptions(),
                clientSecret,
                widgetId: 'last-used-card',
                placeholder: '456',
              }}
              style={{ width: '30%', height: 80 }}
              onChange={handleCvcEvent('last-used-card')}
              onFocus={() => console.log('CvcWidget [last-used-card] Focus')}
              onBlur={() => console.log('CvcWidget [last-used-card] Blur')}
            />
          )}

          {renderPaymentMethod(lastUsedMethod, 'Last Used Method')}
          {renderPaymentMethod(defaultMethod, 'Default Method')}

        <TouchableOpacity
          style={[styles.button, isLoading && styles.buttonDisabled]}
          onPress={refreshSavedMethods}
          disabled={isLoading || !paymentSession}
        >
          <Text style={styles.buttonText}>
            {isLoading ? 'Loading...' : 'Refresh Saved Methods'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.confirmButton, isLoading && styles.buttonDisabled]}
          onPress={confirmWithDefault}
          disabled={isLoading || !defaultMethod}
        >
          <Text style={styles.buttonText}>
            {isLoading ? 'Processing...' : 'Confirm with Default'}
          </Text>
        </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.button,
              styles.confirmButton,
              isLoading && styles.buttonDisabled,
            ]}
            onPress={confirmWithLastUsed}
            disabled={isLoading || !lastUsedMethod}
          >
            <Text style={styles.buttonText}>
              {isLoading ? 'Processing...' : 'Confirm with Last Used'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.button,
              styles.confirmButton,
              isLoading && styles.buttonDisabled,
            ]}
            onPress={confirmWithDefault}
            disabled={isLoading || !defaultMethod}
          >
            <Text style={styles.buttonText}>
              {isLoading ? 'Processing...' : 'Confirm with Default'}
            </Text>
          </TouchableOpacity>
         <TouchableOpacity
          style={[styles.button, styles.confirmButton, isLoading && styles.buttonDisabled]}
          onPress={confirmWithLastUsed}
          disabled={isLoading || !lastUsedMethod}
        >
          <Text style={styles.buttonText}>
            {isLoading ? 'Processing...' : 'Confirm with Last Used'}
          </Text>
        </TouchableOpacity>

          {isLoading && (
            <ActivityIndicator
              size="large"
              color="#007AFF"
              style={styles.loader}
            />
          )}
        </View>
      </HyperElements>
    </ScrollView>
  );
}
