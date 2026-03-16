import SwiftUI

@Observable
final class AppState {
    var agents: [Agent] = MockData.agents
    var gateways: [Gateway] = MockData.gateways
    var sessions: [Session] = MockData.sessions
    var messages: [Message] = MockData.messages
    var skills: [Skill] = MockData.skills

    var selectedAgentId: String = "1"
    var selectedGatewayId: String = "g1"
    var selectedVisualThemeID: AppVisualThemeID = .eva00

    var selectedAgent: Agent? {
        agents.first { $0.id == selectedAgentId }
    }

    var currentVisualTheme: AppVisualTheme {
        AppVisualTheme.theme(for: selectedVisualThemeID)
    }

    var currentGateway: Gateway? {
        gateways.first { $0.id == selectedGatewayId }
    }

    var currentGatewayType: GatewayType {
        currentGateway?.type ?? .local
    }

    var currentGatewayAgents: [Agent] {
        agents.filter { $0.gatewayId == selectedGatewayId }
    }

    func selectGateway(_ id: String) {
        selectedGatewayId = id
        let visible = currentGatewayAgents
        if !visible.contains(where: { $0.id == selectedAgentId }),
           let first = visible.first {
            selectedAgentId = first.id
        }
    }

    func agent(for id: String) -> Agent? {
        agents.first { $0.id == id }
    }

    func sessions(for agentId: String) -> [Session] {
        sessions.filter { $0.agentId == agentId }
    }

    func messages(for sessionId: String) -> [Message] {
        messages.filter { $0.sessionId == sessionId }
    }
}
