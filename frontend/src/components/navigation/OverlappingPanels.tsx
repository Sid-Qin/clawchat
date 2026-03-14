import React, { ReactNode } from 'react';
import { View, StyleSheet, Dimensions } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { useTheme } from '../../hooks/useTheme';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

// Panel widths
const LEFT_PANEL_WIDTH = 312; // 72 (Sidebar) + 240 (Session List)
const RIGHT_PANEL_WIDTH = 280;
const SPRING_CONFIG = {
  damping: 20,
  stiffness: 150,
  mass: 1,
  overshootClamping: false,
  restDisplacementThreshold: 0.1,
  restSpeedThreshold: 0.1,
};

interface OverlappingPanelsProps {
  leftPanel: ReactNode;
  centerPanel: ReactNode;
  rightPanel: ReactNode;
}

export const OverlappingPanels: React.FC<OverlappingPanelsProps> = ({
  leftPanel,
  centerPanel,
  rightPanel,
}) => {
  const { colors } = useTheme();
  const translateX = useSharedValue(0);
  const startX = useSharedValue(0);

  const panGesture = Gesture.Pan()
    .activeOffsetX([-20, 20])
    .onStart(() => {
      startX.value = translateX.value;
    })
    .onUpdate((event) => {
      let nextX = startX.value + event.translationX;
      // Clamp values
      if (nextX > LEFT_PANEL_WIDTH) nextX = LEFT_PANEL_WIDTH;
      if (nextX < -RIGHT_PANEL_WIDTH) nextX = -RIGHT_PANEL_WIDTH;
      translateX.value = nextX;
    })
    .onEnd((event) => {
      const velocityX = event.velocityX;
      const currentX = translateX.value;
      
      let snapPoint = 0;
      
      if (currentX > 0) {
        // Moving right (opening left panel)
        if (currentX > LEFT_PANEL_WIDTH / 2 || velocityX > 500) {
          snapPoint = LEFT_PANEL_WIDTH;
        } else {
          snapPoint = 0;
        }
      } else {
        // Moving left (opening right panel)
        if (currentX < -RIGHT_PANEL_WIDTH / 2 || velocityX < -500) {
          snapPoint = -RIGHT_PANEL_WIDTH;
        } else {
          snapPoint = 0;
        }
      }
      
      translateX.value = withSpring(snapPoint, SPRING_CONFIG);
    });

  const centerAnimatedStyle = useAnimatedStyle(() => {
    const scale = interpolate(
      Math.abs(translateX.value),
      [0, Math.max(LEFT_PANEL_WIDTH, RIGHT_PANEL_WIDTH)],
      [1, 0.95],
      Extrapolation.CLAMP
    );
    
    const borderRadius = interpolate(
      Math.abs(translateX.value),
      [0, Math.max(LEFT_PANEL_WIDTH, RIGHT_PANEL_WIDTH)],
      [0, 20],
      Extrapolation.CLAMP
    );

    return {
      transform: [
        { translateX: translateX.value },
        { scale }
      ],
      borderRadius,
      overflow: 'hidden',
    };
  });

  const leftPanelStyle = useAnimatedStyle(() => {
    const translate = interpolate(
      translateX.value,
      [0, LEFT_PANEL_WIDTH],
      [-LEFT_PANEL_WIDTH * 0.3, 0],
      Extrapolation.CLAMP
    );
    
    return {
      transform: [{ translateX: translate }],
      opacity: interpolate(translateX.value, [0, LEFT_PANEL_WIDTH], [0, 1], Extrapolation.CLAMP),
      zIndex: translateX.value > 0 ? 1 : -1,
    };
  });

  const rightPanelStyle = useAnimatedStyle(() => {
    const translate = interpolate(
      translateX.value,
      [-RIGHT_PANEL_WIDTH, 0],
      [0, RIGHT_PANEL_WIDTH * 0.3],
      Extrapolation.CLAMP
    );
    
    return {
      transform: [{ translateX: translate }],
      opacity: interpolate(translateX.value, [-RIGHT_PANEL_WIDTH, 0], [1, 0], Extrapolation.CLAMP),
      zIndex: translateX.value < 0 ? 1 : -1,
    };
  });

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Left Panel */}
      <Animated.View style={[styles.sidePanel, styles.leftPanel, leftPanelStyle]}>
        {leftPanel}
      </Animated.View>

      {/* Right Panel */}
      <Animated.View style={[styles.sidePanel, styles.rightPanel, rightPanelStyle]}>
        {rightPanel}
      </Animated.View>

      {/* Center Panel */}
      <GestureDetector gesture={panGesture}>
        <Animated.View style={[styles.centerPanel, centerAnimatedStyle, { backgroundColor: colors.background }]}>
          {centerPanel}
        </Animated.View>
      </GestureDetector>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  centerPanel: {
    flex: 1,
    zIndex: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    elevation: 10,
  },
  sidePanel: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    width: '100%',
  },
  leftPanel: {
    left: 0,
    width: LEFT_PANEL_WIDTH,
  },
  rightPanel: {
    right: 0,
    width: RIGHT_PANEL_WIDTH,
  },
});
