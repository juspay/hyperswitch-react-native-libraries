import { useState, useEffect, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity } from 'react-native';
import {
  PaymentWidget,
  HyperElements,
  type HyperElementsOptions,
  type HyperInstance,
} from '@juspay-tech/react-native-hyperswitch';
import {
  initialBaseUrl,
  getCustomisationOptions,
  getStatus,
  getErrorMessage,
} from './utils';
import { styles } from './styles';

interface PaymentScreenProps {
  hyperPromise: Promise<HyperInstance>;
}

export default function PaymentScreen({ hyperPromise }: PaymentScreenProps) {
  const [status, setStatus] = useState<string | null | undefined>(null);
  const [message, setMessage] = useState<string | null | undefined>(null);
  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [clientSecret, setClientSecret] = useState<string | null | undefined>(null);
  const [sdkAuthorisation, setSdkAuthorisation] = useState<string | null | undefined>(null);

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
      await createPaymentIntent();
      setStatus('Ready to checkout');
      setMessage(null);
    } catch (error) {
      console.error('Setup failed:', error);
      setStatus('Setup Error:');
      setMessage(getErrorMessage(error));
    }
  }, [createPaymentIntent]);

  const checkout = async (): Promise<void> => {
    // Checkout logic would go here using useWidget hook
    console.log('Checkout initiated');
  };

  useEffect(() => {
    setup();
  }, [setup]);

  const hyperElementsOptions: HyperElementsOptions = {
    clientSecret: clientSecret ?? undefined,
    sdkAuthorisation: sdkAuthorisation ?? undefined,
  };

  return (
    <HyperElements hyper={hyperPromise} options={hyperElementsOptions}>
      <View style={styles.container}>
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
  );
}
