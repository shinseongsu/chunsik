import SwiftUI

extension NodeSettingsSheet {
    func loadCurrentSettings() {
        guard let node = node else { return }
        title = node.title
        selectedAgentID = node.agentID

        if let config = node.conversationConfig {
            convAgent1ID = config.agent1ID
            convAgent2ID = config.agent2ID
            convMaxRounds = config.maxRounds
            convGoal = config.conversationGoal
            convAutoTerminate = config.autoTerminate
        }

        if let prompt = node.customSystemPrompt {
            useCustomPrompt = true
            systemPrompt = prompt
        } else {
            systemPrompt = resolveEffectivePrompt()
        }

        if let model = node.customModel,
           let m = AppSettings.ClaudeModel(rawValue: model) {
            useCustomModel = true
            selectedModel = m
        }

        if let temp = node.customTemperature {
            useCustomTemperature = true
            temperature = temp
        }

        if let tokens = node.customMaxTokens {
            useCustomMaxTokens = true
            maxTokens = tokens
        }

        if let tools = node.customToolConfigs {
            useCustomTools = true
            toolConfigs = tools
        } else {
            toolConfigs = resolveInheritedTools()
        }

        loadAgentFields()
    }

    func loadAgentFields() {
        if let agent = linkedAgent {
            agentName = agent.name
            agentPrompt = agent.systemPrompt
            agentToolConfigs = agent.toolConfigs
            agentProjectPath = agent.projectPath
            agentProjectAlias = agent.projectAlias
        }
    }

    func saveAll() {
        guard let index = workflowManager.currentWorkflow?.nodes.firstIndex(where: { $0.id == nodeID }) else { return }

        workflowManager.currentWorkflow?.nodes[index].title = title

        if node?.nodeType == .conversation {
            workflowManager.currentWorkflow?.nodes[index].conversationConfig = ConversationConfig(
                agent1ID: convAgent1ID,
                agent2ID: convAgent2ID,
                maxRounds: convMaxRounds,
                conversationGoal: convGoal,
                autoTerminate: convAutoTerminate
            )
        } else {
            workflowManager.currentWorkflow?.nodes[index].agentID = selectedAgentID
            workflowManager.currentWorkflow?.nodes[index].customSystemPrompt = useCustomPrompt ? systemPrompt : nil
            workflowManager.currentWorkflow?.nodes[index].customModel = useCustomModel ? selectedModel.rawValue : nil
            workflowManager.currentWorkflow?.nodes[index].customTemperature = useCustomTemperature ? temperature : nil
            workflowManager.currentWorkflow?.nodes[index].customMaxTokens = useCustomMaxTokens ? maxTokens : nil
            workflowManager.currentWorkflow?.nodes[index].customToolConfigs = useCustomTools ? toolConfigs : nil
        }

        if let agent = linkedAgent {
            var updated = agent
            updated.name = agentName
            updated.systemPrompt = agentPrompt
            updated.toolConfigs = agentToolConfigs
            updated.projectPath = agentProjectPath
            updated.projectAlias = agentProjectAlias
            agentManager.updateAgent(updated)
        }
    }

    func resetToDefaults() {
        useCustomPrompt = false
        useCustomModel = false
        useCustomTemperature = false
        useCustomMaxTokens = false
        useCustomTools = false
        systemPrompt = resolveEffectivePrompt()
        selectedModel = settingsStore.settings.model
        temperature = settingsStore.settings.temperature
        maxTokens = settingsStore.settings.maxTokens
        toolConfigs = resolveInheritedTools()
    }

    func resolveEffectivePrompt() -> String {
        if let agent = linkedAgent {
            return agent.systemPrompt
        }
        return node?.agentRole?.defaultSystemPrompt ?? "당신은 유능한 AI 어시스턴트입니다."
    }

    func resolveInheritedTools() -> [ToolConfig] {
        linkedAgent?.toolConfigs ?? []
    }

    func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
            content()
        }
    }

    func priorityBadge(_ label: String, isActive: Bool) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isActive ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            .foregroundColor(isActive ? .accentColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    var effectiveSettingsSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("적용 우선순위")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 4) {
                priorityBadge("노드 커스텀", isActive: node?.hasCustomSettings == true)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                priorityBadge("에이전트", isActive: linkedAgent != nil)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                priorityBadge("전역/역할 기본", isActive: true)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    func sourceLabel(_ label: String, source: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 9))
            Text(source)
                .font(.system(size: 11))
        }
        .foregroundColor(.secondary)
    }

    var promptSource: String {
        if let agent = linkedAgent {
            return "'\(agent.name)' 에이전트 프롬프트 사용중"
        }
        if let role = node?.agentRole {
            return "\(role.displayName) 역할 기본 프롬프트 사용중"
        }
        return "기본 프롬프트 사용중"
    }

    var toolsSource: String {
        if let agent = linkedAgent {
            return agent.name
        }
        return "없음"
    }
}
