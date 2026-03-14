import React, { useState } from "react";
import {
  FlatList,
  Image,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  ScrollView,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { GlassView } from "../../../src/components/glass/GlassView";
import { useTheme } from "../../../src/hooks/useTheme";

export default function NotificationsTab() {
  const { colors, typography } = useTheme();
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.topFade, { height: insets.top + 16 }]} pointerEvents="none">
        <LinearGradient
          colors={[colors.background, colors.background, colors.background + '00']}
          locations={[0, 0.6, 1]}
          style={StyleSheet.absoluteFill}
        />
      </View>
      <ScrollView contentContainerStyle={[styles.scrollContent, { paddingTop: insets.top + 16 }]}>
        {/* Token Usage Card */}
        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <View style={styles.cardHeader}>
            <Text style={[styles.cardTitle, { color: colors.textMain }]}>Token 用量</Text>
            <View style={styles.cardTabs}>
              <Text style={[styles.cardTab, styles.cardTabActive, { color: colors.textMain }]}>7天</Text>
              <Text style={[styles.cardTab, { color: colors.textSecondary }]}>30天</Text>
            </View>
          </View>
          
          <Text style={[styles.tokenTotal, { color: colors.textMain }]}>46.8M</Text>
          <Text style={[styles.tokenSubtitle, { color: colors.textSecondary }]}>tokens - 过去 7 天</Text>
          
          <View style={styles.tokenStats}>
            <View style={styles.tokenStatItem}>
              <Text style={[styles.tokenStatLabel, { color: colors.textSecondary }]}>输入</Text>
              <Text style={[styles.tokenStatValue, { color: colors.textMain }]}>29.6M</Text>
            </View>
            <View style={styles.tokenStatItem}>
              <Text style={[styles.tokenStatLabel, { color: colors.textSecondary }]}>输出</Text>
              <Text style={[styles.tokenStatValue, { color: colors.textMain }]}>84.0K</Text>
            </View>
            <View style={styles.tokenStatItem}>
              <Text style={[styles.tokenStatLabel, { color: colors.textSecondary }]}>缓存</Text>
              <Text style={[styles.tokenStatValue, { color: colors.textMain }]}>17.1M</Text>
            </View>
          </View>

          <View style={styles.modelDist}>
            <View style={styles.modelDistRow}>
              <Text style={[styles.modelDistLabel, { color: colors.textSecondary }]}>MiniMax-M2.5</Text>
              <Text style={[styles.modelDistValue, { color: colors.textMain }]}>32.1M</Text>
            </View>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: '70%', backgroundColor: colors.primary }]} />
            </View>
            
            <View style={styles.modelDistRow}>
              <Text style={[styles.modelDistLabel, { color: colors.textSecondary }]}>Claude 3.5 Sonnet</Text>
              <Text style={[styles.modelDistValue, { color: colors.textMain }]}>14.7M</Text>
            </View>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: '30%', backgroundColor: '#8E8E93' }]} />
            </View>
          </View>
        </View>

        {/* Quick Actions Card */}
        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Text style={[styles.sectionTitle, { color: colors.textSecondary }]}>OPENCLAW 配置</Text>
          <TouchableOpacity style={styles.actionItem}>
            <Ionicons name="document-text-outline" size={20} color={colors.textMain} />
            <Text style={[styles.actionText, { color: colors.textMain }]}>查看配置</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionItem}>
            <Ionicons name="sync-outline" size={20} color={colors.textMain} />
            <Text style={[styles.actionText, { color: colors.textMain }]}>恢复配置备份</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionItem}>
            <Ionicons name="eye-outline" size={20} color={colors.textMain} />
            <Text style={[styles.actionText, { color: colors.textMain }]}>开启 Skills Watch</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>

          <Text style={[styles.sectionTitle, { color: colors.textSecondary, marginTop: 16 }]}>诊断与日志</Text>
          <TouchableOpacity style={styles.actionItem}>
            <Ionicons name="medkit-outline" size={20} color={colors.textMain} />
            <Text style={[styles.actionText, { color: colors.textMain }]}>运行诊断</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionItem}>
            <Ionicons name="list-outline" size={20} color={colors.textMain} />
            <Text style={[styles.actionText, { color: colors.textMain }]}>查看日志</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>

          <Text style={[styles.sectionTitle, { color: colors.textSecondary, marginTop: 16 }]}>系统维护</Text>
          <TouchableOpacity style={styles.actionItem}>
            <Ionicons name="construct-outline" size={20} color={colors.textMain} />
            <Text style={[styles.actionText, { color: colors.textMain }]}>工具权限修复</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionItem}>
            <Ionicons name="power-outline" size={20} color={colors.danger} />
            <Text style={[styles.actionText, { color: colors.danger }]}>重启 Gateway</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionItem}>
            <Ionicons name="arrow-up-circle-outline" size={20} color={colors.textMain} />
            <Text style={[styles.actionText, { color: colors.textMain }]}>更新 openclaw</Text>
            <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
          </TouchableOpacity>
        </View>

        {/* Errors and Notifications */}
        <View style={styles.notificationsList}>
          <Text style={[styles.sectionTitle, { color: colors.textSecondary, marginLeft: 16, marginBottom: 8 }]}>最新消息</Text>
          
          <View style={[styles.alertCard, { backgroundColor: 'rgba(255, 59, 48, 0.1)' }]}>
            <View style={styles.alertHeader}>
              <Ionicons name="alert-circle" size={20} color={colors.danger} />
              <Text style={[styles.alertTitle, { color: colors.danger }]}>工具执行失败</Text>
            </View>
            <Text style={[styles.alertDesc, { color: colors.textMain }]}>
              Agent "林恩.ai" 尝试执行 shell 命令时被拒绝，权限未开启。
            </Text>
            <Text style={[styles.alertTime, { color: colors.textSecondary }]}>10 分钟前</Text>
          </View>

          <View style={[styles.alertCard, { backgroundColor: 'rgba(52, 199, 89, 0.1)' }]}>
            <View style={styles.alertHeader}>
              <Ionicons name="arrow-up-circle" size={20} color={colors.success} />
              <Text style={[styles.alertTitle, { color: colors.success }]}>有新版本可用</Text>
            </View>
            <Text style={[styles.alertDesc, { color: colors.textMain }]}>
              OpenClaw v2026.3.9 已发布，包含性能优化和新的模型支持。
            </Text>
            <Text style={[styles.alertTime, { color: colors.textSecondary }]}>2 小时前</Text>
          </View>
        </View>

      </ScrollView>
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
  scrollContent: {
    padding: 16,
    paddingBottom: 100,
  },
  card: {
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '600',
  },
  cardTabs: {
    flexDirection: 'row',
    backgroundColor: 'rgba(0,0,0,0.05)',
    borderRadius: 8,
    padding: 2,
  },
  cardTab: {
    paddingHorizontal: 12,
    paddingVertical: 4,
    fontSize: 12,
    fontWeight: '500',
    borderRadius: 6,
  },
  cardTabActive: {
    backgroundColor: 'rgba(255,255,255,0.1)',
  },
  tokenTotal: {
    fontSize: 40,
    fontWeight: 'bold',
  },
  tokenSubtitle: {
    fontSize: 14,
    marginBottom: 20,
  },
  tokenStats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 24,
    backgroundColor: 'rgba(0,0,0,0.02)',
    padding: 12,
    borderRadius: 12,
  },
  tokenStatItem: {
    alignItems: 'center',
  },
  tokenStatLabel: {
    fontSize: 12,
    marginBottom: 4,
  },
  tokenStatValue: {
    fontSize: 16,
    fontWeight: '600',
  },
  modelDist: {
    marginTop: 8,
  },
  modelDistRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  modelDistLabel: {
    fontSize: 13,
  },
  modelDistValue: {
    fontSize: 13,
    fontWeight: '500',
  },
  progressBar: {
    height: 6,
    backgroundColor: 'rgba(0,0,0,0.05)',
    borderRadius: 3,
    marginBottom: 16,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: 3,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 1,
    marginBottom: 8,
  },
  actionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(0,0,0,0.05)',
  },
  actionText: {
    flex: 1,
    fontSize: 16,
    marginLeft: 12,
  },
  notificationsList: {
    marginTop: 8,
  },
  alertCard: {
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
  },
  alertHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  alertTitle: {
    fontSize: 15,
    fontWeight: '600',
    marginLeft: 8,
  },
  alertDesc: {
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 8,
  },
  alertTime: {
    fontSize: 12,
  },
});
