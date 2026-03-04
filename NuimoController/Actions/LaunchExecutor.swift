import AppKit
import os.log

struct LaunchExecutor: Sendable {
    private static let logger = Logger(subsystem: "com.nuimo.controller", category: "LaunchExecutor")

    func execute(app: String) {
        Self.logger.info("Launching app: \(app)")

        if app.contains(".") && !app.contains("/") {
            // Looks like a bundle ID
            launchByBundleId(app)
        } else {
            launchByName(app)
        }
    }

    private func launchByBundleId(_ bundleId: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            Self.logger.error("App not found for bundle ID: \(bundleId)")
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    private func launchByName(_ name: String) {
        let url = URL(fileURLWithPath: "/Applications/\(name).app")
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else {
            Self.logger.error("App not found: \(name)")
        }
    }
}
