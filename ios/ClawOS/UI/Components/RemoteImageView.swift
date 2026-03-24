import SwiftUI
import UIKit
import Combine

@MainActor
final class RemoteImageLoader: ObservableObject {
    private static let cache = NSCache<NSURL, UIImage>()

    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false

    private let url: URL
    private var task: Task<Void, Never>?

    init(url: URL) {
        self.url = url
        self.image = Self.cache.object(forKey: url as NSURL)
    }

    deinit {
        task?.cancel()
    }

    func load() {
        if image != nil || isLoading { return }

        isLoading = true
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }

            defer {
                if !Task.isCancelled {
                    self.isLoading = false
                }
            }

            do {
                var request = URLRequest(url: self.url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 30

                let (data, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled,
                      let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode,
                      let image = UIImage(data: data) else {
                    return
                }

                Self.cache.setObject(image, forKey: self.url as NSURL)
                self.image = image
            } catch {
                if Task.isCancelled { return }
            }
        }
    }
}

struct RemoteImageView<Placeholder: View>: View {
    let url: URL
    let placeholder: (Bool) -> Placeholder

    @StateObject private var loader: RemoteImageLoader

    init(
        url: URL,
        @ViewBuilder placeholder: @escaping (Bool) -> Placeholder
    ) {
        self.url = url
        self.placeholder = placeholder
        _loader = StateObject(wrappedValue: RemoteImageLoader(url: url))
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder(loader.isLoading)
            }
        }
        .task(id: url) {
            loader.load()
        }
    }
}
