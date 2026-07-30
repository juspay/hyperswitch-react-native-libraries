import {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from 'react';
import type { ViewStyle } from 'react-native';
import NativePaymentWidgetImpl from './NativePaymentWidgetImpl';
import { registerWidget, unregisterWidget } from '../context/WidgetRegistry';
import { confirmPayment as nativeConfirmPayment } from '../modules/NativeHyperswitchSdk';
import type { paymentResult } from '../modules/NativeHyperswitchSdk';
import type { PaymentSheetConfiguration } from '../types/PaymentSheetConfiguration';
import { useHyperElementsContext } from '../context/HyperElements';
import {
  dispatchViewManagerCommand,
  getFindNodeHandle,
} from '../utils/ReactNativeUtils';
import {
  makeUnknownEventWarningPayload,
  validateSubscribedEventStrings,
} from '../utils/EventValidator';
import type {
  paymentEventResult,
  paymentEventNative,
  nativeEvent,
} from '../types/NativeModuleTypes';

function parsePaymentResult(result: string): paymentResult {
  return JSON.parse(result);
}

type PaymentWidgetRef = {
  confirmPayment: () => Promise<paymentResult>;
};

type PaymentElementProps = {
  widgetId: string;
  options?: PaymentSheetConfiguration;
  onPaymentResult: (result: paymentResult) => void;
  // onPaymentConfirmButtonClick:() =>void;
  onChange?: (event: paymentEventResult) => void;
  onReady?: (event: string) => void;
  style?: ViewStyle;
};

export const PaymentElement = forwardRef<PaymentWidgetRef, PaymentElementProps>(
  (props, ref) => {
    const { widgetId, options, onPaymentResult, onChange, style } = props;
    const [viewId, setViewId] = useState<number | undefined>(undefined);
    const { paymentSessionConfig, hyperswitchConfig } =
      useHyperElementsContext();
    const viewRef = useRef(null);
    const isRegisteredRef = useRef(false);

    useEffect(() => {
      let isMounted = true;

      const findNodeHandle = (attempt: number) => {
        if (!isMounted || viewId !== undefined) {
          return;
        }
        if (viewRef.current != null) {
          const id = getFindNodeHandle(viewRef.current);
          if (id !== -1) {
            setViewId(id);
          } else if (attempt < 20) {
            setTimeout(() => findNodeHandle(attempt + 1), 100);
          }
        } else if (attempt < 20) {
          setTimeout(() => findNodeHandle(attempt + 1), 100);
        }
      };

      findNodeHandle(3);

      return () => {
        isMounted = false;
      };
    }, [viewId]);

    useEffect(() => {
      if (viewId !== undefined) {
        registerWidget(widgetId, viewId);
        isRegisteredRef.current = true;
        return () => {
          if (isRegisteredRef.current) {
            unregisterWidget(widgetId);
            isRegisteredRef.current = false;
          }
        };
      }
      return undefined;
    }, [viewId, widgetId]);

    useEffect(() => {
      if (viewId !== undefined) {
        dispatchViewManagerCommand(viewId, 1, []);
      }
    }, [viewId]);

    useImperativeHandle(
      ref,
      () => ({
        confirmPayment: (): Promise<paymentResult> => {
          if (viewRef.current == null) {
            return Promise.resolve({
              status: 'failed',
              message: 'Widget not ready',
              error: 'Widget not ready',
              type: undefined,
            });
          }
          const id = getFindNodeHandle(viewRef.current);
          if (id === -1) {
            return Promise.resolve({
              status: 'failed',
              message: 'Widget not ready',
              error: 'Unable to find native view handle',
              type: undefined,
            });
          }
          return new Promise((resolve) => {
            nativeConfirmPayment(id, (result: paymentResult) => {
              resolve({
                status: result.status,
                message: result.message,
                type: result.type,
              });
            });
          });
        },
      }),
      // eslint-disable-next-line react-hooks/exhaustive-deps
      [viewId]
    );

    const warningEmitted = useRef(false);

    useEffect(() => {
      if (!options || !onChange || warningEmitted.current) {
        return;
      }
      const subscribedEvents = options.subscribedEvents as string[] | undefined;

      const invalidEvents = validateSubscribedEventStrings(subscribedEvents);
      if (invalidEvents.length > 0) {
        warningEmitted.current = true;
        const warningPayload = makeUnknownEventWarningPayload(invalidEvents);
        onChange({
          eventName: 'UNKNOWN_EVENT_SUBSCRIBED',
          payload: {
            message: warningPayload.message,
            invalidEvents: warningPayload.invalidEvents,
            validEvents: warningPayload.validEvents,
          },
        });
      }
    }, [options, onChange]);

    const onPaymentResultInternal = (event: nativeEvent) => {
      onPaymentResult(parsePaymentResult(event.nativeEvent.result ?? ''));
    };

    const onPaymentEventInternal = (event: paymentEventNative) => {
      onChange?.(event.nativeEvent);
    };

    return (
      <NativePaymentWidgetImpl
        ref={viewRef}
        sdkAuthorization={paymentSessionConfig?.sdkAuthorization ?? ''}
        widgetType="widgetPaymentSheet"
        onPaymentEvent={onPaymentEventInternal}
        onPaymentResult={onPaymentResultInternal}
        options={{
          hyperswitchConfig: hyperswitchConfig || undefined,
          paymentSessionConfig: paymentSessionConfig || undefined,
          configuration: options as Record<string, unknown> | undefined,
        }}
        style={{...style,  flex: 1}}
      />
    );
  }
);
