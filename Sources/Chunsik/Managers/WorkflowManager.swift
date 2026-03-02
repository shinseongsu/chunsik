import Foundation
import SwiftUI

@MainActor
final class WorkflowManager: ObservableObject {
    @Published var currentWorkflow: Workflow?
    @Published var workflowHistory: [Workflow] = []
    @Published var selectedNodeID: UUID?
    @Published var selectedEdgeID: UUID?
    @Published var savedTemplates: [WorkflowTemplate] = []

    let agentManager: AgentManager
    let settingsStore: SettingsStore
    let nodeOutputStore: NodeOutputStore

    private let workflowsKey = "com.chunsik.workflows"
    private let templatesKey = "com.chunsik.templates"

    init(agentManager: AgentManager, settingsStore: SettingsStore, nodeOutputStore: NodeOutputStore) {
        self.agentManager = agentManager
        self.settingsStore = settingsStore
        self.nodeOutputStore = nodeOutputStore
        loadTemplates()
    }

    var isRunning: Bool {
        currentWorkflow?.status == .running
    }

    func addNode(_ node: WorkflowNode) {
        currentWorkflow?.nodes.append(node)
    }

    func removeNode(_ nodeID: UUID) {
        currentWorkflow?.nodes.removeAll { $0.id == nodeID }
        currentWorkflow?.edges.removeAll { $0.sourceNodeID == nodeID || $0.targetNodeID == nodeID }
        if selectedNodeID == nodeID { selectedNodeID = nil }
    }

    func moveNode(_ nodeID: UUID, to position: CGPoint) {
        if let index = currentWorkflow?.nodes.firstIndex(where: { $0.id == nodeID }) {
            currentWorkflow?.nodes[index].position = CGPointCodable(position)
        }
    }

    func addEdge(_ edge: NodeEdge) {
        guard currentWorkflow?.edges.contains(where: {
            $0.sourceNodeID == edge.sourceNodeID &&
            $0.sourcePortID == edge.sourcePortID &&
            $0.targetNodeID == edge.targetNodeID &&
            $0.targetPortID == edge.targetPortID
        }) != true else { return }

        currentWorkflow?.edges.append(edge)
    }

    func removeEdge(_ edgeID: UUID) {
        currentWorkflow?.edges.removeAll { $0.id == edgeID }
        if selectedEdgeID == edgeID { selectedEdgeID = nil }
    }

    func newWorkflow() {
        currentWorkflow = Workflow()
        linkNodesToAgents()
        selectedNodeID = nil
        selectedEdgeID = nil
    }

    func ensureWorkflow() {
        if currentWorkflow == nil {
            newWorkflow()
        }
    }

    func linkNodesToAgents() {
        guard currentWorkflow != nil else { return }
        for i in currentWorkflow!.nodes.indices {
            let node = currentWorkflow!.nodes[i]
            if node.nodeType == .agent, node.agentID == nil, let role = node.agentRole {
                if let agent = agentManager.agent(for: role) {
                    currentWorkflow!.nodes[i].agentID = agent.id
                }
            }
        }
    }

    func resolvedAgent(for node: WorkflowNode) -> Agent? {
        if let agentID = node.agentID {
            return agentManager.agents.first { $0.id == agentID }
        } else if let role = node.agentRole {
            return agentManager.agent(for: role)
        }
        return nil
    }

    func saveAsTemplate(name: String) {
        guard let workflow = currentWorkflow else { return }
        let template = WorkflowTemplate(from: workflow)
        var t = template
        t = WorkflowTemplate(
            id: template.id,
            name: name,
            nodes: template.nodes,
            edges: template.edges,
            createdAt: template.createdAt
        )
        savedTemplates.append(t)
        persistTemplates()
    }

    func loadTemplate(_ template: WorkflowTemplate) {
        var workflow = Workflow(
            name: template.name,
            nodes: template.nodes,
            edges: template.edges
        )
        workflow.status = .idle
        currentWorkflow = workflow
        selectedNodeID = nil
        selectedEdgeID = nil
    }

    func deleteTemplate(_ templateID: UUID) {
        savedTemplates.removeAll { $0.id == templateID }
        persistTemplates()
    }

    private func persistTemplates() {
        if let data = try? JSONEncoder().encode(savedTemplates) {
            UserDefaults.standard.set(data, forKey: templatesKey)
        }
    }

    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([WorkflowTemplate].self, from: data) {
            savedTemplates = decoded
        }
    }

    enum WorkflowError: LocalizedError {
        case cycleDetected
        case noWorkflow

        var errorDescription: String? {
            switch self {
            case .cycleDetected:
                return "워크플로우에 순환이 감지되었습니다. 연결을 확인해주세요."
            case .noWorkflow:
                return "활성 워크플로우가 없습니다."
            }
        }
    }

    enum ConversationError: LocalizedError {
        case missingAgents

        var errorDescription: String? {
            switch self {
            case .missingAgents:
                return "대화 노드에 에이전트가 설정되지 않았습니다."
            }
        }
    }
}
