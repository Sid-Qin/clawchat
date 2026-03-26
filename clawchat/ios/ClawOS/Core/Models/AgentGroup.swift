import Foundation

struct AgentGroup: Identifiable, Codable, Hashable {
    static let defaultName = "Agent Team"

    let id: String
    var name: String
    var agentIds: [String]

    var displayName: String {
        Self.normalizedName(name)
    }

    init(id: String = UUID().uuidString, name: String = AgentGroup.defaultName, agentIds: [String]) {
        self.id = id
        self.name = Self.normalizedName(name)
        self.agentIds = agentIds
    }

    static func normalizedName(_ rawName: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "Group" {
            return defaultName
        }
        return trimmed
    }
}

enum AgentStripItem: Identifiable, Codable, Hashable {
    case single(agentId: String)
    case group(AgentGroup)

    var id: String {
        switch self {
        case .single(let agentId): return agentId
        case .group(let group): return "group_\(group.id)"
        }
    }

    var containedAgentIds: [String] {
        switch self {
        case .single(let agentId): return [agentId]
        case .group(let group): return group.agentIds
        }
    }

    var isSingle: Bool {
        if case .single = self { return true }
        return false
    }
}
