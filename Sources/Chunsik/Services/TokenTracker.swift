import Foundation
import Combine

@MainActor
final class TokenTracker: ObservableObject {
    @Published private(set) var appInputTokens: Int = 0
    @Published private(set) var appOutputTokens: Int = 0
    @Published private(set) var appCostUSD: Double = 0
    @Published private(set) var appRequestCount: Int = 0

    @Published private(set) var claudeUsage: ClaudeUsageSnapshot?

    @Published private(set) var lastFullRefresh: Date?

    private var refreshTimer: AnyCancellable?

    var appTotalTokens: Int { appInputTokens + appOutputTokens }

    init() {
        refreshClaudeUsage()
        refreshTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshClaudeUsage()
            }
    }

    func addUsage(input: Int, output: Int, cost: Double? = nil) {
        appInputTokens += input
        appOutputTokens += output
        appRequestCount += 1
        if let c = cost, c > 0 {
            appCostUSD += c
        }
    }

    func addUsage(from response: MessageResponse) {
        let input = response.inputTokens ?? 0
        let output = response.outputTokens ?? 0
        if input > 0 || output > 0 || response.costUSD != nil {
            addUsage(input: input, output: output, cost: response.costUSD)
        }
    }

    func refreshClaudeUsage() {
        Task.detached {
            let snapshot = ClaudeUsageReader.readTodayUsage()
            await MainActor.run {
                self.claudeUsage = snapshot
                self.lastFullRefresh = Date()
            }
        }
    }

    var menuBarDisplay: String {
        let total = claudeUsage?.totalTokens ?? appTotalTokens
        return formatTokenCount(total)
    }

    var appTotalDisplay: String { formatTokenCount(appTotalTokens) }
    var appInputDisplay: String { formatTokenCount(appInputTokens) }
    var appOutputDisplay: String { formatTokenCount(appOutputTokens) }

    var costDisplay: String {
        if appCostUSD > 0 {
            return appCostUSD < 0.01
                ? String(format: "$%.4f", appCostUSD)
                : String(format: "$%.2f", appCostUSD)
        }
        return "--"
    }

    var claudeTotalDisplay: String {
        guard let u = claudeUsage else { return "--" }
        return formatTokenCount(u.totalTokens)
    }

    var claudeInputDisplay: String {
        guard let u = claudeUsage else { return "--" }
        return formatTokenCount(u.inputTokens)
    }

    var claudeOutputDisplay: String {
        guard let u = claudeUsage else { return "--" }
        return formatTokenCount(u.outputTokens)
    }

    var claudeCacheDisplay: String {
        guard let u = claudeUsage else { return "--" }
        return formatTokenCount(u.cacheReadTokens + u.cacheCreateTokens)
    }

    var claudeSessionCount: Int {
        claudeUsage?.sessionCount ?? 0
    }

    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
