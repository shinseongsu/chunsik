import SwiftUI

struct ChatView: View {
    @EnvironmentObject var agentManager: AgentManager
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var inputText = ""

    var agent: Agent

    private var isLoading: Bool {
        guard let liveAgent = agentManager.agents.first(where: { $0.id == agent.id }) else {
            return false
        }
        return liveAgent.status == .thinking || liveAgent.status == .working
    }

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            Divider()

            if agent.conversationHistory.isEmpty {
                emptyState
            } else {
                messageList
            }

            Divider()

            ChatInputView(
                text: $inputText,
                isLoading: isLoading
            ) {
                sendMessage()
            }
        }
    }

    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(agent.name)
                    .font(.headline)
                Text(agent.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadge(status: agent.status)

            Button {
                agentManager.clearConversation(agentID: agent.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("대화 내역 삭제")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text("\(agent.name)와 대화를 시작하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !ClaudeCodeService.isAvailable {
                Label("Claude Code가 설치되어 있지 않습니다", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            if !agent.presetPrompts.isEmpty {
                VStack(spacing: 8) {
                    Text("빠른 시작")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(agent.presetPrompts, id: \.self) { prompt in
                        Button {
                            sendPresetPrompt(prompt)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.accentColor)
                                Text(prompt)
                                    .font(.system(size: 13))
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.controlBackgroundColor))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: 500)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(agent.conversationHistory) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("생각하는 중...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("loading")
                    }
                }
                .padding()
            }
            .onChange(of: agent.conversationHistory.count) { _, _ in
                withAnimation {
                    if let last = agent.conversationHistory.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        inputText = ""

        Task {
            await agentManager.sendMessage(
                content,
                to: agent.id,
                settings: settingsStore.settings
            )
        }
    }

    private func sendPresetPrompt(_ prompt: String) {
        Task {
            await agentManager.sendMessage(
                prompt,
                to: agent.id,
                settings: settingsStore.settings
            )
        }
    }
}
