import SwiftUI

extension NodeCanvasView {
    var backgroundGestures: some Gesture {
        SimultaneousGesture(panGesture, zoomGesture)
    }

    var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newZoom = max(0.2, min(3.0, value))
                zoom = newZoom
            }
    }

    func nodeDragGesture(for node: WorkflowNode) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let newPos = CGPoint(
                    x: (value.location.x - offset.width) / zoom,
                    y: (value.location.y - offset.height) / zoom
                )
                workflowManager.moveNode(node.id, to: newPos)
            }
    }

    func handleEdgeDrop(at location: CGPoint) {
        defer {
            isDraftingEdge = false
            draftSourceNodeID = nil
            draftSourcePortID = nil
        }

        guard let sourceNodeID = draftSourceNodeID,
              let sourcePortID = draftSourcePortID else { return }

        let threshold: CGFloat = 30

        guard let workflow = workflowManager.currentWorkflow else { return }

        for node in workflow.nodes where node.id != sourceNodeID {
            for port in node.inputPorts {
                if let portPos = portPositions[port.id] {
                    let distance = hypot(location.x - portPos.x, location.y - portPos.y)
                    if distance < threshold {
                        let edge = NodeEdge(
                            sourceNodeID: sourceNodeID,
                            sourcePortID: sourcePortID,
                            targetNodeID: node.id,
                            targetPortID: port.id
                        )
                        workflowManager.addEdge(edge)
                        return
                    }
                }
            }
        }
    }

    func deleteSelection() {
        if let nodeID = workflowManager.selectedNodeID {
            workflowManager.removeNode(nodeID)
        } else if let edgeID = workflowManager.selectedEdgeID {
            workflowManager.removeEdge(edgeID)
        }
    }

    struct DraftEdgeModifier: ViewModifier {
        @Binding var draftEndPoint: CGPoint
        @Binding var isDrafting: Bool

        func body(content: Content) -> some View {
            content
                .onContinuousHover { phase in
                    if isDrafting {
                        switch phase {
                        case .active(let location):
                            draftEndPoint = location
                        case .ended:
                            break
                        }
                    }
                }
        }
    }
}
