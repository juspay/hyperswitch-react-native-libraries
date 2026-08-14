// HyperswitchCVCInput.tsx
import { useState, forwardRef } from 'react';
import { View, Image, StyleSheet } from 'react-native';
import type {
  HyperswitchTextInputProps,
  HyperswitchTextInputRef,
} from './HyperswitchTextInputBase';
import { HyperswitchTextInputBase } from './HyperswitchTextInputBase';
import type { HyperswitchTextInputState } from './HyperswitchTextInputState';

const CVCImage = require('../assets/cardIcons/cvc3-light.png');

/**
 * Props for the `HyperswitchCVCInput` component.
 * Extends `HyperswitchTextInputProps` but fixes `type` to `cvc`.
 */
export interface HyperswitchCVCInputProps extends Omit<
  HyperswitchTextInputProps,
  'type'
> {
  /**
   * Width of the CVC image.
   * @default 48
   */
  iconWidth?: number;
  /**
   * Height of the CVC image.
   * @default 24
   */
  iconHeight?: number;
  /**
   * Padding around the CVC image.
   * @default 8
   */
  iconPadding?: number;
  /**
   * Position of the CVC image ('left', 'right', or 'none').
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
   * Style for the CVC image.
   */
  iconStyle?: object;
}
/**
 * Secure input for card security codes (CVC/CVV).
 *
 * Behavior:
 * - Sets `type="cvc"`, applies numeric mask and length validators.
 * - Displays a contextual CVC illustration icon.
 * - Supports `secureTextEntry` for privacy.
 */
const HyperswitchCVCInput = forwardRef<
  HyperswitchTextInputRef,
  HyperswitchCVCInputProps
>(
  (
    {
      secureTextEntry = true,
      iconPosition = 'right',
      iconWidth = 42,
      iconHeight = 24,
      iconPadding = 8,
      onStateChange,
      containerStyle,
      textStyle: textStyle,
      iconStyle,
      containerHeight = 50,
      accessibilityLabel = 'Card security code',
      ...otherProps
    },
    ref
  ) => {
    const [cvcIcon, setCVCIcon] = useState<any>(CVCImage);

    const handleStateChange = (newState: HyperswitchTextInputState) => {
      if (newState.type === 'cvc') {
        // TODO: Separate icon for CVV??
        setCVCIcon(CVCImage);
      }
      onStateChange?.(newState);
    };

    return (
      <View
        style={[styles.container, containerStyle, { height: containerHeight }]}
      >
        <HyperswitchTextInputBase
          {...otherProps}
          type="cvc"
          ref={ref}
          secureTextEntry={secureTextEntry}
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
            source={cvcIcon}
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
            accessibilityLabel="Payment Card CVC Icon"
          />
        )}

        {iconPosition === 'right' && (
          <Image
            source={cvcIcon}
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
            accessibilityLabel="Payment Card CVC Icon"
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

export default HyperswitchCVCInput;
