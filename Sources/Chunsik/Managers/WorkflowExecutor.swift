import Foundation
import SwiftUI

extension WorkflowManager {

    func startWorkflow(requirement: String) async {
        guard var workflow = currentWorkflow else { return }

        for i in workflow.nodes.indices {
            workflow.nodes[i].status = .idle
            workflow.nodes[i].inputData = ""
            workflow.nodes[i].outputData = ""
            workflow.nodes[i].conversationHistory = []
        }
        workflow.status = .running
        workflow.userRequirement = requirement
        currentWorkflow = workflow

        nodeOutputStore.reset()

        let engine = GraphExecutionEngine(
            nodes: workflow.nodes,
            edges: workflow.edges
        )

        if engine.hasCycle() {
            currentWorkflow?.status = .failed
            return
        }

        let levels = engine.executionLevels()

        do {
            for level in levels {
                for nodeID in level {
                    if let idx = currentWorkflow?.nodes.firstIndex(where: { $0.id == nodeID }) {
                        currentWorkflow?.nodes[idx].status = .waiting
                    }
                }

                try await withThrowingTaskGroup(of: (UUID, String).self) { group in
                    for nodeID in level {
                        guard let node = currentWorkflow?.node(by: nodeID) else { continue }

                        if node.nodeType == .start || node.nodeType == .output {
                            if node.nodeType == .start {
                                if let idx = currentWorkflow?.nodes.firstIndex(where: { $0.id == nodeID }) {
                                    currentWorkflow?.nodes[idx].inputData = requirement
                                    currentWorkflow?.nodes[idx].outputData = requirement
                                    currentWorkflow?.nodes[idx].status = .completed
                                }
                            } else if node.nodeType == .output {
                                let aggregated = engine.aggregateInputs(
                                    for: nodeID,
                                    allNodes: currentWorkflow?.nodes ?? []
                                )
                                if let idx = currentWorkflow?.nodes.firstIndex(where: { $0.id == nodeID }) {
                                    currentWorkflow?.nodes[idx].inputData = aggregated
                                    currentWorkflow?.nodes[idx].outputData = aggregated
                                    currentWorkflow?.nodes[idx].status = .completed
                                }
                            }
                            continue
                        }

                        let input = engine.aggregateInputs(
                            for: nodeID,
                            allNodes: currentWorkflow?.nodes ?? []
                        )

                        let capturedInput = input.isEmpty ? requirement : input

                        let workflowProjectPath = currentWorkflow?.projectPath ?? ""
                        group.addTask { [self] in
                            let result = try await self.executeNode(node, input: capturedInput, workflowProjectPath: workflowProjectPath)
                            return (nodeID, result)
                        }
                    }

                    for try await (nodeID, result) in group {
                        if let idx = currentWorkflow?.nodes.firstIndex(where: { $0.id == nodeID }) {
                            currentWorkflow?.nodes[idx].outputData = result
                            currentWorkflow?.nodes[idx].status = .completed
                        }
                    }
                }
            }

            currentWorkflow?.status = .completed
            if let wf = currentWorkflow {
                workflowHistory.append(wf)
            }
        } catch {
            currentWorkflow?.status = .failed
            if let wf = currentWorkflow {
                for i in wf.nodes.indices {
                    if currentWorkflow?.nodes[i].status == .running ||
                       currentWorkflow?.nodes[i].status == .waiting {
                        currentWorkflow?.nodes[i].status = .failed
                        currentWorkflow?.nodes[i].outputData = "오류: \(error.localizedDescription)"
                    }
                }
                workflowHistory.append(currentWorkflow!)
            }
        }
    }

    func executeNode(_ node: WorkflowNode, input: String, workflowProjectPath: String = "") async throws -> String {
        if node.nodeType == .conversation {
            return try await executeConversationNode(node, input: input, workflowProjectPath: workflowProjectPath)
        }

        let nodeID = node.id

        await MainActor.run {
            if let idx = currentWorkflow?.nodes.firstIndex(where: { $0.id == nodeID }) {
                currentWorkflow?.nodes[idx].status = .running
                currentWorkflow?.nodes[idx].inputData = input
            }
            nodeOutputStore.startStreaming(for: nodeID)
        }

        let agent: Agent?
        if let agentID = node.agentID {
            agent = agentManager.agents.first { $0.id == agentID }
        } else if let role = node.agentRole {
            agent = agentManager.agent(for: role)
        } else {
            agent = nil
        }

        let systemPrompt = node.customSystemPrompt
            ?? agent?.systemPrompt
            ?? node.agentRole?.defaultSystemPrompt
            ?? "당신은 유능한 AI 어시스턴트입니다."

        let model = node.customModel
            ?? settingsStore.settings.model.rawValue

        let toolConfigs = node.customToolConfigs
            ?? agent?.toolConfigs
            ?? []

        let maxTokens = node.customMaxTokens
            ?? settingsStore.settings.maxTokens

        let temperature = node.customTemperature
            ?? settingsStore.settings.temperature

        if let agentID = agent?.id {
            agentManager.updateAgentStatus(agentID, status: .working)
        }

        defer {
            if let agentID = agent?.id {
                Task { @MainActor in
                    self.agentManager.updateAgentStatus(agentID, status: .done)
                    try? await Task.sleep(for: .seconds(3))
                    self.agentManager.updateAgentStatus(agentID, status: .idle)
                }
            }
            Task { @MainActor in
                self.nodeOutputStore.setComplete(for: nodeID)
            }
        }

        let settings = settingsStore.settings
        let service: MessageService = settings.serviceType == .claudeAPI
            ? ClaudeAPIService(apiKey: KeychainHelper.load(key: "claude_api_key") ?? "")
            : ClaudeCodeService()

        let effectiveProjectPath: String? = if !workflowProjectPath.isEmpty {
            workflowProjectPath
        } else if agent?.projectPath.isEmpty == false {
            agent?.projectPath
        } else {
            nil
        }

        let outputStore = nodeOutputStore
        let response = try await service.sendMessageStreaming(
            messages: [ChatMessage(role: .user, content: input)],
            systemPrompt: systemPrompt,
            model: model,
            maxTokens: maxTokens,
            temperature: temperature,
            toolConfigs: toolConfigs,
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
}
