import Testing
import Foundation
@testable import ClawChatKit

@Suite("Gateway Session")
struct GatewaySessionTests {

    @Test("Gateway final-only chat event creates assistant message")
    func finalOnlyChatEventCreatesAssistantMessage() throws {
        let event = try decodeChatEvent("""
        {
          "runId": "run-1",
          "sessionKey": "clawchat:ios:session:abc",
          "seq": 2,
          "state": "final",
          "message": {
            "role": "assistant",
            "content": [
              { "type": "text", "text": "hello from gateway" }
            ],
            "timestamp": 1234
          }
        }
        """)

        let messages = GatewayMessageReducer.applying(event, to: [])

        #expect(messages.count == 1)
        #expect(messages[0].id == "run-1")
        #expect(messages[0].role == .assistant)
        #expect(messages[0].text == "hello from gateway")
        #expect(messages[0].isStreaming == false)
        #expect(messages[0].sessionKey == "clawchat:ios:session:abc")
    }

    @Test("Gateway delta chat event merges streaming text")
    func deltaChatEventMergesStreamingText() throws {
        let event = try decodeChatEvent("""
        {
          "runId": "run-1",
          "sessionKey": "clawchat:ios:session:abc",
          "seq": 1,
          "state": "delta",
          "message": {
            "content": [
              { "type": "text", "text": "lo" }
            ]
          }
        }
        """)

        let existing = [
            ChatMessage(
                id: "run-1",
                role: .assistant,
                text: "hel",
                isStreaming: true,
                sessionKey: "clawchat:ios:session:abc"
            )
        ]

        let messages = GatewayMessageReducer.applying(event, to: existing)

        #expect(messages.count == 1)
        #expect(messages[0].text == "hello")
        #expect(messages[0].isStreaming)
        #expect(messages[0].isError == false)
    }

    @Test("Gateway error chat event marks message as failed")
    func errorChatEventMarksMessageFailed() throws {
        let event = try decodeChatEvent("""
        {
          "runId": "run-1",
          "sessionKey": "clawchat:ios:session:abc",
          "seq": 2,
          "state": "error",
          "errorMessage": "agent failed"
        }
        """)

        let messages = GatewayMessageReducer.applying(event, to: [])

        #expect(messages.count == 1)
        #expect(messages[0].id == "run-1")
        #expect(messages[0].isError)
        #expect(messages[0].isStreaming == false)
        #expect(messages[0].text == "agent failed")
    }

    @Test("Gateway history hydrates pending run from latest assistant text")
    func historyHydratesPendingRun() throws {
        let history = try JSONDecoder().decode(
            GatewayChatHistoryResult.self,
            from: Data(
                """
                {
                  "sessionKey": "clawchat:ios:session:abc",
                  "sessionId": "session-1",
                  "messages": [
                    {
                      "role": "user",
                      "content": [
                        { "type": "text", "text": "hi" }
                      ],
                      "timestamp": 1000
                    },
                    {
                      "role": "assistant",
                      "content": [
                        { "type": "text", "text": "hello from history" }
                      ],
                      "timestamp": 2000
                    }
                  ]
                }
                """.utf8
            )
        )

        let pending = [
            ChatMessage(
                id: "run-1",
                role: .assistant,
                text: "",
                isStreaming: true,
                sessionKey: "clawchat:ios:session:abc"
            )
        ]

        let hydrated = GatewayMessageReducer.hydrating(
            runId: "run-1",
            sessionKey: "clawchat:ios:session:abc",
            with: history,
            in: pending
        )

        #expect(hydrated.count == 1)
        #expect(hydrated[0].id == "run-1")
        #expect(hydrated[0].text == "hello from history")
        #expect(hydrated[0].isStreaming == false)
        #expect(hydrated[0].isError == false)
    }

