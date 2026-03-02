import Foundation
import SwiftUI

extension WorkflowManager {

    func executeConversationNode(_ node: WorkflowNode, input: String, workflowProjectPath: String) async throws -> String {
        guard let config = node.conversationConfig,
              let agent1ID = config.agent1ID,
              let agent2ID = config.agent2ID else {
            throw ConversationError.missingAgents
        }

        guard let agent1 = agentManager.agents.first(where: { $0.id == agent1ID }),
              let agent2 = agentManager.agents.first(where: { $0.id == agent2ID }) else {
            throw ConversationError.missingAgents
        }

        let nodeID = node.id

        await MainActor.run {
            if let idx = currentWorkflow?.nodes.firstIndex(where: { $0.id == nodeID }) {
                currentWorkflow?.nodes[idx].status = .running
                currentWorkflow?.nodes[idx].inputData = input
                currentWorkflow?.nodes[idx].conversationHistory = []
            }
            nodeOutputStore.startStreaming(for: nodeID)
        }

        defer {
            Task { @MainActor in
                self.nodeOutputStore.setComplete(for: nodeID)
            }
        }

        var messages: [ConversationMessage] = []
        let terminationKeyword = "[합의완료]"

        for round in 1...config.maxRounds {
            let agent1Prompt = buildConversationPrompt(
                agentName: agent1.name,
                goal: config.conversationGoal,
                round: round,
                maxRounds: config.maxRounds,
                previousMessages: messages,
                input: input
            )

            let agent1Response = try await sendToAgent(
                agent: agent1,
                prompt: agent1Prompt,
                workflowProjectPath: workflowProjectPath,
                nodeID: node.id
            )

            let msg1 = ConversationMessage(agentName: agent1.name, content: agent1Response, round: round)
            messages.append(msg1)

            await MainActor.run {
                if let idx = currentWorkflow?.nodes.firstIndex(where: { $0.id == node.id }) {
                    currentWorkflow?.nodes[idx].conversationHistory = messages
                    currentWorkflow?.nodes[idx].outputData = formatConversationOutput(messages)
                }
            }

            if config.autoTerminate && agent1Response.contains(terminationKeyword) {
                break
            }

            let agent2Prompt = buildConversationPrompt(
                agentName: agent2.name,
                goal: config.conversationGoal,
                round: round,
                maxRounds: config.maxRounds,
                previousMessages: messages,
                input: input
            )

            let agent2Response = try await sendToAgent(
                agent: agent2,
                prompt: agent2Prompt,
                workflowProjectPath: workflowProjectPath,
                nodeID: node.id
            )

            let msg2 = ConversationMessage(agentName: agent2.name, content: agent2Response, round: round)
            messages.append(msg2)

            await MainActor.run {
                if let idx = currentWorkflow?.nodes.firstIndex(where: { $0.id == node.id }) {
                    currentWorkflow?.nodes[idx].conversationHistory = messages
                    currentWorkflow?.nodes[idx].outputData = formatConversationOutput(messages)
                }
            }

            if config.autoTerminate && agent2Response.contains(terminationKeyword) {
                break
            }
        }

        return formatConversationOutput(messages)
    }

    func buildConversationPrompt(
        agentName: String,
        goal: String,
        round: Int,
        maxRounds: Int,
        previousMessages: [ConversationMessage],
        input: String
    ) -> String {
        var prompt = """
        당신은 \(agentName)입니다. 다른 에이전트와 대화 중입니다.
        대화 목표: \(goal)
        합의에 도달하면 응답 마지막에 [합의완료]를 포함하세요.
        현재 라운드: \(round)/\(maxRounds)

        --- 입력 ---
        \(input)
        """

        if !previousMessages.isEmpty {
            prompt += "\n\n--- 이전 대화 ---\n"
            for msg in previousMessages {
                prompt += "[\(msg.agentName)] (라운드 \(msg.round)):\n\(msg.content)\n\n"
            }
        }

        prompt += "\n--- 당신의 응답 ---"
        return prompt
    }

    func sendToAgent(agent: Agent, prompt: String, workflowProjectPath: String, nodeID: UUID) async throws -> String {
        let systemPrompt = agent.systemPrompt.isEmpty
            ? agent.agentRole.defaultSystemPrompt
            : agent.systemPrompt

        let model = settingsStore.settings.model.rawValue
        let maxTokens = settingsStore.settings.maxTokens
        let temperature = settingsStore.settings.temperature

        let settings = settingsStore.settings
        let service: MessageService = settings.serviceType == .claudeAPI
            ? ClaudeAPIService(apiKey: KeychainHelper.load(key: "claude_api_key") ?? "")
            : ClaudeCodeService()

        let effectiveProjectPath: String? = if !workflowProjectPath.isEmpty {
            workflowProjectPath
        } else if !agent.projectPath.isEmpty {
            agent.projectPath
        } else {
            nil
        }

        let outputStore = nodeOutputStore
        let response = try await service.sendMessageStreaming(
            messages: [ChatMessage(role: .user, content: prompt)],
            systemPrompt: systemPrompt,
            model: model,
            maxTokens: maxTokens,
            temperature: temperature,
            toolConfigs: agent.toolConfigs,
            projectPath: effectiveProjectPath,
            timeout: nil,
            onPartialOutput: { text in
                Task { @MainActor in
                    outputStore.append(text, for: nodeID)
                }
            }
        )
        return response.content
    }

    func formatConversationOutput(_ messages: [ConversationMessage]) -> String {
        messages.map { "[\($0.agentName)] (라운드 \($0.round)):\n\($0.content)" }
            .joined(separator: "\n\n---\n\n")
    }
}
