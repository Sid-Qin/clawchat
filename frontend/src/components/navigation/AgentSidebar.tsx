import { Ionicons } from "@expo/vector-icons";
import React, { useState, useEffect } from "react";
import {
  Image,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  View,
  ActionSheetIOS,
  Platform,
  Modal,
  Text,
  TextInput,
  Dimensions,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTheme } from "../../hooks/useTheme";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  runOnJS,
  withTiming,
} from "react-native-reanimated";

const { height: SCREEN_HEIGHT } = Dimensions.get("window");

interface SidebarAgent {
  id: string;
  avatar: string;
  isGateway?: boolean;
  hasNotif?: boolean;
}

const SIDEBAR_AGENTS: SidebarAgent[] = [
  { id: "gateway", avatar: "", isGateway: true },
  { id: "a1", avatar: "https://i.pravatar.cc/150?u=lynning", hasNotif: false },
  { id: "a2", avatar: "https://i.pravatar.cc/150?u=shield", hasNotif: false },
  { id: "a3", avatar: "https://i.pravatar.cc/150?u=bersney", hasNotif: true },
  { id: "a4", avatar: "https://i.pravatar.cc/150?u=panda99", hasNotif: false },
  { id: "a5", avatar: "https://i.pravatar.cc/150?u=otter55", hasNotif: false },
  { id: "a6", avatar: "https://i.pravatar.cc/150?u=group1", hasNotif: false },
];

