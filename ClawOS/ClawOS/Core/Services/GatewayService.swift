import Foundation

enum GatewayService {
    static func fetchGateways() async -> [Gateway] {
        MockData.gateways
    }
}
