import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useRef, useState } from "react";
import {
  Animated,
  Image,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  ActionSheetIOS,
  Platform,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { GlassView } from "../../../src/components/glass/GlassView";
import { useTheme } from "../../../src/hooks/useTheme";
import { mockAgents } from "../../../src/data/mockData";

const BANNER_HEIGHT = 180;

export default function AgentProfileTab() {
  const { colors, typography } = useTheme();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const scrollY = useRef(new Animated.Value(0)).current;
  
  const [currentAgentId, setCurrentAgentId] = useState(mockAgents[0].id);
  const currentAgent = mockAgents.find(a => a.id === currentAgentId) || mockAgents[0];

  const handleSwitchAgent = () => {
    if (Platform.OS === 'ios') {
      const options = ['取消', ...mockAgents.slice(0, 5).map(a => a.name)];
      ActionSheetIOS.showActionSheetWithOptions(
        {
          options,
          cancelButtonIndex: 0,
          title: '切换 Agent',
        },
        (buttonIndex) => {
          if (buttonIndex > 0) {
            setCurrentAgentId(mockAgents[buttonIndex - 1].id);
          }
        }
      );
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.topFade, { height: insets.top + 16 }]} pointerEvents="none">
        <LinearGradient
          colors={['rgba(0,0,0,0.35)', 'rgba(0,0,0,0.15)', 'transparent']}
          locations={[0, 0.5, 1]}
          style={StyleSheet.absoluteFill}
        />
      </View>
      <Animated.ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingBottom: 100 }}
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: true }
        )}
        scrollEventThrottle={16}
      >
        {/* Banner with stretch-to-zoom */}
        <View style={styles.bannerContainer}>
          <Animated.Image 
            source={{ uri: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop' }} 
            style={[
              styles.bannerImage,
              {
                transform: [
                  {
                    translateY: scrollY.interpolate({
                      inputRange: [-200, 0, BANNER_HEIGHT],
                      outputRange: [-100, 0, 0],
                    }),
                  },
                  {
                    scale: scrollY.interpolate({
                      inputRange: [-200, 0],
                      outputRange: [2.2, 1],
                      extrapolateRight: 'clamp',
                    }),
                  },
                ],
              },
            ]}
          />
          {/* Settings Icon */}
          <TouchableOpacity 
            style={[styles.settingsBtn, { top: insets.top + 10 }]}
            onPress={() => router.push('/(main)/settings')}
          >
            <View style={styles.settingsIconBg}>
              <Ionicons name="settings" size={20} color="#fff" />
            </View>
          </TouchableOpacity>
        </View>

        {/* Profile Content */}
        <View style={styles.profileContent}>
          {/* Avatar Area */}
          <View style={styles.avatarRow}>
            <View style={styles.avatarWrapper}>
              <Image source={{ uri: currentAgent.avatar }} style={[styles.avatar, { borderColor: colors.background }]} />
              <View style={[styles.statusDot, { backgroundColor: colors.success, borderColor: colors.background }]} />
            </View>
            
            <TouchableOpacity style={[styles.addStatusBtn, { backgroundColor: colors.card }]}>
              <Ionicons name="add-circle" size={16} color={colors.textMain} />
              <Text style={[styles.addStatusText, { color: colors.textMain }]}>添加状态</Text>
            </TouchableOpacity>
          </View>

          {/* Name & Switcher */}
          <View style={styles.nameSection}>
            <TouchableOpacity style={styles.nameRow} onPress={handleSwitchAgent}>
              <Text style={[styles.nameText, { color: colors.textMain, fontSize: typography.sizes.xxl, fontWeight: typography.weights.bold }]}>
                {currentAgent.name}
              </Text>
              <Ionicons name="chevron-down" size={20} color={colors.textMuted} style={{ marginLeft: 4, marginTop: 4 }} />
            </TouchableOpacity>
            <Text style={[styles.idText, { color: colors.textMuted }]}>
              {currentAgent.id}_agent 🦞 🤖
            </Text>
          </View>

          {/* Edit Profile Button */}
          <TouchableOpacity style={[styles.editProfileBtn, { backgroundColor: colors.panel }]}>
            <Ionicons name="pencil" size={16} color={colors.textMain} />
            <Text style={[styles.editProfileText, { color: colors.textMain }]}>编辑 Agent 资料</Text>
          </TouchableOpacity>

          {/* Info Cards */}
          <View style={styles.cardsContainer}>
            <GlassView style={styles.infoCard} intensity={40}>
              <Text style={[styles.cardLabel, { color: colors.textMain }]}>默认模型</Text>
              <View style={[styles.cardBadge, { backgroundColor: colors.border }]}>
                <Ionicons name="sparkles" size={14} color={colors.primary} />
                <Text style={[styles.cardBadgeText, { color: colors.textMain }]}>{currentAgent.model || 'MiniMax-M2.5'}</Text>
              </View>
            </GlassView>

            <GlassView style={styles.infoCard} intensity={40}>
              <Text style={[styles.cardLabel, { color: colors.textMain }]}>创建时间</Text>
              <Text style={[styles.cardValue, { color: colors.textSecondary }]}>
                <Ionicons name="calendar-outline" size={14} color={colors.textMuted} /> 2026年3月10日
              </Text>
            </GlassView>

            <GlassView style={styles.infoCard} intensity={40}>
              <View style={styles.rowBetween}>
                <Text style={[styles.cardLabel, { color: colors.textMain }]}>已启用 Skills</Text>
                <View style={styles.skillsPreview}>
                  <View style={[styles.skillDot, { backgroundColor: '#FF9500', zIndex: 3 }]}><Ionicons name="terminal" size={10} color="#fff" /></View>
                  <View style={[styles.skillDot, { backgroundColor: '#34C759', zIndex: 2, marginLeft: -8 }]}><Ionicons name="folder" size={10} color="#fff" /></View>
                  <View style={[styles.skillDot, { backgroundColor: '#007AFF', zIndex: 1, marginLeft: -8 }]}><Ionicons name="globe" size={10} color="#fff" /></View>
                  <Ionicons name="chevron-forward" size={16} color={colors.textMuted} style={{ marginLeft: 8 }} />
                </View>
              </View>
            </GlassView>

            <GlassView style={styles.infoCard} intensity={40}>
              <Text style={[styles.cardLabel, { color: colors.textMain }]}>主题与设定</Text>
              <Text style={[styles.cardValue, { color: colors.textSecondary, marginTop: 8 }]} numberOfLines={2}>
                {currentAgent.theme || 'You are a helpful AI assistant. You can help users with various tasks and answer questions.'}
              </Text>
            </GlassView>
          </View>
        </View>
      </Animated.ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  topFade: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
  },
  bannerContainer: {
    width: '100%',
    height: BANNER_HEIGHT,
    position: 'relative',
    overflow: 'hidden',
  },
  bannerImage: {
    width: '100%',
    height: BANNER_HEIGHT,
    resizeMode: 'cover',
  },
  settingsBtn: {
    position: 'absolute',
    right: 16,
    zIndex: 10,
  },
  settingsIconBg: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  profileContent: {
    paddingHorizontal: 16,
  },
  avatarRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    marginTop: -40,
    marginBottom: 16,
  },
  avatarWrapper: {
    position: 'relative',
  },
  avatar: {
    width: 84,
    height: 84,
    borderRadius: 42,
    borderWidth: 4,
  },
  statusDot: {
    position: 'absolute',
    bottom: 2,
    right: 2,
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 3,
  },
  addStatusBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    marginBottom: 8,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  addStatusText: {
    fontSize: 13,
    fontWeight: '600',
    marginLeft: 4,
  },
  nameSection: {
    marginBottom: 20,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  nameText: {
    letterSpacing: 0.5,
  },
  idText: {
    fontSize: 15,
    marginTop: 4,
  },
  editProfileBtn: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 12,
    borderRadius: 12,
    marginBottom: 24,
  },
  editProfileText: {
    fontSize: 15,
    fontWeight: '600',
    marginLeft: 6,
  },
  cardsContainer: {
    gap: 12,
  },
  infoCard: {
    padding: 16,
    borderRadius: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
  },
  cardLabel: {
    fontSize: 15,
    fontWeight: '500',
  },
  cardValue: {
    fontSize: 14,
  },
  cardBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    gap: 4,
  },
  cardBadgeText: {
    fontSize: 13,
    fontWeight: '500',
  },
  rowBetween: {
    width: '100%',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  skillsPreview: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  skillDot: {
    width: 24,
    height: 24,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#fff', // Ideally use background color
  },
});
