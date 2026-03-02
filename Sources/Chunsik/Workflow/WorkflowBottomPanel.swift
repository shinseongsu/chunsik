import SwiftUI

extension WorkflowDashboardView {
    var bottomPanel: some View {
        VStack(spacing: 0) {
            if let nodeID = workflowManager.selectedNodeID,
               let node = workflowManager.currentWorkflow?.node(by: nodeID) {
                if node.status == .running || nodeOutputStore.isStreaming[nodeID] == true {
                    NodeTerminalView(node: node)
                        .frame(maxHeight: 250)
                    Divider()
                } else if !node.outputData.isEmpty {
                    NodeResultDetailView(node: node)
                        .frame(maxHeight: 200)
                    Divider()
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                if let path = workflowManager.currentWorkflow?.projectPath, !path.isEmpty {
                    Text(path)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("프로젝트 경로 미설정")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("찾아보기...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.message = "워크플로우에 사용할 프로젝트 폴더를 선택하세요"
                    if panel.runModal() == .OK, let url = panel.url {
                        workflowManager.currentWorkflow?.projectPath = url.path
                    }
                }
                .font(.system(size: 11))

                if let path = workflowManager.currentWorkflow?.projectPath, !path.isEmpty {
                    Button {
                        workflowManager.currentWorkflow?.projectPath = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            HStack(spacing: 8) {
                TextField("프로젝트 요구사항을 입력하세요...", text: $requirementText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    let text = requirementText
                    requirementText = ""
                    Task {
                        await workflowManager.startWorkflow(requirement: text)
                    }
                } label: {
                    Image(systemName: workflowManager.isRunning ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
                .disabled(requirementText.trimmingCharacters(in: .whitespaces).isEmpty || workflowManager.isRunning)
            }
            .padding(12)
        }
    }

    var templateSaveSheet: some View {
        VStack(spacing: 16) {
            Text("템플릿으로 저장")
                .font(.headline)

            TextField("템플릿 이름", text: $templateName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("취소") {
                    showTemplateSave = false
                    templateName = ""
                }

                Spacer()

                Button("저장") {
                    workflowManager.saveAsTemplate(name: templateName)
                    showTemplateSave = false
                    templateName = ""
                }
                .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}
