import SwiftUI

struct WorkflowResultsView: View {
    let nodes: [WorkflowNode]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(nodes.filter { $0.nodeType == .agent }) { node in
                    NodeResultCard(node: node)
                }
            }
            .padding()
        }
    }
}

struct NodeResultCard: View {
    let node: WorkflowNode
    @State private var isExpanded = false

    private var statusColor: Color {
        switch node.status {
        case .idle: return .gray
        case .waiting: return .yellow
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(node.title)
                        .font(.system(size: 13, weight: .semibold))

                    if let role = node.agentRole {
                        Text("(\(role.displayName))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Text("— \(node.status.displayName)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded && !node.outputData.isEmpty {
                Divider()

                ScrollView {
                    Text(node.outputData)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(maxHeight: 300)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct NodeResultDetailView: View {
    let node: WorkflowNode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(node.title)
                    .font(.system(size: 12, weight: .semibold))
                if let role = node.agentRole {
                    Text("· \(role.displayName)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(node.status.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                Text(node.outputData)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
