import SwiftUI

extension NodeSettingsSheet {
    var conversationSettingsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsSection("기본 정보") {
                LabeledField("노드 이름") {
                    TextField("이름", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Divider()

            settingsSection("에이전트 선택") {
                LabeledField("에이전트 1") {
                    Picker("에이전트 1", selection: $convAgent1ID) {
                        Text("선택하세요").tag(nil as UUID?)
                        ForEach(agentManager.agents) { agent in
                            Text("\(agent.name) (\(agent.agentRole.displayName))")
                                .tag(agent.id as UUID?)
                        }
                    }
                    .labelsHidden()
                }

                LabeledField("에이전트 2") {
                    Picker("에이전트 2", selection: $convAgent2ID) {
                        Text("선택하세요").tag(nil as UUID?)
                        ForEach(agentManager.agents) { agent in
                            Text("\(agent.name) (\(agent.agentRole.displayName))")
                                .tag(agent.id as UUID?)
                        }
                    }
                    .labelsHidden()
                }

                if convAgent1ID != nil && convAgent2ID != nil && convAgent1ID == convAgent2ID {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("같은 에이전트를 선택했습니다. 다른 에이전트를 선택하세요.")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.orange)
                }
            }

            Divider()

            settingsSection("대화 설정") {
                LabeledField("최대 라운드 수") {
                    Stepper(value: $convMaxRounds, in: 1...10) {
                        Text("\(convMaxRounds) 라운드")
                            .font(.system(size: 12, design: .monospaced))
                    }
                }

                LabeledField("대화 목표") {
                    TextEditor(text: $convGoal)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 60, maxHeight: 120)
                        .border(Color.secondary.opacity(0.3))
                }

                Toggle("자동 종료 ([합의완료] 키워드)", isOn: $convAutoTerminate)
                    .toggleStyle(.switch)

                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("에이전트가 응답에 [합의완료]를 포함하면 남은 라운드를 건너뜁니다.")
                        .font(.system(size: 10))
                }
                .foregroundColor(.secondary)
            }
        }
    }
}
