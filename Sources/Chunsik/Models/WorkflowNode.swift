import Foundation
import CoreGraphics

struct ConversationConfig: Codable, Equatable {
    var agent1ID: UUID?
    var agent2ID: UUID?
    var maxRounds: Int
    var conversationGoal: String
    var autoTerminate: Bool

    init(
        agent1ID: UUID? = nil,
        agent2ID: UUID? = nil,
        maxRounds: Int = 3,
        conversationGoal: String = "",
        autoTerminate: Bool = true
    ) {
        self.agent1ID = agent1ID
        self.agent2ID = agent2ID
        self.maxRounds = maxRounds
        self.conversationGoal = conversationGoal
        self.autoTerminate = autoTerminate
    }
}

struct ConversationMessage: Codable, Equatable {
    let agentName: String
    let content: String
    let round: Int
}

struct WorkflowNode: Identifiable, Codable, Equatable {
    let id: UUID
    var nodeType: NodeType
    var agentRole: AgentRole?
    var agentID: UUID?
    var position: CGPointCodable
    var title: String
    var status: NodeStatus
    var inputData: String
    var outputData: String
    var inputPorts: [Port]
    var outputPorts: [Port]

    var conversationConfig: ConversationConfig?
    var conversationHistory: [ConversationMessage]

    var customSystemPrompt: String?
    var customModel: String?
    var customTemperature: Double?
    var customMaxTokens: Int?
    var customToolConfigs: [ToolConfig]?

    var hasCustomSettings: Bool {
        customSystemPrompt != nil ||
        customModel != nil ||
        customTemperature != nil ||
        customMaxTokens != nil ||
        (customToolConfigs != nil && !customToolConfigs!.isEmpty)
    }

    init(
        id: UUID = UUID(),
        nodeType: NodeType,
        agentRole: AgentRole? = nil,
        agentID: UUID? = nil,
        position: CGPointCodable = CGPointCodable(x: 0, y: 0),
        title: String = "",
        status: NodeStatus = .idle,
        inputData: String = "",
        outputData: String = "",
        inputPorts: [Port]? = nil,
        outputPorts: [Port]? = nil,
        conversationConfig: ConversationConfig? = nil,
        conversationHistory: [ConversationMessage] = [],
        customSystemPrompt: String? = nil,
        customModel: String? = nil,
        customTemperature: Double? = nil,
        customMaxTokens: Int? = nil,
        customToolConfigs: [ToolConfig]? = nil
    ) {
        self.id = id
        self.nodeType = nodeType
        self.agentRole = agentRole
        self.agentID = agentID
        self.position = position
        self.title = title.isEmpty ? (agentRole?.displayName ?? nodeType.displayName) : title
        self.status = status
        self.inputData = inputData
        self.outputData = outputData
        self.conversationConfig = conversationConfig
        self.conversationHistory = conversationHistory
        self.customSystemPrompt = customSystemPrompt
        self.customModel = customModel
        self.customTemperature = customTemperature
        self.customMaxTokens = customMaxTokens
        self.customToolConfigs = customToolConfigs

        if let inp = inputPorts {
            self.inputPorts = inp
        } else {
            switch nodeType {
            case .start:
                self.inputPorts = []
            case .agent, .conversation, .output:
                self.inputPorts = [Port(direction: .input, label: "입력")]
            }
        }

        if let out = outputPorts {
            self.outputPorts = out
        } else {
            switch nodeType {
            case .output:
                self.outputPorts = []
            case .start, .agent, .conversation:
                self.outputPorts = [Port(direction: .output, label: "출력")]
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, nodeType, agentRole, agentID, position, title, status
        case inputData, outputData, inputPorts, outputPorts
        case conversationConfig, conversationHistory
        case customSystemPrompt, customModel, customTemperature, customMaxTokens, customToolConfigs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        agentRole = try container.decodeIfPresent(AgentRole.self, forKey: .agentRole)
        agentID = try container.decodeIfPresent(UUID.self, forKey: .agentID)
        position = try container.decode(CGPointCodable.self, forKey: .position)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decode(NodeStatus.self, forKey: .status)
        inputData = try container.decodeIfPresent(String.self, forKey: .inputData) ?? ""
        outputData = try container.decodeIfPresent(String.self, forKey: .outputData) ?? ""
        inputPorts = try container.decode([Port].self, forKey: .inputPorts)
        outputPorts = try container.decode([Port].self, forKey: .outputPorts)
        conversationConfig = try container.decodeIfPresent(ConversationConfig.self, forKey: .conversationConfig)
        conversationHistory = try container.decodeIfPresent([ConversationMessage].self, forKey: .conversationHistory) ?? []
        customSystemPrompt = try container.decodeIfPresent(String.self, forKey: .customSystemPrompt)
        customModel = try container.decodeIfPresent(String.self, forKey: .customModel)
        customTemperature = try container.decodeIfPresent(Double.self, forKey: .customTemperature)
        customMaxTokens = try container.decodeIfPresent(Int.self, forKey: .customMaxTokens)
        customToolConfigs = try container.decodeIfPresent([ToolConfig].self, forKey: .customToolConfigs)
    }

    static func == (lhs: WorkflowNode, rhs: WorkflowNode) -> Bool {
        lhs.id == rhs.id
    }
}
