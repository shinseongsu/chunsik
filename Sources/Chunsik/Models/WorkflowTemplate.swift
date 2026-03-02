import Foundation

struct WorkflowTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var nodes: [WorkflowNode]
    var edges: [NodeEdge]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        nodes: [WorkflowNode],
        edges: [NodeEdge],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.nodes = nodes
        self.edges = edges
        self.createdAt = createdAt
    }

    init(from workflow: Workflow) {
        self.id = UUID()
        self.name = workflow.name
        self.nodes = workflow.nodes.map { node in
            var n = node
            n.status = .idle
            n.inputData = ""
            n.outputData = ""
            return n
        }
        self.edges = workflow.edges
        self.createdAt = Date()
    }
}
