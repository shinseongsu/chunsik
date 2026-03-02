import SwiftUI

struct NodeCanvasView: View {
    @EnvironmentObject var workflowManager: WorkflowManager
    @EnvironmentObject var agentManager: AgentManager
    @State var zoom: CGFloat = 1.0
    @State var offset: CGSize = .zero
    @State var portPositions: [UUID: CGPoint] = [:]

    @State var isDraftingEdge = false
    @State var draftSourceNodeID: UUID?
    @State var draftSourcePortID: UUID?
    @State var draftEndPoint: CGPoint = .zero

    @State var lastOffset: CGSize = .zero

    @State private var showNodeSettings = false
    @State private var settingsNodeID: UUID?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CanvasGridBackground(zoom: zoom, offset: offset)
                    .gesture(backgroundGestures)

                canvasContent
            }
            .coordinateSpace(name: "canvas")
            .clipped()
            .onPreferenceChange(PortPositionKey.self) { positions in
                portPositions = positions
            }
            .sheet(isPresented: $showNodeSettings) {
                if let nodeID = settingsNodeID {
                    NodeSettingsSheet(nodeID: nodeID)
                }
            }
        }
    }

    var canvasContent: some View {
        ZStack {
            edgesLayer

            if isDraftingEdge, let sourcePortID = draftSourcePortID,
               let sourcePos = portPositions[sourcePortID] {
                EdgeView(
                    from: sourcePos,
                    to: draftEndPoint,
                    isDraft: true
                )
            }

            nodesLayer
        }
    }

    var edgesLayer: some View {
        ForEach(workflowManager.currentWorkflow?.edges ?? []) { edge in
            if let fromPos = portPositions[edge.sourcePortID],
               let toPos = portPositions[edge.targetPortID] {
                ZStack {
                    EdgeView(
                        from: fromPos,
                        to: toPos,
                        isSelected: workflowManager.selectedEdgeID == edge.id
                    )

                    if let sourceNode = workflowManager.currentWorkflow?.nodes.first(where: { $0.id == edge.sourceNodeID }),
                       !sourceNode.outputData.isEmpty {
                        let midPoint = CGPoint(
                            x: (fromPos.x + toPos.x) / 2,
                            y: (fromPos.y + toPos.y) / 2 - 14
                        )
                        Text(String(sourceNode.outputData.prefix(30)) + (sourceNode.outputData.count > 30 ? "..." : ""))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .position(midPoint)
                    }
                }
                .onTapGesture {
                    workflowManager.selectedEdgeID = edge.id
                    workflowManager.selectedNodeID = nil
                }
            }
        }
    }

    var nodesLayer: some View {
        ForEach(workflowManager.currentWorkflow?.nodes ?? []) { node in
            CanvasNodeView(
                node: node,
                isSelected: workflowManager.selectedNodeID == node.id,
                edges: workflowManager.currentWorkflow?.edges ?? [],
                linkedAgent: workflowManager.resolvedAgent(for: node),
                allAgents: agentManager.agents,
                onDragStart: { nodeID, portID in
                    isDraftingEdge = true
                    draftSourceNodeID = nodeID
                    draftSourcePortID = portID
                },
                onDragEnd: { location in
                    handleEdgeDrop(at: location)
                },
                onOpenSettings: {
                    openNodeSettings(node.id)
                }
            )
            .position(canvasPosition(for: node))
            .gesture(nodeDragGesture(for: node))
            .onTapGesture(count: 2) {
                openNodeSettings(node.id)
            }
            .onTapGesture {
                workflowManager.selectedNodeID = node.id
                workflowManager.selectedEdgeID = nil
            }
        }
    }

    func openNodeSettings(_ nodeID: UUID) {
        guard let node = workflowManager.currentWorkflow?.node(by: nodeID),
              node.nodeType == .agent || node.nodeType == .conversation else { return }
        settingsNodeID = nodeID
        showNodeSettings = true
    }

    func canvasPosition(for node: WorkflowNode) -> CGPoint {
        CGPoint(
            x: node.position.x * zoom + offset.width,
            y: node.position.y * zoom + offset.height
        )
    }

    func worldPosition(from screenPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: (screenPoint.x - offset.width) / zoom,
            y: (screenPoint.y - offset.height) / zoom
        )
    }
}
