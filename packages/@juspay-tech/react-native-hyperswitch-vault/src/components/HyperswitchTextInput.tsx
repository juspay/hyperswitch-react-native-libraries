import { forwardRef, useImperativeHandle, useRef } from 'react';
import HyperswitchTextInputBase, {
  type HyperswitchTextInputRef,
  type HyperswitchPredefinedInputProps,
} from './HyperswitchTextInputBase';

import HyperswitchCardInput, {
  type HyperswitchCardInputProps,
} from './HyperswitchCardInput';
import HyperswitchCVCInput, {
  type HyperswitchCVCInputProps,
} from './HyperswitchCVCInput';
import ExpDateSeparateSerializer from '../utils/serializers/ExpDateSeparateSerializer';
import type { TextInput } from 'react-native';

export type CardNumberWidgetProps = Omit<
  HyperswitchCardInputProps,
  'fieldName'
> & {
  fieldName?: string;
};

export const CardNumberWidget = forwardRef<
  HyperswitchTextInputRef,
  CardNumberWidgetProps
>((props, ref) => {
  const { fieldName = 'pan', ...rest } = props;
  const inner = useRef<TextInput>(null);
  useImperativeHandle(ref, () => ({
    focus: () => inner.current?.focus(),
    blur: () => inner.current?.blur(),
  }));
  return <HyperswitchCardInput {...rest} fieldName={fieldName} ref={inner} />;
});

export type CardCVCWidgetProps = Omit<HyperswitchCVCInputProps, 'fieldName'> & {
  fieldName?: string;
};

export const CardCVCWidget = forwardRef<
  HyperswitchTextInputRef,
  CardCVCWidgetProps
>((props, ref) => {
  const { fieldName = 'cvc', ...rest } = props;
  const inner = useRef<TextInput>(null);
  useImperativeHandle(ref, () => ({
    focus: () => inner.current?.focus(),
    blur: () => inner.current?.blur(),
  }));
  return <HyperswitchCVCInput {...rest} fieldName={fieldName} ref={inner} />;
});

export type CardExpiryWidgetProps = Omit<
  HyperswitchPredefinedInputProps,
  'fieldName' | 'type'
> & {
  fieldName?: string;
};

export const CardExpiryWidget = forwardRef<
  HyperswitchTextInputRef,
  CardExpiryWidgetProps
>((props, ref) => {
  const {
    fieldName = 'expDate',
    serializers = [new ExpDateSeparateSerializer('exp_month', 'exp_year')],
    accessibilityLabel = 'Card expiration date',
    ...rest
  } = props;
  return (
    <HyperswitchTextInputBase
      {...rest}
      ref={ref}
      fieldName={fieldName}
      type="expDate"
      serializers={serializers}
      accessibilityLabel={accessibilityLabel}
    />
  );
});

export type CardHolderWidgetProps = Omit<
  HyperswitchPredefinedInputProps,
  'fieldName' | 'type'
> & {
  fieldName?: string;
};

export const CardHolderWidget = forwardRef<
  HyperswitchTextInputRef,
  CardHolderWidgetProps
>((props, ref) => {
  const {
    fieldName = 'cardholder',
    accessibilityLabel = 'Cardholder name',
    ...rest
  } = props;
  return (
    <HyperswitchTextInputBase
      {...rest}
      ref={ref}
      fieldName={fieldName}
      type="cardHolderName"
      accessibilityLabel={accessibilityLabel}
    />
  );
});
