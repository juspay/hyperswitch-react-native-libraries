import { useState } from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import {
  Hyperswitch,
  type HyperswitchSession,
  type PaymentSession,
} from "@juspay-tech/react-native-hyperswitch";
import {
  initialBaseUrl,
  intentData,
  profileId,
  publishableKey,
  secretKey,
  serverURL,
} from "./utils";
import DemoPopup from "./pages/DemoPopup";
let hyperSingleton: Promise<HyperswitchSession> | null = null;

function getHyperSingleton(): Promise<HyperswitchSession> {
  if (!hyperSingleton) {
    hyperSingleton = Hyperswitch.init({
      publishableKey,
      profileId,
    }) as Promise<HyperswitchSession>;
  }
  return hyperSingleton;
}

export default function App() {
  const [status, setStatus] = useState<string | null>(null);
  const [session, setSession] = useState<PaymentSession | null>(null);
  const hyperPromise = getHyperSingleton();
  const [openEmbeddedSheet, setOpenEmbeddedSheet] = useState(false);
  const [sdkAuthorization, setSdkAuthorization] = useState<string | null>(null);
  const [paymentId, setPaymentId] = useState<string | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);

  const initDemo = async () => {
    if (!hyperPromise) {
      setStatus("HYPERSWITCH_PUBLISHABLE_KEY is not set");
      return;
    }
    setStatus("Initializing demo...");
    const serverUrl = serverURL;
    const url = initialBaseUrl
      ? `${initialBaseUrl}/create-payment-intent`
      : undefined;
    fetch(serverUrl ?? url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Api-Key": secretKey,
      },
      body: JSON.stringify(intentData),
    })
      .then((r) => r.json())
      .then((data) => {
        if (data.sdk_authorization || data.sdkAuthorization) {
          setSdkAuthorization(data.sdk_authorization || data.sdkAuthorization);
          hyperPromise?.then(async (hyper) => {
            let session = await hyper.initPaymentSession({
              sdkAuthorization: data.sdk_authorization || data.sdkAuthorization,
            });
            setSession(session);
          });
          setStatus("SDK initialized successfully");
        } else {
          setStatus("Failed to get sdkAuthorization from server");
        }
      })
      .catch((err) => {
        setStatus(`Failed: ${err.message}`);
      });
  };

  const openSDK = async () => {
    if (!session) {
      setStatus("Session not initialized. Please init demo first.");
      return;
    }
    let result = await session.presentPaymentSheet({
      merchantDisplayName: "Hyperswitch Demo",
      appearance :{
        theme: "Glass",
      }
    });
    console.log("Payment result", result);
    if (result.type === "completed") {
      setStatus("Payment completed successfully");
    } else {
      setStatus(`Payment ${result.type}: ${result.message}`);
    }
  };

  if (!publishableKey) {
    return (
      <View style={styles.center}>
        <Text>Set HYPERSWITCH_PUBLISHABLE_KEY to enable payments.</Text>
      </View>
    );
  }
  const props = {
    hyperPromise,
    sdkAuthorization: sdkAuthorization ?? null,
    paymentId,
    setPaymentId,
    loadError,
    setLoadError,
    setSdkAuthorization,
    onClose: () => setOpenEmbeddedSheet(false),
  };

  return (
    <View style={styles.container}>
      {status && (
        <View style={styles.statusBar}>
          <Text style={styles.statusText}>Status: {status.toUpperCase()}</Text>
        </View>
      )}
      <TouchableOpacity style={styles.button} onPress={() => initDemo()}>
        <Text style={styles.buttonText}>Init session</Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={[styles.button, { marginTop: 16 }]}
        onPress={() => openSDK()}
      >
        <Text style={styles.buttonText}>Open Sheet</Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={[styles.button, { marginTop: 16 }]}
        onPress={() => {
          initDemo();
          setOpenEmbeddedSheet(true);
        }}
      >
        <Text style={styles.buttonText}>Open Custom Sheet</Text>
      </TouchableOpacity>
      {openEmbeddedSheet && <DemoPopup {...props} />}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    backgroundColor: "#fafafa",
    padding: 16,
  },
  center: {
    alignItems: "center",
    justifyContent: "center",
  },
  statusBar: {
    marginBottom: 24,
    paddingVertical: 12,
    paddingHorizontal: 20,
    backgroundColor: "#e5e7eb",
    borderRadius: 999,
  },
  statusText: {
    fontSize: 14,
    color: "#111827",
  },
  button: {
    height: 48,
    paddingHorizontal: 16,
    borderRadius: 999,
    backgroundColor: "#111827",
    alignItems: "center",
    justifyContent: "center",
    textAlign: "center",
  },
  buttonText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "500",
  },
});
