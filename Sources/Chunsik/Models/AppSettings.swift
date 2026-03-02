import Foundation

enum ServiceType: String, Codable, CaseIterable {
    case claudeCode = "claude_code"
    case claudeAPI = "claude_api"

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code CLI"
        case .claudeAPI: return "Claude API"
        }
    }
}

struct AppSettings: Codable {
    var serviceType: ServiceType
    var model: ClaudeModel
    var maxTokens: Int
    var temperature: Double

    enum ClaudeModel: String, Codable, CaseIterable {
        case sonnet = "claude-sonnet-4-6"
        case haiku = "claude-haiku-4-5-20251001"
        case opus = "claude-opus-4-6"

        var displayName: String {
            switch self {
            case .sonnet: return "Claude Sonnet 4.6"
            case .haiku: return "Claude Haiku 4.5"
            case .opus: return "Claude Opus 4.6"
            }
        }

        var apiModelID: String {
            rawValue
        }
    }

    static var `default`: AppSettings {
        AppSettings(
            serviceType: .claudeCode,
            model: .sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
    }

    init(serviceType: ServiceType = .claudeCode, model: ClaudeModel, maxTokens: Int, temperature: Double) {
        self.serviceType = serviceType
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.serviceType = (try? container.decode(ServiceType.self, forKey: .serviceType)) ?? .claudeCode
        self.model = try container.decode(ClaudeModel.self, forKey: .model)
        self.maxTokens = try container.decode(Int.self, forKey: .maxTokens)
        self.temperature = try container.decode(Double.self, forKey: .temperature)
    }
}
