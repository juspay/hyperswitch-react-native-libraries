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
import type { options as PaymentSheetConfigurationOptions } from '../types/PaymentSheetConfiguration';

function parsePaymentResult(result: string): paymentResult {
  return JSON.parse(result);
}

type PaymentWidgetRef = {
  confirmPayment: () => Promise<paymentResult>;
};

type PaymentElementProps = {
  widgetId: string;
  sdkAuthorization?: string;
  onPaymentResult: (result: paymentResult) => void;
  onPaymentEvent?: (event: paymentEventResult) => void;
  options?: PaymentSheetConfigurationOptions;
  style?: ViewStyle;
};

export const PaymentElementView = forwardRef<PaymentWidgetRef, PaymentElementProps>(
  function PaymentElement(
    {
      widgetId,
      sdkAuthorization,
      onPaymentResult,
      onPaymentEvent,
      options,
      style,
    },
    ref
  ) {
    const [viewId, setViewId] = useState<number | undefined>(undefined);
    const viewRef = useRef<unknown>(null);
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
      if (!options || !onPaymentEvent || warningEmitted.current) {
        return;
      }
      const subscribedEvents = options.subscribedEvents as string[] | undefined;

      const invalidEvents = validateSubscribedEventStrings(subscribedEvents);
      if (invalidEvents.length > 0) {
        warningEmitted.current = true;
        const warningPayload = makeUnknownEventWarningPayload(invalidEvents);
        onPaymentEvent({
          eventName: 'UNKNOWN_EVENT_SUBSCRIBED',
          payload: {
            message: warningPayload.message,
            invalidEvents: warningPayload.invalidEvents,
            validEvents: warningPayload.validEvents,
          },
        });
      }
    }, [options, onPaymentEvent]);

    const onPaymentResultInternal = (event: nativeEvent) => {
      onPaymentResult(parsePaymentResult(event.nativeEvent.result ?? ''));
    };

    const onPaymentEventInternal = (event: paymentEventNative) => {
      onPaymentEvent?.(event.nativeEvent);
    };

    return (
      <NativePaymentWidgetImpl
        ref={viewRef}
        sdkAuthorization={sdkAuthorization}
        widgetType="widgetPaymentSheet"
        onPaymentResult={onPaymentResultInternal}
        onPaymentEvent={onPaymentEventInternal}
        options={options}
        style={style}
      />
    );
  }
);
