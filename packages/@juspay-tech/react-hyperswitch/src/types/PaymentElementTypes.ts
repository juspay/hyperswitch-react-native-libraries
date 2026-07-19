import { PaymentEventData, PaymentRequestData, PaymentResult } from './PaymentTypes';
import type { ComponentType, CSSProperties } from 'react';

export type removeListenerFunction = Promise<{ remove: () => void }> | { remove: () => void };
export interface PaymentElement {
  Component?: ComponentType<any>;
  on(event: string, handler?: (data?: PaymentEventData) => void): removeListenerFunction;
  onPaymentResult(handler?: (data: PaymentResult) => void): removeListenerFunction;
  onPaymentConfirmButtonClick(handler?: (data: PaymentRequestData) => boolean): removeListenerFunction;
  collapse(): void;
  blur(): void;
  update(options: Record<string, Object>): void;
  destroy(): void;
  unmount(): void;
  mount(selector: string): void;
  focus(): void;
  clear(): void;
  confirmPayment(options?: { confirmParams?: Record<string, Object> }): Promise<PaymentResult>;
}

import { PaymentSheetOptions as PaymentElementOptions } from './PaymentSheetTypes';

export type { PaymentElementOptions };

export interface PaymentElementHandle {
  confirmPayment(options?: { confirmParams?: Record<string, Object> }): Promise<PaymentResult>;
  collapse(): void;
  focus(): void;
  blur(): void;
  clear(): void;
  update(options: Record<string, Object>): void;
  destroy(): void;
}

export interface PaymentElementProps {
  id?: string;
  options?: PaymentElementOptions;
  onReady?: () => void;
  onChange?: (data?: PaymentEventData) => void;
  onPaymentResult?: (data: PaymentResult) => void;
  onPaymentConfirmButtonClick?: (data: PaymentRequestData) => boolean;
  className?: string;
  style?: CSSProperties;
}
