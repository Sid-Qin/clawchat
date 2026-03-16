import Foundation

enum AgentService {
    static func fetchAgents() async -> [Agent] {
        MockData.agents
    }
}
