import SwiftUI

extension SettingsView {
    var claudeCodeStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if claudeAvailable {
                    Label("Claude Code가 연결되었습니다", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("Claude Code를 찾을 수 없습니다", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                Spacer()
            }
            .font(.caption)

            if !claudeAvailable {
                Text("터미널에서 'claude' 명령이 동작하는지 확인해주세요.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    var claudeAPISettingsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SecureField("API 키 입력", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)

                Button(action: saveAPIKey) {
                    Text("저장")
                }
                .disabled(apiKeyInput.isEmpty)
            }

            if apiKeySaved {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("API 키가 Keychain에 저장되어 있습니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(role: .destructive, action: deleteAPIKey) {
                        Text("삭제")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                Button(action: testConnection) {
                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 2)
                        Text("테스트 중...")
                    } else {
                        Text("연결 테스트")
                    }
                }
                .disabled(isTesting || (!apiKeySaved && apiKeyInput.isEmpty))

                if let result = testResult {
                    switch result {
                    case .success:
                        Label("연결 성공", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    case .failure(let msg):
                        Label(msg, systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    func saveAPIKey() {
        let success = KeychainHelper.save(key: "claude_api_key", value: apiKeyInput)
        if success {
            apiKeySaved = true
            apiKeyInput = ""
            testResult = nil
        }
    }

    func deleteAPIKey() {
        KeychainHelper.delete(key: "claude_api_key")
        apiKeySaved = false
        apiKeyInput = ""
        testResult = nil
    }

    func testConnection() {
        isTesting = true
        testResult = nil

        let key = apiKeyInput.isEmpty
            ? (KeychainHelper.load(key: "claude_api_key") ?? "")
            : apiKeyInput

        Task {
            do {
                try await ClaudeAPIService.testConnection(apiKey: key)
                await MainActor.run {
                    testResult = .success
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = .failure(error.localizedDescription)
                    isTesting = false
                }
            }
        }
    }
}
