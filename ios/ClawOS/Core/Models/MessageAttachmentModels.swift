import Foundation
import ClawChatKit
import ImageIO
import UniformTypeIdentifiers

enum StoredMessageAttachmentType: String, Codable, Hashable {
    case image
    case video
    case audio
    case file
}

struct StoredMessageAttachment: Identifiable, Codable, Hashable {
    let id: String
    let type: StoredMessageAttachmentType
    let filename: String
    let mimeType: String
    let size: Int

    var iconName: String {
        switch type {
        case .image:
            "photo"
        case .video:
            "video"
        case .audio:
            "waveform"
        case .file:
            "doc"
        }
    }

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

struct ComposerAttachment: Identifiable, Hashable {
    let id: String
    let type: MessageAttachmentType
    let filename: String
    let mimeType: String
    let size: Int
    let dataBase64: String

    var iconName: String {
        switch type {
        case .image:
            "photo"
        case .video:
            "video"
        case .audio:
            "waveform"
        case .file:
            "doc"
        }
    }

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var protocolAttachment: MessageAttachment {
        MessageAttachment(
            type: type,
            mimeType: mimeType,
            filename: filename,
            size: size,
            data: dataBase64
        )
    }

    var storedAttachment: StoredMessageAttachment {
        StoredMessageAttachment(
            id: id,
            type: StoredMessageAttachmentType(rawValue: type.rawValue) ?? .file,
            filename: filename,
            mimeType: mimeType,
            size: size
        )
    }

    nonisolated static func prepared(
        data: Data,
        filename: String,
        mimeType: String,
        type: MessageAttachmentType,
        maxBytes: Int
    ) throws -> ComposerAttachment {
        let normalizedPayload = try normalizedPayload(
            data: data,
            filename: filename,
            mimeType: mimeType,
            type: type,
            maxBytes: maxBytes
        )

        return ComposerAttachment(
            id: UUID().uuidString,
            type: type,
            filename: normalizedPayload.filename,
            mimeType: normalizedPayload.mimeType,
            size: normalizedPayload.data.count,
            dataBase64: normalizedPayload.data.base64EncodedString()
        )
    }

    private struct NormalizedPayload {
        let data: Data
        let filename: String
        let mimeType: String
    }

    nonisolated private static func normalizedPayload(
        data: Data,
        filename: String,
        mimeType: String,
        type: MessageAttachmentType,
        maxBytes: Int
    ) throws -> NormalizedPayload {
        guard data.count > maxBytes else {
            return NormalizedPayload(data: data, filename: filename, mimeType: mimeType)
        }

        guard type == .image else {
            throw ComposerAttachmentPreparationError.tooLarge(
                filename: filename,
                maxBytes: maxBytes
            )
        }

        return try compressedImagePayload(
            data: data,
            filename: filename,
            maxBytes: maxBytes
        )
    }

    nonisolated private static func compressedImagePayload(
        data: Data,
        filename: String,
        maxBytes: Int
    ) throws -> NormalizedPayload {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ComposerAttachmentPreparationError.unreadable(
                "无法读取所选图片。"
            )
        }

        let maxSourceDimension = maxPixelDimension(for: source)
        let dimensionCandidates = [maxSourceDimension, 2048, 1600, 1280, 1024, 768, 512]
            .filter { $0 > 0 }
        let qualities: [Double] = [0.82, 0.72, 0.62, 0.52, 0.42, 0.32]

        for dimension in dimensionCandidates {
            guard let image = downsampledImage(source: source, maxPixelSize: dimension) else { continue }
            for quality in qualities {
                guard let jpegData = jpegData(from: image, quality: quality) else { continue }
                guard jpegData.count <= maxBytes else { continue }

                return NormalizedPayload(
                    data: jpegData,
                    filename: normalizedJPEGFilename(from: filename),
                    mimeType: "image/jpeg"
                )
            }
        }

        throw ComposerAttachmentPreparationError.tooLarge(
            filename: filename,
            maxBytes: maxBytes
        )
    }

    nonisolated private static func maxPixelDimension(for source: CGImageSource) -> CGFloat {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return 0
        }
        let width = properties[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
        return max(width, height)
    }

    nonisolated private static func downsampledImage(
        source: CGImageSource,
        maxPixelSize: CGFloat
    ) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    nonisolated private static func jpegData(from image: CGImage, quality: Double) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    nonisolated private static func normalizedJPEGFilename(from filename: String) -> String {
        let base = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        return base.isEmpty ? "attachment.jpg" : "\(base).jpg"
    }
}

enum ComposerAttachmentPreparationError: LocalizedError {
    case unreadable(String)
    case tooLarge(filename: String, maxBytes: Int)

    var errorDescription: String? {
        switch self {
        case .unreadable(let message):
            return message
        case .tooLarge(let filename, let maxBytes):
            let limit = ByteCountFormatter.string(
                fromByteCount: Int64(maxBytes),
                countStyle: .file
            )
            return "“\(filename)” 超过 \(limit)，当前版本暂不支持。"
        }
    }
}
