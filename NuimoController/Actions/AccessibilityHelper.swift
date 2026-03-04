import AppKit
import os.log

enum AccessibilityHelper {
    private static let logger = Logger(subsystem: "com.nuimo.controller", category: "Accessibility")

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func promptIfNeeded() {
        guard !isTrusted else { return }
        logger.warning("Accessibility access not granted — prompting user")

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
