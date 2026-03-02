import SwiftUI

struct ToolConfigEditorView: View {
    @Binding var toolConfigs: [ToolConfig]

    @State private var showAddSheet = false

    var body: some View {
        Section("MCP 도구") {
            if toolConfigs.isEmpty {
                Text("연결된 도구 없음")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                ForEach(toolConfigs) { tool in
                    HStack {
                        Toggle(isOn: Binding(
                            get: { tool.isEnabled },
                            set: { newValue in
                                if let idx = toolConfigs.firstIndex(where: { $0.id == tool.id }) {
                                    toolConfigs[idx].isEnabled = newValue
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.name)
                                    .font(.system(size: 12, weight: .medium))
                                Text(tool.command)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)

                        Button {
                            toolConfigs.removeAll { $0.id == tool.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                showAddSheet = true
            } label: {
                Label("MCP 서버 추가", systemImage: "plus.circle.fill")
                    .font(.system(size: 12))
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddToolConfigSheet { newTool in
                toolConfigs.append(newTool)
            }
        }
    }
}

struct AddToolConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var command = ""
    @State private var argsText = ""
    @State private var envPairs: [(key: String, value: String)] = []

    let onAdd: (ToolConfig) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("MCP 서버 추가")
                .font(.headline)
                .padding()

            Divider()

            Form {
                TextField("이름", text: $name)
                    .help("예: filesystem, github")
                TextField("명령어", text: $command)
                    .help("예: npx, python")
                TextField("인자 (쉼표 구분)", text: $argsText)
                    .help("예: -y,@modelcontextprotocol/server-filesystem,/tmp")

                Section("환경 변수") {
                    ForEach(envPairs.indices, id: \.self) { index in
                        HStack {
                            TextField("키", text: Binding(
                                get: { envPairs[index].key },
                                set: { envPairs[index].key = $0 }
                            ))
                            TextField("값", text: Binding(
                                get: { envPairs[index].value },
                                set: { envPairs[index].value = $0 }
                            ))
                            Button {
                                envPairs.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {
                        envPairs.append((key: "", value: ""))
                    } label: {
                        Label("환경 변수 추가", systemImage: "plus.circle.fill")
                            .font(.system(size: 12))
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Button("취소") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("추가") {
                    let args = argsText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    var env: [String: String] = [:]
                    for pair in envPairs where !pair.key.isEmpty {
                        env[pair.key] = pair.value
                    }
                    let tool = ToolConfig(name: name, command: command, args: args, env: env)
                    onAdd(tool)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || command.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 450)
    }
}
