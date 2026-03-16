import Foundation

struct TokenUsageStats {
    let total: String
    let input: String
    let output: String
    let cached: String
    let modelBreakdown: [(model: String, tokens: String, progress: Double)]
}

enum TokenUsageService {
    static func fetchUsage(days: Int = 7) async -> TokenUsageStats {
        TokenUsageStats(
            total: "46.8M",
            input: "29.6M",
            output: "84.0K",
            cached: "17.1M",
            modelBreakdown: [
                ("MiniMax-M2.5", "32.1M", 0.7),
                ("Claude 3.5 Sonnet", "14.7M", 0.3),
            ]
        )
    }
}