export const AgentSidebar = () => {
  const { colors, typography } = useTheme();
  const insets = useSafeAreaInsets();
  const [selectedId, setSelectedId] = useState("a3");
  const [gatewayType, setGatewayType] = useState<"local" | "cloud">("local");
  const [isAddAgentVisible, setIsAddAgentVisible] = useState(false);
  const [newAgentName, setNewAgentName] = useState("");
  const [newAgentEmoji, setNewAgentEmoji] = useState("🤖");
  const [newAgentModel, setNewAgentModel] = useState("MiniMax-M2.5");

  const translateY = useSharedValue(0);

  useEffect(() => {
    if (isAddAgentVisible) {
      translateY.value = withSpring(0, { damping: 20, stiffness: 200 });
    }
  }, [isAddAgentVisible]);

  const closeAddAgentModal = () => {
    setIsAddAgentVisible(false);
    translateY.value = 0;
  };

  const panGesture = Gesture.Pan()
    .onUpdate((event) => {
      if (event.translationY > 0) {
        translateY.value = event.translationY;
      }
    })
    .onEnd((event) => {
      if (event.translationY > 150 || event.velocityY > 500) {
        translateY.value = withTiming(SCREEN_HEIGHT, { duration: 250 }, () => {
          runOnJS(closeAddAgentModal)();
        });
      } else {
        translateY.value = withSpring(0, { damping: 20, stiffness: 200 });
      }
    });

  const animatedModalStyle = useAnimatedStyle(() => {
    return {
      transform: [{ translateY: translateY.value }],
    };
  });

  const handleGatewayPress = () => {
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          options: ["取消", "本地 Gateway", "云端 Gateway", "添加 Gateway..."],
          cancelButtonIndex: 0,
          userInterfaceStyle: "dark", // or dynamically based on theme
        },
        (buttonIndex) => {
          if (buttonIndex === 1) {
            setGatewayType("local");
            setSelectedId("gateway");
          } else if (buttonIndex === 2) {
            setGatewayType("cloud");
            setSelectedId("gateway");
          }
          // handle '添加 Gateway...' later
        }
      );
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: colors.sidebar }]}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={[styles.scrollContent, { paddingTop: insets.top }]}
      >
        {SIDEBAR_AGENTS.map((agent, idx) => {
          const isSelected = selectedId === agent.id;

          if (agent.isGateway) {
            return (
              <React.Fragment key={agent.id}>
                <TouchableOpacity
                  style={[
                    styles.gatewayBtn,
                    {
                      backgroundColor: isSelected
                        ? colors.primary
                        : colors.panel,
                    },
                  ]}
                  onPress={handleGatewayPress}
                  activeOpacity={0.8}
                >
                  <Text style={{ fontSize: 24 }}>🦞</Text>
                  <View style={[styles.statusIndicator, { backgroundColor: gatewayType === 'local' ? colors.success : colors.primary }]} />
                </TouchableOpacity>
                <View
                  style={[styles.divider, { backgroundColor: colors.border }]}
                />
              </React.Fragment>
            );
          }

          return (
            <TouchableOpacity
              key={agent.id}
              style={styles.agentItem}
              onPress={() => setSelectedId(agent.id)}
              activeOpacity={0.7}
            >
              {/* Left indicator pill */}
              <View style={styles.indicatorWrap}>
                {isSelected ? (
                  <View
                    style={[
                      styles.indicatorLong,
                      { backgroundColor: colors.textMain },
                    ]}
                  />
                ) : agent.hasNotif ? (
                  <View
                    style={[
                      styles.indicatorDot,
                      { backgroundColor: colors.textMain },
                    ]}
                  />
                ) : null}
              </View>

              <Image
                source={{ uri: agent.avatar }}
                style={[styles.avatar, { borderRadius: isSelected ? 16 : 24 }]}
              />
            </TouchableOpacity>
          );
        })}

        <View style={[styles.divider, { backgroundColor: colors.border }]} />

        <TouchableOpacity
          style={[styles.iconBtn, { backgroundColor: colors.panel }]}
          onPress={() => setIsAddAgentVisible(true)}
        >
          <Ionicons name="add" size={22} color={colors.success} />
        </TouchableOpacity>
      </ScrollView>

      {/* Add Agent Modal */}
      <Modal
        animationType="slide"
        transparent={true}
        visible={isAddAgentVisible}
        onRequestClose={closeAddAgentModal}
      >
        <View style={styles.modalOverlay}>
          <TouchableOpacity 
            style={StyleSheet.absoluteFill} 
            activeOpacity={1} 
            onPress={closeAddAgentModal} 
          />
          <GestureDetector gesture={panGesture}>
            <Animated.View style={[styles.modalContent, { backgroundColor: colors.background, paddingBottom: insets.bottom + 24 }, animatedModalStyle]}>
              <View style={[styles.dragIndicator, { backgroundColor: colors.textMuted, opacity: 0.3 }]} />
              <View style={styles.modalHeader}>
                <Text style={[styles.modalTitle, { color: colors.textMain, ...typography.title3 }]}>新建 Agent</Text>
                <TouchableOpacity onPress={closeAddAgentModal}>
                  <Ionicons name="close" size={24} color={colors.textSecondary} />
                </TouchableOpacity>
              </View>

              <View style={styles.inputGroup}>
                <Text style={[styles.inputLabel, { color: colors.textSecondary }]}>名称</Text>
                <TextInput
                  style={[styles.input, { backgroundColor: colors.panel, color: colors.textMain }]}
                  value={newAgentName}
                  onChangeText={setNewAgentName}
                  placeholder="Agent 名称"
                  placeholderTextColor={colors.textMuted}
                />
              </View>

              <View style={styles.inputGroup}>
                <Text style={[styles.inputLabel, { color: colors.textSecondary }]}>Emoji (可选)</Text>
                <TextInput
                  style={[styles.input, { backgroundColor: colors.panel, color: colors.textMain }]}
                  value={newAgentEmoji}
                  onChangeText={setNewAgentEmoji}
                  placeholder="🤖"
                  placeholderTextColor={colors.textMuted}
                />
              </View>
              
              <View style={styles.inputGroup}>
                <Text style={[styles.inputLabel, { color: colors.textSecondary }]}>默认模型</Text>
                <TouchableOpacity 
                  style={[styles.modelSelectBtn, { backgroundColor: colors.panel }]}
                  onPress={() => {
                    if (Platform.OS === 'ios') {
                      ActionSheetIOS.showActionSheetWithOptions(
                        {
                          options: ['取消', 'MiniMax-M2.5', 'Claude 3.5 Sonnet', 'GPT-4o'],
                          cancelButtonIndex: 0,
                        },
                        (buttonIndex) => {
                          if (buttonIndex === 1) setNewAgentModel('MiniMax-M2.5');
                          if (buttonIndex === 2) setNewAgentModel('Claude 3.5 Sonnet');
                          if (buttonIndex === 3) setNewAgentModel('GPT-4o');
                        }
                      );
                    }
                  }}
                >
                  <Text style={{ color: colors.textMain }}>{newAgentModel}</Text>
                  <Ionicons name="chevron-down" size={20} color={colors.textSecondary} />
                </TouchableOpacity>
              </View>

              <TouchableOpacity 
                style={[styles.createBtn, { backgroundColor: colors.primary }]}
                onPress={() => {
                  closeAddAgentModal();
                  setNewAgentName("");
                }}
              >
                <Text style={[styles.createBtnText, { ...typography.headline }]}>创建 Agent</Text>
              </TouchableOpacity>
            </Animated.View>
          </GestureDetector>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: 72,
    height: "100%",
  },
  scrollContent: {
    alignItems: "center",
    paddingBottom: 24,
    gap: 6,
  },
  iconBtn: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: "center",
    alignItems: "center",
  },
  gatewayBtn: {
    width: 52,
    height: 52,
    borderRadius: 16,
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 4,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  divider: {
    width: 32,
    height: 2,
    borderRadius: 1,
    marginVertical: 4,
  },
  agentItem: {
    width: 72,
    height: 52,
    flexDirection: "row",
    alignItems: "center",
  },
  indicatorWrap: {
    width: 8,
    height: 52,
    justifyContent: "center",
    alignItems: "flex-start",
  },
  indicatorLong: {
    width: 4,
    height: 36,
    borderTopRightRadius: 4,
    borderBottomRightRadius: 4,
  },
  indicatorDot: {
    width: 4,
    height: 8,
    borderTopRightRadius: 4,
    borderBottomRightRadius: 4,
  },
  avatar: {
    width: 48,
    height: 48,
    marginLeft: 4,
  },
  statusIndicator: {
    position: 'absolute',
    bottom: 2,
    right: 2,
    width: 12,
    height: 12,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: '#1e1f22', // Match sidebar background
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'transparent',
    justifyContent: 'flex-end',
  },
  modalContent: {
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 24,
    minHeight: '50%',
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 10,
  },
  dragIndicator: {
    width: 40,
    height: 4,
    backgroundColor: 'rgba(0,0,0,0.1)',
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: 20,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 24,
  },
  modalTitle: {
    fontWeight: '600',
  },
  inputGroup: {
    marginBottom: 20,
  },
  inputLabel: {
    marginBottom: 8,
    fontSize: 14,
    fontWeight: '500',
  },
  input: {
    height: 48,
    borderRadius: 12,
    paddingHorizontal: 16,
    fontSize: 16,
  },
  modelSelectBtn: {
    height: 48,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
  },
  createBtn: {
    height: 50,
    borderRadius: 25,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 12,
  },
  createBtnText: {
    color: '#fff',
    fontWeight: '600',
  },
});
