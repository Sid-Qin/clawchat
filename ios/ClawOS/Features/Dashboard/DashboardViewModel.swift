import Foundation

struct MockMoment: Identifiable {
    let id: String
    let title: String
    let content: String
    /// Asset image names (local) or URL strings (remote)
    let images: [String]
    let authorName: String
    /// Asset image name for avatar
    let authorAvatar: String
    let likes: Int
    let comments: Int
    let isLiked: Bool
    let isFollowed: Bool
}

@Observable
final class DashboardViewModel {
    var selectedPeriod = 0
    var isRefreshing = false
    var selectedMomentId: String?

    var moments: [MockMoment] = []

    func refresh() async {
        isRefreshing = true
        try? await Task.sleep(for: .milliseconds(600))
        isRefreshing = false
    }
}
