import SwiftUI

struct WorkflowDashboardView: View {
    @EnvironmentObject var workflowManager: WorkflowManager
    @EnvironmentObject var agentManager: AgentManager
    @EnvironmentObject var nodeOutputStore: NodeOutputStore
    @State var requirementText = ""
    @State var showPalette = true
    @State var templateName = ""
    @State var showTemplateSave = false
    @State private var selectedNodeDetail: WorkflowNode?

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            Divider()

            HSplitView {
                if showPalette {
                    NodePaletteView()
                }

                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        WorkflowFlowView()

                        if let workflow = workflowManager.currentWorkflow {
                            VStack(spacing: 4) {
                                Text("\(workflow.nodes.count) 노드 · \(workflow.edges.count) 연결")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding(8)
                        }
                    }

                    Divider()

                    bottomPanel
                }
            }
        }
        .onAppear {
            workflowManager.ensureWorkflow()
        }
        .sheet(isPresented: $showTemplateSave) {
            templateSaveSheet
        }
        .onDeleteCommand {
            deleteSelection()
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPalette.toggle()
                }
            } label: {
                Image(systemName: showPalette ? "sidebar.left" : "sidebar.left")
                    .foregroundColor(showPalette ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("팔레트 토글")

            Divider()
                .frame(height: 16)

            Text(workflowManager.currentWorkflow?.name ?? "워크플로우")
                .font(.system(size: 13, weight: .semibold))

            if let status = workflowManager.currentWorkflow?.status {
                Text(status.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor(status).opacity(0.15))
                    .foregroundColor(statusColor(status))
                    .clipShape(Capsule())
            }

            Spacer()

            Button {
                deleteSelection()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .disabled(workflowManager.selectedNodeID == nil && workflowManager.selectedEdgeID == nil)
            .help("선택 항목 삭제")

            Button {
                showTemplateSave = true
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("템플릿으로 저장")

            Button {
                workflowManager.newWorkflow()
            } label: {
                Image(systemName: "plus.rectangle")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("새 워크플로우")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func statusColor(_ status: WorkflowStatus) -> Color {
        switch status {
        case .idle: return .gray
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    private func deleteSelection() {
        if let nodeID = workflowManager.selectedNodeID {
            workflowManager.removeNode(nodeID)
        } else if let edgeID = workflowManager.selectedEdgeID {
            workflowManager.removeEdge(edgeID)
        }
    }
}
