import Foundation

struct NodeEdge: Identifiable, Codable, Equatable {
    let id: UUID
    var sourceNodeID: UUID
    var sourcePortID: UUID
    var targetNodeID: UUID
    var targetPortID: UUID

    init(
        id: UUID = UUID(),
        sourceNodeID: UUID,
        sourcePortID: UUID,
        targetNodeID: UUID,
        targetPortID: UUID
    ) {
        self.id = id
        self.sourceNodeID = sourceNodeID
        self.sourcePortID = sourcePortID
        self.targetNodeID = targetNodeID
        self.targetPortID = targetPortID
    }
}
