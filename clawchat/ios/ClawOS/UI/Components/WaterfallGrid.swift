import SwiftUI

/// Masonry / waterfall grid layout (Xiaohongshu-style).
/// Distributes child views into N columns, always placing the next item
/// into the shortest column to keep heights balanced.
struct WaterfallGrid: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 10

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? 300
        let colWidth = columnWidth(for: width)
        var heights = Array(repeating: CGFloat.zero, count: columns)

        for subview in subviews {
            let col = shortestColumn(heights)
            let size = subview.sizeThatFits(.init(width: colWidth, height: nil))
            heights[col] += size.height + spacing
        }

        let maxH = heights.max() ?? 0
        return CGSize(width: width, height: max(maxH - spacing, 0))
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let colWidth = columnWidth(for: bounds.width)
        var heights = Array(repeating: CGFloat.zero, count: columns)

        for subview in subviews {
            let col = shortestColumn(heights)
            let x = bounds.minX + CGFloat(col) * (colWidth + spacing)
            let y = bounds.minY + heights[col]
            let size = subview.sizeThatFits(.init(width: colWidth, height: nil))

            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: .init(width: colWidth, height: size.height)
            )
            heights[col] += size.height + spacing
        }
    }

    private func columnWidth(for totalWidth: CGFloat) -> CGFloat {
        let gaps = CGFloat(columns - 1) * spacing
        return (totalWidth - gaps) / CGFloat(columns)
    }

    private func shortestColumn(_ heights: [CGFloat]) -> Int {
        var minIdx = 0
        for i in 1..<heights.count {
            if heights[i] < heights[minIdx] { minIdx = i }
        }
        return minIdx
    }
}
