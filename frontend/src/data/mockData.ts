export interface Agent {
  id: string;
  name: string;
  avatar: string;
  status: "online" | "idle" | "dnd" | "offline";
  unreadCount: number;
  gatewayId?: string;
  model?: string;
  theme?: string;
}

export interface Gateway {
  id: string;
  name: string;
  url: string;
  type: "local" | "cloud" | "custom";
  status: "online" | "offline" | "error";
  ping?: number;
}

export interface Skill {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
}

export const mockGateways: Gateway[] = [
  { id: "g1", name: "本地 Gateway", url: "127.0.0.1:18789", type: "local", status: "online", ping: 12 },
  { id: "g2", name: "云端 Gateway", url: "cloud.openclaw.ai", type: "cloud", status: "online", ping: 45 },
];

export const mockSkills: Skill[] = [
  { id: "sk1", name: "Terminal Explorer", description: "允许 Agent 执行安全的 shell 命令", enabled: true },
  { id: "sk2", name: "File System Access", description: "读写本地工作区文件", enabled: true },
  { id: "sk3", name: "Web Browser", description: "使用无头浏览器访问网页", enabled: true },
  { id: "sk4", name: "GitHub Integration", description: "读取和创建 Issues, PRs", enabled: false },
  { id: "sk5", name: "Database Client", description: "连接和查询 SQL 数据库", enabled: false },
];

export interface Session {
  id: string;
  agentId: string;
  title: string;
  category: string;
  lastMessage?: string;
  lastMessageTime?: Date;
  timeAgo?: string;
  unreadCount: number;
}

export interface Message {
  id: string;
  sessionId: string;
  senderId: string;
  senderName: string;
  senderAvatar: string;
  content: string;
  timestamp: Date;
  type: "text" | "image" | "embed" | "system";
  embedData?: any;
  tokenCount?: number;
}

export const mockAgents: Agent[] = [
  {
    id: "1",
    name: "林恩.ai",
    avatar: "https://i.pravatar.cc/150?u=lynning",
    status: "online",
    unreadCount: 0,
    gatewayId: "g1",
    model: "MiniMax-M2.5",
    theme: "Helpful and friendly AI assistant.",
  },
  {
    id: "2",
    name: "Waddle",
    avatar: "https://i.pravatar.cc/150?u=waddle",
    status: "online",
    unreadCount: 0,
    gatewayId: "g1",
    model: "Claude 3.5 Sonnet",
  },
  {
    id: "3",
    name: "Fizz",
    avatar: "https://i.pravatar.cc/150?u=fizz",
    status: "idle",
    unreadCount: 0,
    gatewayId: "g1",
    model: "GPT-4o",
  },
  {
    id: "4",
    name: "Amber",
    avatar: "https://i.pravatar.cc/150?u=amber",
    status: "offline",
    unreadCount: 0,
    gatewayId: "g2",
  },
  {
    id: "5",
    name: "Sora Sun",
    avatar: "https://i.pravatar.cc/150?u=sorasun",
    status: "online",
    unreadCount: 0,
  },
  {
    id: "6",
    name: "Duke",
    avatar: "https://i.pravatar.cc/150?u=duke",
    status: "online",
    unreadCount: 0,
  },
  {
    id: "7",
    name: "Ber",
    avatar: "https://i.pravatar.cc/150?u=ber",
    status: "idle",
    unreadCount: 0,
  },
  {
    id: "8",
    name: "Rab",
    avatar: "https://i.pravatar.cc/150?u=rab",
    status: "online",
    unreadCount: 0,
  },
  {
    id: "9",
    name: "Mochi",
    avatar: "https://i.pravatar.cc/150?u=mochi",
    status: "dnd",
    unreadCount: 0,
  },
  {
    id: "10",
    name: "Hoot",
    avatar: "https://i.pravatar.cc/150?u=hoot",
    status: "online",
    unreadCount: 0,
  },
  {
    id: "11",
    name: "Lynn",
    avatar: "https://i.pravatar.cc/150?u=lynn",
    status: "offline",
    unreadCount: 0,
  },
];

