import Foundation
import Combine

@MainActor
final class ConnectionMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var statusText: String = "확인 중..."
    @Published private(set) var lastChecked: Date?

    private let settingsStore: SettingsStore
    private var timer: AnyCancellable?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        checkConnection()
        startMonitoring()
    }

    private func startMonitoring() {
        timer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkConnection()
            }
    }

    func checkConnection() {
        lastChecked = Date()

        switch settingsStore.settings.serviceType {
        case .claudeAPI:
            let hasKey = !(KeychainHelper.load(key: "claude_api_key") ?? "").isEmpty
            isConnected = hasKey
            statusText = hasKey ? "API 연결됨" : "API 키 없음"

        case .claudeCode:
            let available = ClaudeCodeService.isAvailable
            isConnected = available
            statusText = available ? "CLI 연결됨" : "CLI 없음"
        }
    }

    func testConnectionAsync() async {
        lastChecked = Date()

        switch settingsStore.settings.serviceType {
        case .claudeAPI:
            let apiKey = KeychainHelper.load(key: "claude_api_key") ?? ""
            guard !apiKey.isEmpty else {
                isConnected = false
                statusText = "API 키 없음"
                return
            }
            do {
                try await ClaudeAPIService.testConnection(apiKey: apiKey)
                isConnected = true
                statusText = "API 연결됨"
            } catch {
                isConnected = false
                statusText = "연결 실패"
            }

        case .claudeCode:
            let available = ClaudeCodeService.isAvailable
            isConnected = available
            statusText = available ? "CLI 연결됨" : "CLI 없음"
        }
    }
}
