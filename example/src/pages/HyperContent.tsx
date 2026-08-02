import { useCallback, useEffect, useRef, useState } from "react";
import { Alert } from "react-native";
import {
  PaymentElement,
  CardCVCElement,
  useWidgets,
  usePaymentSession,
  type CustomerLastUsedPaymentMethod,
  type CustomerSavedPaymentMethodsSession,
  type PaymentElementHandle,
} from "@juspay-tech/react-native-hyperswitch";
import { FormLayout } from "./FormLayout";
import { initialBaseUrl } from "../utils";

export type {
  CustomerLastUsedPaymentMethod,
  CustomerSavedPaymentMethodsSession,
};

export type SharedProps = {
  isAmountScreen: boolean;
  setIsAmountScreen: (v: boolean) => void;
  amount: number;
  setAmount: (v: number) => void;
  onClose: () => void;
  paymentId: string | null;
  sdkAuthorization: string | null;
  setSdkAuthorization: (v: string | null) => void;
};

export function HyperContent(props: SharedProps) {
  const { amount, paymentId, setSdkAuthorization } = props;
  const paymentSession = usePaymentSession();
  const widgets = useWidgets();
  const [lastUsed, setLastUsed] = useState<
    CustomerLastUsedPaymentMethod | null | undefined
  >(null);
  const [methodsSession, setMethodsSession] =
    useState<CustomerSavedPaymentMethodsSession | null>(null);
  const [loadingSaved, setLoadingSaved] = useState(true);

  const paymentRef = useRef<PaymentElementHandle>(null);

  useEffect(() => {
    if (!paymentSession) return;
    let cancelled = false;
    (async () => {
      try {
        const handler = await paymentSession.getCustomerSavedPaymentMethods({
          hiddenPaymentMethods: ["paypal", "google_pay", "apple_pay"],
        });
        if (cancelled) return;
        setMethodsSession(handler);
        const data = await handler.getCustomerLastUsedPaymentMethodData();
        console.log("[Example] Last used payment method data:", data);
        if (data?.status === "failed") {
          setLastUsed(null);
        } else {
          setLastUsed(data);
        }
        setLoadingSaved(false);
      } catch (ex) {
        setLastUsed(undefined);
        setLoadingSaved(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [paymentSession]);

  const updateAmount = useCallback(async () => {
    if (!paymentSession || !paymentId) {
      console.log(
        "[Example] Cannot update amount: paymentSession or paymentId is null",
      );
      return;
    }
    console.log("[Example] Updating amount to:", amount);
    await paymentSession.updateIntent(async () => {
      const response = await fetch(`${initialBaseUrl}/update-payment`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          payment_id: paymentId,
          amount: amount * 100,
        }),
      });
      const data = await response.json();
      console.log("[Example] Update response:", data);  
      if (!response.ok) throw new Error(data.error ?? "Update failed");
      setSdkAuthorization(data.sdkAuthorization);
      return { sdkAuthorization: data.sdkAuthorization };
    });
  }, [paymentSession, paymentId, amount, setSdkAuthorization]);

  return (
    <FormLayout
      {...props}
      cvcSlot={
        lastUsed?.payment_method === "card" ? (
          <CardCVCElement
            id={"card-cvc-element"}
            options={{
              placeholder: "123",
              appearance: {
                shapes: {
                  borderRadius: 0,
                  borderWidth: 0,
                  shadow: {
                    blurRadius: 0,
                    intensity: 0,
                  },
                },
              },
              cvcIcon: "hidden",
              subscribedEvents: ["CVC_STATUS"],
            }}
            onReady={() => {
              console.log("[Example] CvcWidget ready");
            }}
            onFocus={() => console.log("[Example] CvcWidget focused")}
            onBlur={() => console.log("[Example] CvcWidget blurred")}
            style={{ minHeight: 50 }}
          />
        ) : null
      }
      paymentSlot={
        <PaymentElement
          widgetId="payment-element-id"
          ref={paymentRef}
          onPaymentResult={(data) => {
            props.onClose();
            setTimeout(() => {
              Alert.alert(`Type: ${data?.type}`, `Message: ${data?.message}`);
            }, 0);
          }}
          onChange={(event) => {
            console.log(
              "[Example] PaymentElement onChange event:",
              JSON.stringify(event),
            );
          }}
          options={{
            merchantDisplayName: "Hyperswitch Example",
            displayDefaultSavedPaymentIcon: false,
            paymentMethodLayout: {
              type: "tabs",
              radios: false,
              maxAccordionItems: 2,
              defaultCollapsed: true,
              spacedAccordionItems: true,
              cvcIcon: "hidden",
              cardBrandIcon: "hideGeneric",
              showCheckedIconForSelection: true,
              savedMethodCustomization: {
                cvcIcon: "hidden",
                hideCardExpiry: true,
                defaultCollapsed: false,
                groupingBehavior: { displayInSeparateScreen: false },
                hiddenPaymentMethods: ["paypal", "google_pay", "apple_pay"],
              },
            },
            appearance: {
              theme: "Light",
              shapes: {
                borderRadius: 16.0,
                borderWidth: 1.0,
                inputHeight: 56.0,
                gap: 24.0,
                shadow: {
                  color: "#000000",
                  opacity: 0,
                  blurRadius: 0,
                  intensity: 0,
                  offset: { x: 0, y: 0 },
                },
              },
              primaryButton: {
                height: 56.0,
              },
              logo: {
                borderRadius: 50,
                colors: {
                  light: {
                    backgroundColor: "black",
                    unselected: "white",
                  },
                  dark: {
                    backgroundColor: "white",
                    unselected: "black",
                  },
                },
              },
            },
            splitCardFields: true,
            subscribedEvents: [
              "PAYMENT_METHOD_STATUS",
              "PAYMENT_METHOD_INFO_BILLING_ADDRESS",
              "PAYMENT_METHOD_INFO_CARD",
              "FORM_STATUS",
            ],
          }}
          onReady={() => console.log("[Example] PaymentElement ready")}
          style={{ width: "100%", height: "100%" }}
        />
      }
      lastUsed={lastUsed}
      methodsSession={methodsSession}
      loadingSaved={loadingSaved}
      canSubmit={!!paymentSession}
      amount={amount}
      updateAmount={updateAmount}
      widgets={widgets}
    />
  );
}
