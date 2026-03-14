import React from 'react';
import { View, ViewProps, StyleSheet, Platform } from 'react-native';
import { BlurView } from 'expo-blur';
import { useTheme } from '../../hooks/useTheme';

let LiquidGlassView: any = null;
let isLiquidGlassSupported = false;

try {
  const liquidGlass = require('@callstack/liquid-glass');
  LiquidGlassView = liquidGlass.LiquidGlassView;
  isLiquidGlassSupported = liquidGlass.isLiquidGlassSupported ?? false;
} catch {
  // @callstack/liquid-glass not available (e.g. Expo Go)
}

interface GlassViewProps extends ViewProps {
  intensity?: number;
  effect?: 'regular' | 'clear' | 'none';
  interactive?: boolean;
}

export const GlassView: React.FC<GlassViewProps> = ({
  children,
  style,
  intensity = 20,
  effect = 'regular',
  interactive = false,
  ...props
}) => {
  const { colors, isDark } = useTheme();

  if (isLiquidGlassSupported && LiquidGlassView) {
    return (
      <LiquidGlassView
        effect={effect}
        interactive={interactive}
        style={[style]}
        {...props}
      >
        {children}
      </LiquidGlassView>
    );
  }

  if (Platform.OS === 'web') {
    return (
      <View style={[styles.container, { backgroundColor: colors.card }, style]} {...props}>
        {children}
      </View>
    );
  }

  return (
    <BlurView
      intensity={intensity}
      tint={isDark ? 'dark' : 'light'}
      style={[styles.container, style]}
      {...props}
    >
      <View style={[StyleSheet.absoluteFill, { backgroundColor: colors.card }]} />
      {children}
    </BlurView>
  );
};

const styles = StyleSheet.create({
  container: {
    overflow: 'hidden',
  },
});
