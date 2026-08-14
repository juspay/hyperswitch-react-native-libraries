// HyperswitchCardInput.tsx
import { useState, forwardRef } from 'react';
import { View, Image, StyleSheet } from 'react-native';
import type {
  HyperswitchTextInputProps,
  HyperswitchTextInputRef,
} from './HyperswitchTextInputBase';
import { HyperswitchTextInputBase } from './HyperswitchTextInputBase';
import type { HyperswitchTextInputState } from './HyperswitchTextInputState';
import { PaymentCardBrandsManager } from '../utils/paymentCards/PaymentCardBrandsManager';

/**
 * Props for the `HyperswitchCardInput` component.
 * Extends `HyperswitchTextInputProps` but fixes `type` to `card`.
 */
export interface HyperswitchCardInputProps extends Omit<
  HyperswitchTextInputProps,
  'type'
> {
  /**
   * Width of the card brand icon.
   * @default 42
   */
  iconWidth?: number;
  /**
   * Height of the card brand icon.
   * @default 24
   */
  iconHeight?: number;
  /**
   * Padding around the card brand icon.
   * @default 8
   */
  iconPadding?: number;
  /**
   * Position of the card brand icon ('left', 'right', or 'none').
   * @default 'right'
   */
  iconPosition?: 'left' | 'right' | 'none';
  /**
   * Height of the container view.
   * @default 50
   */
  containerHeight?: number;
  /**
   * Style for the container view.
   */
  containerStyle?: object;
  /**
   * Style for the text input.
   */
  textStyle?: object;
  /**
   * Style for the card brand icon.
   */
  iconStyle?: object;
}

/**
 * Secure input for payment card numbers.
 *
 * Behavior:
 * - Sets `type="card"` with default card mask and validators.
 * - Detects card brand dynamically and updates brand icon.
 * - Pads input to avoid icon overlap based on `iconPosition`.
 */
const HyperswitchCardInput = forwardRef<
  HyperswitchTextInputRef,
  HyperswitchCardInputProps
>(
  (
    {
      iconPosition = 'right',
      iconWidth = 42,
      iconHeight = 24,
      iconPadding = 8,
      onStateChange,
      containerStyle,
      textStyle: textStyle,
      iconStyle,
      containerHeight = 50,
      accessibilityLabel = 'Payment card number',
      ...otherProps
    },
    ref
  ) => {
    const manager = PaymentCardBrandsManager.getInstance();
    const [brandIcon, setBrandIcon] = useState<any>(
      manager.getBrandIcon('unknown')
    );

    const handleStateChange = (newState: HyperswitchTextInputState) => {
      if (newState.type === 'card' && 'cardBrand' in newState) {
        const brandName = newState.cardBrand?.toLowerCase() || 'unknown';
        setBrandIcon(manager.getBrandIcon(brandName));
      }
      onStateChange?.(newState);
    };

    return (
      <View
        style={[styles.container, containerStyle, { height: containerHeight }]}
      >
        <HyperswitchTextInputBase
          {...otherProps}
          ref={ref}
          type="card"
          onStateChange={handleStateChange}
          accessibilityLabel={accessibilityLabel}
          textStyle={[
            {
              paddingLeft:
                iconPosition === 'left' ? iconWidth + iconPadding : 0,
              paddingRight:
                iconPosition === 'right' ? iconWidth + iconPadding : 0,
            },
            textStyle, // Merged with default padding
          ]}
        />

        {iconPosition === 'left' && (
          <Image
            source={brandIcon}
            style={[
              styles.icon,
              {
                width: iconWidth,
                height: iconHeight,
                left: iconPadding,
                top: '50%',
                transform: [{ translateY: -iconHeight / 2 }],
              },
              iconStyle,
            ]}
            accessibilityLabel="Payment Card Brand Icon"
          />
        )}

        {iconPosition === 'right' && (
          <Image
            source={brandIcon}
            style={[
              styles.icon,
              {
                width: iconWidth,
                height: iconHeight,
                right: iconPadding,
                top: '50%',
                transform: [{ translateY: -iconHeight / 2 }],
              },
              iconStyle,
            ]}
            accessibilityLabel="Payment Card Brand Icon"
          />
        )}
      </View>
    );
  }
);

const styles = StyleSheet.create({
  container: {
    position: 'relative',
    width: '100%',
    justifyContent: 'center',
  },
  icon: {
    position: 'absolute',
    resizeMode: 'contain',
  },
});

export default HyperswitchCardInput;
