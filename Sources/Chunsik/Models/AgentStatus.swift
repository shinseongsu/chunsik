import SwiftUI

enum AgentStatus: String, Codable, CaseIterable {
    case idle = "idle"
    case working = "working"
    case thinking = "thinking"
    case done = "done"
    case error = "error"

    var displayName: String {
        switch self {
        case .idle: return "대기중"
        case .working: return "업무중"
        case .thinking: return "생각중"
        case .done: return "완료"
        case .error: return "오류"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .gray
        case .working: return .green
        case .thinking: return .yellow
        case .done: return .purple
        case .error: return .red
        }
    }

var systemImage: String {
        switch self {
        case .idle: return "moon.zzz.fill"
        case .working: return "hammer.fill"
        case .thinking: return "brain.head.profile"
        case .done: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}
