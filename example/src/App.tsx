import { View, Text } from 'react-native';
import { HyperProvider } from '@juspay-tech/react-native-hyperswitch';
import PaymentScreen from './PaymentScreen';

export default function App() {
  const publishableKey = process.env.HYPERSWITCH_PUBLISHABLE_KEY;
  const profileId = process.env.PROFILE_ID;

  return publishableKey && profileId ? (
    <HyperProvider publishableKey={publishableKey} profileId={profileId}>
      <PaymentScreen />
    </HyperProvider>
  ) : (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <Text>Configure env and restart Metro server</Text>
    </View>
  );
}
