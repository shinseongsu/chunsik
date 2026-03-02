import SwiftUI

struct NodeTerminalView: View {
    let node: WorkflowNode
    @EnvironmentObject var nodeOutputStore: NodeOutputStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if nodeOutputStore.isStreaming[node.id] == true {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .opacity(pulseOpacity)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: pulseOpacity
                        )
                        .onAppear { pulseOpacity = 0.3 }
                }

                Text(node.title)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.green)

                if let role = node.agentRole {
                    Text("· \(role.displayName)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                }

                Spacer()

                if nodeOutputStore.isStreaming[node.id] == true {
                    Text("STREAMING")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .clipShape(Capsule())
                } else {
                    Text("COMPLETE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.green.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(white: 0.1))

            Divider().background(Color.green.opacity(0.3))

            ScrollViewReader { proxy in
                ScrollView {
                    Text(styledText)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)

                    Color.clear
                        .frame(height: 1)
                        .id("terminal_bottom")
                }
                .onChange(of: rawText) {
                    if nodeOutputStore.isStreaming[node.id] == true {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("terminal_bottom", anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    proxy.scrollTo("terminal_bottom", anchor: .bottom)
                }
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    @State private var pulseOpacity: Double = 1.0

    private var rawText: String {
        if let streamingOutput = nodeOutputStore.outputs[node.id], !streamingOutput.isEmpty {
            return streamingOutput
        }
        return node.outputData.isEmpty ? "Waiting for output..." : node.outputData
    }

    private var styledText: AttributedString {
        Self.parseANSI(rawText)
    }

    private static func parseANSI(_ input: String) -> AttributedString {
        var result = AttributedString()
        let defaultColor = Color(white: 0.9)
        var currentColor = defaultColor

        let scanner = Scanner(string: input)
        scanner.charactersToBeSkipped = nil

        while !scanner.isAtEnd {
            if let text = scanner.scanUpToString("\u{001B}") {
                var segment = AttributedString(text)
                segment.foregroundColor = currentColor
                result.append(segment)
            }

            if scanner.scanString("\u{001B}[") != nil {
                if let codeStr = scanner.scanUpToString("m") {
                    _ = scanner.scanString("m")
                    currentColor = colorForANSICode(codeStr, default: defaultColor)
                }
            }
        }

        return result
    }

    private static func colorForANSICode(_ code: String, default defaultColor: Color) -> Color {
        switch code {
        case "0":  return defaultColor
        case "31": return Color.red
        case "32": return Color.green
        case "33": return Color.yellow
        case "34": return Color.blue
        case "36": return Color.cyan
        case "90": return Color(white: 0.5)
        default:   return defaultColor
        }
    }
}
