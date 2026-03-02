import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingWindow: FloatingCharacterWindow?
    var dashboardWindow: NSWindow?

    var statusItem: NSStatusItem?
    var cancellables = Set<AnyCancellable>()

    let agentManager = AgentManager()
    let settingsStore = SettingsStore()
    let tokenTracker = TokenTracker()
    let nodeOutputStore = NodeOutputStore()
    lazy var connectionMonitor = ConnectionMonitor(settingsStore: settingsStore)
    lazy var workflowManager = WorkflowManager(agentManager: agentManager, settingsStore: settingsStore, nodeOutputStore: nodeOutputStore)

    func applicationDidFinishLaunching(_ notification: Notification) {
        agentManager.tokenTracker = tokenTracker
        _ = connectionMonitor

        setupStatusItem()
        observeStatusChanges()

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        setupFloatingWindow()
    }

    func observeStatusChanges() {
        tokenTracker.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.updateStatusItemDisplay() }
            }
            .store(in: &cancellables)

        connectionMonitor.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.updateStatusItemDisplay() }
            }
            .store(in: &cancellables)

        agentManager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.rebuildMenu() }
            }
            .store(in: &cancellables)

        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateStatusItemDisplay()
            }
            .store(in: &cancellables)
    }

    @objc func agentMenuItemClicked(_ sender: NSMenuItem) {
        guard let agentID = sender.representedObject as? UUID else { return }
        agentManager.selectedAgentID = agentID
        toggleDashboard()
    }

    @objc func showDashboardAction() { showDashboard() }
    @objc func refreshConnection() { connectionMonitor.checkConnection() }
    @objc func quitApp() { NSApplication.shared.terminate(nil) }

    func setupFloatingWindow() {
        guard floatingWindow == nil else { return }

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let windowWidth: CGFloat = 600
        let windowHeight: CGFloat = 400
        let x = screenFrame.maxX - windowWidth - 20
        let y = screenFrame.minY + 20

        let contentRect = NSRect(x: x, y: y, width: windowWidth, height: windowHeight)
        let panel = FloatingCharacterWindow(contentRect: contentRect)

        let floatingView = FloatingCharacterView {
            self.toggleDashboard()
        }
        .environmentObject(agentManager)
        .environmentObject(settingsStore)

        let hostingView = TransparentHostingView(rootView: floatingView)
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        self.floatingWindow = panel
    }

    func toggleDashboard() {
        if let window = dashboardWindow, window.isVisible {
            window.orderOut(nil)
        } else {
            showDashboard()
        }
    }

    func showDashboard() {
        if dashboardWindow == nil {
            workflowManager.ensureWorkflow()

            let dashboardView = DashboardView()
                .environmentObject(agentManager)
                .environmentObject(settingsStore)
                .environmentObject(workflowManager)
                .environmentObject(nodeOutputStore)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "춘식이 대시보드"
            window.center()
            window.contentView = NSHostingView(rootView: dashboardView)
            window.isReleasedWhenClosed = false
            self.dashboardWindow = window
        }

        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
