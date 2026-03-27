import SwiftUI
import ClawChatKit

// MARK: - Deep Link Parser

enum PairingDeepLink {
    enum ParsedLink {
        case relay(relay: String, code: String)
        case gateway(url: String, token: String)
    }

    static func parse(_ url: URL) -> ParsedLink? {
        guard url.scheme == "clawchat" else { return nil }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []

        switch url.host {
        case "pair":
            guard let relay = items.first(where: { $0.name == "relay" })?.value,
                  let code = items.first(where: { $0.name == "code" })?.value else { return nil }
            return .relay(relay: relay, code: code)

        case "gateway":
            guard let gatewayUrl = items.first(where: { $0.name == "url" })?.value,
                  let token = items.first(where: { $0.name == "token" })?.value else { return nil }
            return .gateway(url: gatewayUrl, token: token)

        default:
            return nil
        }
    }
}

// MARK: - Floating Card Overlay (used at app root)

struct PairingOverlay: View {
    @Environment(AppState.self) private var appState
    @Namespace private var glassNS

    private var shouldShow: Bool {
        appState.showPairing
    }

    var body: some View {
        ZStack {
            if shouldShow {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        hideKeyboard()
                    }

                ConnectionCardView()
                    .environment(appState)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .padding(.horizontal, 24)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: shouldShow)
    }
}

// MARK: - Connection Card (dual-mode)

