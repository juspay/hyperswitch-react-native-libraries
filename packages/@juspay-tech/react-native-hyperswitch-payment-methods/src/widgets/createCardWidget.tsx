import { forwardRef, useContext, useImperativeHandle, useRef } from 'react';
import { FormContext } from '../core/FormContext';
import type { FieldKind, WidgetHandle } from '../core/types';
import { Placeholder } from './Placeholder';
import type { WidgetProps } from './types';

export function createCardWidget(kind: FieldKind, displayName: string) {
  const CardWidget = forwardRef<WidgetHandle, WidgetProps>((props, ref) => {
    const ctx = useContext(FormContext);
    const fieldRef = useRef<WidgetHandle | null>(null);

    useImperativeHandle(
      ref,
      () => ({
        focus: () => fieldRef.current?.focus(),
        blur: () => fieldRef.current?.blur(),
      }),
      []
    );

    if (!ctx) {
      throw new Error(
        `${displayName} must be rendered inside a <HyperswitchForm>.`
      );
    }

    if (ctx.collector === undefined) {
      return <Placeholder kind={kind} {...props} />;
    }

    const Field = ctx.adapter.Field;
    return (
      <Field
        kind={kind}
        collector={ctx.collector}
        fieldRef={fieldRef}
        {...props}
      />
    );
  });

  CardWidget.displayName = displayName;
  return CardWidget;
}
