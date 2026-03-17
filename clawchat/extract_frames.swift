import AVFoundation
import CoreImage

let videoURL = URL(fileURLWithPath: "/Users/sidqin/Desktop/306357944557901433897dff085876d8.mp4")
let asset = AVAsset(url: videoURL)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true

let duration = try! await asset.load(.duration)
let durationSeconds = CMTimeGetSeconds(duration)

for i in 0..<Int(durationSeconds) {
    let time = CMTime(seconds: Double(i), preferredTimescale: 600)
    let cgImage = try! generator.copyCGImage(at: time, actualTime: nil)
    
    let context = CIContext()
    let ciImage = CIImage(cgImage: cgImage)
    
    let url = URL(fileURLWithPath: "/Users/sidqin/Desktop/frame_\(i).jpg")
    try! context.writeJPEGRepresentation(of: ciImage, to: url, colorSpace: ciImage.colorSpace!)
}
print("Extracted \(Int(durationSeconds)) frames.")
