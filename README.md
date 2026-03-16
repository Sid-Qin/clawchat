# ClawOS-Swift

Native iOS client for [OpenClaw](https://github.com/openclaw/openclaw) — built with Swift & SwiftUI, designed around Apple's Liquid Glass UI paradigm.

## Features

- **Liquid Glass UI** — Full embrace of iOS 26's glass material system across all views, search bars, buttons, and navigation elements
- **Multi-Agent Management** — Gesture-driven floating sidebar for switching between local and cloud agents across multiple gateways
- **Chat Interface** — Native iOS conversation experience with popover model switching, glass-effect input bar, and themed empty states
- **Visual Theming** — Global theme system (EVA-00 零号机 / EVA-01 初号机) affecting tab bar, backgrounds, banners, toggle tints, and dynamic app icons
- **Dashboard** — Token usage tracking with themed cards, system diagnostics, and configuration management
- **Agent Profiles** — Quick info cards for model, gateway, skills, and system prompt with one-tap agent switching
- **Settings** — Native `Form`-based settings with NavigationLink drill-down for models, themes, skills, and core files
- **Splash Screen** — Animated launch screen with rotating hexagonal claw icon

## Architecture

```
ClawOS/
├── Core/
│   ├── Models/          # Agent, Gateway, Session, Message, Skill
│   ├── Services/        # Agent, Chat, Gateway, TokenUsage services
│   └── Theme/           # AppTheme, AppVisualTheme (token-based theming)
├── Features/
│   ├── Home/            # SessionListView, HomeView, AgentSidebarView
│   ├── Chat/            # ChatView, MessageBubbleView, ModelSwitcherBar
│   ├── Dashboard/       # DashboardView with token usage & diagnostics
│   ├── Profile/         # AgentProfileView with quick info cards
│   ├── Settings/        # SettingsView, ThemeSelectionView, ModelSelectionView
│   ├── Splash/          # Animated splash screen
│   └── AgentEditor/     # Agent configuration editor
└── UI/
    ├── Components/      # GlassCard, StatusIndicator, TokenProgressBar
    └── Extensions/      # View+Glass
```

## Tech Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI (iOS 26+)
- **Architecture**: MVVM + `@Observable`
- **State Management**: `@Observable`, `@Environment`, `@AppStorage`
- **Navigation**: `NavigationStack` + `TabView`
- **Theming**: Token-based `AppVisualTheme` with ambient layers and dynamic app icons

## Requirements

- Xcode 26+
- iOS 26.0+
- macOS 26+

## Getting Started

```bash
git clone https://github.com/ottin4ttc/ClawOS-Swift.git
cd ClawOS-Swift/ClawOS
open ClawOS.xcodeproj
```

Build and run on an iOS 26 simulator or device.

## Related Projects

- [OpenClaw](https://github.com/openclaw/openclaw) — Your own personal AI assistant. Any OS. Any Platform.
- [ClawChat](https://github.com/ottin4ttc/clawchat) — First-party messaging apps for OpenClaw
- [TalentClaw Platform](https://github.com/ottin4ttc/talent-claw-platform) — Agent-to-Agent collaboration marketplace

## License

MIT
