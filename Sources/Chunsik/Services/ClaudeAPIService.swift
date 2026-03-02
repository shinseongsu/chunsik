import Foundation

final class ClaudeAPIService: MessageService {

    enum APIError: LocalizedError {
        case invalidAPIKey
        case rateLimited
        case serverError(Int)
        case networkError(String)
        case emptyResponse
        case decodingError(String)

        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "API 키가 유효하지 않습니다. 설정에서 확인해주세요."
            case .rateLimited:
                return "요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요."
            case .serverError(let code):
                return "서버 오류가 발생했습니다. (코드: \(code))"
            case .networkError(let msg):
                return "네트워크 오류: \(msg)"
            case .emptyResponse:
                return "응답이 비어있습니다."
            case .decodingError(let msg):
                return "응답 파싱 오류: \(msg)"
            }
        }
    }

    private let apiKey: String
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    private static let modelMapping: [String: String] = [
        "sonnet": "claude-sonnet-4-20250514",
        "haiku": "claude-haiku-4-5-20251001",
        "opus": "claude-opus-4-20250514",
    ]

    func sendMessage(
        messages: [ChatMessage],
        systemPrompt: String?,
        model: String,
        maxTokens: Int,
        temperature: Double,
        toolConfigs: [ToolConfig],
        projectPath: String? = nil,
        timeout: Double? = 120
    ) async throws -> MessageResponse {
        guard !apiKey.isEmpty else {
            throw APIError.invalidAPIKey
        }

        let apiModel = Self.modelMapping[model] ?? model

        let apiMessages = messages
            .filter { $0.role != .system }
            .suffix(20)
            .map { msg -> [String: String] in
                [
                    "role": msg.role == .user ? "user" : "assistant",
                    "content": msg.content,
                ]
            }

        var body: [String: Any] = [
            "model": apiModel,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "messages": Array(apiMessages),
        ]

        if let sp = systemPrompt, !sp.isEmpty {
            var finalPrompt = sp
            if let path = projectPath, !path.isEmpty {
                finalPrompt = "[프로젝트 컨텍스트] 작업 대상: \(path)\n\n" + finalPrompt
            }
            body["system"] = finalPrompt
        } else if let path = projectPath, !path.isEmpty {
            body["system"] = "[프로젝트 컨텍스트] 작업 대상: \(path)"
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = jsonData

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("잘못된 응답 형식")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw APIError.invalidAPIKey
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw APIError.decodingError("응답 구조가 예상과 다릅니다.")
        }

        let texts = content.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }

        let result = texts.joined()
        if result.isEmpty {
            throw APIError.emptyResponse
        }

        let usage = json["usage"] as? [String: Any]
        let inputTokens = usage?["input_tokens"] as? Int
        let outputTokens = usage?["output_tokens"] as? Int

        let rateLimitTokensLimit = (httpResponse.value(forHTTPHeaderField: "anthropic-ratelimit-tokens-limit")).flatMap { Int($0) }
        let rateLimitTokensRemaining = (httpResponse.value(forHTTPHeaderField: "anthropic-ratelimit-tokens-remaining")).flatMap { Int($0) }

        return MessageResponse(
            content: result,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            rateLimitTokensLimit: rateLimitTokensLimit,
            rateLimitTokensRemaining: rateLimitTokensRemaining
        )
    }

    static func testConnection(apiKey: String) async throws {
        let service = ClaudeAPIService(apiKey: apiKey)
        let _ = try await service.sendMessage(
            messages: [ChatMessage(role: .user, content: "Hi, respond with just 'ok'.")],
            systemPrompt: "Respond with exactly 'ok' and nothing else.",
            model: "haiku",
            maxTokens: 16,
            temperature: 0,
            toolConfigs: [],
            projectPath: nil
        )
    }
}
