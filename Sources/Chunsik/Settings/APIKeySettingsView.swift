import SwiftUI

struct ClaudeCodeStatusView: View {
    @State private var isAvailable = false
    @State private var claudePath: String?

    var body: some View {
        GroupBox("Claude Code 상태") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if isAvailable {
                        Label("연결됨", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("찾을 수 없음", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Button("새로고침") {
                        checkStatus()
                    }
                    .font(.caption)
                }

                if let path = claudePath {
                    Text("경로: \(path)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                if !isAvailable {
                    Text("Claude Code CLI를 설치해주세요.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
        }
        .onAppear {
            checkStatus()
        }
    }

    private func checkStatus() {
        claudePath = ClaudeCodeService.findClaudePath()
        isAvailable = claudePath != nil
    }
}
