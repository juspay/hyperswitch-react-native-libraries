import { forwardRef, useEffect, useRef, useState } from 'react';
import type { ViewStyle } from 'react-native';
import { registerWidget, unregisterWidget } from '../context/WidgetRegistry';
import { getFindNodeHandle } from '../utils/ReactNativeUtils';
import type {
  paymentEventResult,
  paymentResult,
  paymentEventNative,
} from '../types/NativeModuleTypes';
import type { PaymentSheetConfiguration } from '../types/PaymentSheetConfiguration';
import NativePaymentWidgetImpl from './NativePaymentWidgetImpl';

type CVCElementProps = {
  id?: string;
  options?: PaymentSheetConfiguration;
  onChange?: (event: paymentEventResult) => void;
  onFocus?: () => void;
  onBlur?: () => void;
  onPaymentResult?: (result: paymentResult) => void;
  style?: ViewStyle;
};

function parsePaymentResult(result: string): paymentResult {
  return JSON.parse(result);
}

export const CVCElementView = forwardRef<unknown, CVCElementProps>(
  (props, ref) => {
    const {
      id,
      options,
      onChange,
      onFocus,
      onBlur,
      onPaymentResult,
      style,
    } = props;
    // const {paymentSessionConfig, hyperswitchConfig} = useHyperElementsContext();
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
        ref={viewRef}
        widgetType="widgetPaymentSheet"
        sdkAuthorization={paymentSessionConfig?.sdkAuthorization ?? ''}
        onPaymentEvent={onPaymentEventInternal}
        onPaymentResult={onPaymentResultInternal}
        options={{
          hyperswitchConfig,
          paymentSessionConfig,
          configuration: options,
        }}
        style={style}
      />
    );
  }
);
