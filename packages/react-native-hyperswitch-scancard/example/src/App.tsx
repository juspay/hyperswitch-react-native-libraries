import * as React from 'react';

import { StyleSheet, View, Text, SafeAreaView, TouchableOpacity } from 'react-native';
import {
  ScanCardComponent,
  ScanCardReturnType,
  isAvailable,
  launchScanCard
} from '@juspay-tech/react-native-hyperswitch-scancard';

export default function App() {
  const [result, setResult] = React.useState<ScanCardReturnType | null>(null);

  const handleScanCardCallback = (scanData: ScanCardReturnType | null) => {
    setResult(scanData);
    console.log(scanData);
  };

  return (
    <SafeAreaView style={styles.container}>
      <View>
        <Text>Card Number: {result?.data?.pan}</Text>
        <Text>Expiry Month: {result?.data?.expiryMonth}</Text>
        <Text>Expiry Year: {result?.data?.expiryYear}</Text>
        <ScanCardComponent callback={handleScanCardCallback}>
          <Text style={styles.button}>Start Scan [Component]</Text>
        </ScanCardComponent>
       {isAvailable &&
        <TouchableOpacity onPress={() => launchScanCard(handleScanCardCallback)} >
          <Text style={styles.button}>Start Scan [Function]</Text>
          </TouchableOpacity>
    }
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  button: {
    color: 'blue'
  },
  box: {
    width: '100%',
    height: '100%',
    marginVertical: 20,
    backgroundColor: 'white',
  },
});
