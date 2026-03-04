import Foundation
import AppKit
import os.log

final class SleepWakeHandler: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "SleepWake")

    var onSleep: (() -> Void)?
    var onWake: (() -> Void)?

    private(set) var isSleeping: Bool = false

    func startObserving() {
        let wsnc = NSWorkspace.shared.notificationCenter

        wsnc.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        wsnc.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        logger.info("Sleep/wake observation started")
    }

    func stopObserving() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        logger.info("Sleep/wake observation stopped")
    }

    @objc private func handleSleep(_ notification: Notification) {
        logger.info("System going to sleep — pausing BLE")
        isSleeping = true
        onSleep?()
    }

    @objc private func handleWake(_ notification: Notification) {
        logger.info("System woke up — resuming BLE")
        isSleeping = false
        onWake?()
    }

    deinit {
        stopObserving()
    }
}
