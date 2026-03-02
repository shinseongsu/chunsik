import SwiftUI

struct AgentListSidebar: View {
    @EnvironmentObject var agentManager: AgentManager
    @State private var showAddSheet = false
    @State private var editingAgent: Agent?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("에이전트")
                    .font(.headline)
                Spacer()
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .help("새 에이전트 추가")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            List(selection: $agentManager.selectedAgentID) {
                ForEach(agentManager.agents) { agent in
                    AgentRow(agent: agent)
                        .tag(agent.id)
                        .contextMenu {
                            Button("편집") {
                                editingAgent = agent
                            }
                            Button("대화 삭제") {
                                agentManager.clearConversation(agentID: agent.id)
                            }
                            Divider()
                            Button("삭제", role: .destructive) {
                                agentManager.deleteAgent(id: agent.id)
                            }
                        }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 200, idealWidth: 220)
        .sheet(isPresented: $showAddSheet) {
            AgentEditorSheet { name, role, prompt, color, presets, agentRole, toolConfigs, projectPath, projectAlias in
                let agent = Agent(name: name, role: role, systemPrompt: prompt, avatarColor: color, presetPrompts: presets, agentRole: agentRole, toolConfigs: toolConfigs, projectPath: projectPath, projectAlias: projectAlias)
                agentManager.addAgent(agent)
            }
        }
        .sheet(item: $editingAgent) { agent in
            AgentEditorSheet(agent: agent) { name, role, prompt, color, presets, agentRole, toolConfigs, projectPath, projectAlias in
                var updated = agent
                updated.name = name
                updated.role = role
                updated.systemPrompt = prompt
                updated.avatarColor = color
                updated.presetPrompts = presets
                updated.agentRole = agentRole
                updated.toolConfigs = toolConfigs
                updated.projectPath = projectPath
                updated.projectAlias = projectAlias
                agentManager.updateAgent(updated)
            }
        }
    }
}

struct AgentRow: View {
    let agent: Agent

    private var agentColor: Color {
        switch agent.avatarColor {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .yellow: return .yellow
        case .teal: return .teal
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(agentColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(agent.name.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(agent.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(agent.role)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: agent.status.systemImage)
                .font(.system(size: 10))
                .foregroundColor(agent.status.color)
        }
        .padding(.vertical, 4)
    }
}
