import Foundation

struct ToolConfig: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var command: String
    var args: [String]
    var env: [String: String]
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        args: [String] = [],
        env: [String: String] = [:],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.args = args
        self.env = env
        self.isEnabled = isEnabled
    }

    var mcpServerEntry: [String: Any] {
        var entry: [String: Any] = [
            "command": command,
            "args": args,
        ]
        if !env.isEmpty {
            entry["env"] = env
        }
        return entry
    }
}
