import { useEffect, useState } from "react";
import type { ReactNode } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  StyleSheet,
  Alert,
} from "react-native";
import type {
  ElementsActions,
  CustomerLastUsedPaymentMethod,
  CustomerSavedPaymentMethodsSession,
} from "@juspay-tech/react-native-hyperswitch";

export const AMOUNTS = [5, 10, 25, 50];

export type FormLayoutProps = {
  isAmountScreen: boolean;
  setIsAmountScreen: (v: boolean) => void;
  amount: number;
  setAmount: (v: number) => void;
  onClose: () => void;
  cvcSlot: ReactNode;
  paymentSlot: ReactNode;
  lastUsed: CustomerLastUsedPaymentMethod | null | undefined;
  methodsSession: CustomerSavedPaymentMethodsSession | null;
  loadingSaved: boolean;
  canSubmit: boolean;
  updateAmount: (() => Promise<void>) | null;
  widgets: ElementsActions | null;
};

function formatCardLabel(method: CustomerLastUsedPaymentMethod | null): string {
  if (!method) return "Add payment method";
  const card = method.card;
  if (card) {
    const brand = card.scheme ?? card.card_network ?? "Card";
    const last4 = card.last4_digits ?? "••••";
    return `${brand} •••• ${last4}`;
  }
  return method.payment_method_type ?? method.payment_method ?? "Saved method";
}

