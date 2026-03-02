import SwiftUI

extension NodeSettingsSheet {
    var nodeSettingsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if node?.nodeType == .conversation {
                conversationSettingsContent
            } else {
                agentNodeSettingsContent
            }
        }
        .padding()
    }

    var agentNodeSettingsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsSection("기본 정보") {
                LabeledField("노드 이름") {
                    TextField("이름", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledField("연결된 에이전트") {
                    Picker("에이전트", selection: $selectedAgentID) {
                        Text("자동 (역할 기반)").tag(nil as UUID?)
                        ForEach(agentManager.agents) { agent in
                            Text("\(agent.name) (\(agent.agentRole.displayName))")
                                .tag(agent.id as UUID?)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedAgentID) {
                        loadAgentFields()
                    }
                }

                effectiveSettingsSummary
            }

            Divider()

            settingsSection("시스템 프롬프트") {
                Toggle("이 노드 전용 프롬프트 사용", isOn: $useCustomPrompt)
                    .toggleStyle(.switch)

                if useCustomPrompt {
                    TextEditor(text: $systemPrompt)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 80, maxHeight: 150)
                        .border(Color.secondary.opacity(0.3))

                    HStack {
                        if let role = node?.agentRole {
                            Button("역할 기본 프롬프트") {
                                systemPrompt = role.defaultSystemPrompt
                            }
                            .font(.system(size: 11))
                        }
                        if let agent = linkedAgent {
                            Button("에이전트 프롬프트 복사") {
                                systemPrompt = agent.systemPrompt
                            }
                            .font(.system(size: 11))
                        }
                    }
                } else {
                    sourceLabel("프롬프트", source: promptSource)
                }
            }

            Divider()

            settingsSection("AI 모델") {
                Toggle("이 노드 전용 모델 사용", isOn: $useCustomModel)
                    .toggleStyle(.switch)

                if useCustomModel {
                    Picker("모델", selection: $selectedModel) {
                        ForEach(AppSettings.ClaudeModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    sourceLabel("모델", source: "전역 설정: \(settingsStore.settings.model.displayName)")
                }
            }

            Divider()

            settingsSection("Temperature") {
                Toggle("이 노드 전용 Temperature", isOn: $useCustomTemperature)
                    .toggleStyle(.switch)

                if useCustomTemperature {
                    HStack {
                        Slider(value: $temperature, in: 0...1, step: 0.1)
                        Text(String(format: "%.1f", temperature))
                            .font(.system(size: 12, design: .monospaced))
                            .frame(width: 30)
                    }
                }
            }

            Divider()

            settingsSection("MCP 도구") {
                Toggle("이 노드 전용 도구 사용", isOn: $useCustomTools)
                    .toggleStyle(.switch)

                if useCustomTools {
                    NodeToolConfigEditor(toolConfigs: $toolConfigs)
                } else {
                    let inherited = resolveInheritedTools()
                    if inherited.isEmpty {
                        sourceLabel("도구", source: "연결된 도구 없음")
                    } else {
                        sourceLabel("도구", source: "\(inherited.filter(\.isEnabled).count)개 도구 (\(toolsSource)에서 상속)")
                        ForEach(inherited) { tool in
                            HStack(spacing: 6) {
                                Image(systemName: tool.isEnabled ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 10))
                                    .foregroundColor(tool.isEnabled ? .green : .secondary)
                                Text(tool.name)
                                    .font(.system(size: 11))
                                Spacer()
                                Text(tool.command)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
