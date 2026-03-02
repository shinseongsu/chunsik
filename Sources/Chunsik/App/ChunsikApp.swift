import SwiftUI

@main
struct ChunsikApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.settingsStore)
        }
    }
}

struct MenuBarStatusHeader: View {
    @ObservedObject var connectionMonitor: ConnectionMonitor
    @ObservedObject var tokenTracker: TokenTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("춘식이")
                .font(.headline)

            HStack(spacing: 6) {
                Circle()
                    .fill(connectionMonitor.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(connectionMonitor.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("오늘 전체 사용량")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("세션 \(tokenTracker.claudeSessionCount)개")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                usageRow(label: "입력", value: tokenTracker.claudeInputDisplay, icon: "arrow.up.circle")
                usageRow(label: "출력", value: tokenTracker.claudeOutputDisplay, icon: "arrow.down.circle")
                usageRow(label: "캐시", value: tokenTracker.claudeCacheDisplay, icon: "internaldrive")

                HStack {
                    Label("합계", systemImage: "sum")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(tokenTracker.claudeTotalDisplay) tok")
                        .font(.caption2.monospacedDigit().bold())
                }
            }

            if tokenTracker.appTotalTokens > 0 {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("이 앱에서 사용")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    usageRow(label: "입력", value: tokenTracker.appInputDisplay, icon: "arrow.up.circle")
                    usageRow(label: "출력", value: tokenTracker.appOutputDisplay, icon: "arrow.down.circle")

                    if tokenTracker.appCostUSD > 0 {
                        usageRow(label: "비용", value: tokenTracker.costDisplay, icon: "dollarsign.circle")
                    }

                    Text("요청 \(tokenTracker.appRequestCount)회")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if let lastRefresh = tokenTracker.lastFullRefresh {
                Divider()
                Text("최종 갱신: \(lastRefresh, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func usageRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
        }
    }
}
