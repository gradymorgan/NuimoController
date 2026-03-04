import AppKit
import os.log

final class StatusBarController: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "StatusBar")

    private let statusItem: NSStatusItem
    private var connectionState: BLEManagerState = .idle
    private var batteryLevel: UInt8?
    private var deviceInfo: [String: String] = [:]

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
    }

    func updateConnectionState(_ state: BLEManagerState) {
        connectionState = state
        updateIcon()
        updateMenu()
    }

    func updateBattery(_ level: UInt8) {
        batteryLevel = level
        updateMenu()
        updateIcon()
    }

    func updateDeviceInfo(key: String, value: String) {
        deviceInfo[key] = value
        updateMenu()
    }

    // MARK: - Icon

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        let symbolName: String
        switch connectionState {
        case .connected:
            if let battery = batteryLevel, battery <= BatteryMonitor.lowBatteryThreshold {
                symbolName = "circle.grid.3x3.fill"  // Will add badge via accessibilityDescription
            } else {
                symbolName = "circle.grid.3x3.fill"
            }
        case .scanning, .connecting, .discoveringServices:
            symbolName = "circle.grid.3x3"
        case .disconnected:
            symbolName = "circle.grid.3x3"
        case .idle:
            symbolName = "circle.grid.3x3"
        }

        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Nuimo Controller")

        // Apply tint to indicate state
        if connectionState == .connected {
            button.contentTintColor = nil // System default (active)
        } else {
            button.contentTintColor = .secondaryLabelColor // Gray (inactive)
        }
    }

    // MARK: - Menu

    private func updateMenu() {
        statusItem.menu = buildMenu()
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // Status
        let statusTitle: String
        switch connectionState {
        case .idle: statusTitle = "Status: Idle"
        case .scanning: statusTitle = "Status: Scanning..."
        case .connecting: statusTitle = "Status: Connecting..."
        case .discoveringServices: statusTitle = "Status: Discovering..."
        case .connected: statusTitle = "Status: Connected"
        case .disconnected: statusTitle = "Status: Disconnected"
        }

        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.tag = MenuItemTag.status.rawValue
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        // Battery
        if let battery = batteryLevel {
            let batteryItem = NSMenuItem(title: "Battery: \(battery)%", action: nil, keyEquivalent: "")
            batteryItem.isEnabled = false
            menu.addItem(batteryItem)
        }

        // Device info
        if !deviceInfo.isEmpty {
            menu.addItem(NSMenuItem.separator())
            for (key, value) in deviceInfo.sorted(by: { $0.key < $1.key }) {
                let item = NSMenuItem(title: "\(key.capitalized): \(value)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Reconnect", action: #selector(AppDelegate.reconnectClicked), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Reload Config", action: #selector(AppDelegate.reloadConfigClicked), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Config File", action: #selector(StatusBarController.openConfigFile), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quitClicked), keyEquivalent: "q"))

        return menu
    }

    @objc func openConfigFile() {
        let path = DefaultConfig.configFilePath
        let fm = FileManager.default
        if !fm.fileExists(atPath: path) {
            // Create default config
            try? fm.createDirectory(atPath: DefaultConfig.configDirectoryPath, withIntermediateDirectories: true)
            try? DefaultConfig.yaml.write(toFile: path, atomically: true, encoding: .utf8)
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}
