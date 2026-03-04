@testable import NuimoController

final class MockBLEManager: BLEManagerProtocol, @unchecked Sendable {
    var startScanningCalled = false
    var stopScanningCalled = false
    var reconnectCalled = false

    func startScanning() { startScanningCalled = true }
    func stopScanning() { stopScanningCalled = true }
    func reconnect() { reconnectCalled = true }
}

final class MockEventDispatcher: EventDispatcherProtocol, @unchecked Sendable {
    var lastDispatchedEvent: NuimoEvent?

    func dispatch(_ event: NuimoEvent) { lastDispatchedEvent = event }
}

final class MockConfigLoader: ConfigLoaderProtocol, @unchecked Sendable {
    var loadCalled = false
    var reloadCalled = false

    func load() throws { loadCalled = true }
    func reload() throws { reloadCalled = true }
}

final class MockActionExecutor: ActionExecutorProtocol, @unchecked Sendable {
    var lastAction: NuimoAction?

    func execute(_ action: NuimoAction) { lastAction = action }
}

final class MockLEDController: LEDControllerProtocol, @unchecked Sendable {
    var lastPattern: String?

    func showPattern(_ pattern: String, brightness: UInt8, duration: Double) {
        lastPattern = pattern
    }
}
