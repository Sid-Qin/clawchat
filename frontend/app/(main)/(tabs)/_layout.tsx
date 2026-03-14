import { Ionicons } from "@expo/vector-icons";
import { Tabs } from "expo-router";
import React, { useEffect, useRef } from "react";
import { Animated, Pressable, StyleSheet } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { GlassView } from "../../../src/components/glass/GlassView";
import { useTheme } from "../../../src/hooks/useTheme";

function AnimatedTabIcon({ name, size, color, focused }: { name: string; size: number; color: string; focused: boolean }) {
  const scale = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    if (focused) {
      Animated.sequence([
        Animated.spring(scale, { toValue: 1.25, useNativeDriver: true, speed: 50, bounciness: 12 }),
        Animated.spring(scale, { toValue: 1, useNativeDriver: true, speed: 30, bounciness: 8 }),
      ]).start();
    }
  }, [focused]);

  return (
    <Animated.View style={{ transform: [{ scale }] }}>
      <Ionicons name={name as any} size={size} color={color} />
    </Animated.View>
  );
}

export default function TabLayout() {
  const { colors } = useTheme();
  const insets = useSafeAreaInsets();

  const tabBarHeight = 40;

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          position: "absolute",
          borderTopWidth: StyleSheet.hairlineWidth,
          borderTopColor: colors.border,
          elevation: 0,
          backgroundColor: "transparent",
          height: tabBarHeight + insets.bottom,
          bottom: 0,
          left: 0,
          right: 0,
        },
        tabBarBackground: () => (
          <GlassView style={StyleSheet.absoluteFill} intensity={100} />
        ),
        tabBarButton: (props) => (
          <Pressable {...props} android_ripple={{ borderless: true }} />
        ),
        tabBarItemStyle: {
          paddingVertical: 4,
          paddingBottom: insets.bottom + 2,
        },
        tabBarActiveTintColor: colors.textMain,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarShowLabel: true,
        tabBarLabelStyle: {
          fontSize: 10,
          fontWeight: "600",
          marginTop: -2,
        },
        tabBarIconStyle: {
          marginTop: 2,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "主页",
          tabBarIcon: ({ color, focused }) => (
            <AnimatedTabIcon
              name={focused ? "chatbubbles" : "chatbubbles-outline"}
              size={22}
              color={color}
              focused={focused}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="notifications"
        options={{
          title: "看板",
          tabBarIcon: ({ color, focused }) => (
            <AnimatedTabIcon
              name={focused ? "grid" : "grid-outline"}
              size={22}
              color={color}
              focused={focused}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: "您",
          tabBarIcon: ({ color, focused }) => (
            <AnimatedTabIcon
              name={focused ? "person" : "person-outline"}
              size={22}
              color={color}
              focused={focused}
            />
          ),
        }}
      />
    </Tabs>
  );
}
