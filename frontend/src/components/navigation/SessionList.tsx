import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React from "react";
import {
    FlatList,
    Image,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from "react-native";
import { mockAgents, mockSessions } from "../../data/mockData";
import { useTheme } from "../../hooks/useTheme";

export const SessionList = () => {
  const { colors, typography } = useTheme();
  const router = useRouter();

  const renderSessionItem = ({ item }: { item: (typeof mockSessions)[0] }) => {
    // Find the agent for this session to get the avatar
    const agent =
      mockAgents.find((a) => a.id === item.agentId) || mockAgents[0];

    return (
      <TouchableOpacity
        style={styles.sessionItem}
        onPress={() => router.push(`/(main)/chat/${item.id}` as any)}
        activeOpacity={0.6}
      >
        <View style={styles.avatarWrapper}>
          <Image source={{ uri: agent.avatar }} style={styles.avatar} />
          <View
            style={[
              styles.statusDot,
              {
                backgroundColor:
                  agent.status === "online"
                    ? colors.success
                    : agent.status === "idle"
                      ? "#F0B232"
                      : agent.status === "dnd"
                        ? colors.danger
                        : colors.textMuted,
                borderColor: colors.background,
              },
            ]}
          />
        </View>

        <View style={styles.contentContainer}>
          <View style={styles.headerRow}>
            <Text
              style={[
                styles.nameText,
                {
                  color: colors.textMain,
                  fontSize: typography.sizes.md,
                  fontWeight: typography.weights.semibold,
                },
              ]}
            >
              {agent.name}
            </Text>
            <Text
              style={[
                styles.timeText,
                { color: colors.textMuted, fontSize: typography.sizes.xs },
              ]}
            >
              {item.timeAgo}
            </Text>
          </View>
          <Text
            style={[styles.messageText, { color: colors.textMuted }]}
            numberOfLines={1}
          >
            {item.lastMessage}
          </Text>
        </View>

        {item.unreadCount > 0 && (
          <View style={[styles.badge, { backgroundColor: colors.danger }]}>
            <Text style={styles.badgeText}>{item.unreadCount}</Text>
          </View>
        )}
      </TouchableOpacity>
    );
  };

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={styles.searchRow}>
        <View style={[styles.searchBar, { backgroundColor: colors.border }]}>
          <Ionicons name="search" size={16} color={colors.textMuted} />
          <Text style={[styles.searchPlaceholder, { color: colors.textMuted }]}>
            搜索
          </Text>
        </View>
      </View>

      <FlatList
        data={mockSessions}
        keyExtractor={(item) => item.id}
        renderItem={renderSessionItem}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    borderTopLeftRadius: 24,
    overflow: 'hidden',
  },
  searchRow: {
    paddingHorizontal: 16,
    paddingVertical: 16,
  },
  searchBar: {
    flexDirection: "row",
    alignItems: "center",
    height: 36,
    borderRadius: 18,
    paddingHorizontal: 12,
    gap: 6,
  },
  searchPlaceholder: {
    fontSize: 14,
  },
  listContent: {
    paddingBottom: 100,
  },
  sessionItem: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  avatarWrapper: {
    position: "relative",
    marginRight: 12,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
  },
  statusDot: {
    position: "absolute",
    bottom: -1,
    right: -1,
    width: 14,
    height: 14,
    borderRadius: 7,
    borderWidth: 2.5,
  },
  contentContainer: {
    flex: 1,
  },
  headerRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 4,
  },
  nameText: {
    flex: 1,
  },
  timeText: {
    marginLeft: 8,
  },
  messageText: {
    fontSize: 14,
  },
  badge: {
    minWidth: 20,
    height: 20,
    borderRadius: 10,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 6,
    marginLeft: 8,
  },
  badgeText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "bold",
  },
});
