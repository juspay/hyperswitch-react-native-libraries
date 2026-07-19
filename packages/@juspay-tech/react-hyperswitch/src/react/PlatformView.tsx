import { type ComponentType, type CSSProperties, type ReactNode } from 'react';
import type { PaymentElementOptions } from '../definitions';
import type { CvcWidgetOptions } from '../definitions';
import type { PaymentEventData, PaymentResult } from '../definitions';
import { useHyperElementsContext } from './HyperElements';

export interface PlatformViewProps {
  id?: string;
  className?: string;
  style?: CSSProperties | Record<string, unknown>;
  children?: ReactNode;
}

export interface PlatformPaymentElementViewProps extends PlatformViewProps {
  Component?: ComponentType<any>;
  onPaymentResult?: (data: PaymentResult) => void;
  onPaymentEvent?: (data?: PaymentEventData) => void;
  options?: PaymentElementOptions;
}

export interface PlatformCVCElementViewProps extends PlatformViewProps {
  Component?: ComponentType<any>;
  onChange?: (data?: PaymentEventData) => void;
  onFocus?: () => void;
  onBlur?: () => void;
  options?: CvcWidgetOptions;
}

const isReactNative =
  typeof navigator !== 'undefined' &&
  (navigator as any).product === 'ReactNative';

function normalizeNativeStyle(
  style: CSSProperties | Record<string, unknown> | undefined,
): Record<string, unknown> {
  if (!style) {
    return {};
  }
  const normalized: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(style)) {
    if (value === 'inherit' || value === 'auto' || value === 'initial') {
      // Drop CSS keywords that React Native does not understand.
      continue;
    }
    normalized[key] = value;
  }
  return normalized;
}

/**
 * Cross-platform container that renders the component returned by
 * elements.create(...) when running in React Native and a regular <div> when
 * running on the web.
 */
export function PlatformPaymentElementView({
  id,
  className,
  style,
  onPaymentResult,
  onPaymentEvent,
  options,
  Component,
  children,
}: PlatformPaymentElementViewProps) {
  const { sdkAuthorization } = useHyperElementsContext() || {};

  if (isReactNative) {
    if (Component) {
      return (
        <Component
          widgetId={id ?? ''}
          sdkAuthorization={sdkAuthorization ? sdkAuthorization : undefined}
          onPaymentResult={onPaymentResult ?? (() => {})}
          onPaymentEvent={onPaymentEvent}
          className={className}
          style={normalizeNativeStyle(style)}
          options={(options ?? {}) as any}
        />
      );
    }

    throw new Error(
      '[react-hyperswitch] Running in React Native but elements.create({ type: \'paymentElement\' }) did not return a Component.'
    );
  }

  return (
    <div id={id} className={className} style={style as CSSProperties}>
      {children}
    </div>
  );
}

export function PlatformCVCElementView({
  id,
  className,
  style,
  options,
  onChange,
  onFocus,
  onBlur,
  Component,
  children,
}: PlatformCVCElementViewProps) {
  const { sdkAuthorization } = useHyperElementsContext() || {};

  if (isReactNative) {
    if (Component) {
      return (
        <Component
          id={id}
          options={(options ?? {}) as any}
          onChange={onChange}
          sdkAuthorization={sdkAuthorization ? sdkAuthorization : undefined}
          onFocus={onFocus}
          onBlur={onBlur}
          className={className}
          style={normalizeNativeStyle(style)}
        />
      );
    }

    throw new Error(
      '[react-hyperswitch] Running in React Native but elements.create({ type: \'cvcWidget\' }) did not return a Component.'
    );
  }

  return (
    <div id={id} className={className} style={style as CSSProperties}>
      {children}
    </div>
  );
}

export const isWeb = typeof (globalThis as any).document !== 'undefined';
