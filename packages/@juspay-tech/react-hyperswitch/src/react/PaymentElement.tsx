import { forwardRef, useEffect, useId, useImperativeHandle, useMemo, useRef } from 'react';
import { useHyperElementsContext } from './HyperElements';
import { isWeb, PlatformPaymentElementView } from './PlatformView';
import type {
  PaymentElementHandle,
  PaymentElementProps,
  PaymentElement as PaymentElementType,
  removeListenerFunction,
} from '../definitions';

const PaymentElement = forwardRef<PaymentElementHandle, PaymentElementProps>(function PaymentElement(
  { id, options, onReady, onChange, onPaymentResult, onPaymentConfirmButtonClick, className, style },
  ref,
) {
  const {
    elements,
    publishableKey: contextPublishableKey,
    sdkAuthorization: contextSdkAuthorization,
  } = useHyperElementsContext();

  const nativeOptions = useMemo(
    () => ({
      ...options,
      ...(contextPublishableKey ? { publishableKey: contextPublishableKey } : {}),
      ...(contextSdkAuthorization ? { sdkAuthorization: contextSdkAuthorization } : {}),
    }),
    [options, contextPublishableKey, contextSdkAuthorization]
  );

  const reactId = useId();
  const domId = id ? id : `hs-payment-element-${reactId.replace(/:/g, '')}`;

  const instanceRef = useRef<PaymentElementType | null>(null);

  const paymentElement = useMemo(() => {
    if (!elements) return null;
    return elements.create({ type: 'paymentElement', id, options });
  }, [elements, id]);

  const previousOptionsJsonRef = useRef<string>(JSON.stringify(options));

  useEffect(() => {
    previousOptionsJsonRef.current = JSON.stringify(options);
  }, [paymentElement]);

  useEffect(() => {
    if (!isWeb || !paymentElement) return;

    const optionsJson = JSON.stringify(options);
    if (previousOptionsJsonRef.current === optionsJson) return;

    previousOptionsJsonRef.current = optionsJson;
    paymentElement.update((options ?? {}) as Record<string, Object>);
  }, [paymentElement, options]);

  function safeRemove(listener: removeListenerFunction | null | undefined): void {
    if (!listener) return;
    if (listener instanceof Promise) {
      listener.then((h) => h.remove());
    } else {
      listener.remove();
    }
  }

  useEffect(() => {
    if (!paymentElement) return;

    const pe = paymentElement;
    instanceRef.current = pe;

    if (!isWeb) {
      if (onReady) onReady();
      return () => {
        pe.destroy();
        instanceRef.current = null;
      };
    }

    let onChangeListeners: removeListenerFunction[] = [];
    if (onChange) {
      onChangeListeners.push(pe.on('FORM_STATUS', onChange));
      onChangeListeners.push(pe.on('PAYMENT_METHOD_STATUS', onChange));
      onChangeListeners.push(pe.on('PAYMENT_METHOD_INFO_CARD', onChange));
      onChangeListeners.push(pe.on('PAYMENT_METHOD_INFO_BILLING_ADDRESS', onChange));
    }

    pe.mount(`#${domId}`);
    let onPaymentResultListener = pe.onPaymentResult((data) => {
      onPaymentResult ? onPaymentResult(data) : null;
    });
    let onConfirmClicklistener = pe.onPaymentConfirmButtonClick((data) => {
      if (onPaymentConfirmButtonClick) {
        try {
          return onPaymentConfirmButtonClick(data);
        } catch (e) {
          return false;
        }
      }
      return true;
    });

    if (onReady) onReady();

    return () => {
      pe.unmount();
      instanceRef.current = null;
      safeRemove(onPaymentResultListener);
      safeRemove(onConfirmClicklistener);
      onChangeListeners.forEach(safeRemove);
    };
  }, [paymentElement]);

  useImperativeHandle(
    ref,
    () => ({
      confirmPayment(options) {
        if (!instanceRef.current) {
          return Promise.reject(new Error('PaymentElement is not mounted'));
        }
        return instanceRef.current.confirmPayment(options);
      },
      collapse() {
        instanceRef.current?.collapse();
      },
      focus() {
        instanceRef.current?.focus();
      },
      blur() {
        instanceRef.current?.blur();
      },
      clear() {
        instanceRef.current?.clear();
      },
      update(options) {
        instanceRef.current?.update(options);
      },
      destroy() {
        instanceRef.current?.destroy();
        instanceRef.current = null;
      },
    }),
    [],
  );

  if (!isWeb && !paymentElement) {
    return null;
  }

  return (
    <PlatformPaymentElementView
      id={domId}
      Component={paymentElement?.Component}
      className={className}
      style={{ minHeight: 'inherit', width: '100%', flex: 1, ...style }}
      onPaymentResult={onPaymentResult}
      onPaymentEvent={onChange}
      options={nativeOptions}
    />
  );
});

export default PaymentElement;
