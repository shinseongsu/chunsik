import Foundation

struct MessageResponse {
    let content: String
    let inputTokens: Int?
    let outputTokens: Int?

    let costUSD: Double?

    let rateLimitTokensLimit: Int?
    let rateLimitTokensRemaining: Int?

    var totalTokens: Int {
        (inputTokens ?? 0) + (outputTokens ?? 0)
    }

    init(
        content: String,
        inputTokens: Int? = nil,
        outputTokens: Int? = nil,
        costUSD: Double? = nil,
        rateLimitTokensLimit: Int? = nil,
        rateLimitTokensRemaining: Int? = nil
    ) {
        self.content = content
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.costUSD = costUSD
        self.rateLimitTokensLimit = rateLimitTokensLimit
        self.rateLimitTokensRemaining = rateLimitTokensRemaining
    }
}

protocol MessageService {
    func sendMessage(
        messages: [ChatMessage],
        systemPrompt: String?,
        model: String,
        maxTokens: Int,
        temperature: Double,
        toolConfigs: [ToolConfig],
        projectPath: String?,
        timeout: Double?
    ) async throws -> MessageResponse

    func sendMessageStreaming(
        messages: [ChatMessage],
        systemPrompt: String?,
        model: String,
        maxTokens: Int,
        temperature: Double,
        toolConfigs: [ToolConfig],
        projectPath: String?,
        timeout: Double?,
        onPartialOutput: @Sendable @escaping (String) -> Void
    ) async throws -> MessageResponse
}

extension MessageService {
    func sendMessage(
        messages: [ChatMessage],
        systemPrompt: String?,
        model: String,
        maxTokens: Int,
        temperature: Double,
        toolConfigs: [ToolConfig],
        projectPath: String?
    ) async throws -> MessageResponse {
        try await sendMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            model: model,
            maxTokens: maxTokens,
            temperature: temperature,
            toolConfigs: toolConfigs,
            projectPath: projectPath,
            timeout: 120
        )
    }

    func sendMessageStreaming(
        messages: [ChatMessage],
        systemPrompt: String?,
        model: String,
        maxTokens: Int,
        temperature: Double,
        toolConfigs: [ToolConfig],
        projectPath: String?,
        timeout: Double?,
        onPartialOutput: @Sendable @escaping (String) -> Void
    ) async throws -> MessageResponse {
        let response = try await sendMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            model: model,
            maxTokens: maxTokens,
            temperature: temperature,
            toolConfigs: toolConfigs,
            projectPath: projectPath,
            timeout: timeout
        )
        onPartialOutput(response.content)
        return response
    }
}
