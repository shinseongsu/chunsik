import SwiftUI

struct BezierEdgePath: Shape {
    var from: CGPoint
    var to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)

        let dx = abs(to.x - from.x)
        let controlOffset = max(dx * 0.5, 50)

        let cp1 = CGPoint(x: from.x + controlOffset, y: from.y)
        let cp2 = CGPoint(x: to.x - controlOffset, y: to.y)

        path.addCurve(to: to, control1: cp1, control2: cp2)
        return path
    }
}

struct EdgeView: View {
    let from: CGPoint
    let to: CGPoint
    let isSelected: Bool
    let isDraft: Bool

    init(from: CGPoint, to: CGPoint, isSelected: Bool = false, isDraft: Bool = false) {
        self.from = from
        self.to = to
        self.isSelected = isSelected
        self.isDraft = isDraft
    }

    var body: some View {
        ZStack {
            BezierEdgePath(from: from, to: to)
                .stroke(Color.clear, lineWidth: 20)

            BezierEdgePath(from: from, to: to)
                .stroke(
                    isDraft ? Color.accentColor.opacity(0.5) : (isSelected ? Color.accentColor : Color.secondary.opacity(0.6)),
                    style: StrokeStyle(
                        lineWidth: isSelected ? 3 : 2,
                        lineCap: .round,
                        dash: isDraft ? [8, 4] : []
                    )
                )

            if !isDraft {
                arrowHead
            }
        }
    }

    private var arrowHead: some View {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let angle = atan2(dy, dx)

        return Path { path in
            let size: CGFloat = 8
            let tip = to
            let left = CGPoint(
                x: tip.x - size * cos(angle - .pi / 6),
                y: tip.y - size * sin(angle - .pi / 6)
            )
            let right = CGPoint(
                x: tip.x - size * cos(angle + .pi / 6),
                y: tip.y - size * sin(angle + .pi / 6)
            )
            path.move(to: tip)
            path.addLine(to: left)
            path.addLine(to: right)
            path.closeSubpath()
        }
        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.6))
    }
}
