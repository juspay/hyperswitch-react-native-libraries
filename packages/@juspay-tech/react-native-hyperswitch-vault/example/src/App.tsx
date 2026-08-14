import { useState } from 'react';
import {
  Alert,
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {
  CardCVCWidget,
  CardExpiryWidget,
  CardHolderWidget,
  CardNumberWidget,
  HyperswitchTokenizationConfiguration,
  HyperswitchVault,
  type HyperswitchTextInputState,
} from 'react-native-hyperswitch-vault';

const CARD_FORM_ID = 'checkout-card-form';

export default function App() {
  const [fieldStates, setFieldStates] = useState<
    Record<string, HyperswitchTextInputState>
  >({});
  const [status, setStatus] = useState('Ready');

  const updateFieldState = (state: HyperswitchTextInputState) => {
    setFieldStates((current) => ({
      ...current,
      [state.fieldName]: state,
    }));
  };

  const handleSubmit = async () => {
    try {
      setStatus('Submitting');
      const { status: responseStatus } = await HyperswitchVault.submit(
        CARD_FORM_ID,
        {
          vaultId: 'testvault',
          environment: 'sandbox',
          vaultBaseUrl: 'https://vault.example.com',
          path: '/post',
          method: 'POST',
        }
      );
      setStatus(`Submitted: ${responseStatus}`);
    } catch (error) {
      setStatus('Validation or request failed');
      Alert.alert(
        'Unable to submit',
        'Check field validation and Vault setup.'
      );
    }
  };

  const isFormValid =
    Object.keys(fieldStates).length > 0 &&
    Object.values(fieldStates).every((state) => state.isValid);

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.container}>
        <Text style={styles.title}>Hyperswitch Vault</Text>
        <Text style={styles.subtitle}>Card collection example</Text>

        <View style={styles.form}>
          <CardNumberWidget
            id={CARD_FORM_ID}
            placeholder="Card number"
            containerStyle={styles.inputContainer}
            textStyle={styles.input}
            onStateChange={updateFieldState}
            tokenization={HyperswitchTokenizationConfiguration.presets.card}
          />
          <CardHolderWidget
            id={CARD_FORM_ID}
            placeholder="Cardholder name"
            containerStyle={styles.inputContainer}
            textStyle={styles.input}
            onStateChange={updateFieldState}
          />
          <View style={styles.row}>
            <CardExpiryWidget
              id={CARD_FORM_ID}
              placeholder="MM/YY"
              containerStyle={[styles.inputContainer, styles.rowInput]}
              textStyle={styles.input}
              onStateChange={updateFieldState}
            />
            <CardCVCWidget
              id={CARD_FORM_ID}
              placeholder="CVC"
              containerStyle={[styles.inputContainer, styles.rowInput]}
              textStyle={styles.input}
              onStateChange={updateFieldState}
              tokenization={HyperswitchTokenizationConfiguration.presets.cvc}
            />
          </View>

          <Button
            title={isFormValid ? 'Submit to Vault' : 'Complete card details'}
            onPress={handleSubmit}
            disabled={!isFormValid}
          />
          <Text style={styles.status}>{status}</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#f4f7fb',
  },
  container: {
    flexGrow: 1,
    padding: 24,
    justifyContent: 'center',
  },
  title: {
    color: '#111827',
    fontSize: 28,
    fontWeight: '700',
  },
  subtitle: {
    color: '#4b5563',
    fontSize: 16,
    marginTop: 6,
    marginBottom: 24,
  },
  form: {
    gap: 14,
  },
  inputContainer: {
    minHeight: 52,
    borderWidth: 1,
    borderColor: '#cbd5e1',
    borderRadius: 8,
    backgroundColor: '#ffffff',
    paddingHorizontal: 14,
  },
  input: {
    color: '#111827',
    fontSize: 16,
  },
  row: {
    flexDirection: 'row',
    gap: 12,
  },
  rowInput: {
    flex: 1,
  },
  status: {
    color: '#374151',
    fontSize: 14,
    marginTop: 4,
  },
});
