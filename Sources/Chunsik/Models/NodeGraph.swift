import Foundation
import CoreGraphics

struct CGPointCodable: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat

    var cgPoint: CGPoint {
        get { CGPoint(x: x, y: y) }
        set { x = newValue.x; y = newValue.y }
    }

    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }

    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

enum NodeType: String, Codable, CaseIterable {
    case start
    case agent
    case conversation
    case output

    var displayName: String {
        switch self {
        case .start: return "시작"
        case .agent: return "에이전트"
        case .conversation: return "대화"
        case .output: return "출력"
        }
    }

    var systemImage: String {
        switch self {
        case .start: return "play.circle.fill"
        case .agent: return "person.circle.fill"
        case .conversation: return "bubble.left.and.bubble.right.fill"
        case .output: return "doc.circle.fill"
        }
    }
}

enum PortDirection: String, Codable {
    case input
    case output
}

struct Port: Identifiable, Codable, Equatable {
    let id: UUID
    var direction: PortDirection
    var label: String

    init(id: UUID = UUID(), direction: PortDirection, label: String = "") {
        self.id = id
        self.direction = direction
        self.label = label
    }
}

enum NodeStatus: String, Codable {
    case idle
    case waiting
    case running
    case completed
    case failed

    var displayName: String {
        switch self {
        case .idle: return "대기"
        case .waiting: return "대기중"
        case .running: return "실행중"
        case .completed: return "완료"
        case .failed: return "실패"
        }
    }
}
