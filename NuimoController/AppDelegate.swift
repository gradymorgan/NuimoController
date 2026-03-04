import AppKit
import Combine
import CoreBluetooth
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
    private var cancellables = Set<AnyCancellable>()
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        cliOptions = CLIParser.parse()
        if cliOptions.verbose {
            logger.info("Verbose logging enabled")
        }
        logger.info("NuimoController starting up")
        setupComponents()
        setupStatusBar()
        setupSleepWake()
    }

    // MARK: - Component Bootstrap

    private func setupComponents() {
        let loader = ConfigLoader()
        do {
            try loader.load()
        } catch {
            logger.error("Failed to load config: \(error.localizedDescription)")
        }
        self.configLoader = loader

        let config = loader.currentConfig

        let registry = ActionRegistry()
        registry.updateFromConfig(config)

        let executor = ActionExecutor()
        self.actionExecutor = executor

        let dispatcher = EventDispatcher(
            actionRegistry: registry,
            actionExecutor: executor
        )
        self.eventDispatcher = dispatcher

        let ble = BLEManager()
        self.bleManager = ble

        let led = LEDController(bleManager: ble)
        led.updateSettings(
            brightness: config.ledBrightness,
            duration: config.ledDisplayDuration,
            onionSkinning: config.ledOnionSkinning
        )
        self.ledController = led

        // Apply Nuimo connection settings
        ble.deviceNameFilter = config.deviceName
        ble.autoReconnect = config.autoReconnect
        ble.reconnectInterval = config.reconnectIntervalSeconds

        // Re-wire components when config changes
        loader.configChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak registry, weak led, weak ble] (newConfig: NuimoConfig) in
                registry?.updateFromConfig(newConfig)
                led?.updateSettings(
                    brightness: newConfig.ledBrightness,
                    duration: newConfig.ledDisplayDuration,
                    onionSkinning: newConfig.ledOnionSkinning
                )
                ble?.deviceNameFilter = newConfig.deviceName
                ble?.autoReconnect = newConfig.autoReconnect
                ble?.reconnectInterval = newConfig.reconnectIntervalSeconds
            }
            .store(in: &cancellables)

        ble.delegate = self
        ble.startScanning()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let sbc = StatusBarController(statusItem: statusItem)
        self.statusBarController = sbc
        sbc.updateConnectionState(.idle)
        logger.info("Status bar item created")
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
    }

    @objc func quitClicked() {
        logger.info("Quit requested")
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Accessors for testing

    var currentStatusItem: NSStatusItem? { statusItem }
}

// MARK: - BLEManagerDelegate

extension AppDelegate: BLEManagerDelegate {
    func bleManager(_ manager: BLEManager, didChangeState state: BLEManagerState) {
        DispatchQueue.main.async { [weak self] in
            self?.statusBarController?.updateConnectionState(state)
        }
    }

    func bleManager(_ manager: BLEManager, didReceiveData data: Data, forCharacteristic uuid: CBUUID) {
        if let dispatcher = eventDispatcher as? EventDispatcher {
            dispatcher.handleBLEData(data, characteristicUUID: uuid)
        } else {
            logger.error("Event dispatcher does not support handleBLEData")
        }
    }

    func bleManager(_ manager: BLEManager, didReadDeviceInfo key: String, value: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusBarController?.updateDeviceInfo(key: key, value: value)
        }
    }

    func bleManager(_ manager: BLEManager, didUpdateBattery level: UInt8) {
        DispatchQueue.main.async { [weak self] in
            self?.statusBarController?.updateBattery(level)
        }
    }
}

// MARK: - Menu Item Tags

enum MenuItemTag: Int {
    case status = 100
    case launchAtLogin = 101
}

