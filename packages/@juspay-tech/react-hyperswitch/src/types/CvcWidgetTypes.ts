import { removeListenerFunction } from './PaymentElementTypes';
import { ColorType, Font, Shapes } from './AppearanceTypes';
import { PaymentEventData } from './PaymentTypes';
import { Theme } from './PaymentSheetTypes';
import type { ComponentType } from 'react';

export interface CvcAppearance {
  theme?: Theme;
  colors?: ColorType;
  shapes?: Shapes;
  font?: Pick<Font, 'family' | 'scale'>;
}

export interface CvcWidgetOptions {
  appearance?: CvcAppearance;
  placeholder?: string;
  cvcIcon?: 'hidden' | 'shown';
}

export interface CvcWidget {
  Component?: ComponentType<any>;
  mount(selector: string, options?: CvcWidgetOptions): void;
  unmount(): void;
  destroy(): void;
  on(event: string, handler?: (data?: PaymentEventData) => void): removeListenerFunction | null;
}
