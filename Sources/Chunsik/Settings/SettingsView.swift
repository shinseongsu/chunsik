import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State var claudeAvailable = false
    @State var apiKeyInput = ""
    @State var apiKeySaved = false
    @State var isTesting = false
    @State var testResult: TestResult?

    enum TestResult {
        case success
        case failure(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("설정")
                .font(.headline)
                .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    GroupBox("서비스 설정") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("서비스 백엔드", selection: $settingsStore.settings.serviceType) {
                                ForEach(ServiceType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }

                            if settingsStore.settings.serviceType == .claudeCode {
                                claudeCodeStatusView
                            } else {
                                claudeAPISettingsView
                            }
                        }
                        .padding(8)
                    }

                    GroupBox("모델 설정") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("모델", selection: $settingsStore.settings.model) {
                                ForEach(AppSettings.ClaudeModel.allCases, id: \.self) { model in
                                    Text(model.displayName).tag(model)
                                }
                            }

                            HStack {
                                Text("최대 토큰: \(settingsStore.settings.maxTokens)")
                                    .font(.caption)
                                Spacer()
                                Slider(
                                    value: Binding(
                                        get: { Double(settingsStore.settings.maxTokens) },
                                        set: { settingsStore.settings.maxTokens = Int($0) }
                                    ),
                                    in: 256...8192,
                                    step: 256
                                )
                                .frame(width: 200)
                            }

                            HStack {
                                Text("Temperature: \(settingsStore.settings.temperature, specifier: "%.1f")")
                                    .font(.caption)
                                Spacer()
                                Slider(
                                    value: $settingsStore.settings.temperature,
                                    in: 0...1,
                                    step: 0.1
                                )
                                .frame(width: 200)
                            }
                        }
                        .padding(8)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("닫기") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
        .onAppear {
            claudeAvailable = ClaudeCodeService.isAvailable
            if KeychainHelper.load(key: "claude_api_key") != nil {
                apiKeySaved = true
            }
        }
    }
}
