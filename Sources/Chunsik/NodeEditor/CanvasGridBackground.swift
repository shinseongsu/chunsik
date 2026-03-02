import SwiftUI

struct CanvasGridBackground: View {
    let zoom: CGFloat
    let offset: CGSize

    private let dotSpacing: CGFloat = 25
    private let dotRadius: CGFloat = 1.5

    var body: some View {
        Canvas { context, size in
            let spacing = dotSpacing * zoom
            guard spacing > 3 else { return }

            let offsetX = offset.width.truncatingRemainder(dividingBy: spacing)
            let offsetY = offset.height.truncatingRemainder(dividingBy: spacing)

            let cols = Int(size.width / spacing) + 2
            let rows = Int(size.height / spacing) + 2

            let dotColor = Color.secondary.opacity(0.25)

            for col in 0..<cols {
                for row in 0..<rows {
                    let x = CGFloat(col) * spacing + offsetX
                    let y = CGFloat(row) * spacing + offsetY

                    guard x >= -spacing && x <= size.width + spacing &&
                          y >= -spacing && y <= size.height + spacing else { continue }

                    let rect = CGRect(
                        x: x - dotRadius * zoom,
                        y: y - dotRadius * zoom,
                        width: dotRadius * 2 * zoom,
                        height: dotRadius * 2 * zoom
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(dotColor)
                    )
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
