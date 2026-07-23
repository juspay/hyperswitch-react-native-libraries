import { useState } from "react";
import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { Hyperswitch } from "@juspay-tech/react-native-hyperswitch";
import { initialBaseUrl } from "./utils";
import { getCustomisationOptions, profileId, publishableKey } from "./utils";
import type { HyperswitchSession, PaymentSessionConfiguration } from "@juspay-tech/react-native-hyperswitch";

let hyperSingleton: Promise<HyperswitchSession> | null = null;

function getHyperSingleton(): Promise<HyperswitchSession> | null {
  if (!publishableKey) return null;
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
  const hyperPromise = getHyperSingleton();
  const openSDK = async () => {
    const serverUrl = initialBaseUrl;
    fetch(`${serverUrl}/create-payment-intent`)
      .then((r) => r.json())
      .then((data: PaymentSessionConfiguration) => {
        if (data.sdkAuthorization) {
          hyperPromise?.then(async (hyper) => {
            let session = await hyper.initPaymentSession(data);
            let handler = await session.getCustomerSavedPaymentMethods();
            let data2 = await handler.getCustomerLastUsedPaymentMethodData();
            console.log("Last used payment method data", data2);
            let data3 = await handler.getCustomerDefaultSavedPaymentMethodData();
            console.log("Default saved payment method data", data3);
            let result = await session.presentPaymentSheet(
              getCustomisationOptions("tabs"),
            );
            console.log("Payment result", result);
            if (result.type === "completed") {
              setStatus("Payment completed successfully");
            } else {
              setStatus(`Payment ${result.type}: ${result.message}`);
            }
          });
        } else {
          setStatus("Failed to get sdkAuthorization from server");
        }
      })
      .catch((err) => {
        setStatus(`Payment failed: ${err.message}`);
      });
  };

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
      <TouchableOpacity style={styles.button} onPress={() => openSDK()}>
        <Text style={styles.buttonText}>Start Demo</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#fafafa",
    padding: 24,
  },
  center: {
    flex: 1,
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
    fontSize: 16,
    color: "#111827",
  },
  button: {
    height: 48,
    paddingHorizontal: 32,
    borderRadius: 999,
    backgroundColor: "#111827",
    alignItems: "center",
    justifyContent: "center",
  },
  buttonText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "600",
  },
});
