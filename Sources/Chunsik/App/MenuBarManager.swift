import AppKit
import SwiftUI

extension AppDelegate {
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemDisplay()
        rebuildMenu()
    }

    func updateStatusItemDisplay() {
        guard let button = statusItem?.button else { return }

        let connected = connectionMonitor.isConnected
        let iconName = connected ? "bolt.fill" : "bolt.slash.fill"

        let icon = NSImage(systemSymbolName: iconName, accessibilityDescription: "Claude 연결 상태")
        icon?.isTemplate = true

        let hasUsage = (tokenTracker.claudeUsage?.totalTokens ?? 0) > 0 || tokenTracker.appTotalTokens > 0
        let displayText = hasUsage
            ? tokenTracker.menuBarDisplay
            : (connected ? "연결됨" : "끊김")

        let attachment = NSTextAttachment()
        attachment.image = icon

        let attrString = NSMutableAttributedString()
        attrString.append(NSAttributedString(attachment: attachment))
        attrString.append(NSAttributedString(string: " "))

        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize - 1, weight: .medium)
        attrString.append(NSAttributedString(string: displayText, attributes: [.font: font]))

        button.attributedTitle = attrString
        button.image = nil
    }

    func rebuildMenu() {
        let menu = NSMenu()

        let headerItem = NSMenuItem()
        headerItem.view = NSHostingView(rootView:
            MenuBarStatusHeader(
                connectionMonitor: connectionMonitor,
                tokenTracker: tokenTracker
            )
            .frame(width: 260)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        )
        menu.addItem(headerItem)
        menu.addItem(.separator())

        for agent in agentManager.agents {
            let item = NSMenuItem(
                title: "\(agent.name)  —  \(agent.status.displayName)",
                action: #selector(agentMenuItemClicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = agent.id
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            item.image = NSImage(systemSymbolName: agent.status.systemImage, accessibilityDescription: nil)?
                .withSymbolConfiguration(symbolConfig)
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let dashboardItem = NSMenuItem(title: "대시보드 열기", action: #selector(showDashboardAction), keyEquivalent: "d")
        dashboardItem.target = self
        menu.addItem(dashboardItem)

        let workflowItem = NSMenuItem(title: "워크플로우", action: #selector(showDashboardAction), keyEquivalent: "w")
        workflowItem.target = self
        menu.addItem(workflowItem)

        let settingsItem = NSMenuItem(title: "설정...", action: #selector(showDashboardAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "연결 상태 새로고침", action: #selector(refreshConnection), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "종료", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }
}
