import SwiftUI

extension NodeSettingsSheet {
    var agentEditContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let agent = linkedAgent {
                HStack(spacing: 10) {
                    Circle()
                        .fill(agentAvatarColor(agent.avatarColor))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(agent.name.prefix(1)))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(agent.name)
                            .font(.system(size: 14, weight: .semibold))
                        Text(agent.agentRole.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                settingsSection("에이전트 이름") {
                    TextField("이름", text: $agentName)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                settingsSection("시스템 프롬프트") {
                    TextEditor(text: $agentPrompt)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 120, maxHeight: 200)
                        .border(Color.secondary.opacity(0.3))

                    if let role = agent.agentRole as AgentRole? {
                        Button("역할 기본 프롬프트로 초기화") {
                            agentPrompt = role.defaultSystemPrompt
                        }
                        .font(.system(size: 11))
                    }
                }

                Divider()

                settingsSection("프로젝트 설정") {
                    LabeledField("프로젝트 별칭") {
                        TextField("예: 결제 API, 사용자 서비스", text: $agentProjectAlias)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }

                    LabeledField("프로젝트 경로") {
                        HStack {
                            TextField("프로젝트 폴더 경로", text: $agentProjectPath)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .disabled(true)

                            Button("찾아보기...") {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.allowsMultipleSelection = false
                                panel.message = "프로젝트 폴더를 선택하세요"
                                if panel.runModal() == .OK, let url = panel.url {
                                    agentProjectPath = url.path
                                }
                            }
                            .font(.system(size: 11))

                            if !agentProjectPath.isEmpty {
                                Button {
                                    agentProjectPath = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Divider()

                settingsSection("MCP 도구") {
                    NodeToolConfigEditor(toolConfigs: $agentToolConfigs)
                }

                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("여기서 수정한 내용은 에이전트 탭의 '\(agent.name)'에도 바로 반영됩니다.")
                        .font(.system(size: 10))
                }
                .foregroundColor(.orange)
                .padding(.top, 4)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("연결된 에이전트가 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("'노드 설정' 탭에서 에이전트를 선택하세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)
            }
        }
        .padding()
    }
}
