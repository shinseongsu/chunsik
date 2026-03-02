import Foundation

struct GraphExecutionEngine {
    let nodes: [WorkflowNode]
    let edges: [NodeEdge]

    func executionLevels() -> [[UUID]] {
        let nodeIDs = Set(nodes.map(\.id))
        var inDegree: [UUID: Int] = [:]
        var adjacency: [UUID: [UUID]] = [:]

        for id in nodeIDs {
            inDegree[id] = 0
            adjacency[id] = []
        }

        for edge in edges {
            guard nodeIDs.contains(edge.sourceNodeID),
                  nodeIDs.contains(edge.targetNodeID) else { continue }
            adjacency[edge.sourceNodeID, default: []].append(edge.targetNodeID)
            inDegree[edge.targetNodeID, default: 0] += 1
        }

        var levels: [[UUID]] = []
        var queue: [UUID] = nodeIDs.filter { inDegree[$0] == 0 }

        while !queue.isEmpty {
            levels.append(queue)
            var nextQueue: [UUID] = []
            for nodeID in queue {
                for neighbor in adjacency[nodeID] ?? [] {
                    inDegree[neighbor, default: 0] -= 1
                    if inDegree[neighbor] == 0 {
                        nextQueue.append(neighbor)
                    }
                }
            }
            queue = nextQueue
        }

        return levels
    }

    func hasCycle() -> Bool {
        let totalScheduled = executionLevels().flatMap { $0 }.count
        return totalScheduled < nodes.count
    }

    func predecessors(of nodeID: UUID) -> [UUID] {
        edges
            .filter { $0.targetNodeID == nodeID }
            .map(\.sourceNodeID)
    }

    func aggregateInputs(for nodeID: UUID, allNodes: [WorkflowNode]) -> String {
        let predIDs = predecessors(of: nodeID)
        let nodeMap = Dictionary(uniqueKeysWithValues: allNodes.map { ($0.id, $0) })

        let inputs = predIDs.compactMap { id -> String? in
            guard let node = nodeMap[id], !node.outputData.isEmpty else { return nil }
            return "## \(node.title) 결과\n\(node.outputData)"
        }

        return inputs.joined(separator: "\n\n")
    }
}
