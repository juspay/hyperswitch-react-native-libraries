import { useEffect, useRef, useState } from 'react';
import {
  CardCVCElement,
  PaymentElement,
  useWidgets,
  usePaymentSession,
  type CustomerLastUsedPaymentMethod,
  type CustomerSavedPaymentMethodsSession,
  type PaymentElementHandle,
} from '@juspay-tech/react-hyperswitch';
import { FormLayout } from './FormLayout';
import { getCustomisationOptions, getCvcInputOptions, initialBaseUrl } from './utils';
import { Alert } from 'react-native';

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
  const { amount, paymentId, onClose, setSdkAuthorization } = props;
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
        const session = await paymentSession.getCustomerSavedPaymentMethods({
          hiddenPaymentMethods: ['paypal', 'google_pay', 'apple_pay', 'ach'],
        });
        if (cancelled) return;
        setMethodsSession(session);
        const data = await session.getCustomerLastUsedPaymentMethodData();
        console.log("manideep", data);
        setLastUsed(data);
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

  const updateAmount =
    paymentSession && paymentId
      ? async () => {
          await paymentSession.updateIntent(async () => {
            const response = await fetch(`${initialBaseUrl}/update-payment`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                payment_id: paymentId,
                amount: amount * 100,
              }),
            });
            const data = await response.json();
            if (!response.ok) throw new Error(data.error ?? 'Update failed');
            setSdkAuthorization(data.sdkAuthorization);
            return { sdkAuthorization: data.sdkAuthorization };
          });
        }
      : null;

  return (
    <FormLayout
      {...props}
      cvcSlot={
        lastUsed?.payment_method === 'card' ? (
          <CardCVCElement
            id="card-cvc-element"
            options={getCvcInputOptions()}
            onReady={() => console.log('[Example] CvcWidget ready')}
            style={{ minHeight: 50, }}
            onFocus={() => console.log('[Example] CvcWidget focused')}
            onBlur={() => console.log('[Example] CvcWidget blurred')}
          />
        ) : null
      }
      paymentSlot={
          <PaymentElement
            id="payment-element-id"
            onPaymentResult={(data) => {
              onClose();
              setTimeout(() => {
                Alert.alert(`Type: ${data?.type}`, `Message: ${data?.message}`);
              }, 0);
            }}
            options={getCustomisationOptions('tabs')}
            ref={paymentRef}
            onReady={() => console.log('[Example] PaymentElement ready')}
            onChange={(data) =>
              console.log('[Example] PaymentElement paymentEvent:', data)
            }
            style={{ width: '100%', height: '100%' }}
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
