import {
  forwardRef,
  useCallback,
  useContext,
  useEffect,
  useImperativeHandle,
  useRef,
} from 'react';
import { FormContext } from '../core/FormContext';
import type { ElementType, FieldChange, FieldHandle } from '../core/types';
import { Placeholder } from './Placeholder';
import type { FieldProps } from './types';

export function createCardField(elementType: ElementType, displayName: string) {
  const CardField = forwardRef<FieldHandle, FieldProps>((props, ref) => {
    const ctx = useContext(FormContext);
    const fieldRef = useRef<FieldHandle | null>(null);
    const { onChange, onReady, onFocus, onBlur, ...rest } = props;

    /* Read at call time, so a new arrow per render never re-subscribes anything. */
    const onChangeRef = useRef(onChange);
    onChangeRef.current = onChange;
    const onReadyRef = useRef(onReady);
    onReadyRef.current = onReady;

    useImperativeHandle(
      ref,
      () => ({
        focus: () => fieldRef.current?.focus(),
        blur: () => fieldRef.current?.blur(),
        clear: () => fieldRef.current?.clear(),
      }),
      []
    );

    const reportChange = ctx?.reportChange;
    const handleChange = useCallback(
      (change: FieldChange) => {
        reportChange?.(change);
        onChangeRef.current?.(change);
      },
      [reportChange]
    );

    const forgetField = ctx?.forgetField;
    useEffect(
      () => () => {
        forgetField?.(elementType);
      },
      [forgetField]
    );

    const mounted = ctx !== null && ctx.collector !== undefined;
    useEffect(() => {
      if (mounted) onReadyRef.current?.({ elementType });
    }, [mounted]);

    if (!ctx) {
      throw new Error(`${displayName} must be rendered inside a <CardForm>.`);
    }

    if (ctx.collector === undefined) {
      return <Placeholder elementType={elementType} {...rest} />;
    }

    const Field = ctx.adapter.Field;
    return (
      <Field
        elementType={elementType}
        collector={ctx.collector}
        fieldRef={fieldRef}
        onChange={handleChange}
        onFocus={onFocus}
        onBlur={onBlur}
        {...rest}
      />
    );
  });

  CardField.displayName = displayName;
  return CardField;
}