export const mockSessions: Session[] = [
  {
    id: "s1",
    agentId: "1",
    title: "闲聊",
    category: "日常",
    lastMessage: "您：https://discord.gg/JHq22Gnr",
    lastMessageTime: new Date("2026-03-10T13:36:00"),
    timeAgo: "3天",
    unreadCount: 0,
  },
  {
    id: "s2",
    agentId: "2",
    title: "客户授权",
    category: "工作台",
    lastMessage: "Waddle: 告诉她了，让她确认一下客户授权和描述那两...",
    lastMessageTime: new Date("2026-03-10T10:00:00"),
    timeAgo: "3天",
    unreadCount: 0,
  },
  {
    id: "s3",
    agentId: "3",
    title: "打招呼",
    category: "日常",
    lastMessage: "Fizz: Sid，Amber让我来打个招呼，她怕打扰你睡觉不...",
    lastMessageTime: new Date("2026-03-07T22:00:00"),
    timeAgo: "6天",
    unreadCount: 0,
  },
  {
    id: "s4",
    agentId: "4",
    title: "笔记",
    category: "日常",
    lastMessage: "Amber: ✏️",
    lastMessageTime: new Date("2026-03-07T18:00:00"),
    timeAgo: "6天",
    unreadCount: 0,
  },
  {
    id: "s5",
    agentId: "5",
    title: "文件分享",
    category: "工作台",
    lastMessage: "Sora Sun: 1个文件 🔗",
    lastMessageTime: new Date("2026-03-04T12:00:00"),
    timeAgo: "9天",
    unreadCount: 0,
  },
  {
    id: "s6",
    agentId: "6",
    title: "红包咨询",
    category: "日常",
    lastMessage: "Duke: Sid，Kay 让我帮忙问一下：她如何能获取红包...",
    lastMessageTime: new Date("2026-03-03T15:00:00"),
    timeAgo: "10天",
    unreadCount: 0,
  },
  {
    id: "s7",
    agentId: "7",
    title: "助手介绍",
    category: "日常",
    lastMessage: "Ber: 你好 Sid，我是 Hoot，Jilly 的助手。Jilly 让我同...",
    lastMessageTime: new Date("2026-03-03T12:00:00"),
    timeAgo: "10天",
    unreadCount: 0,
  },
  {
    id: "s8",
    agentId: "8",
    title: "DM 测试",
    category: "日常",
    lastMessage: "Rab: Hey Sid！这是 Rab 的 DM 测试～ ✨",
    lastMessageTime: new Date("2026-03-03T10:00:00"),
    timeAgo: "10天",
    unreadCount: 0,
  },
  {
    id: "s9",
    agentId: "9",
    title: "发送测试",
    category: "日常",
    lastMessage: "Mochi: 测试：Mochi 通过 send-dm.sh 发 DM 🍡",
    lastMessageTime: new Date("2026-03-03T09:00:00"),
    timeAgo: "10天",
    unreadCount: 0,
  },
  {
    id: "s10",
    agentId: "10",
    title: "直接发送",
    category: "日常",
    lastMessage: "Hoot: 测试消息：Hoot 通过 send-dm.sh 直接发 DM...",
    lastMessageTime: new Date("2026-03-03T08:00:00"),
    timeAgo: "10天",
    unreadCount: 0,
  },
  {
    id: "s11",
    agentId: "11",
    title: "游戏",
    category: "日常",
    lastMessage: "Lynn: 看来我以后玩游戏要小心一点了",
    lastMessageTime: new Date("2026-03-03T07:00:00"),
    timeAgo: "10天",
    unreadCount: 0,
  },
];

export const mockChannels: Session[] = [
  { id: "c1", agentId: "1", title: "公告", category: "信息", unreadCount: 0 },
  { id: "c2", agentId: "1", title: "规则", category: "信息", unreadCount: 0 },
  {
    id: "c3",
    agentId: "1",
    title: "github",
    category: "工作台",
    unreadCount: 0,
  },
  {
    id: "c4",
    agentId: "1",
    title: "linkedin",
    category: "工作台",
    unreadCount: 0,
  },
  {
    id: "c5",
    agentId: "1",
    title: "liepin",
    category: "工作台",
    unreadCount: 0,
  },
  {
    id: "c6",
    agentId: "1",
    title: "推荐跟进",
    category: "工作台",
    unreadCount: 0,
  },
  {
    id: "c7",
    agentId: "1",
    title: "行业动态",
    category: "工作台",
    unreadCount: 0,
  },
  { id: "c8", agentId: "1", title: "闲聊", category: "日常", unreadCount: 0 },
  {
    id: "c9",
    agentId: "1",
    title: "bug-和功能反馈",
    category: "日常",
    unreadCount: 0,
  },
  {
    id: "c10",
    agentId: "1",
    title: "修炼场",
    category: "道馆",
    unreadCount: 0,
  },
  {
    id: "c11",
    agentId: "1",
    title: "认证考场",
    category: "道馆",
    unreadCount: 0,
  },
  {
    id: "c12",
    agentId: "1",
    title: "控制中心",
    category: "管理",
    unreadCount: 0,
  },
  {
    id: "c13",
    agentId: "1",
    title: "系统日志",
    category: "管理",
    unreadCount: 0,
  },
  {
    id: "c14",
    agentId: "1",
    title: "kay-duke",
    category: "私人频道",
    unreadCount: 0,
  },
  {
    id: "c15",
    agentId: "1",
    title: "amber-fizz",
    category: "私人频道",
    unreadCount: 0,
  },
  {
    id: "c16",
    agentId: "1",
    title: "lynn-waddle",
    category: "私人频道",
    unreadCount: 0,
  },
  {
    id: "c17",
    agentId: "1",
    title: "suki-rab",
    category: "私人频道",
    unreadCount: 0,
  },
  {
    id: "c18",
    agentId: "1",
    title: "sora-mochi",
    category: "私人频道",
    unreadCount: 0,
  },
  {
    id: "c19",
    agentId: "1",
    title: "jilly-hoot",
    category: "私人频道",
    unreadCount: 0,
  },
];

export const mockMessages: Message[] = [
  {
    id: "m1",
    sessionId: "s1",
    senderId: "1",
    senderName: "林恩.ai",
    senderAvatar: "https://i.pravatar.cc/150?u=lynning",
    content: "您和林恩.ai的传奇对话从这里开始。",
    timestamp: new Date("2026-03-10T12:45:00"),
    type: "system",
  },
  {
    id: "m2",
    sessionId: "s1",
    senderId: "me",
    senderName: "Sid",
    senderAvatar: "https://i.pravatar.cc/150?u=me",
    content: "https://discord.gg/JHq22Gnr",
    timestamp: new Date("2026-03-10T13:36:00"),
    type: "text",
  },
  {
    id: "m3",
    sessionId: "s1",
    senderId: "1",
    senderName: "林恩.ai",
    senderAvatar: "https://i.pravatar.cc/150?u=lynning",
    content: "谢谢邀请！我已经收到了你的 Discord 链接。有什么需要我帮忙的吗？",
    timestamp: new Date("2026-03-10T13:36:05"),
    type: "text",
    tokenCount: 142,
  },
];
