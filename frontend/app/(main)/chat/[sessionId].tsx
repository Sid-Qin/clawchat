import { Ionicons } from "@expo/vector-icons";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useState } from "react";
import {
    FlatList,
    Image,
    KeyboardAvoidingView,
    Platform,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View,
    ScrollView,
} from "react-native";
import { GlassView } from "../../../src/components/glass/GlassView";
import {
    mockAgents,
    mockMessages,
    mockSessions,
} from "../../../src/data/mockData";
import { useTheme } from "../../../src/hooks/useTheme";

export default function ChatView() {
  const { sessionId } = useLocalSearchParams();
  const router = useRouter();
  const { colors, typography } = useTheme();
  const [inputText, setInputText] = useState("");

  const session =
    mockSessions.find((s) => s.id === sessionId) || mockSessions[0];
  const agent =
    mockAgents.find((a) => a.id === session.agentId) || mockAgents[0];
  const messages = mockMessages.filter((m) => m.sessionId === session.id);

  const renderMessage = ({
    item,
    index,
  }: {
    item: (typeof mockMessages)[0];
    index: number;
  }) => {
    const isMe = item.senderId === "me";
    const showAvatar =
      !isMe &&
      (index === 0 || mockMessages[index - 1].senderId !== item.senderId);

    return (
      <View
        style={[
          styles.messageRow,
          isMe ? styles.messageRowMe : styles.messageRowOther,
        ]}
      >
        {!isMe && (
          <View style={styles.avatarContainer}>
            {showAvatar ? (
              <Image
                source={{ uri: item.senderAvatar }}
                style={styles.messageAvatar}
              />
            ) : (
              <View style={styles.messageAvatarPlaceholder} />
            )}
          </View>
        )}

        <View
          style={[
            styles.messageContent,
            isMe ? styles.messageContentMe : styles.messageContentOther,
          ]}
        >
          {showAvatar && !isMe && (
            <View style={styles.messageHeader}>
              <Text style={[styles.messageSender, { color: colors.textMain }]}>
                {item.senderName}
              </Text>
              <Text style={[styles.messageTime, { color: colors.textMuted }]}>
                {item.timestamp.toLocaleTimeString([], {
                  hour: "2-digit",
                  minute: "2-digit",
                })}
              </Text>
            </View>
          )}

          <View
            style={[
              styles.bubble,
              isMe
                ? { backgroundColor: colors.primary }
                : { backgroundColor: colors.card },
            ]}
          >
            <Text
              style={[
                styles.messageText,
                { color: isMe ? "#fff" : colors.textMain },
              ]}
            >
              {item.content}
            </Text>
            {item.tokenCount && !isMe && (
              <View style={styles.tokenContainer}>
                <Ionicons name="flash" size={10} color={colors.textSecondary} />
                <Text style={[styles.tokenText, { color: colors.textSecondary }]}>
                  {item.tokenCount} tokens
                </Text>
              </View>
            )}
          </View>
        </View>
      </View>
    );
  };

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
        <View style={styles.headerTitleContainer}>
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
            {agent.name}
          </Text>
        </View>
        <View style={styles.headerActions}>
          <TouchableOpacity style={styles.headerActionBtn}>
            <Ionicons name="call" size={20} color={colors.textMain} />
          </TouchableOpacity>
          <TouchableOpacity style={styles.headerActionBtn}>
            <Ionicons name="videocam" size={20} color={colors.textMain} />
          </TouchableOpacity>
          <TouchableOpacity style={styles.headerActionBtn}>
            <Ionicons name="search" size={20} color={colors.textMain} />
          </TouchableOpacity>
        </View>
      </GlassView>

      <KeyboardAvoidingView
        style={styles.keyboardAvoid}
        behavior={Platform.OS === "ios" ? "padding" : undefined}
      >
        <FlatList
          data={messages}
          keyExtractor={(item) => item.id}
          renderItem={renderMessage}
          contentContainerStyle={styles.messageList}
          ListHeaderComponent={() => (
            <View style={styles.chatStart}>
              <Image
                source={{ uri: agent.avatar }}
                style={styles.chatStartAvatar}
              />
              <Text style={[styles.chatStartTitle, { color: colors.textMain }]}>
                {agent.name}
              </Text>
              <Text style={[styles.chatStartDesc, { color: colors.textMuted }]}>
                您和 {agent.name} 的传奇对话从这里开始。
              </Text>
              <View
                style={[
                  styles.dateSeparator,
                  { backgroundColor: colors.border },
                ]}
              />
              <Text style={[styles.dateText, { color: colors.textMuted }]}>
                2026年3月10日
              </Text>
            </View>
          )}
        />

        {/* Model & Feature Switcher Bar */}
        <View style={[styles.modelBarContainer, { backgroundColor: colors.background, borderTopColor: colors.border }]}>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.modelBarScroll}>
            <TouchableOpacity style={[styles.modelBarBtn, { backgroundColor: colors.panel }]}>
              <Ionicons name="sparkles" size={14} color={colors.primary} style={styles.modelBarIcon} />
              <Text style={[styles.modelBarText, { color: colors.textMain }]}>MiniMax-M2.5</Text>
              <Ionicons name="chevron-down" size={14} color={colors.textSecondary} style={{marginLeft: 4}} />
            </TouchableOpacity>
            
            <TouchableOpacity style={[styles.modelBarBtn, { backgroundColor: colors.panel }]}>
              <Ionicons name="bulb-outline" size={14} color={colors.textSecondary} style={styles.modelBarIcon} />
              <Text style={[styles.modelBarText, { color: colors.textSecondary }]}>思考</Text>
            </TouchableOpacity>
            
            <TouchableOpacity style={[styles.modelBarBtn, { backgroundColor: colors.panel }]}>
              <Ionicons name="terminal-outline" size={14} color={colors.textSecondary} style={styles.modelBarIcon} />
              <Text style={[styles.modelBarText, { color: colors.textSecondary }]}>命令</Text>
            </TouchableOpacity>

            <TouchableOpacity style={[styles.modelBarBtn, { backgroundColor: colors.panel }]}>
              <Ionicons name="analytics-outline" size={14} color={colors.textSecondary} style={styles.modelBarIcon} />
              <Text style={[styles.modelBarText, { color: colors.textSecondary }]}>用量: 12.3K</Text>
            </TouchableOpacity>
          </ScrollView>
        </View>

        {/* Input Area */}
        <GlassView style={styles.inputContainer} intensity={80}>
          <TouchableOpacity style={styles.attachBtn}>
            <Ionicons name="add-circle" size={28} color={colors.textMuted} />
          </TouchableOpacity>

          <View
            style={[styles.inputWrapper, { backgroundColor: colors.border }]}
          >
            <TextInput
              style={[styles.input, { color: colors.textMain }]}
              placeholder={`发送给 @${agent.name}`}
              placeholderTextColor={colors.textMuted}
              value={inputText}
              onChangeText={setInputText}
              multiline
            />
            <TouchableOpacity style={styles.emojiBtn}>
              <Ionicons
                name="happy-outline"
                size={24}
                color={colors.textMuted}
              />
            </TouchableOpacity>
          </View>

          {inputText.length > 0 ? (
            <TouchableOpacity
              style={[styles.sendBtn, { backgroundColor: colors.primary }]}
            >
              <Ionicons name="arrow-up" size={20} color="#fff" />
            </TouchableOpacity>
          ) : (
            <TouchableOpacity 
              style={[styles.micBtnLarge, { backgroundColor: colors.primary }]}
              activeOpacity={0.8}
            >
              <Ionicons name="mic" size={24} color="#fff" />
            </TouchableOpacity>
          )}
        </GlassView>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  keyboardAvoid: {
    flex: 1,
  },
  header: {
    paddingTop: 50,
    paddingBottom: 12,
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 8,
    zIndex: 10,
    borderBottomWidth: 0,
    elevation: 0,
    shadowOpacity: 0,
  },
  backButton: {
    padding: 8,
  },
  headerTitleContainer: {
    flex: 1,
    marginLeft: 8,
  },
  headerTitle: {
    fontSize: 18,
  },
  headerActions: {
    flexDirection: "row",
  },
  headerActionBtn: {
    padding: 8,
    marginLeft: 8,
  },
  messageList: {
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  chatStart: {
    alignItems: "center",
    paddingVertical: 32,
  },
  chatStartAvatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    marginBottom: 16,
  },
  chatStartTitle: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 8,
  },
  chatStartDesc: {
    fontSize: 14,
    marginBottom: 24,
  },
  dateSeparator: {
    height: 1,
    width: "100%",
    position: "absolute",
    bottom: 10,
  },
  dateText: {
    fontSize: 12,
    backgroundColor: "#F2F3F5", // Should match background
    paddingHorizontal: 8,
    marginTop: 16,
  },
  messageRow: {
    flexDirection: "row",
    marginBottom: 16,
  },
  messageRowMe: {
    justifyContent: "flex-end",
  },
  messageRowOther: {
    justifyContent: "flex-start",
  },
  avatarContainer: {
    width: 40,
    marginRight: 12,
  },
  messageAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  messageAvatarPlaceholder: {
    width: 40,
  },
  messageContent: {
    maxWidth: "80%",
  },
  messageContentMe: {
    alignItems: "flex-end",
  },
  messageContentOther: {
    alignItems: "flex-start",
  },
  messageHeader: {
    flexDirection: "row",
    alignItems: "baseline",
    marginBottom: 4,
    marginLeft: 4,
  },
  messageSender: {
    fontSize: 14,
    fontWeight: "600",
    marginRight: 8,
  },
  messageTime: {
    fontSize: 12,
  },
  bubble: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 16,
  },
  messageText: {
    fontSize: 16,
    lineHeight: 22,
  },
  tokenContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
    opacity: 0.8,
  },
  tokenText: {
    fontSize: 10,
    marginLeft: 2,
  },
  modelBarContainer: {
    paddingVertical: 8,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  modelBarScroll: {
    paddingHorizontal: 12,
    gap: 8,
  },
  modelBarBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  modelBarIcon: {
    marginRight: 6,
  },
  modelBarText: {
    fontSize: 13,
    fontWeight: '500',
  },
  inputContainer: {
    flexDirection: "row",
    alignItems: "flex-end",
    paddingHorizontal: 8,
    paddingVertical: 8,
    paddingBottom: Platform.OS === "ios" ? 24 : 8,
  },
  attachBtn: {
    padding: 8,
    marginRight: 4,
    marginBottom: 2,
  },
  inputWrapper: {
    flex: 1,
    flexDirection: "row",
    alignItems: "flex-end",
    borderRadius: 20,
    paddingHorizontal: 12,
    minHeight: 44,
    maxHeight: 120,
  },
  input: {
    flex: 1,
    paddingTop: 12,
    paddingBottom: 12,
    fontSize: 16,
    maxHeight: 100,
  },
  emojiBtn: {
    padding: 8,
    marginBottom: 4,
  },
  micBtnLarge: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: "center",
    alignItems: "center",
    marginLeft: 8,
    marginBottom: 2,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 3,
  },
  sendBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: "center",
    alignItems: "center",
    marginLeft: 8,
    marginBottom: 2,
  },
});
