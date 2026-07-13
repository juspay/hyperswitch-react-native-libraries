// Shared type definitions for the universal HyperswitchSession contract.
// These mirror the shape consumed by @juspay-tech/react-hyperswitch so this
// package can remain dependency-free of the React Native SDK.

import type {
  HyperswitchConfiguration,
  PaymentSessionConfiguration,
} from '../types/HyperswitchSessionTypes';
import type { ComponentType } from 'react';

export type { HyperswitchConfiguration, PaymentSessionConfiguration };

export interface PaymentResult {
  type: 'completed' | 'canceled' | 'failed';
  message?: string;
}

export interface PaymentSheetOptions {
  [key: string]: any;
}

export interface CustomerLastUsedPaymentMethodCard {
  card_network?: string;
  card_brand?: string;
  scheme?: string;
  last4_digits?: string;
  last4?: string;
  last4Digits?: string;
  card_exp_month?: string;
  card_exp_year?: string;
  [key: string]: any;
}

export interface CustomerLastUsedPaymentMethod {
  payment_method?: string;
  payment_method_type?: string;
  card?: CustomerLastUsedPaymentMethodCard;
  error?: any;
  [key: string]: any;
}

export interface CustomerSavedPaymentMethodsSession {
  getCustomerLastUsedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null>;
  getCustomerDefaultSavedPaymentMethodData(): Promise<CustomerLastUsedPaymentMethod | null>;
  confirmWithCustomerLastUsedPaymentMethod(args?: {
    id?: string;
  }): Promise<PaymentResult>;
  confirmWithCustomerDefaultPaymentMethod?(args?: {
    id?: string;
  }): Promise<PaymentResult>;
}

export interface PaymentSession {
  presentPaymentSheet(options?: PaymentSheetOptions): Promise<PaymentResult>;
  getCustomerSavedPaymentMethods(
    options?: any
  ): Promise<CustomerSavedPaymentMethodsSession>;
  updateIntent(
    intentResolver: () => Promise<PaymentSessionConfiguration>
  ): Promise<void>;
}

export interface PaymentElementHandle {
  confirmPayment(options?: {
    confirmParams?: Record<string, any>;
  }): Promise<PaymentResult>;
  collapse(): void;
  focus(): void;
  blur(): void;
  clear(): void;
  update(options: Record<string, any>): void;
  destroy(): void;
}

export interface PaymentElement extends PaymentElementHandle {
  Component?: ComponentType<any>;
  mount(selector: string): void;
  unmount(): void;
  on(event: string, handler?: (data?: any) => void): { remove: () => void };
  onPaymentResult(handler?: (data: PaymentResult) => void): {
    remove: () => void;
  };
  onPaymentConfirmButtonClick(handler?: (data: any) => boolean): {
    remove: () => void;
  };
}

export interface CvcWidget {
  Component?: ComponentType<any>;
  mount(selector: string, options?: Record<string, any>): void;
  unmount(): void;
  destroy(): void;
  on(
    event: string,
    handler?: (data?: any) => void
  ): { remove: () => void } | null;
}

export interface Elements {
  confirmPayment(
    paymentElementRef: { current: PaymentElementHandle | null } | string,
    options?: { confirmParams?: Record<string, any> }
  ): Promise<PaymentResult>;
  presentPaymentSheet(options?: PaymentSheetOptions): Promise<PaymentResult>;
  create(options: {
    type: 'paymentElement';
    id?: string;
    options?: any;
  }): PaymentElement;
  create(options: { type: 'cvcWidget'; id?: string; options?: any }): CvcWidget;
  updateIntent(
    intentResolver: () => Promise<PaymentSessionConfiguration>
  ): Promise<void>;
  getCustomerSavedPaymentMethods(
    options?: any
  ): Promise<CustomerSavedPaymentMethodsSession>;
}

export interface ElementsActions {
  confirmPayment: (
    paymentElementRef: { current: PaymentElementHandle | null } | string,
    options?: { confirmParams?: Record<string, any> }
  ) => Promise<PaymentResult>;
  updateIntent: (
    intentResolver: () => Promise<PaymentSessionConfiguration>
  ) => Promise<void>;
  getCustomerSavedPaymentMethods(): Promise<CustomerSavedPaymentMethodsSession>;
}

export interface HyperswitchSession {
  publishableKey: string;
  elements(options: PaymentSessionConfiguration): Promise<Elements>;
  initPaymentSession(
    options: PaymentSessionConfiguration
  ): Promise<PaymentSession>;
}
