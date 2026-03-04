import ServiceManagement
import os.log

final class LaunchAtLogin: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "LaunchAtLogin")

    var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                    logger.info("Launch at login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    logger.info("Launch at login disabled")
                }
            } catch {
                logger.error("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }

    func toggle() {
        isEnabled = !isEnabled
    }
}
