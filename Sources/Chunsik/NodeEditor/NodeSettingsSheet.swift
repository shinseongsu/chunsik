import SwiftUI

struct NodeSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var workflowManager: WorkflowManager
    @EnvironmentObject var agentManager: AgentManager
    @EnvironmentObject var settingsStore: SettingsStore

    let nodeID: UUID

    @State var selectedTab: SettingsTab = .node

    enum SettingsTab: String, CaseIterable {
        case node = "노드 설정"
        case agent = "에이전트 편집"
    }

    @State var title: String = ""
    @State var selectedAgentID: UUID?
    @State var convAgent1ID: UUID?
    @State var convAgent2ID: UUID?
    @State var convMaxRounds: Int = 3
    @State var convGoal: String = ""
    @State var convAutoTerminate: Bool = true
    @State var useCustomPrompt: Bool = false
    @State var systemPrompt: String = ""
    @State var useCustomModel: Bool = false
    @State var selectedModel: AppSettings.ClaudeModel = .sonnet
    @State var useCustomTemperature: Bool = false
    @State var temperature: Double = 0.7
    @State var useCustomMaxTokens: Bool = false
    @State var maxTokens: Int = 4096
    @State var useCustomTools: Bool = false
    @State var toolConfigs: [ToolConfig] = []

    @State var agentName: String = ""
    @State var agentPrompt: String = ""
    @State var agentToolConfigs: [ToolConfig] = []
    @State var agentProjectPath: String = ""
    @State var agentProjectAlias: String = ""

    var node: WorkflowNode? {
        workflowManager.currentWorkflow?.node(by: nodeID)
    }

    var linkedAgent: Agent? {
        if let id = selectedAgentID {
            return agentManager.agents.first { $0.id == id }
        }
        if let role = node?.agentRole {
            return agentManager.agent(for: role)
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                switch selectedTab {
                case .node:
                    nodeSettingsContent
                case .agent:
                    agentEditContent
                }
            }

            Divider()

            footer
        }
        .frame(width: 500, height: 650)
        .onAppear { loadCurrentSettings() }
    }

    var header: some View {
        HStack {
            if let node = node {
                Image(systemName: node.nodeType.systemImage)
                    .foregroundColor(headerColor)
                Text(node.title)
                    .font(.headline)

                if let agent = linkedAgent {
                    Text("→ \(agent.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    var footer: some View {
        HStack {
            if node?.hasCustomSettings == true {
                Button("노드 설정 초기화") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
            }

            Spacer()

            Button("취소") { dismiss() }
                .keyboardShortcut(.cancelAction)

            Button("저장") {
                saveAll()
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

}
