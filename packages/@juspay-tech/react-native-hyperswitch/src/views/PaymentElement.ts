// Factory for a capacitor-shaped PaymentElement handle backed by an RN view.

import * as React from 'react';
import { PaymentElementView } from './PaymentElementView';
import type { HyperswitchConfiguration, PaymentElement, PaymentSessionConfiguration } from '../types/definitions';
import { confirmPayment } from '../context/WidgetRegistry';
import type { PaymentResult } from '../types/paymentresult';
let paymentElementId = 0;

function mapStatus(status: string): PaymentResult['type'] {
  switch (status) {
    case 'succeeded':
    case 'completed':
    case 'success':
      return 'completed';
    case 'cancelled':
    case 'canceled':
      return 'canceled';
    case 'failed':
    case 'error':
    default:
      return 'failed';
  }
}

export function createPaymentElement(opts?: {
  id?: string;
  options?: any;
  hyperswitchConfig: HyperswitchConfiguration;
  paymentSessionConfig: PaymentSessionConfiguration;
}): PaymentElement {
  const widgetId = opts?.id ?? `rn-payment-element-${++paymentElementId}`;

  const unsupported = (method: string) => (): never => {
    throw new Error(
      `[react-native-hyperswitch] PaymentElement.${method}() is not supported in this environment.`
    );
  };

  const noop = () => {};
  const noopListener = { remove: noop };

  const Component = (props: any) =>
    React.createElement(PaymentElementView as React.ComponentType<any>, {
      ...props,
      widgetId,
      options: {
        ...(opts?.options ?? {}),
        ...(props.options ?? {}),
      },
      hyperswitchConfig: opts?.hyperswitchConfig,
      paymentSessionConfig: opts?.paymentSessionConfig,
      onPaymentResult: props.onPaymentResult ?? noop,
    });

  return {
    Component,
    mount: unsupported('mount'),
    unmount: noop,
    destroy: noop,
    on: () => noopListener,
    onPaymentResult: () => noopListener,
    onPaymentConfirmButtonClick: () => noopListener,
    async confirmPayment(): Promise<PaymentResult> {
      const result = await confirmPayment(widgetId);
      return {
        type: mapStatus(result.status),
        message: result.message,
      };
    },
    collapse: unsupported('collapse'),
    focus: unsupported('focus'),
    blur: unsupported('blur'),
    clear: unsupported('clear'),
    update: unsupported('update'),
  };
}
