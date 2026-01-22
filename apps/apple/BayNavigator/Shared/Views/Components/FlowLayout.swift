import SwiftUI

/// A simple flow layout for wrapping content horizontally
/// Automatically wraps items to the next line when they exceed the available width
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, placement) in result.placements.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + placement.x,
                    y: bounds.minY + placement.y
                ),
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var placements: [(x: CGFloat, y: CGFloat, size: CGSize)]
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var placements: [(x: CGFloat, y: CGFloat, size: CGSize)] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            placements.append((x: currentX, y: currentY, size: size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return LayoutResult(
            size: CGSize(width: totalWidth, height: currentY + lineHeight),
            placements: placements
        )
    }
}

#Preview {
    FlowLayout(spacing: 8) {
        ForEach(["Food", "Housing", "Healthcare", "Employment", "Childcare", "Transportation"], id: \.self) { tag in
            Text(tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
        }
    }
    .padding()
}
