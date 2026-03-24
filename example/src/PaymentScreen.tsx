import { useState, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity } from 'react-native';
import {
  useHyper,
  PaymentWidget,
  HyperElements,
  type PresentPaymentSheetResult,
} from '@juspay-tech/react-native-hyperswitch';
import {
  initialBaseUrl,
  getCustomisationOptions,
  getStatus,
  getErrorMessage,
} from './utils';
import { styles } from './styles';

export default function PaymentScreen() {
  const [status, setStatus] = useState<string | null | undefined>(null);
  const [message, setMessage] = useState<string | null | undefined>(null);
  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [clientSecret, setClientSecret] = useState<string | null | undefined>(null);
  const [sdkAuthorisation, setSdkAuthorisation] = useState<string | null | undefined>(null);

  const createPaymentIntent = useCallback(async (): Promise<void> => {
    const response = await fetch(`${baseURL}/create-payment-intent`);
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || 'Failed to create payment intent');
    }
    setClientSecret(data.clientSecret);
    setSdkAuthorisation(data.sdkAuthorisation);
    setStatus('Ready to checkout');
    setMessage(null);
  }, [baseURL]);

  return (
    <View style={styles.container}>
      <TextInput
        style={styles.textInput}
        placeholder="Enter base URL"
        value={baseURL}
        onChangeText={(text) => setBaseURL(text)}
      />
      <TouchableOpacity style={styles.button} onPress={createPaymentIntent}>
        <Text style={styles.buttonText}>Load client Secret</Text>
      </TouchableOpacity>

      {clientSecret && (
        <HyperElements
          options={{
            clientSecret,
            sdkAuthorisation: sdkAuthorisation || undefined,
          }}
        >
          <PaymentScreenContent
            status={status}
            message={message}
            setStatus={setStatus}
            setMessage={setMessage}
          />
        </HyperElements>
      )}
    </View>
  );
}

// Inner component that has access to HyperElements context
function PaymentScreenContent({
  status,
  message,
  setStatus,
  setMessage,
}: {
  status: string | null | undefined;
  message: string | null | undefined;
  setStatus: (s: string | null | undefined) => void;
  setMessage: (m: string | null | undefined) => void;
}) {
  const { presentPaymentSheet, isReady } = useHyper();
  // const { confirmPayment } = useHyper();

  const checkout = async (): Promise<void> => {
    if (!isReady) {
      setStatus('Not ready');
      setMessage('Please wait for the session to initialize');
      return;
    }

    try {
      const { error, paymentResult }: PresentPaymentSheetResult =
        await presentPaymentSheet(getCustomisationOptions());

      if (error) {
        console.error('Payment failed:', JSON.stringify(error, null, 2));
        setStatus(`Payment failed: ${error.code}`);
        setMessage(error.message);
      } else {
        console.log(
          'Payment completed with status:',
          JSON.stringify(paymentResult, null, 2)
        );
        setStatus(getStatus(paymentResult?.status));
        setMessage(paymentResult?.message);
      }
    } catch (error: any) {
      console.error('Checkout failed:', error);
      setStatus(`Checkout failed`);
      setMessage(getErrorMessage(error));
    }
  };

  return (
    <>
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
    </>
  );
}
