import React, { forwardRef, useCallback, useEffect, useId, useImperativeHandle, useMemo, useRef, type CSSProperties } from 'react';
import { useHyperElementsContext } from './HyperElements';
import { isWeb, PlatformCVCElementView } from './PlatformView';
import type {
  CvcWidget as CvcWidgetType,
  CvcWidgetOptions,
  PaymentEventData,
  removeListenerFunction,
} from '../definitions';

export interface CvcWidgetHandle {
  unmount(): void;
}

export interface CvcWidgetProps {
  id?: string;
  options?: CvcWidgetOptions;
  onChange?: (data?: PaymentEventData) => void;
  onFocus?: () => void;
  onBlur?: () => void;
  onReady?: () => void;
  style?: CSSProperties;
  className?: string;
}

interface CvcStatusPayload {
  cvcStatus?: {
    isCvcFocused?: boolean;
    isCvcBlur?: boolean;
    isCvcEmpty?: boolean;
    isCvcComplete?: boolean;
  };
}

function extractCvcStatus(data?: PaymentEventData): CvcStatusPayload | undefined {
  if (!data) return undefined;
  const payload = data.payload as Record<string, unknown> | undefined;
  if (!payload) return undefined;
  return payload as CvcStatusPayload;
}

const CvcWidget = forwardRef<CvcWidgetHandle, CvcWidgetProps>(function CvcWidgetComponent(
  { id, options, onChange, onFocus, onBlur, onReady, style, className },
  ref,
) {
  const { elements, sessionHandle, publishableKey, sdkAuthorization } = useHyperElementsContext();

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
      ...(publishableKey ? { publishableKey } : {}),
      ...(sdkAuthorization ? { sdkAuthorization } : {}),
    }),
    [options, publishableKey, sdkAuthorization]
  );

  const reactId = useId();
  const domId = id ? id : `hs-cvc-widget-${reactId.replace(/:/g, '')}`;

  const instanceRef = useRef<CvcWidgetType | null>(null);
  const isFocusedRef = useRef(false);

  const cvcWidget = useMemo(() => {
    if (!elements) return null;
    return elements.create({ type: 'cvcWidget', id, options });
  }, [elements, id]);

  const previousOptionsJsonRef = useRef<string>(JSON.stringify(options));

  useEffect(() => {
    previousOptionsJsonRef.current = JSON.stringify(options);
  }, [cvcWidget]);

  useEffect(() => {
    if (!isWeb || !cvcWidget) return;

    const optionsJson = JSON.stringify(options);
    if (previousOptionsJsonRef.current === optionsJson) return;

    previousOptionsJsonRef.current = optionsJson;
    cvcWidget.unmount();
    cvcWidget.mount(`#${domId}`, options);
  }, [cvcWidget, options, domId]);

  const onChangeRef = useRef(onChange);
  const onFocusRef = useRef(onFocus);
  const onBlurRef = useRef(onBlur);

  useEffect(() => {
    onChangeRef.current = onChange;
    onFocusRef.current = onFocus;
    onBlurRef.current = onBlur;
  }, [onChange, onFocus, onBlur]);

  function safeRemove(listener: removeListenerFunction | null | undefined): void {
    if (!listener) return;
    if (listener instanceof Promise) {
      listener.then((h) => h.remove());
    } else {
      listener.remove();
    }
  }

  const handleChange = useCallback((data?: PaymentEventData) => {
    onChangeRef.current?.(data);

    const cvcPayload = extractCvcStatus(data);
    const cvcStatus = cvcPayload?.cvcStatus;
    if (!cvcStatus) return;

    const focused = !!cvcStatus.isCvcFocused;
    const blurred = !!cvcStatus.isCvcBlur;

    if (focused && !isFocusedRef.current) {
      isFocusedRef.current = true;
      onFocusRef.current?.();
    }
    if (blurred && isFocusedRef.current) {
      isFocusedRef.current = false;
      onBlurRef.current?.();
    }
  }, []);

  useEffect(() => {
    if (!cvcWidget) return;

    const widget = cvcWidget;
    instanceRef.current = widget;

    if (!isWeb) {
      if (onReady) onReady();
      return () => {
        widget.destroy();
        instanceRef.current = null;
      };
    }

    const onChangeListener = widget.on('change', handleChange);
    widget.mount(`#${domId}`);

    if (onReady) onReady();

    return () => {
      widget.unmount();
      safeRemove(onChangeListener);
      instanceRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cvcWidget]);

  useImperativeHandle(
    ref,
    () => ({
      unmount() {
        instanceRef.current?.unmount();
        instanceRef.current = null;
      },
    }),
    [],
  );

  if (!isWeb && !cvcWidget) {
    return null;
  }

  return (
    <PlatformCVCElementView
      id={domId}
      Component={cvcWidget?.Component}
      sessionHandle={sessionHandle ?? undefined}
      className={className}
      style={{ minHeight: 'inherit', width: '100%', ...style }}
      options={nativeOptions}
      onChange={handleChange}
    />
  );
});

export default CvcWidget;
