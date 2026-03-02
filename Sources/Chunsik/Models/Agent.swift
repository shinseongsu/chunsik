import Foundation

struct Agent: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var role: String
    var systemPrompt: String
    var status: AgentStatus
    var avatarColor: AvatarColor
    var avatarAnimation: String
    var conversationHistory: [ChatMessage]
    var presetPrompts: [String]
    var agentRole: AgentRole
    var toolConfigs: [ToolConfig]
    var projectPath: String
    var projectAlias: String

    enum AvatarColor: String, Codable, CaseIterable {
        case blue, green, orange, purple, pink, red, yellow, teal

        var displayName: String {
            switch self {
            case .blue: return "파랑"
            case .green: return "초록"
            case .orange: return "주황"
            case .purple: return "보라"
            case .pink: return "분홍"
            case .red: return "빨강"
            case .yellow: return "노랑"
            case .teal: return "청록"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, role, systemPrompt, status, avatarColor, avatarAnimation, conversationHistory, presetPrompts, agentRole, toolConfigs, projectPath, projectAlias
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        role = try container.decode(String.self, forKey: .role)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        status = try container.decode(AgentStatus.self, forKey: .status)
        avatarColor = try container.decode(AvatarColor.self, forKey: .avatarColor)
        avatarAnimation = try container.decode(String.self, forKey: .avatarAnimation)
        conversationHistory = try container.decode([ChatMessage].self, forKey: .conversationHistory)
        presetPrompts = try container.decodeIfPresent([String].self, forKey: .presetPrompts) ?? []
        agentRole = try container.decodeIfPresent(AgentRole.self, forKey: .agentRole) ?? .custom
        toolConfigs = try container.decodeIfPresent([ToolConfig].self, forKey: .toolConfigs) ?? []
        projectPath = try container.decodeIfPresent(String.self, forKey: .projectPath) ?? ""
        projectAlias = try container.decodeIfPresent(String.self, forKey: .projectAlias) ?? ""
    }

    init(
        id: UUID = UUID(),
        name: String,
        role: String,
        systemPrompt: String = "",
        status: AgentStatus = .idle,
        avatarColor: AvatarColor = .blue,
        avatarAnimation: String = "duo_character",
        conversationHistory: [ChatMessage] = [],
        presetPrompts: [String] = [],
        agentRole: AgentRole = .custom,
        toolConfigs: [ToolConfig] = [],
        projectPath: String = "",
        projectAlias: String = ""
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.systemPrompt = systemPrompt
        self.status = status
        self.avatarColor = avatarColor
        self.avatarAnimation = avatarAnimation
        self.conversationHistory = conversationHistory
        self.presetPrompts = presetPrompts
        self.agentRole = agentRole
        self.toolConfigs = toolConfigs
        self.projectPath = projectPath
        self.projectAlias = projectAlias
    }

    static var defaultAgents: [Agent] {
        [
            Agent(
                name: "코드봇",
                role: "프로그래밍 어시스턴트",
                systemPrompt: "당신은 유능한 프로그래밍 어시스턴트입니다. 코드 작성, 디버깅, 리팩토링을 도와주세요.",
                avatarColor: .blue,
                presetPrompts: [
                    "이 코드를 리뷰해줘",
                    "버그를 찾아서 수정해줘",
                    "코드를 리팩토링해줘",
                    "테스트 코드를 작성해줘",
                ]
            ),
            Agent(
                name: "글쓰기봇",
                role: "글쓰기 도우미",
                systemPrompt: "당신은 글쓰기 전문가입니다. 문서 작성, 교정, 요약을 도와주세요.",
                avatarColor: .green,
                avatarAnimation: "duo_stay_motivated",
                presetPrompts: [
                    "이 글을 교정해줘",
                    "내용을 요약해줘",
                    "이메일 초안을 작성해줘",
                    "보고서를 작성해줘",
                ]
            ),
            Agent(
                name: "분석봇",
                role: "데이터 분석가",
                systemPrompt: "당신은 데이터 분석 전문가입니다. 데이터 해석과 인사이트 도출을 도와주세요.",
                avatarColor: .purple,
                avatarAnimation: "duo_loop",
                presetPrompts: [
                    "데이터를 분석해줘",
                    "인사이트를 도출해줘",
                    "트렌드를 파악해줘",
                    "보고서를 작성해줘",
                ]
            ),
            Agent(
                name: "창작봇",
                role: "창작 도우미",
                systemPrompt: "당신은 창의적인 콘텐츠 제작 전문가입니다. 아이디어 구상과 창작을 도와주세요.",
                avatarColor: .pink,
                avatarAnimation: "duo_super",
                presetPrompts: [
                    "아이디어를 브레인스토밍해줘",
                    "스토리를 만들어줘",
                    "광고 카피를 작성해줘",
                    "SNS 콘텐츠를 만들어줘",
                ]
            ),
        ]
    }

    static var defaultTeamAgents: [Agent] {
        [
            Agent(
                name: "PM봇",
                role: "프로젝트 매니저",
                systemPrompt: AgentRole.pm.defaultSystemPrompt,
                avatarColor: .orange,
                avatarAnimation: "duo_character",
                agentRole: .pm
            ),
            Agent(
                name: "백엔드봇",
                role: "백엔드 개발자",
                systemPrompt: AgentRole.backend.defaultSystemPrompt,
                avatarColor: .blue,
                avatarAnimation: "duo_loop",
                agentRole: .backend
            ),
            Agent(
                name: "프론트봇",
                role: "프론트엔드 개발자",
                systemPrompt: AgentRole.frontend.defaultSystemPrompt,
                avatarColor: .green,
                avatarAnimation: "duo_stay_motivated",
                agentRole: .frontend
            ),
            Agent(
                name: "QA봇",
                role: "QA 엔지니어",
                systemPrompt: AgentRole.qa.defaultSystemPrompt,
                avatarColor: .red,
                avatarAnimation: "duo_super",
                agentRole: .qa
            ),
        ]
    }
}
