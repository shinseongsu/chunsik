import SwiftUI
import AppKit

class FloatingCharacterWindow: NSPanel {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow
        isReleasedWhenClosed = false
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

struct FloatingCharacterView: View {
    @EnvironmentObject var agentManager: AgentManager
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Color.clear
            VStack {
                Spacer()
                HStack(spacing: 80) {
                    ForEach(agentManager.agents) { agent in
                        CharacterCard(agent: agent, isSelected: agent.id == agentManager.selectedAgentID)
                            .onTapGesture {
                                agentManager.selectedAgentID = agent.id
                                onTap()
                            }
                    }
                }
                .padding(12)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                )
            }
        }
    }
}

private struct CharacterCard: View {
    let agent: Agent
    let isSelected: Bool

    private var agentColor: Color {
        switch agent.avatarColor {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .yellow: return .yellow
        case .teal: return .teal
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(agent.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 2)
            StatusBadge(status: agent.status)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? agentColor.opacity(0.3) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? agentColor : .clear, lineWidth: 2)
                )
        )
        .overlay(alignment: .bottom) {
            LottieViewRepresentable(animationName: agent.avatarAnimation)
                .frame(width: 800, height: 800)
                .scaleEffect(0.18)
                .frame(width: 140, height: 140)
                .offset(y: -40)
                .allowsHitTesting(false)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct StatusBadge: View {
    let status: AgentStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(status.color).frame(width: 6, height: 6)
            Text(status.displayName)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(status.color.opacity(0.8)))
    }
}
