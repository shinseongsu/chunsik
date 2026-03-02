import Foundation
import SwiftUI

@MainActor
final class AgentManager: ObservableObject {
    @Published var agents: [Agent] {
        didSet { saveAgents() }
    }
    @Published var selectedAgentID: UUID?

    var tokenTracker: TokenTracker?

    private let storageKey = "com.chunsik.agents"

    var selectedAgent: Agent? {
        guard let id = selectedAgentID else { return nil }
        return agents.first { $0.id == id }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Agent].self, from: data) {
            self.agents = decoded.map { agent in
                var a = agent
                if a.status == .thinking || a.status == .working {
                    a.status = .idle
                }
                return a
            }
        } else {
            self.agents = Agent.defaultTeamAgents
        }

        if selectedAgentID == nil {
            selectedAgentID = agents.first?.id
        }
    }

    private func saveAgents() {
        if let data = try? JSONEncoder().encode(agents) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func addAgent(_ agent: Agent) {
        agents.append(agent)
        selectedAgentID = agent.id
    }

    func deleteAgent(id: UUID) {
        agents.removeAll { $0.id == id }
        if selectedAgentID == id {
            selectedAgentID = agents.first?.id
        }
    }

    func updateAgent(_ agent: Agent) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[index] = agent
        }
    }

    func clearConversation(agentID: UUID) {
        if let index = agents.firstIndex(where: { $0.id == agentID }) {
            agents[index].conversationHistory.removeAll()
            agents[index].status = .idle
        }
    }

    func updateAgentStatus(_ agentID: UUID, status: AgentStatus) {
        if let index = agents.firstIndex(where: { $0.id == agentID }) {
            agents[index].status = status
        }
    }

    func appendMessage(_ message: ChatMessage, to agentID: UUID) {
        if let index = agents.firstIndex(where: { $0.id == agentID }) {
            agents[index].conversationHistory.append(message)
        }
    }

    func agent(for role: AgentRole) -> Agent? {
        agents.first { $0.agentRole == role }
    }

    func sendMessage(_ content: String, to agentID: UUID, settings: AppSettings) async {
        guard let index = agents.firstIndex(where: { $0.id == agentID }) else { return }

        let userMessage = ChatMessage(role: .user, content: content)
        agents[index].conversationHistory.append(userMessage)
        agents[index].status = .thinking

        let agentName = agents[index].name
        print("[AgentManager] '\(agentName)'에게 메시지 전송 시작 (서비스: \(settings.serviceType.rawValue), 모델: \(settings.model.rawValue))")

        do {
            let service: MessageService = settings.serviceType == .claudeAPI
                ? ClaudeAPIService(apiKey: KeychainHelper.load(key: "claude_api_key") ?? "")
                : ClaudeCodeService()

            let basePrompt = agents[index].systemPrompt
            let chatPrompt: String? = if basePrompt.isEmpty {
                nil
            } else {
                basePrompt + "\n\n[채팅 모드] 사용자와 직접 대화 중입니다. JSON이나 특수 형식이 아닌 자연스러운 한국어 평문으로 응답하세요."
            }

            let response = try await service.sendMessage(
                messages: agents[index].conversationHistory,
                systemPrompt: chatPrompt,
                model: settings.model.rawValue,
                maxTokens: settings.maxTokens,
                temperature: settings.temperature,
                toolConfigs: agents[index].toolConfigs,
                projectPath: agents[index].projectPath.isEmpty ? nil : agents[index].projectPath
            )

            tokenTracker?.addUsage(from: response)

            print("[AgentManager] '\(agentName)' 응답 수신 완료 (\(response.content.count)자, 토큰: \(response.totalTokens))")

            guard let currentIndex = agents.firstIndex(where: { $0.id == agentID }) else { return }

            let assistantMessage = ChatMessage(role: .assistant, content: response.content)
            agents[currentIndex].conversationHistory.append(assistantMessage)
            agents[currentIndex].status = .done

            let capturedID = agentID
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                if let idx = self.agents.firstIndex(where: { $0.id == capturedID }),
                   self.agents[idx].status == .done {
                    self.agents[idx].status = .idle
                }
            }
        } catch {
            print("[AgentManager] '\(agentName)' 오류 발생: \(error.localizedDescription)")
            if let currentIndex = agents.firstIndex(where: { $0.id == agentID }) {
                let errorMessage = ChatMessage(
                    role: .assistant,
                    content: "오류가 발생했습니다: \(error.localizedDescription)"
                )
                agents[currentIndex].conversationHistory.append(errorMessage)
                agents[currentIndex].status = .error

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(5))
                    if let idx = self.agents.firstIndex(where: { $0.id == agentID }),
                       self.agents[idx].status == .error {
                        self.agents[idx].status = .idle
                    }
                }
            }
        }
    }
}
