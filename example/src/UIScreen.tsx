import { useState, useEffect, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView } from 'react-native';
import {
  PaymentWidget,
  HyperElements,
  useWidget,
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

  const handleConfirmPayment = async () => {
    if (!widget.isReady) {
      onStatusUpdate('Error', 'Widget is not ready');
      return;
    }

    try {
      setIsConfirming(true);
      onStatusUpdate('Confirming...', 'Payment confirmation in progress');
      // Call confirmPayment with widgetId
      const result = await widget.confirmPayment('payment-widget');
      
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
        widgetId="payment-widget"
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
          (!widget.isReady || widget.isConfirmDisabled || isConfirming) && styles.buttonDisabled
        ]} 
        onPress={handleConfirmPayment}
        disabled={!widget.isReady || widget.isConfirmDisabled || isConfirming}
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
      <View style={styles.widgetStatus}>
        <Text style={styles.widgetStatusText}>
          Widget Status: {widget.isReady ? 'Ready' : 'Initializing'}
        </Text>
        <Text style={styles.widgetStatusText}>
          Loading: {widget.isLoading ? 'Yes' : 'No'} | 
          Disabled: {widget.isConfirmDisabled ? 'Yes' : 'No'}
        </Text>
      </View>
    </>
  );
}

export default function UIScreen({ hyperPromise }: UIScreenProps) {
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
    setStatus('Info');
    setMessage('Use the "Confirm Payment" button below to trigger payment via useWidget hook');
  };

  const handleStatusUpdate = (newStatus: string, newMessage?: string) => {
    setStatus(newStatus);
    setMessage(newMessage || null);
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
        
        {/* WidgetContent uses useWidget hook internally */}
        <WidgetContent onStatusUpdate={handleStatusUpdate} />
      </ScrollView>
    </HyperElements>
  );
}
