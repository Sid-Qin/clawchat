import Foundation

struct GatewayThinkingTracker {
    private var routeByRunId: [String: ChatRoute] = [:]
    private var runIdsByRoute: [ChatRoute: Set<String>] = [:]

    var hasActiveRuns: Bool {
        runIdsByRoute.values.contains { !$0.isEmpty }
    }

    mutating func begin(runId: String, route: ChatRoute) {
        if let previousRoute = routeByRunId[runId], previousRoute != route {
            remove(runId: runId, from: previousRoute)
        }

        routeByRunId[runId] = route
        var runIds = runIdsByRoute[route] ?? []
        runIds.insert(runId)
        runIdsByRoute[route] = runIds
    }

    mutating func end(runId: String) {
        guard let route = routeByRunId.removeValue(forKey: runId) else { return }
        remove(runId: runId, from: route)
    }

    mutating func clear() {
        routeByRunId.removeAll()
        runIdsByRoute.removeAll()
    }

    func isThinking(for agentId: String, sessionKey: String?) -> Bool {
        runIdsByRoute.contains { route, runIds in
            !runIds.isEmpty && route.matches(targetAgentId: agentId, targetSessionKey: sessionKey)
        }
    }

    private mutating func remove(runId: String, from route: ChatRoute) {
        guard var runIds = runIdsByRoute[route] else { return }
        runIds.remove(runId)
        if runIds.isEmpty {
            runIdsByRoute.removeValue(forKey: route)
        } else {
            runIdsByRoute[route] = runIds
        }
    }
}
