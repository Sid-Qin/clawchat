import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    let session: Session
    @State private var inputText = ""
    @State private var selectedModel = "MiniMax-M2.5"
    @State private var isModelPickerPresented = false
    @State private var shouldRestoreInputFocus = false
    @FocusState private var isInputFocused: Bool

    private var agent: Agent? {
        appState.agent(for: session.agentId)
    }

    private var chatMessages: [Message] {
        appState.messages(for: session.id)
    }

    private var hasInput: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedModelChipTitle: String {
        switch selectedModel {
        case let model where model.contains("MiniMax"):
            "MiniMax"
        case let model where model.contains("Claude"):
            "Sonnet"
        default:
            selectedModel
        }
    }

    private var currentTheme: AppVisualTheme {
        appState.currentVisualTheme
    }

    private var panelButtonFill: Color {
        currentTheme.softFill
    }

    private var panelButtonStroke: Color {
        currentTheme.softStroke
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                messageArea
                inputBar
            }

            if chatMessages.isEmpty {
                emptyStateOverlay
                    .allowsHitTesting(false)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .background(.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            selectedModel = agent?.model ?? "MiniMax-M2.5"
        }
    }

    // MARK: - Messages

    private var messageArea: some View {
        ScrollView {
            if !chatMessages.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(chatMessages) { message in
                        MessageBubbleView(message: message, agentName: agent?.name ?? "Agent")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .scrollDismissesKeyboard(.interactively)
        .defaultScrollAnchor(.bottom)
        .animation(.easeOut(duration: 0.25), value: chatMessages.count)
        .simultaneousGesture(
            TapGesture().onEnded {
                isInputFocused = false
                withAnimation(.easeOut(duration: 0.16)) {
                    isModelPickerPresented = false
                }
            }
        )
    }

    private var emptyStateOverlay: some View {
        GeometryReader { geo in
            let logoY = isInputFocused ? geo.size.height * 0.24 : geo.size.height * 0.34

            Group {
                if let themeLogo = currentTheme.themeLogoAssetName {
                    Image(themeLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .opacity(0.35)
                } else {
                    Image("clawos_watermark")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(currentTheme.logoTint)
                }
            }
            .position(x: geo.size.width / 2, y: logoY)
            .animation(.easeOut(duration: 0.22), value: isInputFocused)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                inputFieldArea

                HStack(spacing: 8) {
                    Button { } label: {
                        Image(systemName: "paperclip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(panelButtonFill)
                                    .overlay(
                                        Circle()
                                            .stroke(panelButtonStroke, lineWidth: 0.8)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    modelChip

                    Spacer()

                    if hasInput {
                        sendButton
                    } else {
                        Button { } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Speak")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(Color.black, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
            )
            .overlay(alignment: .topLeading) {
                if isModelPickerPresented {
                    modelPickerPanel
                        .offset(x: 52, y: -170)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottomLeading)))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var inputFieldArea: some View {
        TextField("Ask Anything", text: $inputText, axis: .vertical)
            .lineLimit(1...6)
            .textFieldStyle(.plain)
            .font(.body)
            .focused($isInputFocused)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.16)) {
                    isModelPickerPresented = false
                }
                DispatchQueue.main.async {
                    isInputFocused = true
                }
            }
    }

    // MARK: - Model Chip

    private var modelChip: some View {
        Button {
            shouldRestoreInputFocus = isInputFocused
            withAnimation(.easeOut(duration: 0.16)) {
                isModelPickerPresented.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(selectedModelChipTitle)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .frame(minWidth: 106)
            .background(
                Capsule()
                    .fill(panelButtonFill)
                    .overlay(
                        Capsule()
                            .stroke(panelButtonStroke, lineWidth: 0.8)
                    )
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var modelPickerPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(MockData.availableModels, id: \.self) { model in
                Button {
                    selectedModel = model
                    withAnimation(.easeOut(duration: 0.14)) {
                        isModelPickerPresented = false
                    }
                    if shouldRestoreInputFocus {
                        DispatchQueue.main.async {
                            isInputFocused = true
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: modelIcon(for: model))
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 18)
                            .foregroundStyle(.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(modelDisplayTitle(for: model))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(modelSubtitle(for: model))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 12)

                        if model == selectedModel {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if model != MockData.availableModels.last {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .frame(maxWidth: 264)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.28))

                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    Color.white.opacity(0.08),
                                    Color.clear,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 56)

                    Spacer(minLength: 0)
                }

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.92),
                                Color.white.opacity(0.46),
                                Color.white.opacity(0.78),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .white.opacity(0.22), radius: 10, y: -1)
            .shadow(color: .black.opacity(0.10), radius: 18, y: 8)
        }
    }

    private func modelDisplayTitle(for model: String) -> String {
        switch model {
        case let value where value.contains("MiniMax"):
            "MiniMax"
        case let value where value.contains("Claude"):
            "Sonnet"
        default:
            model
        }
    }

    private func modelSubtitle(for model: String) -> String {
        switch model {
        case let value where value.contains("MiniMax"):
            "Balanced speed and reasoning"
        case let value where value.contains("Claude"):
            "Thinks harder"
        case let value where value.contains("GPT"):
            "Fast general responses"
        default:
            "Available model"
        }
    }

    private func modelIcon(for model: String) -> String {
        switch model {
        case let value where value.contains("MiniMax"):
            "bolt"
        case let value where value.contains("Claude"):
            "brain.head.profile"
        case let value where value.contains("GPT"):
            "sparkles"
        default:
            "circle.grid.2x2"
        }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button { } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 32, height: 32)
                .background(Color(.label), in: Circle())
        }
        .buttonStyle(.plain)
        .transition(.scale.combined(with: .opacity))
    }
}