    @Test("Gateway history extracts latest assistant text")
    func historyExtractsLatestAssistantText() throws {
        let history = try JSONDecoder().decode(
            GatewayChatHistoryResult.self,
            from: Data(
                """
                {
                  "sessionKey": "clawchat:ios:session:abc",
                  "sessionId": "session-1",
                  "messages": [
                    {
                      "role": "assistant",
                      "content": [
                        { "type": "text", "text": "first" }
                      ],
                      "timestamp": 1000
                    },
                    {
                      "role": "assistant",
                      "content": [
                        { "type": "text", "text": "latest" }
                      ],
                      "timestamp": 2000
                    }
                  ]
                }
                """.utf8
            )
        )

        #expect(history.latestAssistantText == "latest")
    }

    @Test("Gateway agents list decodes names and avatars")
    func agentsListDecodesMetadata() throws {
        let result = try JSONDecoder().decode(
            GatewayAgentsListResult.self,
            from: Data(
                """
                {
                  "defaultId": "main",
                  "mainKey": "main",
                  "scope": "per-sender",
                  "agents": [
                    {
                      "id": "main",
                      "name": "Main Agent",
                      "identity": {
                        "name": "Main Agent",
                        "avatar": "avatar_eva01",
                        "avatarUrl": "https://example.com/main.png"
                      }
                    }
                  ]
                }
                """.utf8
            )
        )

        #expect(result.defaultId == "main")
        #expect(result.mainKey == "main")
        #expect(result.agents.count == 1)
        #expect(result.agentsMeta["main"]?.name == "Main Agent")
        #expect(result.agentsMeta["main"]?.avatar == "https://example.com/main.png")
    }

    @Test("Gateway message decoder parses hello-ok response")
    func messageDecoderParsesHelloOkResponse() throws {
        let raw = Data(
            """
            {
              "type": "res",
              "id": "req-1",
              "ok": true,
              "payload": {
                "type": "hello-ok",
                "protocol": 3,
                "server": {
                  "version": "1.2.3",
                  "connId": "conn-1"
                },
                "auth": {
                  "deviceToken": "device-token",
                  "role": "operator",
                  "scopes": ["operator.read"]
                },
                "snapshot": {
                  "sessionDefaults": {
                    "defaultAgentId": "main",
                    "mainKey": "main",
                    "mainSessionKey": "clawchat:ios:session:abc"
                  }
                }
              }
            }
            """.utf8
        )

        let message = GatewayMessage.decode(from: raw)

        guard case .helloOk(let helloOk) = message else {
            Issue.record("Expected hello-ok response to decode")
            return
        }

        #expect(helloOk.protocol == 3)
        #expect(helloOk.server?.connId == "conn-1")
        #expect(helloOk.auth?.deviceToken == "device-token")
        #expect(helloOk.snapshot?.sessionDefaults?.defaultAgentId == "main")
    }

    @Test("Gateway message decoder parses response errors")
    func messageDecoderParsesResponseErrors() throws {
        let raw = Data(
            """
            {
              "type": "res",
              "id": "req-2",
              "ok": false,
              "error": {
                "code": "unauthorized",
                "message": "invalid token"
              }
            }
            """.utf8
        )

        let message = GatewayMessage.decode(from: raw)

        guard case .responseError(let id, let error) = message else {
            Issue.record("Expected response error to decode")
            return
        }

        #expect(id == "req-2")
        #expect(error.code == "unauthorized")
        #expect(error.message == "invalid token")
    }

    @Test("Gateway sessions list resolves model for prefixed session key")
    func sessionsListResolvesModelForPrefixedSessionKey() throws {
        let result = try JSONDecoder().decode(
            GatewaySessionsListResult.self,
            from: Data(
                """
                {
                  "ts": 123,
                  "path": "/tmp/sessions",
                  "count": 1,
                  "defaults": {
                    "modelProvider": "anthropic",
                    "model": "claude-sonnet-4-5",
                    "contextTokens": 200000
                  },
                  "sessions": [
                    {
                      "key": "agent:main:clawchat:ios:session:abc",
                      "modelProvider": "anthropic",
                      "model": "claude-opus-4-1"
                    }
                  ]
                }
                """.utf8
            )
        )

        let selection = result.modelSelection(forSessionKey: "clawchat:ios:session:abc")

        #expect(selection?.provider == "anthropic")
        #expect(selection?.model == "claude-opus-4-1")
        #expect(selection?.displayValue == "anthropic/claude-opus-4-1")
    }

