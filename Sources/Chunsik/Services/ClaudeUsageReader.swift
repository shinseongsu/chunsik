import Foundation

struct ClaudeUsageSnapshot {
    let date: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheCreateTokens: Int
    let sessionCount: Int

    var totalTokens: Int { inputTokens + outputTokens }
    var totalWithCache: Int { inputTokens + outputTokens + cacheReadTokens + cacheCreateTokens }
}

enum ClaudeUsageReader {

    private static var projectsDir: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".claude/projects")
    }

    static func readTodayUsage() -> ClaudeUsageSnapshot {
        readUsage(for: todayString())
    }

    static func readUsage(for dateString: String) -> ClaudeUsageSnapshot {
        let fm = FileManager.default
        let projectsPath = projectsDir.path

        guard fm.fileExists(atPath: projectsPath),
              let projectDirs = try? fm.contentsOfDirectory(atPath: projectsPath) else {
            return ClaudeUsageSnapshot(date: dateString, inputTokens: 0, outputTokens: 0,
                                       cacheReadTokens: 0, cacheCreateTokens: 0, sessionCount: 0)
        }

        var totalInput = 0
        var totalOutput = 0
        var totalCacheRead = 0
        var totalCacheCreate = 0
        var sessionSet = Set<String>()

        for dir in projectDirs {
            let dirPath = projectsDir.appendingPathComponent(dir).path
            guard let files = try? fm.contentsOfDirectory(atPath: dirPath) else { continue }

            for file in files where file.hasSuffix(".jsonl") {
                let filePath = projectsDir.appendingPathComponent(dir).appendingPathComponent(file).path
                guard let data = fm.contents(atPath: filePath),
                      let content = String(data: data, encoding: .utf8) else { continue }

                var fileHasDate = false
                for line in content.components(separatedBy: .newlines) {
                    guard !line.isEmpty,
                          line.contains(dateString) else { continue }

                    guard let lineData = line.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }

                    guard let timestamp = json["timestamp"] as? String,
                          timestamp.hasPrefix(dateString) else { continue }

                    guard let message = json["message"] as? [String: Any],
                          let usage = message["usage"] as? [String: Any] else { continue }

                    totalInput += usage["input_tokens"] as? Int ?? 0
                    totalOutput += usage["output_tokens"] as? Int ?? 0
                    totalCacheRead += usage["cache_read_input_tokens"] as? Int ?? 0
                    totalCacheCreate += usage["cache_creation_input_tokens"] as? Int ?? 0
                    fileHasDate = true

                    if let sid = json["sessionId"] as? String {
                        sessionSet.insert(sid)
                    }
                }

                if !fileHasDate {
                }
            }
        }

        return ClaudeUsageSnapshot(
            date: dateString,
            inputTokens: totalInput,
            outputTokens: totalOutput,
            cacheReadTokens: totalCacheRead,
            cacheCreateTokens: totalCacheCreate,
            sessionCount: sessionSet.count
        )
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
