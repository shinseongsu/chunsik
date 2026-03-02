import SwiftUI

struct NodePaletteView: View {
    @EnvironmentObject var workflowManager: WorkflowManager
    @EnvironmentObject var agentManager: AgentManager

    @State private var showTemplates = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("노드 팔레트")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    paletteSection(title: "시스템 노드") {
                        PaletteItem(
                            title: "시작",
                            icon: "play.circle.fill",
                            color: .teal
                        ) {
                            addNode(nodeType: .start, title: "시작")
                        }

                        PaletteItem(
                            title: "대화",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: .purple
                        ) {
                            addNode(nodeType: .conversation, title: "대화")
                        }

                        PaletteItem(
                            title: "출력",
                            icon: "doc.circle.fill",
                            color: .indigo
                        ) {
                            addNode(nodeType: .output, title: "출력")
                        }
                    }

                    paletteSection(title: "에이전트 노드") {
                        ForEach(AgentRole.allCases.filter { $0 != .custom }, id: \.self) { role in
                            PaletteItem(
                                title: role.displayName,
                                icon: "person.circle.fill",
                                color: colorForRole(role)
                            ) {
                                addNode(nodeType: .agent, agentRole: role, title: role.displayName)
                            }
                        }
                    }

                    let customAgents = agentManager.agents.filter { $0.agentRole == .custom }
                    if !customAgents.isEmpty {
                        paletteSection(title: "커스텀 에이전트") {
                            ForEach(customAgents) { agent in
                                PaletteItem(
                                    title: agent.name,
                                    icon: "person.circle.fill",
                                    color: .purple
                                ) {
                                    addNode(
                                        nodeType: .agent,
                                        agentRole: .custom,
                                        agentID: agent.id,
                                        title: agent.name
                                    )
                                }
                            }
                        }
                    }

                    Divider()
                        .padding(.horizontal, 12)

                    paletteSection(title: "템플릿") {
                        if workflowManager.savedTemplates.isEmpty {
                            Text("저장된 템플릿 없음")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                        } else {
                            ForEach(workflowManager.savedTemplates) { template in
                                PaletteItem(
                                    title: template.name,
                                    icon: "doc.on.doc",
                                    color: .orange
                                ) {
                                    workflowManager.loadTemplate(template)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .frame(width: 200)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func paletteSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)

            content()
        }
    }

    private func addNode(
        nodeType: NodeType,
        agentRole: AgentRole? = nil,
        agentID: UUID? = nil,
        title: String
    ) {
        let baseX: CGFloat = 400
        let baseY: CGFloat = 300
        let randomOffset = CGFloat.random(in: -50...50)

        let node = WorkflowNode(
            nodeType: nodeType,
            agentRole: agentRole,
            agentID: agentID,
            position: CGPointCodable(x: baseX + randomOffset, y: baseY + randomOffset),
            title: title
        )
        workflowManager.addNode(node)
    }

    private func colorForRole(_ role: AgentRole) -> Color {
        switch role {
        case .pm: return .orange
        case .backend: return .blue
        case .frontend: return .green
        case .qa: return .red
        case .custom: return .purple
        }
    }
}

struct PaletteItem: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
