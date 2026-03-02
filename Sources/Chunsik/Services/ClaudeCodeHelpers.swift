import Foundation

extension ClaudeCodeService {

    static func findClaudePath() -> String? {
        let home = NSHomeDirectory()
        let candidates = [
            "/usr/local/bin/claude",
            "\(home)/.local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(home)/.claude/local/claude",
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", "which claude"]
            var env = ProcessInfo.processInfo.environment
            env.removeValue(forKey: "CLAUDECODE")
            process.environment = env
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !path.isEmpty && process.terminationStatus == 0 {
                return path
            }
        } catch {}

        return nil
    }

    static var isAvailable: Bool {
        findClaudePath() != nil
    }

    struct CLIOutput {
        let result: String?
        let costUSD: Double?
        let inputTokens: Int?
        let outputTokens: Int?
    }

    static func parseJSONOutput(_ raw: String) -> CLIOutput {
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return CLIOutput(result: raw, costUSD: nil, inputTokens: nil, outputTokens: nil)
        }

        let result = json["result"] as? String
        let costUSD = json["cost_usd"] as? Double

        var inputTokens: Int?
        var outputTokens: Int?
        if let usage = json["usage"] as? [String: Any] {
            inputTokens = usage["input_tokens"] as? Int
            outputTokens = usage["output_tokens"] as? Int
        }

        return CLIOutput(result: result, costUSD: costUSD, inputTokens: inputTokens, outputTokens: outputTokens)
    }

    static func writeMCPConfig(tools: [ToolConfig]) throws -> String {
        var servers: [String: Any] = [:]
        for tool in tools {
            servers[tool.name] = tool.mcpServerEntry
        }
        let config: [String: Any] = ["mcpServers": servers]
        let data = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
        let path = NSTemporaryDirectory() + "chunsik_mcp_\(UUID().uuidString).json"
        try data.write(to: URL(fileURLWithPath: path))
        return path
    }

    func buildPrompt(from messages: [ChatMessage]) -> String {
        let relevant = messages.filter { $0.role != .system }.suffix(20)

        guard let lastMessage = relevant.last else { return "" }

        if relevant.count == 1 {
            return lastMessage.content
        }

        var parts: [String] = []
        for msg in relevant.dropLast() {
            let role = msg.role == .user ? "사용자" : "어시스턴트"
            parts.append("[\(role)] \(msg.content)")
        }

        return """
        이전 대화 내용:
        \(parts.joined(separator: "\n\n"))

        현재 메시지: \(lastMessage.content)

        위 대화의 맥락을 이어서 현재 메시지에 응답해주세요.
        """
    }
}
