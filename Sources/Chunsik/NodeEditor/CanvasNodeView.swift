import SwiftUI

struct CanvasNodeView: View {
    let node: WorkflowNode
    let isSelected: Bool
    let edges: [NodeEdge]
    let linkedAgent: Agent?
    var allAgents: [Agent] = []
    let onDragStart: ((UUID, UUID) -> Void)?
    let onDragEnd: ((CGPoint) -> Void)?
    var onOpenSettings: (() -> Void)?

    private var headerColor: Color {
        if let role = node.agentRole {
            switch role {
            case .pm: return .orange
            case .backend: return .blue
            case .frontend: return .green
            case .qa: return .red
            case .custom: return .purple
            }
        }
        switch node.nodeType {
        case .start: return .teal
        case .output: return .indigo
        case .agent: return .gray
        case .conversation: return .purple
        }
    }

    private var statusColor: Color {
        switch node.status {
        case .idle: return .secondary
        case .waiting: return .yellow
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    private func isPortConnected(_ portID: UUID) -> Bool {
        edges.contains { $0.sourcePortID == portID || $0.targetPortID == portID }
    }

    private var effectiveToolCount: Int {
        if let custom = node.customToolConfigs { return custom.filter(\.isEnabled).count }
        return linkedAgent?.toolConfigs.filter(\.isEnabled).count ?? 0
    }

    private var hasPrompt: Bool {
        if node.customSystemPrompt != nil { return true }
        if let agent = linkedAgent, !agent.systemPrompt.isEmpty { return true }
        return node.agentRole != nil
    }

    var body: some View {
        HStack(spacing: 0) {
            if !node.inputPorts.isEmpty {
                VStack(spacing: 8) {
                    ForEach(node.inputPorts) { port in
                        PortCircle(port: port, nodeID: node.id, isConnected: isPortConnected(port.id), onDragStart: nil, onDragEnd: nil)
                    }
                }.offset(x: -6)
            }
            VStack(spacing: 0) {
                headerSection
                if node.nodeType == .agent { agentDetailSection }
                if node.nodeType == .conversation { conversationDetailSection }
                statusSection
                if !node.outputData.isEmpty { outputDataSection }
            }
            .frame(width: node.outputData.isEmpty ? 160 : 220)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1))
            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.05), radius: isSelected ? 6 : 2)
            if !node.outputPorts.isEmpty {
                VStack(spacing: 8) {
                    ForEach(node.outputPorts) { port in
                        PortCircle(port: port, nodeID: node.id, isConnected: isPortConnected(port.id), onDragStart: onDragStart, onDragEnd: onDragEnd)
                    }
                }.offset(x: 6)
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 5) {
            Image(systemName: node.nodeType.systemImage).font(.system(size: 11))
            Text(node.title).font(.system(size: 12, weight: .semibold)).lineLimit(1)
            Spacer()
            if node.hasCustomSettings {
                Image(systemName: "gearshape.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.8))
            }
        }
        .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6).background(headerColor)
    }

    private var agentDetailSection: some View {
        HStack(spacing: 4) {
            if let agent = linkedAgent {
                Image(systemName: "person.fill").font(.system(size: 8))
                Text(agent.name).font(.system(size: 9)).lineLimit(1)
            } else if let role = node.agentRole {
                Image(systemName: "person.fill").font(.system(size: 8))
                Text(role.displayName).font(.system(size: 9)).lineLimit(1)
            }
            Spacer()
            if hasPrompt { Image(systemName: "text.bubble.fill").font(.system(size: 7)).help("프롬프트 설정됨") }
            if effectiveToolCount > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "puzzlepiece.fill").font(.system(size: 7))
                    Text("\(effectiveToolCount)").font(.system(size: 8, design: .monospaced))
                }.help("MCP 도구 \(effectiveToolCount)개")
            }
            if let model = node.customModel {
                Text(model.prefix(3).uppercased())
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 3).padding(.vertical, 1)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 2)).help("커스텀 모델: \(model)")
            }
        }
        .foregroundColor(.secondary).padding(.horizontal, 10).padding(.vertical, 3)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
    }

    private var conversationDetailSection: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                let a1 = node.conversationConfig?.agent1ID.flatMap { id in allAgents.first { $0.id == id } }?.name ?? "에이전트1"
                let a2 = node.conversationConfig?.agent2ID.flatMap { id in allAgents.first { $0.id == id } }?.name ?? "에이전트2"
                Image(systemName: "person.fill").font(.system(size: 8))
                Text(a1).font(.system(size: 9, weight: .medium)).lineLimit(1)
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 7))
                Text(a2).font(.system(size: 9, weight: .medium)).lineLimit(1)
                Spacer()
            }
            HStack(spacing: 4) {
                let cur = node.conversationHistory.isEmpty ? 0 : (node.conversationHistory.last?.round ?? 0)
                let max = node.conversationConfig?.maxRounds ?? 3
                Image(systemName: "repeat").font(.system(size: 7))
                Text("라운드 \(cur)/\(max)").font(.system(size: 9))
                Spacer()
                if let lastMsg = node.conversationHistory.last {
                    Text("[\(lastMsg.agentName)]").font(.system(size: 8, weight: .medium))
                }
            }
        }
        .foregroundColor(.secondary).padding(.horizontal, 10).padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
    }

    private var statusSection: some View {
        HStack(spacing: 6) {
            Circle().fill(statusColor).frame(width: 6, height: 6)
            Text(node.status.displayName).font(.system(size: 10)).foregroundColor(.secondary)
            Spacer()
            if node.status == .running { ProgressView().scaleEffect(0.5).frame(width: 12, height: 12) }
            if node.nodeType == .agent || node.nodeType == .conversation {
                Button { onOpenSettings?() } label: {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 9)).foregroundColor(.secondary)
                }.buttonStyle(.plain).help("노드 설정")
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5).background(Color(nsColor: .controlBackgroundColor))
    }

    private var outputDataSection: some View {
        Group {
            Divider()
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 3) {
                    Image(systemName: node.status == .completed ? "checkmark.circle.fill" : "ellipsis.circle.fill")
                        .font(.system(size: 8)).foregroundColor(node.status == .completed ? .green : .blue)
                    Text(node.status == .completed ? "응답 완료" : "응답 중...")
                        .font(.system(size: 8, weight: .medium)).foregroundColor(.secondary)
                }
                Text(node.outputData.prefix(120) + (node.outputData.count > 120 ? "..." : ""))
                    .font(.system(size: 9)).foregroundColor(.primary.opacity(0.8)).lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
    }
}
