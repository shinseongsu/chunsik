import Foundation

final class ClaudeCodeService: MessageService {

    private static let defaultTimeoutSeconds: Double = 120

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    enum ServiceError: LocalizedError {
        case claudeNotFound
        case executionFailed(String)
        case emptyResponse
        case timeout(Double)

        var errorDescription: String? {
            switch self {
            case .claudeNotFound:
                return "Claude Code를 찾을 수 없습니다. 터미널에서 'claude' 명령이 동작하는지 확인해주세요."
            case .executionFailed(let msg):
                return "실행 오류: \(msg)"
            case .emptyResponse:
                return "응답이 비어있습니다."
            case .timeout(let seconds):
                return "Claude Code 응답 시간이 초과되었습니다. (\(Int(seconds))초)"
            }
        }
    }

    func sendMessage(
        messages: [ChatMessage],
        systemPrompt: String?,
        model: String,
        maxTokens: Int = 4096,
        temperature: Double = 0.7,
        toolConfigs: [ToolConfig] = [],
        projectPath: String? = nil,
        timeout: Double? = 120
    ) async throws -> MessageResponse {
        guard let claudePath = Self.findClaudePath() else {
            throw ServiceError.claudeNotFound
        }

        let prompt = buildPrompt(from: messages)
        let enabledTools = toolConfigs.filter { $0.isEnabled }

        var mcpConfigPath: String?
        if !enabledTools.isEmpty {
            mcpConfigPath = try Self.writeMCPConfig(tools: enabledTools)
        }

        defer {
            if let path = mcpConfigPath {
                try? FileManager.default.removeItem(atPath: path)
            }
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MessageResponse, Error>) in
            let capturedMcpPath = mcpConfigPath
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: claudePath)

                    var env = ProcessInfo.processInfo.environment
                    env.removeValue(forKey: "CLAUDECODE")
                    process.environment = env

                    var args = ["-p", "--output-format", "json", "--model", model]

                    if let sp = systemPrompt, !sp.isEmpty {
                        args += ["--system-prompt", sp]
                    }

                    if let mcpPath = capturedMcpPath {
                        args += ["--mcp-config", mcpPath]
                    }

                    if let path = projectPath, !path.isEmpty {
                        process.currentDirectoryURL = URL(fileURLWithPath: path)
                    }

                    args.append(prompt)
                    process.arguments = args

                    print("[ClaudeCode] 실행: claude -p --model \(model) \(systemPrompt != nil ? "--system-prompt <...>" : "") \(projectPath.map { "--cwd \($0)" } ?? "") <prompt>")
                    print("[ClaudeCode] 프롬프트 길이: \(prompt.count)자")

                    let outputPipe = Pipe()
                    let errorPipe = Pipe()
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe

                    process.standardInput = FileHandle.nullDevice

                    try process.run()
                    let pid = process.processIdentifier
                    print("[ClaudeCode] 프로세스 시작 (PID: \(pid))")

                    var outputData = Data()
                    var errorData = Data()

                    let group = DispatchGroup()

                    group.enter()
                    DispatchQueue.global().async {
                        outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        group.leave()
                    }

                    group.enter()
                    DispatchQueue.global().async {
                        errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        group.leave()
                    }

                    if let timeoutSeconds = timeout {
                        let deadline = DispatchTime.now() + timeoutSeconds
                        let waitResult = group.wait(timeout: deadline)

                        if waitResult == .timedOut {
                            print("[ClaudeCode] 타임아웃 (\(Int(timeoutSeconds))초) — 프로세스 강제 종료 (PID: \(pid))")
                            process.terminate()
                            process.waitUntilExit()
                            continuation.resume(throwing: ServiceError.timeout(timeoutSeconds))
                            return
                        }
                    } else {
                        group.wait()
                    }

                    process.waitUntilExit()

                    let output = String(data: outputData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let errorOutput = String(data: errorData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                    print("[ClaudeCode] 종료 코드: \(process.terminationStatus), 응답 길이: \(output.count)자")

                    if !errorOutput.isEmpty {
                        print("[ClaudeCode] stderr: \(errorOutput.prefix(500))")
                    }

                    if process.terminationStatus != 0 {
                        let msg = errorOutput.isEmpty
                            ? "종료 코드: \(process.terminationStatus)"
                            : errorOutput
                        continuation.resume(throwing: ServiceError.executionFailed(msg))
                        return
                    }

                    if output.isEmpty {
                        continuation.resume(throwing: ServiceError.emptyResponse)
                        return
                    }

                    let parsed = Self.parseJSONOutput(output)
                    let responseText = parsed.result ?? output
                    let costUSD = parsed.costUSD
                    let inputTokens = parsed.inputTokens ?? (prompt.count / 4)
                    let outputTokens = parsed.outputTokens ?? (responseText.count / 4)

                    if responseText.isEmpty {
                        continuation.resume(throwing: ServiceError.emptyResponse)
                        return
                    }

                    let response = MessageResponse(
                        content: responseText,
                        inputTokens: inputTokens,
                        outputTokens: outputTokens,
                        costUSD: costUSD
                    )
                    continuation.resume(returning: response)
                } catch {
                    print("[ClaudeCode] 예외 발생: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