export function FormLayout({
  isAmountScreen,
  setIsAmountScreen,
  amount,
  setAmount,
  onClose,
  cvcSlot,
  paymentSlot,
  lastUsed,
  methodsSession,
  loadingSaved,
  canSubmit,
  updateAmount,
  widgets,
}: FormLayoutProps) {
  const [message, setMessage] = useState("");
  const [amountVal, setAmountVal] = useState(amount);
  const [isLoading, setIsLoading] = useState(false);

  const handleDeposit = async () => {
    setMessage("");
    setIsLoading(true);

    if (isAmountScreen && !lastUsed) {
      setIsAmountScreen(false);
      setIsLoading(false);
      return;
    }
    if (isAmountScreen) {
      if (!methodsSession) return;
      const { type, message } =
        await methodsSession.confirmWithCustomerLastUsedPaymentMethod({
          id: "card-cvc-element",
        });
      setIsLoading(false);
      if (type === "failed") setMessage(message ?? "Payment error");
      if (type !== "failed") setMessage(`Payment status: ${type}`);
      if (type === "completed") {
        setTimeout(() => {
          onClose();
          Alert.alert(`Type: ${type}\nMessage: ${message ?? ""}`);
        }, 0);
      }
      return;
    }

    if (/*!hyper ||*/ !widgets) return;
    const { type, message } = await widgets.confirmPayment(
      "payment-element-id",
    );
    setIsLoading(false);
    const msg = message ?? "";
    if (
      type !==
      "form_validation_error"
    ) {
      onClose();
      setTimeout(() => {
        Alert.alert(`Type: ${type}\nMessage: ${msg}`);
      }, 0);
    } else {
      setMessage("Please fill the form");
    }
  };

  useEffect(() => {
    if (amountVal !== amount) {
      setAmountVal(amount);
      updateAmount ? updateAmount() : null;
    }
  }, [amount, amountVal, updateAmount]);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        {!isAmountScreen && (
          <TouchableOpacity
            onPress={() => setIsAmountScreen(true)}
            style={styles.backButton}
          >
            <Text style={styles.backText}>←</Text>
          </TouchableOpacity>
        )}
        <Text style={styles.title}>
          {isAmountScreen ? "Deposit Amount" : ""}
        </Text>
        <TouchableOpacity onPress={onClose} style={styles.closeButton}>
          <Text style={styles.closeText}>✕</Text>
        </TouchableOpacity>
        {isAmountScreen && (
          <Text style={styles.balance}>
            Balance: <Text style={styles.balanceBold}>$65.15</Text>
          </Text>
        )}
      </View>

      {isAmountScreen && (
        <View style={styles.savedSection}>
          {loadingSaved ? (
            <View style={styles.skeleton} />
          ) : lastUsed ? (
            <View style={styles.savedRow}>
              <TouchableOpacity
                onPress={() => setIsAmountScreen(false)}
                style={styles.savedMethod}
              >
                <Text style={styles.savedMethodText}>
                  {formatCardLabel(lastUsed)}
                </Text>
                <Text style={styles.chevron}>⌄</Text>
              </TouchableOpacity>
              {cvcSlot && <View style={styles.cvcBox}>{cvcSlot}</View>}
            </View>
          ) : null}
        </View>
      )}

      {!isAmountScreen && (
        <View style={styles.paymentSection}>{paymentSlot}</View>
      )}

      {isAmountScreen && (
        <>
          <View style={styles.amountSection}>
            <View style={styles.amountRow}>
              <Text style={styles.currency}>CA$</Text>
              <TextInput
                style={styles.amountInput}
                keyboardType="numeric"
                value={String(amountVal)}
                onChangeText={(text) => {
                  const val = parseInt(text, 10);
                  setAmountVal(Number.isNaN(val) ? 0 : val);
                }}
                onBlur={() => {
                  updateAmount ? updateAmount() : null;
                }}
              />
            </View>
            <Text style={styles.hint}>Minimum deposit is CA$1</Text>
          </View>

          <View style={styles.chipRow}>
            {AMOUNTS.map((value) => {
              const selected = value === amount;
              return (
                <TouchableOpacity
                  key={value}
                  onPress={() => setAmount(value)}
                  style={[styles.chip, selected && styles.chipSelected]}
                >
                  <Text
                    style={[
                      styles.chipText,
                      selected && styles.chipTextSelected,
                    ]}
                  >
                    CA${value}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </>
      )}

      <View style={styles.footer}>
        {message ? <Text style={styles.error}>{message}</Text> : null}
        <TouchableOpacity
          disabled={!canSubmit || isLoading}
          onPress={handleDeposit}
          style={[
            styles.depositButton,
            (!canSubmit || isLoading) && styles.depositButtonDisabled,
          ]}
        >
          <Text style={styles.depositButtonText}>
            {isLoading ? "Processing…" : `Deposit $${amount}`}
          </Text>
        </TouchableOpacity>
        {isAmountScreen ? (
          <TouchableOpacity onPress={onClose}>
            <Text style={styles.cancel}>Cancel</Text>
          </TouchableOpacity>
        ) : (
          <Text style={styles.secure}>
            🔒 Your payment is secure & encrypted
          </Text>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingBottom: 16,
  },
  header: {
    paddingTop: 24,
    paddingHorizontal: 20,
    paddingBottom: 12,
    alignItems: "center",
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    color: "#111827",
  },
  backButton: {
    position: "absolute",
    left: 16,
    top: 24,
    padding: 8,
  },
  backText: {
    fontSize: 22,
    color: "#6b7280",
  },
  closeButton: {
    position: "absolute",
    right: 16,
    top: 24,
    padding: 8,
  },
  closeText: {
    fontSize: 20,
    color: "#6b7280",
  },
  balance: {
    marginTop: 4,
    fontSize: 14,
    color: "#4b5563",
  },
  balanceBold: {
    fontWeight: "700",
    color: "#111827",
  },
  savedSection: {
    paddingHorizontal: 20,
    paddingTop: 12,
  },
  skeleton: {
    height: 56,
    borderRadius: 12,
    backgroundColor: "#e5e7eb",
  },
  savedRow: {
    flexDirection: "row",
    gap: 12,
  },
  savedMethod: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: "#fff",
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  savedMethodText: {
    fontSize: 14,
    fontWeight: "500",
    color: "#111827",
  },
  chevron: {
    fontSize: 20,
    color: "#6b7280",
  },
  cvcBox: {
    width: 96,
    borderRadius: 12,
    backgroundColor: "#fff",
    overflow: "hidden",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  paymentSection: {
    minHeight: 500,
  },
  amountSection: {
    alignItems: "center",
    paddingTop: 24,
    paddingHorizontal: 20,
  },
  amountRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  currency: {
    fontSize: 24,
    fontWeight: "600",
    color: "#111827",
  },
  amountInput: {
    minWidth: 120,
    fontSize: 56,
    fontWeight: "600",
    color: "#111827",
    textAlign: "center",
    backgroundColor: "#fff",
    borderRadius: 8,
    paddingHorizontal: 12,
  },
  hint: {
    marginTop: 12,
    fontSize: 14,
    color: "#6b7280",
  },
  chipRow: {
    flexDirection: "row",
    gap: 12,
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 20,
  },
  chip: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: "#fff",
    alignItems: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  chipSelected: {
    backgroundColor: "#059669",
  },
  chipText: {
    fontSize: 14,
    fontWeight: "600",
    color: "#111827",
  },
  chipTextSelected: {
    color: "#fff",
  },
  footer: {
    paddingHorizontal: 20,
    paddingTop: 12,
  },
  error: {
    marginBottom: 12,
    textAlign: "center",
    color: "#dc2626",
    fontSize: 14,
  },
  depositButton: {
    height: 56,
    borderRadius: 999,
    backgroundColor: "#059669",
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 3,
  },
  depositButtonDisabled: {
    opacity: 0.6,
  },
  depositButtonText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "700",
  },
  cancel: {
    marginTop: 12,
    textAlign: "center",
    color: "#6b7280",
    fontSize: 14,
  },
  secure: {
    marginTop: 12,
    textAlign: "center",
    color: "#6b7280",
    fontSize: 12,
  },
});
