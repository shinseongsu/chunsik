import Foundation

@MainActor
final class NodeOutputStore: ObservableObject {
    @Published var outputs: [UUID: String] = [:]
    @Published var isStreaming: [UUID: Bool] = [:]

    func append(_ text: String, for nodeID: UUID) {
        outputs[nodeID, default: ""] += text
    }

    func startStreaming(for nodeID: UUID) {
        outputs[nodeID] = ""
        isStreaming[nodeID] = true
    }

    func setComplete(for nodeID: UUID) {
        isStreaming[nodeID] = false
    }

    func clear(for nodeID: UUID) {
        outputs.removeValue(forKey: nodeID)
        isStreaming.removeValue(forKey: nodeID)
    }

    func reset() {
        outputs.removeAll()
        isStreaming.removeAll()
    }
}
