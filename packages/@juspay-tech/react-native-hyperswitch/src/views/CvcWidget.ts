// Factory for a capacitor-shaped CvcWidget handle backed by an RN view.

import * as React from 'react';
import { CVCElementView } from './CVCElementView';
import type { CvcWidget } from '../types/definitions';

let cvcWidgetId = 0;

export function createCvcWidget(opts?: {
  id?: string;
  options?: any;
}): CvcWidget {
  const widgetId = opts?.id ?? `rn-cvc-widget-${++cvcWidgetId}`;
  const noop = () => {};
  const noopListener = { remove: noop };

  const Component = (props: any) =>
    React.createElement(CVCElementView as React.ComponentType<any>, {
      ...props,
      id: widgetId,
      options: {
        ...(opts?.options ?? {}),
        ...(props.options ?? {}),
      },
    });

  return {
    Component,
    mount: noop,
    unmount: noop,
    destroy: noop,
    on: () => noopListener,
  };
}