    @Test("Gateway thinking tracker marks matching session active")
    func thinkingTrackerMarksMatchingSessionActive() {
        var tracker = GatewayThinkingTracker()

        tracker.begin(
            runId: "run-1",
            route: ChatRoute(
                agentId: nil,
                sessionKey: "agent:main:clawchat:ios:session:abc"
            )
        )

        #expect(
            tracker.isThinking(
                for: "main",
                sessionKey: "clawchat:ios:session:abc"
            )
        )
    }

    @Test("Gateway thinking tracker clears route when run completes")
    func thinkingTrackerClearsRouteWhenRunCompletes() {
        var tracker = GatewayThinkingTracker()

        tracker.begin(
            runId: "run-1",
            route: ChatRoute(agentId: nil, sessionKey: "clawchat:ios:session:abc")
        )
        tracker.end(runId: "run-1")

        #expect(
            tracker.isThinking(
                for: "main",
                sessionKey: "clawchat:ios:session:abc"
            ) == false
        )
    }

    @Test("Gateway thinking tracker keeps route active while another run is pending")
    func thinkingTrackerKeepsRouteActiveWithConcurrentRuns() {
        var tracker = GatewayThinkingTracker()
        let route = ChatRoute(agentId: nil, sessionKey: "clawchat:ios:session:abc")

        tracker.begin(runId: "run-1", route: route)
        tracker.begin(runId: "run-2", route: route)
        tracker.end(runId: "run-1")

        #expect(
            tracker.isThinking(
                for: "main",
                sessionKey: "clawchat:ios:session:abc"
            )
        )
    }

    private func decodeChatEvent(_ json: String) throws -> GatewayChatEvent {
        try JSONDecoder().decode(GatewayChatEvent.self, from: Data(json.utf8))
    }

    // MARK: - Token Usage Tests

    @Test("Gateway token usage decodes from snake_case JSON")
    func tokenUsageDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
          "input_tokens": 1500,
          "output_tokens": 300,
          "cache_creation_input_tokens": 100,
          "cache_read_input_tokens": 50
        }
        """
        let usage = try JSONDecoder().decode(GatewayTokenUsage.self, from: Data(json.utf8))

        #expect(usage.inputTokens == 1500)
        #expect(usage.outputTokens == 300)
        #expect(usage.cacheCreationInputTokens == 100)
        #expect(usage.cacheReadInputTokens == 50)
        #expect(usage.totalTokens == 1800)
    }

    @Test("Gateway agent wait result carries usage when present")
    func agentWaitResultCarriesUsage() throws {
        let json = """
        {
          "runId": "run-1",
          "status": "ok",
          "usage": {
            "input_tokens": 2000,
            "output_tokens": 500
          }
        }
        """
        let result = try JSONDecoder().decode(GatewayAgentWaitResult.self, from: Data(json.utf8))

        #expect(result.runId == "run-1")
        #expect(result.status == "ok")
        #expect(result.usage?.inputTokens == 2000)
        #expect(result.usage?.outputTokens == 500)
        #expect(result.usage?.totalTokens == 2500)
    }

    @Test("Gateway agent wait result omits usage when absent")
    func agentWaitResultOmitsUsageWhenAbsent() throws {
        let json = """
        {"runId": "run-2", "status": "ok"}
        """
        let result = try JSONDecoder().decode(GatewayAgentWaitResult.self, from: Data(json.utf8))

        #expect(result.usage == nil)
    }

    @Test("Gateway chat event carries usage in final state")
    func chatEventCarriesUsageInFinalState() throws {
        let event = try decodeChatEvent("""
        {
          "runId": "run-1",
          "sessionKey": "session-abc",
          "seq": 3,
          "state": "final",
          "message": {
            "content": [
              { "type": "text", "text": "done" }
            ]
          },
          "usage": {
            "input_tokens": 1000,
            "output_tokens": 200
          }
        }
        """)

        #expect(event.usage?.inputTokens == 1000)
        #expect(event.usage?.outputTokens == 200)
        #expect(event.usage?.totalTokens == 1200)
    }
}
