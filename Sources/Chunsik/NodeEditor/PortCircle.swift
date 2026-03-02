import SwiftUI

struct PortPositionKey: PreferenceKey {
    static var defaultValue: [UUID: CGPoint] = [:]
    static func reduce(value: inout [UUID: CGPoint], nextValue: () -> [UUID: CGPoint]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct PortCircle: View {
    let port: Port
    let nodeID: UUID
    let isConnected: Bool
    let onDragStart: ((UUID, UUID) -> Void)?
    let onDragEnd: ((CGPoint) -> Void)?

    @State private var isDragging = false

    private var color: Color {
        if isDragging { return .accentColor }
        return isConnected ? .accentColor : .secondary
    }

    var body: some View {
        Circle()
            .fill(isConnected || isDragging ? color : Color(nsColor: .windowBackgroundColor))
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
            )
            .frame(width: 12, height: 12)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: PortPositionKey.self,
                        value: [port.id: geo.frame(in: .named("canvas")).center]
                    )
                }
            )
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .named("canvas"))
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            onDragStart?(nodeID, port.id)
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        onDragEnd?(value.location)
                    }
            )
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
