import CoreGraphics
import os.log

/// Protocol for posting CGEvents, enabling test mocking.
protocol EventPoster: Sendable {
    func post(keyCode: CGKeyCode, modifiers: CGEventFlags, keyDown: Bool)
}

struct SystemEventPoster: EventPoster {
    func post(keyCode: CGKeyCode, modifiers: CGEventFlags, keyDown: Bool) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else { return }
        event.flags = modifiers
        event.post(tap: .cghidEventTap)
    }
}

struct KeystrokeExecutor: Sendable {
    private static let logger = Logger(subsystem: "com.nuimo.controller", category: "KeystrokeExecutor")

    let poster: any EventPoster

    init(poster: any EventPoster = SystemEventPoster()) {
        self.poster = poster
    }

    func execute(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        Self.logger.info("Posting keystroke: keyCode=\(keyCode), modifiers=\(modifiers.rawValue)")
        poster.post(keyCode: keyCode, modifiers: modifiers, keyDown: true)
        poster.post(keyCode: keyCode, modifiers: modifiers, keyDown: false)
    }
}
