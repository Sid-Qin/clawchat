import React from 'react';
import { View, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AgentSidebar } from '../../../src/components/navigation/AgentSidebar';
import { SessionList } from '../../../src/components/navigation/SessionList';
import { useTheme } from '../../../src/hooks/useTheme';

export default function HomeTab() {
  const { colors } = useTheme();
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { backgroundColor: colors.sidebar }]}>
      <View style={styles.sidebarContainer}>
        <AgentSidebar />
      </View>
      <View style={[styles.sessionListContainer, { backgroundColor: colors.background, marginTop: insets.top }]}>
        <SessionList />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'row',
  },
  sidebarContainer: {
    width: 72,
    height: '100%',
  },
  sessionListContainer: {
    flex: 1,
    height: '100%',
    borderTopLeftRadius: 24,
    overflow: 'hidden',
  },
});