struct ConnectionCardView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedMode: ConnectionMethod = .direct
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showScanner = false

    // Gateway direct fields
    @State private var gatewayUrl = ""
    @State private var gatewayToken = ""
    @State private var showToken = false

    // Relay pairing fields
    @State private var relayUrl = "ws://192.168.120.142:8787"
    @State private var pairingCode = ""

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case gatewayUrl, gatewayToken
        case relayUrl, relayCode
    }

    private var accent: Color {
        appState.currentVisualTheme.accent
    }

    private var rawCode: String {
        pairingCode.replacingOccurrences(of: "-", with: "")
    }

    private var isFormValid: Bool {
        switch selectedMode {
        case .direct:
            return !gatewayUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !gatewayToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .relay:
            return !relayUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && rawCode.count >= 6
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                headerArea
                    .padding(.top, 32)
                    .padding(.bottom, 20)

                modePicker
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                formArea
                    .padding(.horizontal, 24)

                if let errorMessage {
                    errorBanner(errorMessage)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

                buttonArea
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 12)
            }
            .padding(.bottom, 20)

            if appState.clawChatManager.hasSavedConnection || !appState.gateways.isEmpty {
                closeButton
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.regularMaterial)
        )
        .adaptiveGlass(in: .rect(cornerRadius: 36))
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                .blendMode(.overlay)
        )
        .shadow(color: .black.opacity(0.15), radius: 40, y: 20)
        .shadow(color: .black.opacity(0.08), radius: 15, y: 8)
        .onTapGesture { hideKeyboard() }
        .sheet(isPresented: $showScanner) {
            QRScannerSheet { parsed in
                handleScannedLink(parsed)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .clawChatDeepLink)) { notification in
            if let relay = notification.userInfo?["relay"] as? String,
               let code = notification.userInfo?["code"] as? String {
                handleRelayDeepLink(relay, code)
            } else if let url = notification.userInfo?["gatewayUrl"] as? String,
                      let token = notification.userInfo?["gatewayToken"] as? String {
                handleGatewayDeepLink(url, token)
            }
        }
    }

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 16) {
            Image("clawos_svg_logo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundStyle(accent)

            VStack(spacing: 6) {
                Text("连接 Gateway")
                    .font(.title3.weight(.bold))

                Text(selectedMode == .direct
                     ? "输入 Gateway 地址和 Token"
                     : "扫描二维码或手动输入配对信息")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .animation(.none, value: selectedMode)
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("连接方式", selection: $selectedMode) {
            Text("Gateway 直连").tag(ConnectionMethod.direct)
            Text("Relay 配对").tag(ConnectionMethod.relay)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedMode) { _, _ in
            errorMessage = nil
        }
    }

    // MARK: - Form

    @ViewBuilder
    private var formArea: some View {
        switch selectedMode {
        case .direct:
            gatewayForm
        case .relay:
            relayForm
        }
    }

    private var gatewayForm: some View {
        VStack(spacing: 16) {
            fieldRow(
                label: "Gateway 地址",
                placeholder: "wss://gateway.example.com",
                text: $gatewayUrl,
                keyboard: .URL,
                field: .gatewayUrl,
                isSecure: false
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Token")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                HStack {
                    Group {
                        if showToken {
                            TextField("粘贴你的 Gateway Token", text: $gatewayToken)
                                .textFieldStyle(.plain)
                        } else {
                            SecureField("粘贴你的 Gateway Token", text: $gatewayToken)
                                .textFieldStyle(.plain)
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .gatewayToken)

                    Button {
                        showToken.toggle()
                    } label: {
                        Image(systemName: showToken ? "eye.slash" : "eye")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        .blendMode(.overlay)
                )
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .gatewayToken }
            }
        }
    }

    private var relayForm: some View {
        VStack(spacing: 16) {
            fieldRow(
                label: "Relay 地址",
                placeholder: "wss://relay.clawchat.dev",
                text: $relayUrl,
                keyboard: .URL,
                field: .relayUrl,
                isSecure: false
            )

            fieldRow(
                label: "配对码",
                placeholder: "ABC-123",
                text: $pairingCode,
                keyboard: .asciiCapable,
                field: .relayCode,
                isSecure: false,
                monospaced: true
            )
            .onChange(of: pairingCode) { _, newValue in
                let cleaned = newValue.replacingOccurrences(of: "-", with: "")
                let capped = String(cleaned.prefix(6)).uppercased()
                if capped.count > 3 {
                    pairingCode = String(capped.prefix(3)) + "-" + String(capped.dropFirst(3))
                } else {
                    pairingCode = capped
                }
            }
        }
    }

    private func fieldRow(
        label: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        field: Field,
        isSecure: Bool,
        monospaced: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            HStack {
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(monospaced ? .system(.body, design: .monospaced, weight: .semibold) : .body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(monospaced ? .characters : .never)
                    .keyboardType(keyboard)
                    .focused($focusedField, equals: field)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    .blendMode(.overlay)
            )
            .contentShape(Rectangle())
            .onTapGesture { focusedField = field }
        }
    }

    // MARK: - Actions

    private var buttonArea: some View {
        HStack(spacing: 12) {
            Button {
                hideKeyboard()
                showScanner = true
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .foregroundStyle(.white)
                    .background(
                        accent.opacity(0.8),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .blendMode(.overlay)
                    )
            }
            .disabled(isConnecting)

            Button {
                hideKeyboard()
                Task { await startConnection() }
            } label: {
                Group {
                    if isConnecting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(selectedMode == .direct ? "连接" : "开始配对")
                        .font(.headline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background(
                    isFormValid ? accent : Color.gray.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .blendMode(.overlay)
                )
            }
            .disabled(!isFormValid || isConnecting)
            .shadow(color: isFormValid ? accent.opacity(0.3) : .clear, radius: 10, y: 4)
        }
    }

    private var closeButton: some View {
        Button {
            hideKeyboard()
            withAnimation { appState.showPairing = false }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(.regularMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                        .blendMode(.overlay)
                )
        }
        .buttonStyle(.plain)
        .padding(16)
    }

    // MARK: - Error

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption.weight(.medium))
            .foregroundStyle(.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.red.opacity(0.2), lineWidth: 1)
            )
    }

    // MARK: - Connection Logic

    private func startConnection() async {
        errorMessage = nil
        isConnecting = true

        do {
            switch selectedMode {
            case .direct:
                var url = gatewayUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                if !url.hasPrefix("ws://") && !url.hasPrefix("wss://") {
                    url = "wss://\(url)"
                }
                try await appState.clawChatManager.connectGateway(
                    url: url,
                    token: gatewayToken.trimmingCharacters(in: .whitespacesAndNewlines)
                )

            case .relay:
                var url = relayUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                if !url.hasPrefix("ws://") && !url.hasPrefix("wss://") {
                    url = "wss://\(url)"
                }
                try await appState.clawChatManager.pair(
                    relayUrl: url,
                    code: rawCode.trimmingCharacters(in: .whitespacesAndNewlines),
                    deviceName: UIDevice.current.name
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
    }

    // MARK: - Deep Link Handlers

    private func handleRelayDeepLink(_ relay: String, _ code: String) {
        selectedMode = .relay
        relayUrl = relay
        let cleaned = code.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
        if cleaned.count > 3 {
            pairingCode = String(cleaned.prefix(3)) + "-" + String(cleaned.dropFirst(3))
        } else {
            pairingCode = String(cleaned)
        }
        Task { await startConnection() }
    }

    private func handleGatewayDeepLink(_ url: String, _ token: String) {
        selectedMode = .direct
        gatewayUrl = url
        gatewayToken = token
    }

    private func handleScannedLink(_ parsed: PairingDeepLink.ParsedLink) {
        switch parsed {
        case .relay(let relay, let code):
            handleRelayDeepLink(relay, code)
        case .gateway(let url, let token):
            handleGatewayDeepLink(url, token)
        }
    }
}

// MARK: - QR Scanner Sheet

private struct QRScannerSheet: View {
    let onParsed: (PairingDeepLink.ParsedLink) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                QRScannerView { scannedValue in
                    handleScanned(scannedValue)
                }
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.red.opacity(0.8), in: Capsule())
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("扫描二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func handleScanned(_ value: String) {
        guard let url = URL(string: value),
              let parsed = PairingDeepLink.parse(url) else {
            errorMessage = "无效的二维码"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                errorMessage = nil
            }
            return
        }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onParsed(parsed)
        }
    }
}

// MARK: - Helpers

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
