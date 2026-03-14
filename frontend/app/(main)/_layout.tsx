import React from 'react';
import { Stack } from 'expo-router';

export default function MainLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen 
        name="chat/[sessionId]" 
        options={{ 
          animation: 'slide_from_right',
          gestureEnabled: true,
        }} 
      />
    </Stack>
  );
}
