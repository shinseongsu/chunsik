import Foundation

extension ClaudeCodeService {

    func sendMessageStreaming(
        messages: [ChatMessage],
        systemPrompt: String?,
        model: String,
        maxTokens: Int = 4096,
        temperature: Double = 0.7,
        toolConfigs: [ToolConfig] = [],
        projectPath: String? = nil,
        timeout: Double? = 120,
        onPartialOutput: @Sendable @escaping (String) -> Void
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

                    var args = ["-p", "--verbose", "--output-format", "stream-json", "--model", model]

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

                    var displayArgs = ["claude", "-p", "--verbose", "--output-format", "stream-json", "--model", model]
                    if systemPrompt != nil { displayArgs += ["--system-prompt", "\"...\""] }
                    if capturedMcpPath != nil { displayArgs += ["--mcp-config", "<tmp>"] }
                    let displayCmd = displayArgs.joined(separator: " ")
                    let cwd = projectPath ?? FileManager.default.currentDirectoryPath

                    let header = """
                    \u{001B}[32m$ \(displayCmd)\u{001B}[0m
                    \u{001B}[90m  cwd: \(cwd)
                      prompt: \(prompt.count)자 (\(prompt.count / 4)토큰 추정)
                      maxTokens: \(maxTokens) | temperature: \(temperature)
                      ──────────────────────────────────────\u{001B}[0m\n
                    """
                    onPartialOutput(header)

                    let outputPipe = Pipe()
                    let errorPipe = Pipe()
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe
                    process.standardInput = FileHandle.nullDevice

                    let lock = NSLock()
                    var contentText = ""
                    var resultJSON: [String: Any]?
                    var lineBuffer = ""

                    let readSemaphore = DispatchSemaphore(value: 0)
                    outputPipe.fileHandleForReading.readabilityHandler = { handle in
                        let data = handle.availableData
                        if data.isEmpty {
                            handle.readabilityHandler = nil
                            readSemaphore.signal()
                            return
                        }
                        guard let chunk = String(data: data, encoding: .utf8) else { return }

                        lock.lock()
                        lineBuffer += chunk
                        while let newlineRange = lineBuffer.range(of: "\n") {
                            let line = String(lineBuffer[lineBuffer.startIndex..<newlineRange.lowerBound])
                            lineBuffer = String(lineBuffer[newlineRange.upperBound...])
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { continue }
                            lock.unlock()
                            Self.handleStreamLine(trimmed, contentText: &contentText, resultJSON: &resultJSON, onPartialOutput: onPartialOutput)
                            lock.lock()
                        }
                        lock.unlock()
                    }

                    var errorData = Data()
                    let errorLock = NSLock()
                    let errorSemaphore = DispatchSemaphore(value: 0)
                    errorPipe.fileHandleForReading.readabilityHandler = { handle in
                        let data = handle.availableData
                        if data.isEmpty {
                            handle.readabilityHandler = nil
                            errorSemaphore.signal()
                            return
                        }
                        errorLock.withLock { errorData.append(data) }
                        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                            onPartialOutput("\u{001B}[33m\(text)\u{001B}[0m")
                        }
                    }

                    try process.run()
                    let pid = process.processIdentifier
                    let startTime = Date()
                    onPartialOutput("\u{001B}[90m  PID: \(pid) | 시작: \(Self.timeFormatter.string(from: startTime))\u{001B}[0m\n\n")

                    if let timeoutSeconds = timeout {
                        let deadline = DispatchTime.now() + timeoutSeconds
                        if readSemaphore.wait(timeout: deadline) == .timedOut {
                            outputPipe.fileHandleForReading.readabilityHandler = nil
                            errorPipe.fileHandleForReading.readabilityHandler = nil
                            process.terminate()
                            process.waitUntilExit()
                            onPartialOutput("\n\u{001B}[31m  TIMEOUT (\(Int(timeoutSeconds))초 초과)\u{001B}[0m\n")
                            continuation.resume(throwing: ServiceError.timeout(timeoutSeconds))
                            return
                        }
                    } else {
                        readSemaphore.wait()
                    }

                    errorSemaphore.wait()
                    process.waitUntilExit()

                    let elapsed = Date().timeIntervalSince(startTime)
                    let output = lock.withLock { contentText.trimmingCharacters(in: .whitespacesAndNewlines) }
                    let errorOutput = errorLock.withLock {
                        String(data: errorData, encoding: .utf8)?
                            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    }

                    let rj = lock.withLock { resultJSON }
                    let costUSD = rj?["cost_usd"] as? Double
                    let durationMs = rj?["duration_ms"] as? Int

                    var footerParts = ["종료코드: \(process.terminationStatus)", "소요: \(String(format: "%.1f", elapsed))초"]
                    if let cost = costUSD { footerParts.append("비용: $\(String(format: "%.4f", cost))") }
                    if let ms = durationMs { footerParts.append("API: \(String(format: "%.1f", Double(ms)/1000))초") }
                    footerParts.append("응답: \(output.count)자")

                    let footer = "\n\u{001B}[90m  ──────────────────────────────────────\n  \(footerParts.joined(separator: " | "))\u{001B}[0m\n"
                    onPartialOutput(footer)

                    if process.terminationStatus != 0 {
                        let msg = errorOutput.isEmpty ? "종료 코드: \(process.terminationStatus)" : errorOutput
                        onPartialOutput("\u{001B}[31m  ERROR: \(msg)\u{001B}[0m\n")
                        continuation.resume(throwing: ServiceError.executionFailed(msg))
                        return
                    }

                    if output.isEmpty {
                        onPartialOutput("\u{001B}[31m  ERROR: 응답이 비어있습니다\u{001B}[0m\n")
                        continuation.resume(throwing: ServiceError.emptyResponse)
                        return
                    }

                    let response = MessageResponse(
                        content: output,
                        inputTokens: prompt.count / 4,
                        outputTokens: output.count / 4,
                        costUSD: costUSD
                    )
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
