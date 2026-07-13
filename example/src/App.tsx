import { useEffect, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Linking,
  StyleSheet,
} from 'react-native';
import { loadHyper } from '@juspay-tech/react-native-hyperswitch';
import type { HyperswitchSession } from '@juspay-tech/react-hyperswitch';
import DemoPopup from './DemoPopup';
import { profileId, publishableKey } from './utils';

let hyperSingleton: Promise<HyperswitchSession> | null = null;

function getHyperSingleton(): Promise<HyperswitchSession> | null {
  if (!publishableKey) return null;
  if (!hyperSingleton) {
    hyperSingleton = loadHyper({
      publishableKey,
      profileId,
    }) as Promise<HyperswitchSession>;
  }
  return hyperSingleton;
}

export default function App() {
  const [open, setOpen] = useState(false);
  const [status, setStatus] = useState<string | null>(null);

  useEffect(() => {
    Linking.getInitialURL().then((url) => {
      if (url) {
        setStatus(new URL(url).searchParams.get('status'));
      }
    });
  }, []);

  const hyperPromise = getHyperSingleton();

  if (!publishableKey) {
    return (
      <View style={styles.center}>
        <Text>Set HYPERSWITCH_PUBLISHABLE_KEY to enable payments.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {status && (
        <View style={styles.statusBar}>
          <Text style={styles.statusText}>Status: {status.toUpperCase()}</Text>
        </View>
      )}
      <TouchableOpacity
        style={styles.button}
        onPress={() => setOpen(true)}
      >
        <Text style={styles.buttonText}>Start Demo</Text>
      </TouchableOpacity>

      {open && hyperPromise && (
        <DemoPopup hyperPromise={hyperPromise} onClose={() => setOpen(false)} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fafafa',
    padding: 24,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statusBar: {
    marginBottom: 24,
    paddingVertical: 12,
    paddingHorizontal: 20,
    backgroundColor: '#e5e7eb',
    borderRadius: 999,
  },
  statusText: {
    fontSize: 16,
    color: '#111827',
  },
  button: {
    height: 48,
    paddingHorizontal: 32,
    borderRadius: 999,
    backgroundColor: '#111827',
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
