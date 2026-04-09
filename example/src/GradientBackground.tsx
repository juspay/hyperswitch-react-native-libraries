import React, { ReactNode } from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';

interface GradientBackgroundProps {
  children: ReactNode;
  style?: ViewStyle;
}

// Midnight Glow Gradient Background Simulation
// Using layered views to create a radial gradient effect
export const GradientBackground: React.FC<GradientBackgroundProps> = ({
  children,
  style,
}) => {
  return (
    <View style={[styles.container, style]}>
      {/* Base background */}
      <View style={styles.baseLayer} />

      {/* Top-left glow */}
      <View style={styles.topLeftGlow} />

      {/* Bottom-right glow */}
      <View style={styles.bottomRightGlow} />

      {/* Center glow */}
      <View style={styles.centerGlow} />

      {/* Content */}
      <View style={styles.content}>{children}</View>
    </View>
  );
};

// Background colors from Midnight Glow palette
const BASE_COLOR = '#020c1b';
const GLOW_TOP_LEFT = '#1a1a2e';
const GLOW_BOTTOM_RIGHT = '#16213e';
const GLOW_CENTER = '#0f3460';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    position: 'relative',
  },
  baseLayer: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: BASE_COLOR,
  },
  topLeftGlow: {
    position: 'absolute',
    top: -100,
    left: -100,
    width: 400,
    height: 400,
    borderRadius: 200,
    backgroundColor: GLOW_TOP_LEFT,
    opacity: 0.6,
  },
  bottomRightGlow: {
    position: 'absolute',
    bottom: -100,
    right: -100,
    width: 400,
    height: 400,
    borderRadius: 200,
    backgroundColor: GLOW_BOTTOM_RIGHT,
    opacity: 0.5,
  },
  centerGlow: {
    position: 'absolute',
    top: '30%',
    left: '10%',
    width: 300,
    height: 300,
    borderRadius: 150,
    backgroundColor: GLOW_CENTER,
    opacity: 0.25,
  },
  content: {
    flex: 1,
    zIndex: 1,
  },
});

export default GradientBackground;
