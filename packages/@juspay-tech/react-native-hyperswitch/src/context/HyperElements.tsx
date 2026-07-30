import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import type { HyperswitchConfiguration, HyperswitchSession, PaymentSession, PaymentSessionConfiguration } from '../types/definitions';
import type { Elements } from '../types/elements';

interface HyperElementsContext {
  paymentSession: PaymentSession | null;
  elements: Elements | null;
  publishableKey: string | null;
  sdkAuthorization: string | null;
  hyperswitchConfig: HyperswitchConfiguration | null;
  paymentSessionConfig: PaymentSessionConfiguration | null;
  loading: boolean;
  error: Error | null;
}

const HyperElementsContext = createContext<HyperElementsContext | undefined>(
  undefined
);

HyperElementsContext.displayName = 'HyperElementsContext';

export interface HyperElementsProps {
  hyper: HyperswitchSession | Promise<HyperswitchSession> | null;
  options: { sdkAuthorization: string };
  children: ReactNode;
}

export function HyperElements({
  hyper,
  options,
  children,
}: HyperElementsProps) {
  const [paymentSession, setPaymentSession] = useState<PaymentSession | null>(
    null
  );
  const [elements, setElements] = useState<Elements | null>(null);
  const [hyperswitchConfig, setHyperswitchConfig] = useState<HyperswitchConfiguration | null>(null);
  const [paymentSessionConfig, setPaymentSessionConfig] = useState<PaymentSessionConfiguration | null>(null);
  const [publishableKey, setPublishableKey] = useState<string | null>(null);
  const [sdkAuthorization, setSdkAuthorization] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!hyper) return;

    let cancelled = false;

    (async () => {
      try {
        const session = await Promise.resolve(hyper);
        const paymentSessionConfig = { sdkAuthorization: options.sdkAuthorization };
        const els = await session.elements(paymentSessionConfig);

        if (!cancelled) {
          setPaymentSession({
            ...els,
          } as PaymentSession);
          setHyperswitchConfig(els.hyperswitchConfig);
          setPaymentSessionConfig(paymentSessionConfig);
          setElements(els);
          setPublishableKey(session.publishableKey ?? null);
          setSdkAuthorization(options.sdkAuthorization ?? null);
          setLoading(false);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err : new Error(String(err)));
          setLoading(false);
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [hyper, options.sdkAuthorization]);

  return (
    <HyperElementsContext.Provider
      value={{
        paymentSession,
        elements,
        publishableKey,
        sdkAuthorization,
        loading,
        error,
        paymentSessionConfig,
        hyperswitchConfig,
      }}
    >
      {children}
    </HyperElementsContext.Provider>
  );
}

export function useHyperElementsContext(): HyperElementsContext {
  const ctx = useContext(HyperElementsContext);
  if (ctx === undefined) {
    throw new Error(
      'useHyperElementsContext must be used inside <HyperElements>'
    );
  }
  return ctx;
}


export function usePaymentSession(): PaymentSession | null {
  const ctx = useHyperElementsContext();
  return ctx.paymentSession;
}

export function useElements(): Elements | null {
  const ctx = useHyperElementsContext();
  return ctx.elements;
} 