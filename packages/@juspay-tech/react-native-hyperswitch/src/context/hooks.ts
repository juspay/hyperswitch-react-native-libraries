import { useCallback, useMemo } from 'react';
import { useHyperElementsContext } from './HyperElements';
import { PaymentSession, PaymentSessionConfiguration, PaymentElementHandle } from '../types/definitions';
import { ElementsActions } from '../types/elements';
import { CustomerSavedPaymentMethodsSession } from '../types/savedPaymentMethods';

export function usePaymentSession(): PaymentSession | null {
  const { paymentSession } = useHyperElementsContext();

  const updateIntent = useCallback(
    async (intentResolver: () => Promise<PaymentSessionConfiguration>): Promise<void> => {
      if (!paymentSession) {
        throw new Error('HyperElements is not initialized');
      }

      return paymentSession.updateIntent(intentResolver);
    },
    [paymentSession],
  );

  return useMemo(
    () => (paymentSession ? { ...paymentSession, updateIntent } : paymentSession),
    [paymentSession, updateIntent],
  );
}

export function useElements(): ElementsActions {
  const { elements } = useHyperElementsContext();

  const confirmPayment = useCallback(
    async (
      paymentElement: { current: PaymentElementHandle | null } | string,
      options?: { confirmParams?: Record<string, Object> },
    ): Promise<PaymentResult> => {
      if (!elements) {
        throw new Error('HyperElements is not initialized');
      }
      if (elements.confirmPayment) {
        return elements.confirmPayment(paymentElement, options);
      }

      if (typeof paymentElement === 'string') {
        throw new Error('confirmPayment by widget id is not supported by this Hyper elements handle');
      }

      const ref = paymentElement.current;
      if (!ref) {
        throw new Error('PaymentElement reference is not mounted');
      }
      return ref.confirmPayment(options);
    },
    [elements],
  );

  const updateIntent = useCallback(
    async (intentResolver: () => Promise<PaymentSessionConfiguration>): Promise<void> => {
      if (!elements) {
        throw new Error('HyperElements is not initialized');
      }

      return elements.updateIntent(intentResolver);
    },
    [elements],
  );

  const getCustomerSavedPaymentMethods = useCallback(async (): Promise<CustomerSavedPaymentMethodsSession> => {
    if (!elements) {
      throw new Error('HyperElements is not initialized');
    }

    return elements.getCustomerSavedPaymentMethods();
  }, [elements]);

  return {
    getCustomerSavedPaymentMethods,
    confirmPayment,
    updateIntent,
  };
}
