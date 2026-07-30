import { forwardRef, useEffect, useRef, useState } from 'react';
import { useHyperElementsContext } from '../context/HyperElements';
import type { CvcWidgetOptions } from '../types/definitions';
import type { ViewStyle } from 'react-native';
import { registerWidget, unregisterWidget } from '../context/WidgetRegistry';
import { getFindNodeHandle } from '../utils/ReactNativeUtils';
import type {
  paymentEventResult,
  paymentResult,
  paymentEventNative,
} from '../types/NativeModuleTypes';
import NativePaymentWidgetImpl from './NativePaymentWidgetImpl';
import { useMemo } from 'react';

type CVCElementProps = {
  id?: string;
  options?: CvcWidgetOptions;
  onChange?: (event: paymentEventResult) => void;
  onFocus?: () => void;
  onReady?: () => void;
  onBlur?: () => void;
  onPaymentResult?: (result: paymentResult) => void;
  style?: ViewStyle;
};

type CVCWidgetRef = {
  confirmPayment: () => Promise<paymentResult>;
};

function parsePaymentResult(result: string): paymentResult {
  return JSON.parse(result);
}

export const CVCElement = forwardRef<CVCWidgetRef, CVCElementProps>(
  (props, _ref) => {
    const {
      id,
      options,
      onChange,
      onFocus,
      onBlur,
      onPaymentResult,
      style,
      onReady,
    } = props;
    const { paymentSessionConfig, hyperswitchConfig } =
      useHyperElementsContext();
    const [viewId, setViewId] = useState<number | undefined>(undefined);
    const viewRef = useRef(null);
    const nativeOptions = useMemo(
      () => ({
        ...options,
        ...{
          paymentMethodLayout: {
            savedMethodCustomization: {
              cvcIcon: options?.cvcIcon ?? 'shown',
            },
          },
        },
      }),
      [options]
    );

    useEffect(() => {
      let isMounted = true;
      const findNodeHandle = (attempt: number) => {
        if (!isMounted || viewId !== undefined) return;
        if (viewRef.current != null) {
          const nativeId = getFindNodeHandle(viewRef.current);
          if (nativeId !== -1) {
            onReady && onReady();
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
            Record<string, unknown> | undefined;
          if (!outerDict) {
            return;
          }
          const cvcStatus = outerDict.cvcStatus as
            Record<string, unknown> | undefined;
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
        widgetType="cvcWidget"
        sdkAuthorization={paymentSessionConfig?.sdkAuthorization ?? ''}
        onPaymentEvent={onPaymentEventInternal}
        onPaymentResult={onPaymentResultInternal}
        options={{
          hyperswitchConfig: hyperswitchConfig || undefined,
          paymentSessionConfig: paymentSessionConfig || undefined,
          configuration: nativeOptions as Record<string, unknown>,
        }}
        style={style}
      />
    );
  }
);
