import SwiftUI

struct LabeledField<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            content
        }
    }
}

extension NodeSettingsSheet {
    var headerColor: Color {
        guard let node = node else { return .gray }
        if let role = node.agentRole {
            switch role {
            case .pm: return .orange
            case .backend: return .blue
            case .frontend: return .green
            case .qa: return .red
            case .custom: return .purple
            }
        }
        switch node.nodeType {
        case .start: return .teal
        case .output: return .indigo
        case .agent: return .gray
        case .conversation: return .purple
        }
    }

    func agentAvatarColor(_ color: Agent.AvatarColor) -> Color {
        switch color {
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
}

struct NodeToolConfigEditor: View {
    @Binding var toolConfigs: [ToolConfig]
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if toolConfigs.isEmpty {
                HStack {
                    Image(systemName: "puzzlepiece")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("연결된 MCP 도구 없음")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(toolConfigs) { tool in
                    HStack {
                        Toggle(isOn: Binding(
                            get: { tool.isEnabled },
                            set: { newValue in
                                if let idx = toolConfigs.firstIndex(where: { $0.id == tool.id }) {
                                    toolConfigs[idx].isEnabled = newValue
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(tool.name)
                                    .font(.system(size: 12, weight: .medium))
                                Text(tool.command + " " + tool.args.joined(separator: " "))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)

                        Button {
                            toolConfigs.removeAll { $0.id == tool.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                showAddSheet = true
            } label: {
                Label("MCP 서버 추가", systemImage: "plus.circle.fill")
                    .font(.system(size: 11))
            }
            .sheet(isPresented: $showAddSheet) {
                AddToolConfigSheet { newTool in
                    toolConfigs.append(newTool)
                }
            }
        }
    }
}
