import { useState, useEffect, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity } from 'react-native';
import {
  useHyper,
  PaymentWidget,
  CvcWidget,
  type InitPaymentSessionParams,
  type InitPaymentSessionResult,
  type PresentPaymentSheetResult,
  type PaymentEvent,
} from '@juspay-tech/react-native-hyperswitch';
import {
  initialBaseUrl,
  getCustomisationOptions,
  getCvcInputOptions,
  getStatus,
  getErrorMessage,
} from './utils';
import { styles } from './styles';

export default function PaymentScreen() {
  const { initPaymentSession, presentPaymentSheet } = useHyper();
  const [status, setStatus] = useState<string>('');
  const [message, setMessage] = useState<string>('');
  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [clientSecret, setClientSecret] = useState<string>('');
  const [sdkAuthorisation, setSdkAuthorisation] = useState<string>('');

  const createPaymentIntent = useCallback(async () => {
    const response = await fetch(`${baseURL}/create-payment-intent`);
    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to create payment intent');
    }

    return {
      clientSecret: data.clientSecret,
      sdkAuthorisation: data.sdkAuthorisation,
    };
  }, [baseURL]);

  const setup = useCallback(async () => {
    try {
      const { clientSecret: secret, sdkAuthorisation: auth } = await createPaymentIntent();
      setClientSecret(secret);
      setSdkAuthorisation(auth);

      const params: InitPaymentSessionParams = {
        paymentIntentClientSecret: secret,
        sdkAuthorisation: auth,
      };

      const result: InitPaymentSessionResult = await initPaymentSession(params);

      if (result.error) {
        throw new Error(result.error);
      }

      setStatus('Ready to checkout');
      setMessage('');
    } catch (error) {
      console.error('Setup failed:', error);
      setStatus('Setup Error');
      setMessage(getErrorMessage(error));
    }
  }, [initPaymentSession, createPaymentIntent]);

  const checkout = async () => {
    try {
      const { error, paymentResult }: PresentPaymentSheetResult = await presentPaymentSheet(
        getCustomisationOptions(),
        (event: PaymentEvent) => {
          console.log('PaymentSheet Event:', event.eventName, event.payload);
        }
      );

      if (error) {
        console.error('Payment failed:', JSON.stringify(error, null, 2));
        setStatus(`Payment failed: ${error.code}`);
        setMessage(error.message);
      } else {
        console.log('Payment completed with status:', JSON.stringify(paymentResult, null, 2));
        setStatus(getStatus(paymentResult?.status));
        setMessage(paymentResult?.message);
      }
    } catch (error: any) {
      console.error('Checkout failed:', error);
      setStatus('Checkout failed');
      setMessage(error.message);
    }
  };

  const handlePaymentResult = (result: any) => {
    console.log('Payment Result from Widget:', result);
    if (result.errorMessage) {
      setStatus(`Payment failed: ${result.errorMessage}`);
      setMessage('');
    } else {
      setStatus(getStatus(result?.status));
      setMessage(result?.status);
    }
  };

  const handleCvcChange = (event: PaymentEvent) => {
    console.log('CvcWidget Event:', event.eventName, event.payload);
    if (event.eventName === 'CVC_STATUS' && typeof event.payload === 'string') {
      const parsed = JSON.parse(event.payload);
      console.log('CVC Status:', JSON.stringify(parsed.cvcStatus, null, 2));
    }
  };

  useEffect(() => {
    setup();
  }, [setup]);

  return (
    <View style={styles.container}>
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

      <View style={styles.status}>
        <Text style={styles.statusText}>{status}</Text>
        {message && <Text style={styles.messageText}>{message}</Text>}
      </View>

      <PaymentWidget
        widgetId="payment-widget"
        onPaymentResult={handlePaymentResult}
        style={{ width: '100%', height: 400 }}
        onPaymentEvent={(event: PaymentEvent) => {
          console.log('PaymentWidget Events:', event.eventName, event.payload);
        }}
        options={{
          ...getCustomisationOptions('accordion'),
          clientSecret,
          sdkAuthorisation,
        }}
      />

      <Text style={styles.statusText}>CVC Widget (for saved cards):</Text>
      {clientSecret && (
        <CvcWidget
          options={{
            ...getCvcInputOptions(),
            clientSecret,
            placeholder: '123',
          }}
          style={{ width: '30%', height: 80 }}
          onChange={handleCvcChange}
        />
      )}
    </View>
  );
}
