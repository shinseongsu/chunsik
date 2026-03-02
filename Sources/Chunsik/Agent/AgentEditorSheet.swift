import SwiftUI

struct AgentEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var name: String
    @State var role: String
    @State var systemPrompt: String
    @State var avatarColor: Agent.AvatarColor
    @State var presetPrompts: [String]
    @State var agentRole: AgentRole
    @State var toolConfigs: [ToolConfig]
    @State var projectPath: String
    @State var projectAlias: String

    let isEditing: Bool
    let onSave: (String, String, String, Agent.AvatarColor, [String], AgentRole, [ToolConfig], String, String) -> Void

    init(agent: Agent? = nil, onSave: @escaping (String, String, String, Agent.AvatarColor, [String], AgentRole, [ToolConfig], String, String) -> Void) {
        if let agent {
            _name = State(initialValue: agent.name)
            _role = State(initialValue: agent.role)
            _systemPrompt = State(initialValue: agent.systemPrompt)
            _avatarColor = State(initialValue: agent.avatarColor)
            _presetPrompts = State(initialValue: agent.presetPrompts)
            _agentRole = State(initialValue: agent.agentRole)
            _toolConfigs = State(initialValue: agent.toolConfigs)
            _projectPath = State(initialValue: agent.projectPath)
            _projectAlias = State(initialValue: agent.projectAlias)
            isEditing = true
        } else {
            _name = State(initialValue: "")
            _role = State(initialValue: "")
            _systemPrompt = State(initialValue: "")
            _avatarColor = State(initialValue: .blue)
            _presetPrompts = State(initialValue: [])
            _agentRole = State(initialValue: .custom)
            _toolConfigs = State(initialValue: [])
            _projectPath = State(initialValue: "")
            _projectAlias = State(initialValue: "")
            isEditing = false
        }
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(isEditing ? "에이전트 편집" : "새 에이전트 추가")
                .font(.headline)
                .padding()

            Divider()

            Form {
                TextField("이름", text: $name)
                TextField("역할", text: $role)

                Picker("색상", selection: $avatarColor) {
                    ForEach(Agent.AvatarColor.allCases, id: \.self) { color in
                        Text(color.displayName).tag(color)
                    }
                }

                Picker("에이전트 역할", selection: $agentRole) {
                    ForEach(AgentRole.allCases, id: \.self) { r in
                        Text(r.displayName).tag(r)
                    }
                }
                .onChange(of: agentRole) { _, newRole in
                    if !isEditing && newRole != .custom {
                        if systemPrompt.isEmpty {
                            systemPrompt = newRole.defaultSystemPrompt
                        }
                    }
                }

                Section("프로젝트 설정") {
                    TextField("프로젝트 별칭", text: $projectAlias, prompt: Text("예: 결제 API, 사용자 서비스"))
                        .font(.system(size: 12))

                    HStack {
                        TextField("프로젝트 경로", text: $projectPath)
                            .font(.system(size: 12))
                            .disabled(true)

                        Button("찾아보기...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            panel.message = "프로젝트 폴더를 선택하세요"
                            if panel.runModal() == .OK, let url = panel.url {
                                projectPath = url.path
                            }
                        }
                        .font(.system(size: 12))

                        if !projectPath.isEmpty {
                            Button {
                                projectPath = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("시스템 프롬프트") {
                    TextEditor(text: $systemPrompt)
                        .font(.system(size: 12))
                        .frame(minHeight: 80)
                }

                Section("기본 프롬프트") {
                    ForEach(presetPrompts.indices, id: \.self) { index in
                        HStack {
                            TextField("프롬프트 \(index + 1)", text: $presetPrompts[index])
                                .font(.system(size: 12))

                            Button {
                                presetPrompts.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        presetPrompts.append("")
                    } label: {
                        Label("프롬프트 추가", systemImage: "plus.circle.fill")
                            .font(.system(size: 12))
                    }
                }

                ToolConfigEditorView(toolConfigs: $toolConfigs)
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Button("취소") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "저장" : "추가") {
                    let filtered = presetPrompts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    onSave(name, role, systemPrompt, avatarColor, filtered, agentRole, toolConfigs, projectPath, projectAlias)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 700)
    }
}
