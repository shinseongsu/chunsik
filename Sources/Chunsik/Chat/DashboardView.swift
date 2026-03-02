import SwiftUI

enum DashboardTab: String, CaseIterable {
    case agents = "에이전트"
    case workflow = "워크플로우"
}

struct DashboardView: View {
    @EnvironmentObject var agentManager: AgentManager
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var workflowManager: WorkflowManager
    @State private var showSettings = false
    @State private var selectedTab: DashboardTab = .agents

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            switch selectedTab {
            case .agents:
                agentsContent
            case .workflow:
                WorkflowDashboardView()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private var agentsContent: some View {
        NavigationSplitView {
            AgentListSidebar()
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                        .help("설정")
                    }
                }
        } detail: {
            if let agent = agentManager.selectedAgent {
                ChatView(agent: agent)
                    .id(agent.id)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("에이전트를 선택하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
