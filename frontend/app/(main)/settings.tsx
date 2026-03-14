import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { GlassView } from "../../src/components/glass/GlassView";
import { useTheme } from "../../src/hooks/useTheme";

export default function SettingsScreen() {
  const { colors, typography, isDark, toggleTheme } = useTheme();
  const router = useRouter();
  const [systemPrompt, setSystemPrompt] = useState(
    "You are a helpful AI assistant...",
  );

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Header */}
      <GlassView style={styles.header} intensity={80}>
        <TouchableOpacity
          onPress={() => router.back()}
          style={styles.backButton}
        >
          <Ionicons name="chevron-back" size={24} color={colors.textMain} />
        </TouchableOpacity>
        <Text
          style={[
            styles.headerTitle,
            {
              color: colors.textMain,
              fontSize: typography.sizes.lg,
              fontWeight: typography.weights.bold,
            },
          ]}
        >
          设置
        </Text>
        <View style={{ width: 40 }} /> {/* Spacer for centering */}
      </GlassView>

      <ScrollView
        style={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {/* Model & Skills Section */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.textMuted }]}>
            模型与能力
          </Text>

          <GlassView style={styles.card} intensity={40}>
            <TouchableOpacity style={styles.row}>
              <View>
                <Text style={[styles.rowLabel, { color: colors.textMain }]}>
                  默认大语言模型
                </Text>
                <Text style={[styles.rowSubLabel, { color: colors.textMuted }]}>
                  MiniMax-M2.5
                </Text>
              </View>
              <Ionicons
                name="chevron-forward"
                size={20}
                color={colors.textMuted}
              />
            </TouchableOpacity>

            <View
              style={[styles.divider, { backgroundColor: colors.border }]}
            />

            <TouchableOpacity style={styles.row}>
              <View>
                <Text style={[styles.rowLabel, { color: colors.textMain }]}>
                  Skills 设定
                </Text>
                <Text style={[styles.rowSubLabel, { color: colors.textMuted }]}>
                  已启用 5 个技能
                </Text>
              </View>
              <Ionicons
                name="chevron-forward"
                size={20}
                color={colors.textMuted}
              />
            </TouchableOpacity>
            
            <View
              style={[styles.divider, { backgroundColor: colors.border }]}
            />
            
            <View style={styles.row}>
              <View>
                <Text style={[styles.rowLabel, { color: colors.textMain }]}>
                  Skills 自动重载 (Watch)
                </Text>
                <Text style={[styles.rowSubLabel, { color: colors.textMuted }]}>
                  监听 Skills 目录变化并自动加载
                </Text>
              </View>
              <Switch
                value={true}
                onValueChange={() => {}}
                trackColor={{ true: colors.primary }}
              />
            </View>
          </GlassView>
        </View>

        {/* Advanced Config Section */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.textMuted }]}>
            核心文件配置
          </Text>

          <GlassView style={styles.card} intensity={40}>
            <TouchableOpacity style={styles.actionItem}>
              <Ionicons name="document-text-outline" size={20} color={colors.textMain} />
              <View style={styles.actionTextContainer}>
                <Text style={[styles.actionText, { color: colors.textMain }]}>soul.md</Text>
                <Text style={[styles.actionSubText, { color: colors.textMuted }]}>核心设定与价值观</Text>
              </View>
              <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
            </TouchableOpacity>
            
            <View style={[styles.divider, { backgroundColor: colors.border, marginLeft: 48 }]} />
            
            <TouchableOpacity style={styles.actionItem}>
              <Ionicons name="document-text-outline" size={20} color={colors.textMain} />
              <View style={styles.actionTextContainer}>
                <Text style={[styles.actionText, { color: colors.textMain }]}>agent.md</Text>
                <Text style={[styles.actionSubText, { color: colors.textMuted }]}>行为准则与工作流</Text>
              </View>
              <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
            </TouchableOpacity>
            
            <View style={[styles.divider, { backgroundColor: colors.border, marginLeft: 48 }]} />
            
            <TouchableOpacity style={styles.actionItem}>
              <Ionicons name="person-circle-outline" size={20} color={colors.textMain} />
              <View style={styles.actionTextContainer}>
                <Text style={[styles.actionText, { color: colors.textMain }]}>identity.md</Text>
                <Text style={[styles.actionSubText, { color: colors.textMuted }]}>身份信息与背景</Text>
              </View>
              <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
            </TouchableOpacity>
            
            <View style={[styles.divider, { backgroundColor: colors.border, marginLeft: 48 }]} />
            
            <TouchableOpacity style={styles.actionItem}>
              <Ionicons name="construct-outline" size={20} color={colors.textMain} />
              <View style={styles.actionTextContainer}>
                <Text style={[styles.actionText, { color: colors.textMain }]}>tools.json</Text>
                <Text style={[styles.actionSubText, { color: colors.textMuted }]}>可用工具与权限</Text>
              </View>
              <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
            </TouchableOpacity>
            
            <View style={[styles.divider, { backgroundColor: colors.border, marginLeft: 48 }]} />
            
            <TouchableOpacity style={styles.actionItem}>
              <Ionicons name="people-outline" size={20} color={colors.textMain} />
              <View style={styles.actionTextContainer}>
                <Text style={[styles.actionText, { color: colors.textMain }]}>users.json</Text>
                <Text style={[styles.actionSubText, { color: colors.textMuted }]}>用户关系与记忆</Text>
              </View>
              <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
            </TouchableOpacity>
          </GlassView>
        </View>

        {/* Memory Section */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.textMuted }]}>
            记忆与上下文
          </Text>
          <GlassView style={styles.card} intensity={40}>
            <TouchableOpacity style={styles.actionItem}>
              <Ionicons name="hardware-chip-outline" size={20} color={colors.textMain} />
              <View style={styles.actionTextContainer}>
                <Text style={[styles.actionText, { color: colors.textMain }]}>长期记忆管理</Text>
                <Text style={[styles.actionSubText, { color: colors.textMuted }]}>查看和编辑 Agent 提取的记忆</Text>
              </View>
              <Ionicons name="chevron-forward" size={16} color={colors.textSecondary} />
            </TouchableOpacity>
          </GlassView>
        </View>

        {/* App Settings */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.textMuted }]}>
            应用设置
          </Text>
          <GlassView
            style={[styles.card, { marginBottom: 120 }]}
            intensity={40}
          >
            <View style={styles.row}>
              <Text style={[styles.rowLabel, { color: colors.textMain }]}>
                暗色模式
              </Text>
              <Switch
                value={isDark}
                onValueChange={toggleTheme}
                trackColor={{ true: colors.primary }}
              />
            </View>
          </GlassView>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingTop: 50,
    paddingBottom: 12,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 8,
    zIndex: 10,
    borderBottomWidth: 0,
    elevation: 0,
    shadowOpacity: 0,
  },
  backButton: {
    padding: 8,
  },
  headerTitle: {
    fontSize: 18,
  },
  content: {
    padding: 16,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: "600",
    textTransform: "uppercase",
    marginBottom: 8,
    marginLeft: 4,
  },
  card: {
    borderRadius: 16,
    overflow: "hidden",
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    padding: 16,
  },
  rowLabel: {
    fontSize: 16,
    fontWeight: "500",
  },
  rowSubLabel: {
    fontSize: 13,
    marginTop: 2,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    marginLeft: 16,
  },
  actionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
  },
  actionTextContainer: {
    flex: 1,
    marginLeft: 12,
  },
  actionText: {
    fontSize: 16,
    fontWeight: '500',
  },
  actionSubText: {
    fontSize: 12,
    marginTop: 2,
  },
});
