import Foundation

enum WorkflowStatus: String, Codable {
    case idle
    case running
    case completed
    case failed

    var displayName: String {
        switch self {
        case .idle: return "대기"
        case .running: return "실행중"
        case .completed: return "완료"
        case .failed: return "실패"
        }
    }
}

struct Workflow: Identifiable, Codable {
    let id: UUID
    var name: String
    var status: WorkflowStatus
    var nodes: [WorkflowNode]
    var edges: [NodeEdge]
    var userRequirement: String
    var projectPath: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, status, nodes, edges, userRequirement, projectPath, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(WorkflowStatus.self, forKey: .status)
        nodes = try container.decode([WorkflowNode].self, forKey: .nodes)
        edges = try container.decode([NodeEdge].self, forKey: .edges)
        userRequirement = try container.decodeIfPresent(String.self, forKey: .userRequirement) ?? ""
        projectPath = try container.decodeIfPresent(String.self, forKey: .projectPath) ?? ""
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    init(
        id: UUID = UUID(),
        name: String = "새 워크플로우",
        status: WorkflowStatus = .idle,
        nodes: [WorkflowNode]? = nil,
        edges: [NodeEdge]? = nil,
        userRequirement: String = "",
        projectPath: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.nodes = nodes ?? Self.defaultNodes()
        self.edges = edges ?? Self.defaultEdges(nodes: nil)
        self.userRequirement = userRequirement
        self.projectPath = projectPath
        self.createdAt = createdAt

        if nodes == nil && edges == nil {
            self.edges = Self.defaultEdges(nodes: self.nodes)
        }
    }

    static func defaultNodes() -> [WorkflowNode] {
        [
            WorkflowNode(
                nodeType: .start,
                position: CGPointCodable(x: 100, y: 300),
                title: "시작"
            ),
            WorkflowNode(
                nodeType: .agent,
                agentRole: .pm,
                position: CGPointCodable(x: 350, y: 300),
                title: "PM"
            ),
            WorkflowNode(
                nodeType: .agent,
                agentRole: .backend,
                position: CGPointCodable(x: 600, y: 200),
                title: "백엔드"
            ),
            WorkflowNode(
                nodeType: .agent,
                agentRole: .frontend,
                position: CGPointCodable(x: 600, y: 400),
                title: "프론트엔드"
            ),
            WorkflowNode(
                nodeType: .agent,
                agentRole: .qa,
                position: CGPointCodable(x: 850, y: 300),
                title: "QA"
            ),
            WorkflowNode(
                nodeType: .output,
                position: CGPointCodable(x: 1100, y: 300),
                title: "출력"
            ),
        ]
    }

    static func defaultEdges(nodes: [WorkflowNode]?) -> [NodeEdge] {
        guard let nodes = nodes, nodes.count >= 6 else { return [] }

        let start = nodes[0]
        let pm = nodes[1]
        let backend = nodes[2]
        let frontend = nodes[3]
        let qa = nodes[4]
        let output = nodes[5]

        return [
            NodeEdge(
                sourceNodeID: start.id,
                sourcePortID: start.outputPorts.first!.id,
                targetNodeID: pm.id,
                targetPortID: pm.inputPorts.first!.id
            ),
            NodeEdge(
                sourceNodeID: pm.id,
                sourcePortID: pm.outputPorts.first!.id,
                targetNodeID: backend.id,
                targetPortID: backend.inputPorts.first!.id
            ),
            NodeEdge(
                sourceNodeID: pm.id,
                sourcePortID: pm.outputPorts.first!.id,
                targetNodeID: frontend.id,
                targetPortID: frontend.inputPorts.first!.id
            ),
            NodeEdge(
                sourceNodeID: backend.id,
                sourcePortID: backend.outputPorts.first!.id,
                targetNodeID: qa.id,
                targetPortID: qa.inputPorts.first!.id
            ),
            NodeEdge(
                sourceNodeID: frontend.id,
                sourcePortID: frontend.outputPorts.first!.id,
                targetNodeID: qa.id,
                targetPortID: qa.inputPorts.first!.id
            ),
            NodeEdge(
                sourceNodeID: qa.id,
                sourcePortID: qa.outputPorts.first!.id,
                targetNodeID: output.id,
                targetPortID: output.inputPorts.first!.id
            ),
        ]
    }

    func node(by id: UUID) -> WorkflowNode? {
        nodes.first { $0.id == id }
    }

    mutating func updateNode(_ node: WorkflowNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }
}
