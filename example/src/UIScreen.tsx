import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView } from 'react-native';
import {
  PaymentWidget,
  HyperElements,
  useWidget,
  type HyperElementsOptions,
  type HyperInstance,
  type PaymentWidgetRef,
} from '@juspay-tech/react-native-hyperswitch';
import {
  initialBaseUrl,
  getCustomisationOptions,
  getStatus,
  getErrorMessage,
} from './utils';
import { styles } from './styles';

interface UIScreenProps {
  hyperPromise: Promise<HyperInstance>;
}

function WidgetContent({
  onStatusUpdate
}: {
  onStatusUpdate: (status: string, message?: string) => void
}) {
  // useWidget hook - uses global WidgetRegistry internally
  const widget2 = useWidget();

  const [isConfirming1, setIsConfirming1] = useState(false);
  const [isConfirming2, setIsConfirming2] = useState(false);
  const widgetRef1 = React.useRef<PaymentWidgetRef | null>(null);
  const widgetRef2 = React.useRef<PaymentWidgetRef | null>(null);

  // Using ref approach
  const handleConfirmPayment1 = async () => {
    try {
      setIsConfirming1(true);
      onStatusUpdate('Confirming Widget 1 (ref)...', 'Payment confirmation in progress');
      const result = await widgetRef1.current?.confirmPayment();
      const status = result?.status || 'unknown';
      const message = result?.message || 'Payment confirmation completed';

      onStatusUpdate(getStatus(status), `Widget 1 (ref): ${message}`);
      setIsConfirming1(false);
    } catch (error) {
      onStatusUpdate('Error', `Widget 1 (ref): ${getErrorMessage(error)}`);
      setIsConfirming1(false);
    }
  };

  // Using useWidget hook approach - directly calls registry without isReady check
  const handleConfirmPayment2 = async () => {
    try {
      setIsConfirming2(true);
      onStatusUpdate('Confirming Widget 2 (useWidget)...', 'Payment confirmation in progress');
      const result = await widget2.confirmPayment('payment-widget-2');
      const status = result?.status || 'unknown';
      const message = result?.message || 'Payment confirmation completed';

      onStatusUpdate(getStatus(status), `Widget 2 (useWidget): ${message}`);
      setIsConfirming2(false);
    } catch (error) {
      onStatusUpdate('Error', `Widget 2 (useWidget): ${getErrorMessage(error)}`);
      setIsConfirming2(false);
    }
  };

  return (
    <>
      {/* First PaymentWidget */}
      <PaymentWidget
        ref={widgetRef1}
        widgetId="payment-widget-1"
        onPaymentResult={(result: any) => {
          if (result.errorMessage) {
            onStatusUpdate(`Widget 1 Payment failed: ${result.errorMessage}`);
          } else {
            onStatusUpdate(getStatus(result?.status), `Widget 1: ${result?.status}`);
          }
        }}
        style={{ width: '100%', height: 300 }}
        options={{
          ...getCustomisationOptions('accordion'),
        }}
      />

      {/* Confirm Payment Button for Widget 1 */}
      <TouchableOpacity
        style={[
          styles.button,
          styles.confirmButton,
          (isConfirming1) && styles.buttonDisabled
        ]}
        onPress={handleConfirmPayment1}
        disabled={isConfirming1}
      >
        <Text style={styles.buttonText}>
          {isConfirming1 ? 'Confirming...' : 'Confirm Payment Widget 1'}
        </Text>
      </TouchableOpacity>

      {/* Second PaymentWidget */}
      <PaymentWidget
        ref={widgetRef2}
        widgetId="payment-widget-2"
        onPaymentResult={(result: any) => {
          console.log('--- Payment result:', result);
          if (result.errorMessage) {
            onStatusUpdate(`Widget 2 Payment failed: ${result.errorMessage}`);
          } else {
            onStatusUpdate(getStatus(result?.status), `Widget 2: ${result?.status}`);
          }
        }}
        style={{ width: '100%', height: 300, marginTop: 20 }}
        options={{
          ...getCustomisationOptions('accordion'),
        }}
      />

      {/* Confirm Payment Button for Widget 2 */}
      <TouchableOpacity
        style={[
          styles.button,
          styles.confirmButton,
          (isConfirming2) && styles.buttonDisabled
        ]}
        onPress={handleConfirmPayment2}
        disabled={isConfirming2}
      >
        <Text style={styles.buttonText}>
          {isConfirming2 ? 'Confirming...' : 'Confirm Payment Widget 2'}
        </Text>
      </TouchableOpacity>
    </>
  );
}

export default function UIScreen({ hyperPromise }: UIScreenProps) {
  const [status, setStatus] = useState<string | null | undefined>(null);
  const [message, setMessage] = useState<string | null | undefined>(null);
  const [baseURL, setBaseURL] = useState<string>(initialBaseUrl);
  const [clientSecret, setClientSecret] = useState<string | null | undefined>(
    null
  );
  const [sdkAuthorisation, setSdkAuthorisation] = useState<
    string | null | undefined
  >(null);

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
    setStatus('Info');
    setMessage(
      'Use the "Confirm Payment" button below to trigger payment via useWidget hook'
    );
  };

  const handleStatusUpdate = useCallback((newStatus: string, newMessage?: string) => {
    setStatus(newStatus);
    setMessage(newMessage || null);
  }, []);

  useEffect(() => {
    setup();
  }, [setup]);

  const hyperElementsOptions: HyperElementsOptions = {
    clientSecret: clientSecret ?? undefined,
    sdkAuthorisation: sdkAuthorisation ?? undefined,
  };

  return (
    <HyperElements hyper={hyperPromise} options={hyperElementsOptions}>
      <ScrollView
        style={styles.scrollContainer}
        contentContainerStyle={styles.container}
      >
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

        {/* WidgetContent uses useWidget hook internally */}
        <WidgetContent onStatusUpdate={handleStatusUpdate} />
      </ScrollView>
    </HyperElements>
  );
}
