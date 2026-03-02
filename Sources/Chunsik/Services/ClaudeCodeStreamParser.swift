import Foundation

extension ClaudeCodeService {
    static func handleStreamLine(
        _ trimmed: String,
        contentText: inout String,
        resultJSON: inout [String: Any]?,
        onPartialOutput: @escaping (String) -> Void
    ) {
        guard let jsonData = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let type = json["type"] as? String else {
            onPartialOutput(trimmed + "\n")
            return
        }

        switch type {
        case "assistant":
            let contentBlocks: [[String: Any]]? =
                (json["message"] as? [String: Any])?["content"] as? [[String: Any]]
                ?? json["content"] as? [[String: Any]]

            if let blocks = contentBlocks {
                for block in blocks {
                    guard let blockType = block["type"] as? String else { continue }
                    if blockType == "text", let text = block["text"] as? String, !text.isEmpty {
                        contentText += text
                        onPartialOutput(text + "\n")
                    } else if blockType == "tool_use" {
                        let toolName = block["name"] as? String ?? "unknown"
                        onPartialOutput("\u{001B}[36m[tool_use] \(toolName)\u{001B}[0m\n")
                    } else if blockType == "tool_result" {
                        let toolID = block["tool_use_id"] as? String ?? ""
                        onPartialOutput("\u{001B}[90m[tool_result \(toolID.prefix(8))...]\u{001B}[0m\n")
                    }
                }
            }

        case "user":
            let contentBlocks: [[String: Any]]? =
                (json["message"] as? [String: Any])?["content"] as? [[String: Any]]
                ?? json["content"] as? [[String: Any]]

            if let blocks = contentBlocks {
                for block in blocks {
                    if let blockType = block["type"] as? String, blockType == "tool_result" {
                        let content = block["content"] as? String ?? ""
                        let preview = content.prefix(200)
                        onPartialOutput("\u{001B}[33m[tool_result] \(preview)\(content.count > 200 ? "..." : "")\u{001B}[0m\n")
                    }
                }
            }

        case "content_block_delta":
            if let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                contentText += text
                onPartialOutput(text)
            }

        case "result":
            resultJSON = json
            if let resultText = json["result"] as? String {
                if contentText.isEmpty {
                    contentText = resultText
                    onPartialOutput(resultText)
                }
            }

        default:
            let subtype = json["subtype"] as? String
            let label = subtype != nil ? "\(type)/\(subtype!)" : type
            onPartialOutput("\u{001B}[90m[\(label)] \u{001B}[0m")
        }
    }
}
