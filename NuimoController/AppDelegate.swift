import AppKit
import os.log

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "AppDelegate")

    // MARK: - Components
    var bleManager: (any BLEManagerProtocol)?
    var eventDispatcher: (any EventDispatcherProtocol)?
    var configLoader: (any ConfigLoaderProtocol)?
    var actionExecutor: (any ActionExecutorProtocol)?
    var ledController: (any LEDControllerProtocol)?

    private(set) var launchAtLogin = LaunchAtLogin()
    private(set) var sleepWakeHandler = SleepWakeHandler()
    private(set) var cliOptions = CLIOptions()

    func applicationDidFinishLaunching(_ notification: Notification) {
        cliOptions = CLIParser.parse()
        if cliOptions.verbose {
            logger.info("Verbose logging enabled")
        }
        logger.info("NuimoController starting up")
        setupStatusBar()
        setupSleepWake()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.grid.3x3", accessibilityDescription: "Nuimo Controller")
        }

        statusItem.menu = buildMenu()
        logger.info("Status bar item created")
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let statusMenuItem = NSMenuItem(title: "Status: Disconnected", action: nil, keyEquivalent: "")
        statusMenuItem.tag = MenuItemTag.status.rawValue
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Reconnect", action: #selector(reconnectClicked), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Reload Config", action: #selector(reloadConfigClicked), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.tag = MenuItemTag.launchAtLogin.rawValue
        loginItem.state = launchAtLogin.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q"))

        return menu
    }

    // MARK: - Sleep/Wake

    private func setupSleepWake() {
        sleepWakeHandler.onSleep = { [weak self] in
            (self?.bleManager as? BLEManager)?.pauseForSleep()
        }
        sleepWakeHandler.onWake = { [weak self] in
            (self?.bleManager as? BLEManager)?.resumeAfterWake()
        }
        sleepWakeHandler.startObserving()
    }

    // MARK: - Menu Actions

    @objc func reconnectClicked() {
        logger.info("Reconnect requested")
        bleManager?.reconnect()
    }

    @objc func reloadConfigClicked() {
        logger.info("Config reload requested")
        do {
            try configLoader?.reload()
        } catch {
            logger.error("Config reload failed: \(error.localizedDescription)")
        }
    }

    @objc func toggleLaunchAtLogin() {
        launchAtLogin.toggle()
        // Update menu to reflect new state
        statusItem.menu = buildMenu()
    }

    @objc func quitClicked() {
        logger.info("Quit requested")
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Accessors for testing

    var currentStatusItem: NSStatusItem? { statusItem }
}

// MARK: - Menu Item Tags

enum MenuItemTag: Int {
    case status = 100
    case launchAtLogin = 101
}
