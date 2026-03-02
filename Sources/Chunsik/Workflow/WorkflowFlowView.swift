import SwiftUI

struct WorkflowFlowView: View {
    @EnvironmentObject var workflowManager: WorkflowManager

    var body: some View {
        NodeCanvasView()
    }
}
