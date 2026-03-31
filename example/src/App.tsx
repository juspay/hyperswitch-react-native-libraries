import { View, Text } from 'react-native';
import {
  HyperInit,
} from '@juspay-tech/react-native-hyperswitch';
import PaymentScreen from './PaymentScreen';

export default function App() {
  const publishableKey = process.env.HYPERSWITCH_PUBLISHABLE_KEY;
  const profileId = process.env.PROFILE_ID;

  const hyperPromise =
    publishableKey && profileId ?
      HyperInit(publishableKey, profileId)
    : null;

  if (!publishableKey || !profileId) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <Text>Configure env and restart Metro server</Text>
      </View>
    );
  }

  if (!hyperPromise) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <Text>Initializing...</Text>
      </View>
    );
  }

  return (<PaymentScreen hyperPromise={hyperPromise} />);
}