import { forwardRef, useEffect, useRef, useState } from 'react';
import type { ViewStyle } from 'react-native';
import NativePaymentWidgetImpl from './NativePaymentWidgetImpl';
import { registerWidget, unregisterWidget } from '../context/WidgetRegistry';
import { getFindNodeHandle } from '../utils/ReactNativeUtils';
import type {
  paymentEventResult,
  paymentResult,
  paymentEventNative,
} from '../types/NativeModuleTypes';
import type { options as PaymentSheetConfigurationOptions } from '../types/PaymentSheetConfiguration';

type CVCElementProps = {
  id?: string;
  sdkAuthorization?: string;
  options?: PaymentSheetConfigurationOptions;
  onChange?: (event: paymentEventResult) => void;
  onFocus?: () => void;
  onBlur?: () => void;
  onPaymentResult?: (result: paymentResult) => void;
  style?: ViewStyle;
};

function parsePaymentResult(result: string): paymentResult {
  return JSON.parse(result);
}

export const CVCElementView = forwardRef<unknown, CVCElementProps>(function CVCElement(
  {
    id,
    sdkAuthorization,
    options,
    onChange,
    onFocus,
    onBlur,
    onPaymentResult,
    style,
  },
  ref
) {
  const [viewId, setViewId] = useState<number | undefined>(undefined);
  const viewRef = useRef<unknown>(null);

  useEffect(() => {
    let isMounted = true;
    const findNodeHandle = (attempt: number) => {
      if (!isMounted || viewId !== undefined) return;
      if (viewRef.current != null) {
        const nativeId = getFindNodeHandle(viewRef.current);
        if (nativeId !== -1) {
          setViewId(nativeId);
        } else if (attempt < 20) {
          setTimeout(() => findNodeHandle(attempt + 1), 100);
        }
      } else if (attempt < 20) {
        setTimeout(() => findNodeHandle(attempt + 1), 100);
      }
    };
    findNodeHandle(0);
    return () => {
      isMounted = false;
    };
  }, [viewId]);

  useEffect(() => {
    if (!id || viewId === undefined) return undefined;
    registerWidget(id, viewId);
    return () => unregisterWidget(id);
  }, [id, viewId]);

  const onPaymentEventInternal = (event: paymentEventNative) => {
    onChange?.(event.nativeEvent);

    if (event.nativeEvent.eventName === 'CVC_STATUS') {
      try {
        const outerDict = event.nativeEvent.payload as
          | Record<string, unknown>
          | undefined;
        if (!outerDict) {
          return;
        }
        const cvcStatus = outerDict.cvcStatus as
          | Record<string, unknown>
          | undefined;
        if (!cvcStatus) {
          return;
        }
        const isCvcFocused = Boolean(cvcStatus.isCvcFocused);
        const isCvcBlur = Boolean(cvcStatus.isCvcBlur);
        if (isCvcFocused) {
          onFocus?.();
        }
        if (isCvcBlur) {
          onBlur?.();
        }
      } catch {
        // Ignore malformed native events
      }
    }
  };

  const onPaymentResultInternal = (event: {
    nativeEvent: { result?: string };
  }) => {
    onPaymentResult?.(parsePaymentResult(event.nativeEvent.result ?? ''));
  };

  return (
    <NativePaymentWidgetImpl
      ref={(node: unknown) => {
        viewRef.current = node;
        if (typeof ref === 'function') ref(node);
        else if (ref) ref.current = node;
      }}
      sdkAuthorization={sdkAuthorization}
      widgetType="cvcWidget"
      onPaymentEvent={onPaymentEventInternal}
      onPaymentResult={onPaymentResultInternal}
      options={options}
      style={style}
    />
  );
});
